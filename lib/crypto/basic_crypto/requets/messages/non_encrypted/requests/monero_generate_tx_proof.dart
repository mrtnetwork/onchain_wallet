import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/models/networks/monero/account/account.dart';

final class NoneEncryptedRequestMoneroGenerateTxProof
    extends CryptoRequest<AppSerializationString> {
  final String txId;
  final DefaultAPIProvider provider;
  final String? message;
  final List<List<int>>? txKeys;
  final MoneroAddress? receiverAddress;
  NoneEncryptedRequestMoneroGenerateTxProof(
      {required this.txId,
      required this.provider,
      required this.message,
      this.txKeys,
      this.receiverAddress});
  factory NoneEncryptedRequestMoneroGenerateTxProof.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CryptoRequestMethod.moneroGenerateProof.tag);

    return NoneEncryptedRequestMoneroGenerateTxProof(
        txId: values.rawValueAt(0),
        provider:
            DefaultAPIProvider.deserialize(object: values.objectAt<CborTagValue>(1)),
        message: values.rawValueAt(2),
        txKeys: values
            .listAt<CborBytesValue>(3, emptyOnNull: true)
            .map((e) => e.value)
            .toList()
            .emptyAsNull,
        receiverAddress: values.maybeObjectAt<MoneroAddress, CborStringValue>(
            4, (e) => MoneroAddress(e.value)));
  }

  @override
  AppSerializationString parsResult(MessageArgsComplete result) {
    return AppSerializationString.deserialize(obj: result.result);
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.moneroGenerateProof;

  @override
  Future<AppSerializationString> result(AppContext context,
      {List<int>? encryptedPart}) async {
    final client = MoneroClient.fromProviders(provider: provider, netApi: context.netApi);
    try {
      final account = MoneroAccountIndexWithPrimaryKey.deserialize(bytes: encryptedPart);
      final MoneroTransaction transaction = await client.getTx(txId);
      final txKeys = this.txKeys;
      final receiver = receiverAddress;
      MoneroTxProof? proof;
      if (txKeys != null && txKeys.isNotEmpty && receiver != null) {
        proof = MoneroTransactionHelper.generateOutProofVar(
            transaction: transaction,
            receiverAddress: receiver,
            allTxKeys: txKeys.map((e) => MoneroPrivateKey.fromBytes(e)).toList(),
            message: message);
      } else {
        proof = MoneroTransactionHelper.generateInProofVar(
            transaction: transaction,
            account: account.viewKey.account,
            index: account.index.index,
            message: message);
      }
      if (proof == null) {
        throw WalletExceptionConst.moneroProofGenerationFailed;
      }
      return AppSerializationString(proof.toBase58());
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
        AppSerialization.listFromObjects(
            txKeys?.map((e) => CborBytesValue(e)).toList() ?? []),
        receiverAddress?.address.toCbor()
      ];
}
