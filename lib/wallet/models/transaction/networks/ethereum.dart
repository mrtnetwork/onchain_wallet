import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:on_chain/on_chain.dart';

class EthWalletTransaction extends ChainTransaction<EthWalletTransactionTransferOutput> {
  EthWalletTransaction(
      {required String txId,
      DateTime? time,
      required super.outputs,
      super.web3Client,
      super.totalOutput,
      required WalletEthereumNetwork network,
      super.type = WalletTransactionType.send,
      super.status = WalletTransactionStatus.pending})
      : super(time: time ?? DateTime.now(), txId: StringUtils.normalizeHex(txId));

  factory EthWalletTransaction.deserialize(WalletEthereumNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NetworkType.ethereum.identifier);
    return EthWalletTransaction(
        txId: values.rawValueAt(0),
        time: values.rawValueAt(1),
        network: network,
        totalOutput: values.maybeObjectAt<WalletTransactionAmount, CborTagValue>(
            2, (e) => WalletTransactionAmount.deserialize(network, object: e)),
        outputs: values
            .listAt<CborTagValue>(3)
            .map(
                (e) => EthWalletTransactionTransferOutput.deserialize(network, object: e))
            .toList(),
        web3Client: values.maybeObjectAt<WalletWeb3ClientTransaction, CborTagValue>(
            4, (e) => WalletWeb3ClientTransaction.deserialize(object: e)),
        type: WalletTransactionType.fromValue(values.rawValueAt(5)),
        status: WalletTransactionStatus.fromValue(values.rawValueAt(6)));
  }

  @override
  NetworkType get network => NetworkType.ethereum;
}

class EthWalletTransactionTransferOutput
    extends WalletTransactionTransferOutput<ETHAddress> {
  const EthWalletTransactionTransferOutput({required super.to, required super.amount});

  factory EthWalletTransactionTransferOutput.deserialize(WalletEthereumNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletTransactionOutputType.transfer.tag);
    return EthWalletTransactionTransferOutput(
        amount: WalletTransactionIntegerAmount.deserialize(network,
            object: values.objectAt<CborTagValue>(0)),
        to: ETHAddress.deserializeIAddress(bytes: values.rawValueAt(1)));
  }

  @override
  String get address => to.address;

  @override
  List<CborObject?> get serializationItems =>
      [amount.toCbor(), CborBytesValue(to.encodeAsIAddress())];
}
