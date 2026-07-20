import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:on_chain/on_chain.dart';

class SuiWalletTransaction extends ChainTransaction<SuiWalletTransactionTransferOutput> {
  SuiWalletTransaction(
      {required super.txId,
      DateTime? time,
      super.outputs,
      super.web3Client,
      super.totalOutput,
      required WalletSuiNetwork network,
      super.type = WalletTransactionType.send,
      super.status = WalletTransactionStatus.pending})
      : super(time: time ?? DateTime.now());

  factory SuiWalletTransaction.deserialize(WalletSuiNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: NetworkType.sui.identifier);
    return SuiWalletTransaction(
        txId: values.rawValueAt(0),
        time: values.rawValueAt(1),
        network: network,
        totalOutput: values.maybeObjectAt<WalletTransactionAmount, CborTagValue>(
            2, (e) => WalletTransactionAmount.deserialize(network, object: e)),
        outputs: values
            .listAt<CborTagValue>(3)
            .map(
                (e) => SuiWalletTransactionTransferOutput.deserialize(network, object: e))
            .toList(),
        web3Client: values.maybeObjectAt<WalletWeb3ClientTransaction, CborTagValue>(
            4, (e) => WalletWeb3ClientTransaction.deserialize(object: e)),
        type: WalletTransactionType.fromValue(values.rawValueAt(5)),
        status: WalletTransactionStatus.fromValue(values.rawValueAt(6)));
  }
  @override
  NetworkType get network => NetworkType.sui;
}

class SuiWalletTransactionTransferOutput
    extends WalletTransactionTransferOutput<SuiAddress> {
  const SuiWalletTransactionTransferOutput({required super.to, required super.amount});

  factory SuiWalletTransactionTransferOutput.deserialize(WalletSuiNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletTransactionOutputType.transfer.tag);
    return SuiWalletTransactionTransferOutput(
        amount: WalletTransactionIntegerAmount.deserialize(network,
            object: values.objectAt<CborTagValue>(0)),
        to: SuiAddress.deserializeIAddress(bytes: values.rawValueAt(1)));
  }

  @override
  String get address => to.address;

  @override
  List<CborObject?> get serializationItems =>
      [amount.toCbor(), CborBytesValue(to.encodeAsIAddress())];
}
