import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/utxos.dart';
import 'package:zcash_dart/zcash.dart';

class TransparentFullUtxoInfos {
  final ZcashUtxoTransparent utxo;
  final ZcashTransactionWithBlockInfo? transaction;
  const TransparentFullUtxoInfos({required this.utxo, required this.transaction});
}

class ZcashTransactionWithBlockInfo {
  final ZWalletdCompactBlock block;
  final TransactionData transaction;
  final ZcashTxId txId;
  const ZcashTransactionWithBlockInfo(
      {required this.block, required this.transaction, required this.txId});
}
