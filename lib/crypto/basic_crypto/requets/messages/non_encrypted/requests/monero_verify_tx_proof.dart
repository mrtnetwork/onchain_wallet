import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';

final class NoneEncryptedRequestMoneroVerifyTxProof
    extends CryptoRequest<AppSerializationBigInt> {
  final String txId;
  final DefaultAPIProvider provider;
  final String? message;
  final MoneroAddress address;
  final String signature;
  NoneEncryptedRequestMoneroVerifyTxProof(
      {required this.txId,
      required this.provider,
      required this.message,
      required this.address,
      required this.signature});
  factory NoneEncryptedRequestMoneroVerifyTxProof.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CryptoRequestMethod.moneroVerifyProof.tag);

    return NoneEncryptedRequestMoneroVerifyTxProof(
        txId: values.rawValueAt(0),
        provider:
            DefaultAPIProvider.deserialize(object: values.objectAt<CborTagValue>(1)),
        message: values.rawValueAt(2),
        address: MoneroAddress(values.rawValueAt(3)),
        signature: values.rawValueAt(4));
  }

  @override
  AppSerializationBigInt parsResult(MessageArgsComplete result) {
    return AppSerializationBigInt.deserialize(obj: result.result);
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.moneroVerifyProof;

  @override
  Future<AppSerializationBigInt> result(AppContext context,
      {List<int>? encryptedPart}) async {
    final client = MoneroClient.fromProviders(provider: provider, netApi: context.netApi);
    try {
      final transaction = await client.getTx(txId);
      final amount = MoneroTransactionHelper.checkProofVar(
          transaction: transaction,
          address: address,
          proofStr: signature,
          message: message);
      return AppSerializationBigInt(amount ?? BigInt.from(-1));
    } finally {
      client.dispose();
    }
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems => [
        txId.toCbor(),
        provider.toCbor(),
        message?.toCbor(),
        address.address.toCbor(),
        signature.toCbor()
      ];
}
