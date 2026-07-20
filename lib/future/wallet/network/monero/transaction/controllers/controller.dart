import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/transaction/controllers/utxos.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

import 'fee.dart';
import 'provider.dart';
import 'signer.dart';

abstract class MoneroTransactionStateController extends BaseMoneroTransactionController
    with
        MoneroTransactionApiController,
        MoneroTransactionFeeController,
        MoneroTransactionUtxosController,
        MoneroTransactionSignerController {
  Token get transferToken;

  MoneroTransactionStateController(
      {required super.walletProvider, required super.account, required super.address});

  @override
  Future<IMoneroTransactionData> simulateTransaction() async {
    final transaction = await buildTransactionData(simulate: true);
    return transaction;
  }

  @override
  Future<IMoneroSignedTransaction> signTransaction(IMoneroTransaction transaction,
      {bool fakeSignature = false}) async {
    final signedTx = await signTransactionInternal(transaction);
    return signedTx;
  }

  @override
  Future<IMoneroTransaction> buildTransaction({bool simulate = false}) async {
    final transactionData = await buildTransactionData(simulate: simulate);
    final payments = transactionData.payments.map((e) => e.toLockedPayment()).toList();
    final spendablePayment = await buildRingOutput(payments);
    return IMoneroTransaction(
        account: address,
        transactionData: transactionData,
        fee: txFee.fee.fee.balance,
        spendablePayment: spendablePayment);
  }

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

  @override
  Widget onTxCompleteWidget(
      {required MoneroWalletTransaction? transaction,
      required SubmitTransactionSuccess<IMoneroSignedTransaction> txId,
      required MoneroChain account}) {
    return SuccessTransactionTextView(
      txId: txId.txId,
      account: account,
      transaction: transaction,
      additionalWidget: transaction == null
          ? null
          : (context) {
              return FixedElevatedButton(
                  onPressed: () {
                    context.openSliverDialog(
                        widget: (p0) => TransactionModalView(
                              account: account,
                              transaction: transaction,
                              address: address,
                            ),
                        label: "transaction".tr);
                  },
                  child: Text("show_proofs".tr));
            },
    );
  }

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required MoneroNetworkClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await super.initForm(context: context, client: client, updateAccount: updateAccount);
    final syncing = await account.getSyncing();
    final addresses = await syncing.andThenAsync((e) async {
      final related = await account.getPrimaryAccountAddresses(address);
      return related.map((addresses) => (syncing: e, addresses: addresses));
    });
    return addresses.fold(
      onErr: (error) => throw error.exception,
      onOk: (value) async {
        final syncing = value.syncing;
        if (syncing == null) {
          throw AppException("transaction_required_syncing_desc");
        }
        final height = await client.getHeight();
        await initAccountUtxos(
            addresses: value.addresses, syncing: syncing, latestHeight: height);
        return this;
      },
    );
  }
}
