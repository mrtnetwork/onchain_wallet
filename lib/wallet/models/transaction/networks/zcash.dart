import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:zcash_dart/zcash.dart';

class ZcashWalletTransaction extends ChainTransaction<ZcashWalletTransactionOutput> {
  ZcashWalletTransaction(
      {required String txId,
      required super.time,
      required super.outputs,
      required WalletZcashNetwork network,
      required super.totalOutput,
      super.memos = const [],
      super.web3Client,
      super.type = WalletTransactionType.send,
      super.status = WalletTransactionStatus.pending})
      : super(txId: StringUtils.normalizeHex(txId));

  factory ZcashWalletTransaction.deserialize(WalletZcashNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: NetworkType.zcash.identifier);
    return ZcashWalletTransaction(
        txId: values.rawValueAt(0),
        time: values.rawValueAt(1),
        network: network,
        totalOutput: values.maybeObjectAt<WalletTransactionAmount, CborTagValue>(
            2, (e) => WalletTransactionAmount.deserialize(network, object: e)),
        outputs: values
            .listAt<CborTagValue>(3)
            .map((e) => ZcashWalletTransactionOutput.deserialize(network, object: e))
            .toList(),
        type: WalletTransactionType.fromValue(values.rawValueAt(5)),
        status: WalletTransactionStatus.fromValue(values.rawValueAt(6)),
        memos: values
            .listAt<CborTagValue>(7)
            .map((e) => WalletTransactionMemo.deserialize(object: e))
            .toList(),
        web3Client: values.maybeObjectAt<WalletWeb3ClientTransaction, CborTagValue>(
            8, (e) => WalletWeb3ClientTransaction.deserialize(object: e)));
  }

  List<ZcashProtocol> get protocols => outputs.expand((e) => e.protocols).toList();

  @override
  NetworkType get network => NetworkType.zcash;
  @override
  List<CborObject?> get serializationItems => [
        txId.toCbor(),
        time.toCbor(),
        totalOutput?.toCbor(),
        AppSerialization.listFromObjects(outputs.map((e) => e.toCbor()).toList()),
        web3Client?.toCbor(),
        type.value.toCbor(),
        status.value.toCbor(),
        AppSerialization.listFromObjects(memos.map((e) => e.toCbor()).toList()),
        web3Client?.toCbor()
      ];
}

class ZcashWalletTransactionOutput extends WalletTransactionTransferOutput<ZcashAddress> {
  ZcashWalletTransactionOutput({required super.amount, required super.to, super.memo});

  @override
  String get address => to.address;

  factory ZcashWalletTransactionOutput.deserialize(WalletZcashNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.zcashWalletTransactionOutput);
    return ZcashWalletTransactionOutput(
        amount: WalletTransactionIntegerAmount.deserialize(network,
            object: values.objectAt<CborTagValue>(0)),
        to: ZcashAddress.deserializeIAddress(bytes: values.rawValueAt(1)),
        memo: values.maybeObjectAt<WalletTransactionMemo, CborObject>(
          2,
          (e) => WalletTransactionMemo.deserialize(object: e),
        ));
  }

  @override
  List<CborObject?> get serializationItems =>
      [amount.toCbor(), CborBytesValue(to.encodeAsIAddress()), memo?.toCbor()];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.zcashWalletTransactionOutput;

  List<ZcashProtocol> get protocols => to.supportedProtocols;
}
