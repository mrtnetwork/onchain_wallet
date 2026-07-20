import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/app/core.dart';

class SolanaWalletTransaction extends ChainTransaction<SolanaWalletTransactionOutput> {
  SolanaWalletTransaction(
      {required super.txId,
      DateTime? time,
      super.outputs = const [],
      super.web3Client,
      super.totalOutput,
      required WalletSolanaNetwork network,
      super.type = WalletTransactionType.send,
      super.status = WalletTransactionStatus.pending,
      super.memos})
      : super(time: time ?? DateTime.now());

  factory SolanaWalletTransaction.deserialize(WalletSolanaNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: NetworkType.solana.identifier);
    return SolanaWalletTransaction(
        txId: values.rawValueAt(0),
        time: values.rawValueAt(1),
        network: network,
        totalOutput: values.maybeObjectAt<WalletTransactionAmount, CborTagValue>(
            2, (e) => WalletTransactionAmount.deserialize(network, object: e)),
        outputs: values
            .listAt<CborTagValue>(3)
            .map((e) => SolanaWalletTransactionOutput.deserialize(network, object: e))
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
  NetworkType get network => NetworkType.solana;
}

abstract class SolanaWalletTransactionOutput extends WalletTransactionOutput {
  const SolanaWalletTransactionOutput({required super.type});
  factory SolanaWalletTransactionOutput.deserialize(WalletSolanaNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborTagValue tag =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    final type = WalletTransactionOutputType.fromTag(tag.tags);
    return switch (type) {
      WalletTransactionOutputType.transfer =>
        SolanaWalletTransactionTransferOutput.deserialize(network,
            bytes: bytes, object: object),
      WalletTransactionOutputType.operation =>
        SolanaWalletTransactionOperationOutput.deserialize(network,
            bytes: bytes, object: object),
      _ => throw WalletExceptionConst.invalidWalletTransactionData
    };
  }
}

class SolanaWalletTransactionTransferOutput
    extends WalletTransactionTransferOutput<SolAddress>
    implements SolanaWalletTransactionOutput {
  const SolanaWalletTransactionTransferOutput({required super.to, required super.amount});

  factory SolanaWalletTransactionTransferOutput.deserialize(WalletSolanaNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletTransactionOutputType.transfer.tag);
    return SolanaWalletTransactionTransferOutput(
        amount: WalletTransactionIntegerAmount.deserialize(network,
            object: values.objectAt<CborTagValue>(0)),
        to: SolAddress.deserializeIAddress(bytes: values.rawValueAt(1)));
  }

  @override
  String get address => to.address;

  @override
  List<CborObject?> get serializationItems =>
      [amount.toCbor(), CborBytesValue(to.encodeAsIAddress())];
}

class SolanaWalletTransactionOperationOutput extends WalletTransactionOperationOutput
    implements SolanaWalletTransactionOutput {
  const SolanaWalletTransactionOperationOutput(
      {required super.name, super.amount, super.content});

  factory SolanaWalletTransactionOperationOutput.deserialize(WalletSolanaNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletTransactionOutputType.operation.tag);
    return SolanaWalletTransactionOperationOutput(
        name: values.rawValueAt(0),
        amount: values.maybeObjectAt<WalletTransactionIntegerAmount, CborTagValue>(
            1, (e) => WalletTransactionIntegerAmount.deserialize(network, object: e)),
        content: values.rawValueAt(2));
  }

  @override
  List<CborObject?> get serializationItems =>
      [name.toCbor(), amount?.toCbor(), content?.toCbor()];
}
