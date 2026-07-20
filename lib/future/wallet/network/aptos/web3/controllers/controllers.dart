import 'package:on_chain_wallet/future/wallet/network/aptos/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/web3/web3/networks/aptos/params/core/request.dart';

abstract class Web3AptosTransactionStateController<RESPONSE,
        T extends Web3AptosRequestParam<RESPONSE>, E extends IWeb3AptosTransactionData>
    extends BaseWeb3AptosTransactionStateController<RESPONSE, T, E> {
  Web3AptosTransactionStateController(
      {required super.walletProvider, required super.request});

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required IWeb3AptosSignedTransaction<IWeb3AptosTransactionData>
          signedTransaction}) async {
    final result = await client.submitTransaction(signedTransaction.finalTransactionData);
    return SubmitTransactionSuccess(
        txId: result.$1, signedTransaction: signedTransaction);
  }
}
