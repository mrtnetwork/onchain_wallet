import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/wallet/keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain/solidity/abi/abi.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/personal_sign_response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';

final class WalletRequestEthereumTypedDataSign
    extends WalletRequest<CryptoPersonalSignResponse> {
  final EIP712Base message;
  final Bip32DerivationIndex index;

  const WalletRequestEthereumTypedDataSign._(
      {required this.message, required this.index});

  factory WalletRequestEthereumTypedDataSign({
    required EIP712Base message,
    required Bip32DerivationIndex index,
  }) {
    return WalletRequestEthereumTypedDataSign._(message: message, index: index);
  }
  factory WalletRequestEthereumTypedDataSign.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletRequestMethod.ethereumTypedDataSign.tag);
    return WalletRequestEthereumTypedDataSign(
        message: EIP712Base.fromJson(StringUtils.toJson(values.rawValueAt(0))),
        index:
            Bip32DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(1)));
  }

  @override
  WalletRequestMethod get method => WalletRequestMethod.ethereumTypedDataSign;

  static List<int> sign(
      {required MemoryWalletContext wallet,
      required Bip32DerivationIndex index,
      required EIP712Base message,
      int? payloadLength}) {
    final responseKeys = wallet.readSecretKeys([index]).keys.first;
    final signer = ETHSigner.fromKeyBytes(responseKeys.key.privateKeyBytes());
    final sign = signer.signConst(message.encode(hash: false));
    return sign.toBytes();
  }

  @override
  Future<CryptoPersonalSignResponse> parsResult(MessageArgsComplete result) async {
    return CryptoPersonalSignResponse.deserialize(object: result.result);
  }

  @override
  Future<CryptoPersonalSignResponse> result(
      MemoryWalletContext wallet, AppContext context) async {
    final signature = sign(wallet: wallet, index: index, message: message);
    return CryptoPersonalSignResponse(signature: signature);
  }

  @override
  List<CborObject?> get serializationItems =>
      [StringUtils.fromJson(message.toJson()).toCbor(), index.toCbor()];
}
