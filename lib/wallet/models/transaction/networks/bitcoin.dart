import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';

class BitcoinWalletTransaction extends ChainTransaction<BitcoinWalletTransactionOutput> {
  final String scriptHash;
  BitcoinWalletTransaction(
      {required String txId,
      super.time,
      super.outputs,
      super.web3Client,
      required super.totalOutput,
      required WalletBitcoinNetwork network,
      required this.scriptHash,
      super.type = WalletTransactionType.send,
      super.status = WalletTransactionStatus.pending,
      super.memos})
      : super(txId: StringUtils.normalizeHex(txId));

  factory BitcoinWalletTransaction.deserialize(WalletBitcoinNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: NetworkType.bitcoinAndForked.identifier);
    return BitcoinWalletTransaction(
        txId: values.rawValueAt(0),
        time: values.rawValueAt(1),
        network: network,
        totalOutput: values.maybeObjectAt<WalletTransactionAmount, CborTagValue>(
            2, (e) => WalletTransactionAmount.deserialize(network, object: e)),
        outputs: values
            .listAt<CborTagValue>(3)
            .map((e) => BitcoinWalletTransactionOutput.deserialize(network, object: e))
            .toList(),
        web3Client: values.maybeObjectAt<WalletWeb3ClientTransaction, CborTagValue>(
            4, (e) => WalletWeb3ClientTransaction.deserialize(object: e)),
        type: WalletTransactionType.fromValue(values.rawValueAt(5)),
        status: WalletTransactionStatus.fromValue(values.rawValueAt(6)),
        scriptHash: values.rawValueAt(7),
        memos: values
            .listAt<CborTagValue>(8)
            .map((e) => WalletTransactionMemo.deserialize(object: e))
            .toList());
  }

  @override
  NetworkType get network => NetworkType.bitcoinAndForked;

  @override
  List<CborObject?> get serializationItems => [
        txId.toCbor(),
        time.toCbor(),
        totalOutput?.toCbor(),
        AppSerialization.listFromObjects(outputs.map((e) => e.toCbor()).toList()),
        web3Client?.toCbor(),
        type.value.toCbor(),
        status.value.toCbor(),
        scriptHash.toCbor(),
        AppSerialization.listFromObjects(memos.map((e) => e.toCbor()).toList())
      ];
}

abstract class BitcoinWalletTransactionOutput extends WalletTransactionOutput {
  const BitcoinWalletTransactionOutput({required super.type});
  factory BitcoinWalletTransactionOutput.deserialize(WalletBitcoinNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborTagValue tag =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    final type = WalletTransactionOutputType.fromTag(tag.tags);
    return switch (type) {
      WalletTransactionOutputType.transfer =>
        BitcoinWalletTransactionTransferOutput.deserialize(network,
            bytes: bytes, object: object),
      _ => throw WalletExceptionConst.invalidWalletTransactionData
    };
  }
}

class BitcoinWalletTransactionTransferOutput
    extends WalletTransactionTransferOutput<BitcoinNetworkAddress>
    implements BitcoinWalletTransactionOutput {
  BitcoinWalletTransactionTransferOutput({required super.amount, required super.to});

  @override
  String get address => to.address;

  factory BitcoinWalletTransactionTransferOutput.deserialize(WalletBitcoinNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletTransactionOutputType.transfer.tag);
    return BitcoinWalletTransactionTransferOutput(
        amount: WalletTransactionIntegerAmount.deserialize(network,
            object: values.objectAt<CborTagValue>(0)),
        to: BitcoinNetworkAddress.deserializeIAddress(bytes: values.rawValueAt(1)));
  }

  @override
  List<CborObject?> get serializationItems =>
      [amount.toCbor(), CborBytesValue(to.encodeAsIAddress())];
}
