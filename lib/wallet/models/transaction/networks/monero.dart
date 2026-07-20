import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';

class MoneroWalletTransactionProof {
  final String txId;
  final List<List<int>>? txKeys;
  final MoneroAddress recepient;
  const MoneroWalletTransactionProof(
      {required this.txKeys, required this.recepient, required this.txId});
}

class MoneroWalletTransaction extends ChainTransaction<MoneroWalletTransactionOutput> {
  final List<List<int>>? txKeys;
  MoneroWalletTransaction(
      {required String txId,
      required super.time,
      required super.outputs,
      required WalletMoneroNetwork network,
      required List<List<int>>? txKeys,
      required super.totalOutput,
      super.memos,
      super.type = WalletTransactionType.send,
      super.status = WalletTransactionStatus.pending})
      : txKeys = txKeys?.emptyAsNull?.map((e) => e.asImmutableBytes).toImutableList,
        super(txId: StringUtils.normalizeHex(txId));

  factory MoneroWalletTransaction.deserialize(WalletMoneroNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: NetworkType.monero.identifier);
    return MoneroWalletTransaction(
        txId: values.rawValueAt(0),
        time: values.rawValueAt(1),
        network: network,
        totalOutput: values.maybeObjectAt<WalletTransactionAmount, CborTagValue>(
            2, (e) => WalletTransactionAmount.deserialize(network, object: e)),
        outputs: values
            .listAt<CborTagValue>(3)
            .map((e) => MoneroWalletTransactionOutput.deserialize(network, object: e))
            .toList(),
        type: WalletTransactionType.fromValue(values.rawValueAt(5)),
        status: WalletTransactionStatus.fromValue(values.rawValueAt(6)),
        txKeys: values
            .listAt<CborBytesValue>(7, emptyOnNull: true)
            .map((e) => e.value)
            .toList(),
        memos: values
            .listAt<CborTagValue>(8)
            .map((e) => WalletTransactionMemo.deserialize(object: e))
            .toList());
  }

  @override
  NetworkType get network => NetworkType.monero;

  MoneroWalletTransactionProof generateProofRequest(MoneroAddress recepient) {
    return MoneroWalletTransactionProof(txKeys: txKeys, recepient: recepient, txId: txId);
  }

  @override
  List<CborObject?> get serializationItems => [
        txId.toCbor(),
        time.toCbor(),
        totalOutput?.toCbor(),
        AppSerialization.listFromObjects(outputs.map((e) => e.toCbor()).toList()),
        web3Client?.toCbor(),
        type.value.toCbor(),
        status.value.toCbor(),
        AppSerialization.listFromObjects(
            txKeys?.map((e) => CborBytesValue(e)).toList() ?? []),
        AppSerialization.listFromObjects(memos.map((e) => e.toCbor()).toList()),
      ];
}

class MoneroWalletTransactionOutput
    extends WalletTransactionTransferOutput<MoneroAddress> {
  MoneroWalletTransactionOutput({required super.amount, required super.to});

  @override
  String get address => to.address;

  factory MoneroWalletTransactionOutput.deserialize(WalletMoneroNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.moneroWalletTransactionOutput);
    return MoneroWalletTransactionOutput(
      amount: WalletTransactionIntegerAmount.deserialize(network,
          object: values.objectAt<CborTagValue>(0)),
      to: MoneroAddress.deserializeIAddress(bytes: values.rawValueAt(1)),
    );
  }

  @override
  List<CborObject?> get serializationItems =>
      [amount.toCbor(), CborBytesValue(to.encodeAsIAddress())];
  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.moneroWalletTransactionOutput;
}
