import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/read_account_public_keys_response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/zcash_context.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/account.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';

final class WalletRequestReadAccountPublicKeys
    extends WalletRequest<ReadAccountPublicKeysResponse> {
  final ReadAccountPublicKeyRequest request;
  const WalletRequestReadAccountPublicKeys(this.request);

  factory WalletRequestReadAccountPublicKeys.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletRequestMethod.readAccountPublicKeys.tag);
    return WalletRequestReadAccountPublicKeys(ReadAccountPublicKeyRequest.deserialize(
        object: values.objectAt<CborTagValue>(0)));
  }

  @override
  WalletRequestMethod get method => WalletRequestMethod.readAccountPublicKeys;

  @override
  Future<ReadAccountPublicKeysResponse> parsResult(MessageArgsComplete result) async {
    return ReadAccountPublicKeysResponse.deserialize(object: result.result);
  }

  @override
  Future<ReadAccountPublicKeysResponse> result(
      MemoryWalletContext wallet, AppContext context) async {
    final (crypto, _) = (await OnChainCryptoContext.inst(context)).unwrap();
    switch (request) {
      case ReadAccountPublicKeyRequestDefault request:
        final keys = wallet.readPublicKeys(request.keys.indexes);
        return ReadAccountPublicKeysResponseDefault(keys.keys);
      case ReadAccountPublicKeyRequestZcash request:
        List<ReadAccountPublicKeysResponseZcashReceivers> receivers = [];
        Bip32Slip10Secp256k1? transparent;
        SaplingDiversifiableFullViewingKey? sapling;
        OrchardFullViewingKey? orchard;
        OrchardIncomingViewingKey? orchardIvk;
        SaplingIncomingViewingKey? saplingIvk;
        Bip32Slip10Secp256k1? transparentIvk;
        CryptoPublicKeyDataWithInfo? getSingleKey(
            CryptoPublicKeysResponse key, ZcashAccountInfoType type) {
          if (key.keys.length == 1) return key.keys[0];
          if (type != ZcashAccountInfoType.p2shMsig) {
            throw AppInternalError.internalError("Unexpected sapling key response.");
          }
          return null;
        }
        for (final i in request.receivers) {
          final keys = wallet.readPublicKeys(i.indexes);
          receivers.add(ReadAccountPublicKeysResponseZcashReceivers(
              keys: keys.keys, type: i.type, index: i.index?.toU128(), change: i.change));
          final type = i.type;
          switch (type) {
            case ZcashAccountInfoType.orchard:
              final orchardKey = getSingleKey(keys, type)!;
              orchard = orchardKey.key.cast<Zip32PublicKeyData>().toFvk().cast();
              orchardIvk = orchard.toIvk(i.change!, context: crypto);
              continue;
            case ZcashAccountInfoType.sapling:
              final saplingKey = getSingleKey(keys, type)!;
              sapling = saplingKey.key.cast<Zip32PublicKeyData>().toFvk().cast();
              saplingIvk = sapling.toIvk(i.change!);
              continue;
            case ZcashAccountInfoType.p2pkh:
            case ZcashAccountInfoType.p2sh:
              final index = i.indexes.elementAt(0).cast<Bip32DerivationIndex>();
              final level = index.level();
              final change = index.change();
              if (level == Bip44Levels.addressIndex && change != null) {
                final keys =
                    wallet.readPublicKeys([index.take(Bip44Levels.account)]).keys.first;
                final bipKey = keys.key.cast<PublicKeyData>().toHdKey();
                if (bipKey == null || bipKey is! Bip32Slip10Secp256k1) {
                  throw AppInternalError.internalError("Unexpected bip key type.");
                }
                transparent = bipKey;
                transparentIvk = bipKey.childKey(Bip32KeyIndex(change.value));
              }
              continue;
            case ZcashAccountInfoType.p2shMsig:
              continue;
          }
        }
        ReadAccountPublicKeysResponseZcashFvk? ufvk;
        if (orchard != null || sapling != null) {
          final fvk = UnifiedFullViewingKey(
              network: request.network,
              orchard: orchard,
              sapling: sapling,
              transparent: transparent);
          final encodedUfvk = fvk.encode();
          final encodedUivk = UnifiedIncomingViewingKey(
                  network: request.network,
                  orchard: orchardIvk,
                  sapling: saplingIvk,
                  transparent: transparentIvk)
              .encode();
          ufvk = ReadAccountPublicKeysResponseZcashFvk(
            ufvk: encodedUfvk,
            uivk: encodedUivk,
            types: [
              if (orchard != null) ZcashAccountInfoType.orchard,
              if (saplingIvk != null) ZcashAccountInfoType.sapling,
              if (transparent != null)
                request.receivers.firstWhere((e) => e.type.isTransparent).type,
            ],
          );
        }

        return ReadAccountPublicKeysResponseZcash(keys: receivers, ufvk: ufvk);
    }
  }

  @override
  List<CborObject?> get serializationItems => [request.toCbor()];
}
