import 'package:bitcoin_base/bitcoin_base.dart';

class BitcoinAccountUtxosInfo {
  final List<UtxoWithAddress> utxos;
  final Map<String, ElectrumVerbosTxResponse> fetchedTransaction;
  const BitcoinAccountUtxosInfo({required this.utxos, required this.fetchedTransaction});
}
