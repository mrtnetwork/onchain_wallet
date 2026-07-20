import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:polkadot_dart/polkadot_dart.dart';
import 'package:on_chain_wallet/app/core.dart';

class SubstrateWalletTransaction
    extends ChainTransaction<SubstrateWalletTransactionOutput> {
  final int? block;
  final String extrinsics;
  SubstrateWalletTransaction(
      {required String txId,
      required this.block,
      required this.extrinsics,
      DateTime? time,
      super.outputs = const [],
      super.web3Client,
      super.totalOutput,
      required WalletSubstrateNetwork network,
      super.type = WalletTransactionType.send,
      super.status = WalletTransactionStatus.pending})
      : super(time: time ?? DateTime.now(), txId: StringUtils.normalizeHex(txId));

  factory SubstrateWalletTransaction.deserialize(WalletSubstrateNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NetworkType.substrate.identifier);
    return SubstrateWalletTransaction(
        txId: values.rawValueAt(0),
        time: values.rawValueAt(1),
        network: network,
        totalOutput: values.maybeObjectAt<WalletTransactionAmount, CborTagValue>(
            2, (e) => WalletTransactionAmount.deserialize(network, object: e)),
        outputs: values
            .listAt<CborTagValue>(3)
            .map((e) => SubstrateWalletTransactionOutput.deserialize(network, object: e))
            .toList(),
        web3Client: values.maybeObjectAt<WalletWeb3ClientTransaction, CborTagValue>(
            4, (e) => WalletWeb3ClientTransaction.deserialize(object: e)),
        type: WalletTransactionType.fromValue(values.rawValueAt(5)),
        status: WalletTransactionStatus.fromValue(values.rawValueAt(6)),
        block: values.rawValueAt(7),
        extrinsics: values.rawValueAt(8));
  }

  @override
  NetworkType get network => NetworkType.substrate;

  @override
  List<CborObject?> get serializationItems => [
        txId.toCbor(),
        time.toCbor(),
        totalOutput?.toCbor(),
        AppSerialization.listFromObjects(outputs.map((e) => e.toCbor()).toList()),
        web3Client?.toCbor(),
        type.value.toCbor(),
        status.value.toCbor(),
        block?.toCbor(),
        extrinsics.toCbor()
      ];
}

abstract class SubstrateWalletTransactionOutput extends WalletTransactionOutput {
  const SubstrateWalletTransactionOutput({required super.type});
  factory SubstrateWalletTransactionOutput.deserialize(WalletSubstrateNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborTagValue tag =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    final type = WalletTransactionOutputType.fromTag(tag.tags);
    return switch (type) {
      WalletTransactionOutputType.transfer =>
        SubstrateWalletTransactionTransferOutput.deserialize(network,
            bytes: bytes, object: object),
      WalletTransactionOutputType.operation =>
        SubstrateWalletTransactionOperationOutput.deserialize(network,
            bytes: bytes, object: object),
      _ => throw WalletExceptionConst.invalidWalletTransactionData
    };
  }
}

class SubstrateWalletTransactionTransferOutput
    extends WalletTransactionTransferOutput<BaseSubstrateAddress>
    implements SubstrateWalletTransactionOutput {
  const SubstrateWalletTransactionTransferOutput(
      {required super.to, required super.amount});

  factory SubstrateWalletTransactionTransferOutput.deserialize(
      WalletSubstrateNetwork network,
      {List<int>? bytes,
      CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletTransactionOutputType.transfer.tag);
    return SubstrateWalletTransactionTransferOutput(
        amount: WalletTransactionIntegerAmount.deserialize(network,
            object: values.objectAt<CborTagValue>(0)),
        to: BaseSubstrateAddress.deserializeIAddress(bytes: values.rawValueAt(1)));
  }

  @override
  String get address => to.address;

  @override
  List<CborObject?> get serializationItems =>
      [amount.toCbor(), CborBytesValue(to.encodeAsIAddress())];
}

class SubstrateWalletTransactionOperationOutput extends WalletTransactionOperationOutput
    implements SubstrateWalletTransactionOutput {
  const SubstrateWalletTransactionOperationOutput(
      {required super.name, super.amount, super.content});

  factory SubstrateWalletTransactionOperationOutput.deserialize(
      WalletSubstrateNetwork network,
      {List<int>? bytes,
      CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletTransactionOutputType.operation.tag);
    return SubstrateWalletTransactionOperationOutput(
        name: values.rawValueAt(0),
        amount: values.maybeObjectAt<WalletTransactionIntegerAmount, CborTagValue>(
            1, (e) => WalletTransactionIntegerAmount.deserialize(network, object: e)),
        content: values.rawValueAt(2));
  }

  @override
  List<CborObject?> get serializationItems =>
      [name.toCbor(), amount?.toCbor(), content?.toCbor()];
}
