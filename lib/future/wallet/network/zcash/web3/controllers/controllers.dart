import 'package:on_chain_wallet/future/wallet/network/zcash/transaction/controllers/fee.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/transaction/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/transaction/controllers/utxos.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/web3/web3.dart';
import 'dart:async';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/web3/web3/networks/networks.dart';

abstract class Web3ZcashTransactionStateController<RESPONSE,
        T extends Web3ZcashRequestParam<RESPONSE>>
    extends BaseWeb3ZcashTransactionStateController<RESPONSE, T>
    with
        ZcashTransactionApiController,
        ZcashTransactionFeeController,
        ZcashTransactionUtxosController,
        ZcashWeb3TransactionApiController {
  Web3ZcashTransactionStateController(
      {required super.walletProvider, required super.request});

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required IZcashSignedTransaction signedTransaction}) async {
    final response =
        await client.submitTransaction(signedTransaction.finalTransactionData);
    return SubmitTransactionSuccess(
        txId: response ?? signedTransaction.txId, signedTransaction: signedTransaction);
  }
}
