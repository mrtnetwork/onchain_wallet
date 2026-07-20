import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';

class ADAWalletTransaction extends ChainTransaction {
  ADAWalletTransaction(
      {required String txId,
      DateTime? time,
      super.outputs,
      super.web3Client,
      super.totalOutput,
      required WalletCardanoNetwork network,
      super.type = WalletTransactionType.send,
      super.status = WalletTransactionStatus.pending})
      : super(time: time ?? DateTime.now(), txId: StringUtils.normalizeHex(txId));

  factory ADAWalletTransaction.deserialize(WalletCardanoNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: NetworkType.cardano.identifier);
    return ADAWalletTransaction(
        txId: values.rawValueAt(0),
        time: values.rawValueAt(1),
        network: network,
        totalOutput: values.maybeObjectAt<WalletTransactionAmount, CborTagValue>(
            2, (e) => WalletTransactionAmount.deserialize(network, object: e)),
        outputs: [],
        web3Client: values.maybeObjectAt<WalletWeb3ClientTransaction, CborTagValue>(
            4, (e) => WalletWeb3ClientTransaction.deserialize(object: e)),
        type: WalletTransactionType.fromValue(values.rawValueAt(5)),
        status: WalletTransactionStatus.fromValue(values.rawValueAt(6)));
  }

  @override
  NetworkType get network => NetworkType.cardano;
}
