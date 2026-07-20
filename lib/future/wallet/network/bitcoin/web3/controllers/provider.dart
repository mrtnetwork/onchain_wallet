import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/types/types.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/constant/constants/exception.dart';

mixin BitcoinWeb3TransactionApiController on DisposableMixin {
  BitcoinNetworkClient get client;
  WalletBitcoinNetwork get network;
  Future<List<BitcoinPsbtInputWithAccount>> readAccountPsbtUtxos(
      List<BitcoinPsbtInputWithAccount> inputs) async {
    List<BitcoinPsbtInputWithAccount> checkedInputs = [];
    Map<String, List<UtxoWithAddress>> utxos0 = {};
    Map<String, BtcTransaction> txs = {};
    for (final i in inputs) {
      if (i.owner != null) {
        if (!utxos0.containsKey(i.address.view)) {
          final utxos = await client.readUtxos(i.owner!);
          utxos0[i.address.view] = utxos;
        }
        final utxo = utxos0[i.address.view]!.firstWhere(
            (e) => e.utxo.txHash == i.input.txId && e.utxo.vout == i.input.txIndex,
            orElse: () => throw Web3BitcoinExceptionConstant.txInputNotFound(
                i.input.txId, i.input.txIndex));
        checkedInputs.add(i.copyWith(value: utxo.utxo.value, network: network));
        continue;
      }
      txs[i.input.txId] ??= await client.getTx(i.input.txId);
      final transaction = txs[i.input.txId]!;

      if (i.input.txIndex >= transaction.outputs.length) {
        throw Web3BitcoinExceptionConstant.txInputNotFound(i.input.txId, i.input.txIndex);
      }
      final output = transaction.outputs[i.input.txIndex];
      checkedInputs.add(i.copyWith(value: output.amount, network: network));
    }
    return checkedInputs;
  }
}
