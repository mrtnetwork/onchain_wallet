import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:xrpl_dart/xrpl_dart.dart';
import 'package:on_chain_wallet/app/core.dart';

class XRPWalletTransaction extends ChainTransaction<XRPWalletTransactionOutput> {
  XRPWalletTransaction(
      {required String txId,
      DateTime? time,
      super.outputs = const [],
      super.web3Client,
      super.totalOutput,
      required WalletXRPNetwork network,
      super.type = WalletTransactionType.send,
      super.status = WalletTransactionStatus.pending,
      List<XRPWalletTransactionOperationInput> super.inputs = const []})
      : super(time: time ?? DateTime.now(), txId: StringUtils.normalizeHex(txId));

  factory XRPWalletTransaction.deserialize(WalletXRPNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: NetworkType.xrpl.identifier);
    return XRPWalletTransaction(
        txId: values.rawValueAt(0),
        time: values.rawValueAt(1),
        network: network,
        totalOutput: values.maybeObjectAt<WalletTransactionAmount, CborTagValue>(
            2, (e) => WalletTransactionAmount.deserialize(network, object: e)),
        outputs: values
            .listAt<CborTagValue>(3)
            .map((e) => XRPWalletTransactionOutput.deserialize(network, object: e))
            .toList(),
        web3Client: values.maybeObjectAt<WalletWeb3ClientTransaction, CborTagValue>(
            4, (e) => WalletWeb3ClientTransaction.deserialize(object: e)),
        type: WalletTransactionType.fromValue(values.rawValueAt(5)),
        status: WalletTransactionStatus.fromValue(values.rawValueAt(6)),
        inputs: values
            .listAt<CborTagValue>(7, emptyOnNull: true)
            .map((e) => XRPWalletTransactionOperationInput.deserialize(object: e))
            .toList());
  }

  @override
  NetworkType get network => NetworkType.xrpl;
}

abstract class XRPWalletTransactionOutput extends WalletTransactionOutput {
  const XRPWalletTransactionOutput({required super.type});
  factory XRPWalletTransactionOutput.deserialize(WalletXRPNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborTagValue tag =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    final type = WalletTransactionOutputType.fromTag(tag.tags);
    return switch (type) {
      WalletTransactionOutputType.transfer =>
        XRPWalletTransactionTransferOutput.deserialize(network,
            bytes: bytes, object: object),
      WalletTransactionOutputType.operation =>
        XRPWalletTransactionOperationOutput.deserialize(network,
            bytes: bytes, object: object),
      _ => throw WalletExceptionConst.invalidWalletTransactionData
    };
  }
}

class XRPWalletTransactionTransferOutput
    extends WalletTransactionTransferOutput<XRPBaseAddress>
    implements XRPWalletTransactionOutput {
  const XRPWalletTransactionTransferOutput({required super.to, required super.amount});

  factory XRPWalletTransactionTransferOutput.deserialize(WalletXRPNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletTransactionOutputType.transfer.tag);
    return XRPWalletTransactionTransferOutput(
        amount: WalletTransactionAmount.deserialize(network,
            object: values.objectAt<CborTagValue>(0)),
        to: XRPBaseAddress.deserializeIAddress(bytes: values.rawValueAt(1)));
  }

  @override
  String get address => to.address;

  @override
  List<CborObject?> get serializationItems =>
      [amount.toCbor(), CborBytesValue(to.encodeAsIAddress())];
}

class XRPWalletTransactionOperationInput
    extends WalletTransactionOperationInput<XRPBaseAddress> {
  @override
  final XRPBaseAddress address;

  const XRPWalletTransactionOperationInput(
      {required this.address, required super.operation});
  factory XRPWalletTransactionOperationInput.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletTransactionInputType.operation.tag);
    return XRPWalletTransactionOperationInput(
        address: XRPBaseAddress.deserializeIAddress(bytes: values.rawValueAt(0)),
        operation: values.rawValueAt<String?>(1) ?? "Payment");
  }

  @override
  String get addressStr => address.classicAddress;

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(address.encodeAsIAddress()),
        CborStringValue(operation),
      ];
}

class XRPWalletTransactionOperationOutput extends WalletTransactionOperationOutput
    implements XRPWalletTransactionOutput {
  const XRPWalletTransactionOperationOutput(
      {required super.name, super.amount, super.content});

  factory XRPWalletTransactionOperationOutput.deserialize(WalletXRPNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletTransactionOutputType.operation.tag);
    return XRPWalletTransactionOperationOutput(
        name: values.rawValueAt(0),
        amount: values.maybeObjectAt<WalletTransactionAmount, CborTagValue>(
            1, (e) => WalletTransactionAmount.deserialize(network, object: e)),
        content: values.rawValueAt(2));
  }

  @override
  List<CborObject?> get serializationItems =>
      [name.toCbor(), amount?.toCbor(), content?.toCbor()];
}
