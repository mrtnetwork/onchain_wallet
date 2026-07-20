import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:stellar_dart/stellar_dart.dart';
import 'package:on_chain_wallet/app/core.dart';

class StellarWalletTransaction extends ChainTransaction<StellarWalletTransactionOutput> {
  StellarWalletTransaction(
      {required String txId,
      DateTime? time,
      super.outputs = const [],
      super.web3Client,
      super.totalOutput,
      required WalletStellarNetwork network,
      super.type = WalletTransactionType.send,
      super.status = WalletTransactionStatus.pending,
      super.memos})
      : super(time: time ?? DateTime.now(), txId: StringUtils.normalizeHex(txId));

  factory StellarWalletTransaction.deserialize(WalletStellarNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: NetworkType.stellar.identifier);
    return StellarWalletTransaction(
        txId: values.rawValueAt(0),
        time: values.rawValueAt(1),
        network: network,
        totalOutput: values.maybeObjectAt<WalletTransactionAmount, CborTagValue>(
            2, (e) => WalletTransactionAmount.deserialize(network, object: e)),
        outputs: values
            .listAt<CborTagValue>(3)
            .map((e) => StellarWalletTransactionOutput.deserialize(network, object: e))
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
  NetworkType get network => NetworkType.stellar;
}

abstract class StellarWalletTransactionOutput extends WalletTransactionOutput {
  const StellarWalletTransactionOutput({required super.type});
  factory StellarWalletTransactionOutput.deserialize(WalletStellarNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborTagValue tag =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    final type = WalletTransactionOutputType.fromTag(tag.tags);
    return switch (type) {
      WalletTransactionOutputType.transfer =>
        StellarWalletTransactionTransferOutput.deserialize(network,
            bytes: bytes, object: object),
      WalletTransactionOutputType.operation =>
        StellarWalletTransactionOperationOutput.deserialize(network,
            bytes: bytes, object: object),
      _ => throw WalletExceptionConst.invalidWalletTransactionData
    };
  }
}

class StellarWalletTransactionTransferOutput
    extends WalletTransactionTransferOutput<StellarAddress>
    implements StellarWalletTransactionOutput {
  const StellarWalletTransactionTransferOutput(
      {required super.to, required super.amount});

  factory StellarWalletTransactionTransferOutput.deserialize(WalletStellarNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletTransactionOutputType.transfer.tag);
    return StellarWalletTransactionTransferOutput(
        amount: WalletTransactionIntegerAmount.deserialize(network,
            object: values.objectAt<CborTagValue>(0)),
        to: StellarAddress.deserializeIAddress(bytes: values.rawValueAt(1)));
  }

  @override
  String get address => to.baseAddress;

  @override
  List<CborObject?> get serializationItems =>
      [amount.toCbor(), CborBytesValue(to.encodeAsIAddress())];
}

class StellarWalletTransactionOperationOutput extends WalletTransactionOperationOutput
    implements StellarWalletTransactionOutput {
  const StellarWalletTransactionOperationOutput(
      {required super.name, super.amount, super.content});

  factory StellarWalletTransactionOperationOutput.deserialize(
      WalletStellarNetwork network,
      {List<int>? bytes,
      CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletTransactionOutputType.operation.tag);
    return StellarWalletTransactionOperationOutput(
        name: values.rawValueAt(0),
        amount: values.maybeObjectAt<WalletTransactionIntegerAmount, CborTagValue>(
            1, (e) => WalletTransactionIntegerAmount.deserialize(network, object: e)),
        content: values.rawValueAt(2));
  }

  @override
  List<CborObject?> get serializationItems =>
      [name.toCbor(), amount?.toCbor(), content?.toCbor()];
}
