import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/transaction/controllers/fee.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/transaction/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/transaction/controllers/signer.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/transaction/controllers/utxos.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/web3/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/web3/types/types.dart';
import 'package:on_chain_wallet/web3/web3/networks/monero/params/core/request.dart';
import 'dart:async';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';

abstract class Web3MoneroTransactionStateController<RESPONSE,
        T extends Web3MoneroRequestParam<RESPONSE>>
    extends BaseWeb3MoneroTransactionStateController<RESPONSE, T>
    with
        MoneroTransactionApiController,
        MoneroTransactionFeeController,
        MoneroTransactionUtxosController,
        MoneroWeb3TransactionApiController,
        MoneroTransactionSignerController {
  Web3MoneroTransactionStateController(
      {required super.walletProvider, required super.request});

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required IMoneroSignedTransaction signedTransaction}) async {
    final response = await client.sendTx(signedTransaction.finalTransactionData.txBytes);
    if (response.isOk) {
      return SubmitTransactionSuccess(
          txId: signedTransaction.finalTransactionData.txData.txID,
          signedTransaction: signedTransaction);
    }
    return SubmitTransactionFailed(
        "transaction_submission_error".tr.replaceOne(response.getErrorMessage() ?? ''));
  }
}
