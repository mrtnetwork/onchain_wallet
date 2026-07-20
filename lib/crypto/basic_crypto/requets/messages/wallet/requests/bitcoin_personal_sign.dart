import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';

import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/personal_sign_response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';

final class WalletRequestBitcoinSignMessage
    extends WalletRequest<CryptoBitcoinPersonalSignResponse> {
  final List<int> message;
  final Bip32DerivationIndex index;
  final String messagePrefix;
  final BIP137Mode? mode;
  final bool useTaproot;
  WalletRequestBitcoinSignMessage._({
    required this.message,
    required this.index,
    required this.messagePrefix,
    required this.mode,
    required this.useTaproot,
  });

  factory WalletRequestBitcoinSignMessage(
      {required List<int> message,
      required Bip32DerivationIndex index,
      required bool useTaproot,
      required BIP137Mode mode,
      required String messagePrefix}) {
    return WalletRequestBitcoinSignMessage._(
        message: message.asImmutableBytes,
        index: index,
        messagePrefix: messagePrefix,
        mode: useTaproot ? null : mode,
        useTaproot: useTaproot);
  }

  factory WalletRequestBitcoinSignMessage.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletRequestMethod.bitcoinSignMessage.tag);
    return WalletRequestBitcoinSignMessage._(
        message: values.rawValueAt(0),
        index: Bip32DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(1)),
        messagePrefix: values.rawValueAt(2),
        mode: values.maybeObjectAt<BIP137Mode, CborIntValue>(
            3, (e) => BIP137Mode.fromValue(e.value)),
        useTaproot: values.rawValueAt(4));
  }

  @override
  WalletRequestMethod get method => WalletRequestMethod.bitcoinSignMessage;
  static CryptoBitcoinPersonalSignResponse sign(
      {required MemoryWalletContext wallet,
      required Bip32DerivationIndex index,
      required List<int> message,
      required bool useTaproot,
      required BIP137Mode? mode,
      required String messagePrefix}) {
    final responseKeys = wallet.readSecretKeys([index]).keys.first;
    final signer = BitcoinKeySigner.fromKeyBytes(responseKeys.key.privateKeyBytes());
    final digest =
        QuickCrypto.sha256Hash(BitcoinSignerUtils.magicMessage(message, messagePrefix))
            .asImmutableBytes;
    List<int> signature;
    if (useTaproot) {
      signature = signer.signBip340Const(digest: digest);
    } else {
      signature = signer.signMessageConst(message: digest, hashMessage: false);
      if (mode != null) {
        final int rId = signature[0] + mode.header;
        signature = [rId, ...signature.sublist(1)];
      }
    }
    return CryptoBitcoinPersonalSignResponse(signature: signature, digest: digest);
  }

  // @override
  // Future<MessageArgsTwoBytes> getResult(MemoryWalletContext wallet) async {
  //   return sign(
  //       wallet: wallet.masterKey,
  //       index: index,
  //       message: message,
  //       mode: mode,
  //       messagePrefix: messagePrefix,
  //       useTaproot: useTaproot);
  // }

  @override
  Future<CryptoBitcoinPersonalSignResponse> parsResult(MessageArgsComplete result) async {
    return CryptoBitcoinPersonalSignResponse.deserialize(object: result.result);
  }

  @override
  Future<CryptoBitcoinPersonalSignResponse> result(
      MemoryWalletContext wallet, AppContext context) async {
    return sign(
        wallet: wallet,
        index: index,
        message: message,
        mode: mode,
        useTaproot: useTaproot,
        messagePrefix: messagePrefix);
  }

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(message),
        index.toCbor(),
        messagePrefix.toCbor(),
        mode?.header.toCbor(),
        useTaproot.toCbor()
      ];
}
