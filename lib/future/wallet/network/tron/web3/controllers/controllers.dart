import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/web3/web3/networks/tron/params/core/request.dart';

abstract class Web3TronTransactionStateController<RESPONSE,
        T extends Web3TronRequestParam<RESPONSE>, E extends IWeb3TronTransactionData>
    extends BaseWeb3TronTransactionStateController<RESPONSE, T, E> {
  Web3TronTransactionStateController(
      {required super.walletProvider, required super.request});

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required IWeb3TronSignedTransaction<E> signedTransaction}) async {
    final result =
        await client.sendTransaction(signedTransaction.finalTransactionData.toHex);
    if (result.result) {
      return SubmitTransactionSuccess(
          txId: result.txid, signedTransaction: signedTransaction);
    }
    return SubmitTransactionFailed(result.message ?? "submit_transaction_failed".tr);
  }
}
