import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/web3/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/params/core/request.dart';

abstract class Web3XRPTransactionStateController<RESPONSE,
        T extends Web3XRPRequestParam<RESPONSE>, E extends IWeb3XRPTransactionData>
    extends BaseWeb3XRPTransactionStateController<RESPONSE, T, E>
    with
        XRPWeb3TransactionApiController,
        XRPTransactionApiController,
        RippleTransactionFeeController {
  Web3XRPTransactionStateController(
      {required super.walletProvider, required super.request});

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required IWeb3XRPSignedTransaction<E> signedTransaction}) async {
    final txResult = await broadcastTransaction(signedTransaction.finalTransactionData);
    if (!txResult.isSuccess) {
      return SubmitTransactionFailed(txResult.engineResultMessage);
    }
    return SubmitTransactionSuccess<IWeb3XRPSignedTransaction<E>>(
        txId: signedTransaction.finalTransactionData.getHash(),
        signedTransaction: signedTransaction);
  }
}
