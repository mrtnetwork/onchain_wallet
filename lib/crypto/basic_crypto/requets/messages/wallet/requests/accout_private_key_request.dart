import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/read_account_private_key.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/zcash_context.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/account.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';

final class WalletRequestReadAccountPrivateKeys
    extends WalletRequest<ReadAccountPrivateKeysResponse> {
  final ReadAccountPrivateKeyRequest request;
  const WalletRequestReadAccountPrivateKeys(this.request);

  factory WalletRequestReadAccountPrivateKeys.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletRequestMethod.readAccountPrivateKeys.tag);
    return WalletRequestReadAccountPrivateKeys(ReadAccountPrivateKeyRequest.deserialize(
        object: values.objectAt<CborTagValue>(0)));
  }

  @override
  WalletRequestMethod get method => WalletRequestMethod.readAccountPrivateKeys;

  @override
  Future<ReadAccountPrivateKeysResponse> parsResult(MessageArgsComplete result) async {
    return ReadAccountPrivateKeysResponse.deserialize(object: result.result);
  }

  @override
  Future<ReadAccountPrivateKeysResponse> result(
      MemoryWalletContext wallet, AppContext context) async {
    final (crypto, _) = (await OnChainCryptoContext.inst(context)).unwrap();
    switch (request) {
      case ReadAccountPrivateKeyRequestDefault request:
        final keys = wallet.readSecretKeys(request.keys.indexes);
        return ReadAccountPrivateKeysResponseDefault(keys.keys);
      case ReadAccountPrivateKeyRequestZcash request:
        List<ReadAccountPrivateKeysResponseZcashReceivers> receivers = [];
        Bip32Slip10Secp256k1? transparent;
        Zip32Sapling? sapling;
        Zip32Orchard? orchard;
        CryptoPrivateKeyDataWithInfo? getSingleKey(
            CryptoPrivateKeysResponse key, ZcashAccountInfoType type) {
          if (key.keys.length == 1) return key.keys[0];
          if (type != ZcashAccountInfoType.p2shMsig) {
            throw AppInternalError.internalError("Unexpected sapling key response.");
          }
          return null;
        }
        bool hasOrchard = request.receivers.any((e) => e.type.isOrchard);
        bool hasSapling = request.receivers.any((e) => e.type.isSapling);
        bool hasStandardTransparent =
            request.receivers.any((e) => e.type.isStandardTransparent);
        bool canDeriveUfsk = hasOrchard && hasSapling && hasStandardTransparent;
        for (final i in request.receivers) {
          final keys = wallet.readSecretKeys(i.indexes);
          receivers.add(ReadAccountPrivateKeysResponseZcashReceivers(
              keys: keys.keys, type: i.type, index: i.index?.toU128(), change: i.change));
          if (!canDeriveUfsk) continue;
          final type = i.type;
          switch (type) {
            case ZcashAccountInfoType.orchard:
              final orchardKey = getSingleKey(keys, type)!;
              orchard = orchardKey.key.toHdKey() as Zip32Orchard;
              continue;
            case ZcashAccountInfoType.sapling:
              final saplingKey = getSingleKey(keys, type)!;
              sapling = saplingKey.key.toHdKey() as Zip32Sapling;
              continue;
            case ZcashAccountInfoType.p2pkh:
            case ZcashAccountInfoType.p2sh:
              final index = i.indexes.elementAt(0).cast<Bip32DerivationIndex>();
              final level = index.level();
              final change = index.change();
              if (level == Bip44Levels.addressIndex && change != null) {
                final keys =
                    wallet.readSecretKeys([index.take(Bip44Levels.account)]).keys.first;
                final bipKey = keys.key.cast<PrivateKeyData>().toHdKey();
                if (bipKey is! Bip32Slip10Secp256k1) {
                  throw AppInternalError.internalError("Unexpected bip key type.");
                }
                transparent = bipKey;
              }
              continue;
            case ZcashAccountInfoType.p2shMsig:
              continue;
          }
        }
        String? ufsk;
        // ReadAccountPrivateKeysResponseZcashFvk? ufvk;
        if (orchard != null && sapling != null && transparent != null) {
          final fvk = UnifiedSpendingKey(
              orchard: orchard,
              sapling: sapling,
              transparent: transparent,
              context: crypto,
              config: request.network.config());
          ufsk = BytesUtils.toHexString(fvk.encodeUnifiedSpeningKeyBytes());
        }
        return ReadAccountPrivateKeysResponseZcash(keys: receivers, ufsk: ufsk);
    }
  }

  @override
  List<CborObject?> get serializationItems => [request.toCbor()];
}
