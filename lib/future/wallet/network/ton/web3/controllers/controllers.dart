import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/web3/web3/networks/ton/params/core/request.dart';

abstract class Web3TonTransactionStateController<RESPONSE,
        T extends Web3TonRequestParam<RESPONSE>, E extends IWeb3TonTransactionData>
    extends BaseWeb3TonTransactionStateController<RESPONSE, T, E> {
  Web3TonTransactionStateController(
      {required super.walletProvider, required super.request});

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required IWeb3TonSignedTransaction<E> signedTransaction}) async {
    final txId = await client.submitBoc(boc: signedTransaction.externalMessage);
    return SubmitTransactionSuccess<IWeb3TonSignedTransaction<E>>(
        txId: txId.$1,
        warning: txId.$2 ? null : "tx_submit_response_failed_desc".tr,
        signedTransaction: signedTransaction);
  }
}
