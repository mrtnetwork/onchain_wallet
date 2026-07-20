import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';

class CosmosWalletTransaction
    extends ChainTransaction<CosmosWalletTransactionTransferOutput> {
  CosmosWalletTransaction(
      {required String txId,
      required super.time,
      required super.outputs,
      super.web3Client,
      required super.totalOutput,
      required WalletCosmosNetwork network,
      WalletTransactionType? type,
      super.memos,
      super.status = WalletTransactionStatus.pending})
      : super(
            type: type ??
                (web3Client != null
                    ? WalletTransactionType.web3
                    : WalletTransactionType.send),
            txId: StringUtils.normalizeHex(txId));

  factory CosmosWalletTransaction.deserialize(WalletCosmosNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: NetworkType.cosmos.identifier);
    return CosmosWalletTransaction(
        txId: values.rawValueAt(0),
        time: values.rawValueAt(1),
        network: network,
        totalOutput: values.maybeObjectAt<WalletTransactionAmount, CborTagValue>(
            2, (e) => WalletTransactionAmount.deserialize(network, object: e)),
        outputs: values
            .listAt<CborTagValue>(3)
            .map((e) =>
                CosmosWalletTransactionTransferOutput.deserialize(network, object: e))
            .toList(),
        web3Client: values.maybeObjectAt<WalletWeb3ClientTransaction, CborTagValue>(
            4, (e) => WalletWeb3ClientTransaction.deserialize(object: e)),
        type: WalletTransactionType.fromValue(values.rawValueAt(5)),
        status: WalletTransactionStatus.fromValue(values.rawValueAt(6)),
        memos: values
            .listAt<CborTagValue>(7)
            .map((e) => WalletTransactionMemo.deserialize(object: e))
            .toList());
  }

  @override
  NetworkType get network => NetworkType.cosmos;
}

class CosmosWalletTransactionTransferOutput
    extends WalletTransactionTransferOutput<CosmosBaseAddress> {
  const CosmosWalletTransactionTransferOutput({required super.to, required super.amount});

  factory CosmosWalletTransactionTransferOutput.deserialize(WalletCosmosNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletTransactionOutputType.transfer.tag);
    return CosmosWalletTransactionTransferOutput(
        amount: WalletTransactionIntegerAmount.deserialize(network,
            object: values.objectAt<CborTagValue>(0)),
        to: CosmosBaseAddress.deserializeIAddress(bytes: values.rawValueAt(1)));
  }

  @override
  String get address => to.address;

  @override
  List<CborObject?> get serializationItems =>
      [amount.toCbor(), CborBytesValue(to.encodeAsIAddress())];
}
