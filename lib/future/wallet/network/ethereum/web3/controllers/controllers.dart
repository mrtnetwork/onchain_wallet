import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/etherum.dart';

abstract class Web3EthereumTransactionStateController<
        RESPONSE,
        T extends Web3EthereumRequestParam<RESPONSE>,
        E extends IWeb3EthereumTransactionData>
    extends BaseWeb3EthereumTransactionStateController<RESPONSE, T, E> {
  Web3EthereumTransactionStateController(
      {required super.walletProvider, required super.request});

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required IWeb3EthereumSignedTransaction<E> signedTransaction}) async {
    final txId = await client.sendRawTransaction(signedTransaction.finalTransactionData);
    return SubmitTransactionSuccess(txId: txId, signedTransaction: signedTransaction);
  }
}
