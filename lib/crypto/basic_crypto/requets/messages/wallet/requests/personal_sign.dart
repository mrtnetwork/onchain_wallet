import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/personal_sign_response.dart';

final class WalletRequestSignMessage extends WalletRequest<CryptoPersonalSignResponse> {
  final List<int> message;
  final Bip32DerivationIndex index;
  final int? payloadLength;
  final NetworkType network;
  const WalletRequestSignMessage._({
    required this.message,
    required this.index,
    this.payloadLength,
    required this.network,
  });

  factory WalletRequestSignMessage(
      {required List<int> message,
      required Bip32DerivationIndex index,
      NetworkType network = NetworkType.ethereum,
      int? payloadLength}) {
    return WalletRequestSignMessage._(
      message: message.asImmutableBytes,
      index: index,
      network: network,
      payloadLength: payloadLength,
    );
  }
  factory WalletRequestSignMessage.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletRequestMethod.signMessage.tag);
    return WalletRequestSignMessage(
        message: values.rawValueAt(0),
        index: Bip32DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(1)),
        payloadLength: values.rawValueAt(2),
        network: NetworkType.fromIdentifier(values.rawValueAt(3)));
  }

  @override
  WalletRequestMethod get method => WalletRequestMethod.signMessage;
  static List<int> sign(
      {required MemoryWalletContext wallet,
      required Bip32DerivationIndex index,
      required List<int> message,
      required NetworkType network,
      int? payloadLength}) {
    switch (network) {
      case NetworkType.ethereum:
        final responseKeys = wallet.readSecretKeys([index]).keys.first;
        final signer = ETHSigner.fromKeyBytes(responseKeys.key.privateKeyBytes());
        return signer.signProsonalMessageConst(message, payloadLength: payloadLength);
      case NetworkType.tron:
        final responseKeys = wallet.readSecretKeys([index]).keys.first;
        final signer = TronSigner.fromKeyBytes(responseKeys.key.privateKeyBytes());
        return signer.signProsonalMessageConst(message, payloadLength: payloadLength);
      default:
        throw WalletExceptionConst.unsuportedFeature;
    }
  }

  @override
  Future<CryptoPersonalSignResponse> parsResult(MessageArgsComplete result) async {
    return CryptoPersonalSignResponse.deserialize(object: result.result);
  }

  @override
  Future<CryptoPersonalSignResponse> result(
      MemoryWalletContext wallet, AppContext context) async {
    final signature =
        sign(wallet: wallet, index: index, message: message, network: network);
    return CryptoPersonalSignResponse(signature: signature);
  }

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(message),
        index.toCbor(),
        payloadLength?.toCbor(),
        network.identifier.id.toCbor()
      ];
}
