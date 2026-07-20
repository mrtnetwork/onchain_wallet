import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

import 'fee.dart';
import 'memo.dart';
import 'provider.dart';
import 'signer.dart';

abstract class RippleTransactionStateController<TX extends SubmittableTransaction>
    extends BaseRippleTransactionController<IXRPTransactionData<TX>>
    with
        XRPTransactionApiController,
        RippleTransactionFeeController,
        RippleTransactionMemoController<IXRPTransactionData<TX>>,
        RippleTransactionSignerController {
  RippleTransactionStateController(
      {required super.walletProvider, required super.account, required super.address});

  TX buildTransactionInternal();
  @override
  Future<IXRPTransactionData<TX>> buildTransactionData({bool simulate = false}) async {
    return IXRPTransactionData(
        fee: txFee.fee, submittableTransaction: buildTransactionInternal());
  }

  @override
  Future<void> estimateFee() async {
    if (!fieldsReady) return;
    final error = (buildTransactionInternal()).validate;
    if (error != null) {
      return;
    }
    await super.estimateFee();
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;

    String? simulateError =
        txFee.fee.hasError ? "transaction_simulation_failed".tr : null;
    final r = address.addressData.currencyBalance - txFee.fee.fee.balance;
    if (r.isNegative) {
      return TransactionStateStatus.insufficient(IntegerBalance.token(r, network.token),
          warning: simulateError);
    }
    final error = (buildTransactionInternal()).validate;
    if (error != null) {
      return TransactionStateStatus.error(error: error);
    }
    return TransactionStateStatus.ready(warning: simulateError);
  }

  @override
  Future<IXRPTransaction<IXRPTransactionData<TX>>> buildTransaction(
      {bool simulate = false}) async {
    final transaction = await buildTransactionData(simulate: simulate);
    await filledTransactionRequirment(transaction.submittableTransaction);
    return IXRPTransaction(account: address, transactionData: transaction);
  }

  @override
  Future<SubmittableTransaction> simulateTransaction() async {
    final transaction = await buildTransaction(simulate: true);
    return transaction.transactionData.submittableTransaction;
  }

  @override
  Future<IXRPSignedTransaction<IXRPTransactionData<TX>>> signTransaction(
      IXRPTransaction<IXRPTransactionData<TX>> transaction,
      {bool fakeSignature = false}) async {
    final xrpTransaction = transaction.transactionData.submittableTransaction;
    final signature =
        await signTransactionInternalFull(transaction: xrpTransaction, address: address);
    return IXRPSignedTransaction(
        signature: signature.signature,
        transaction: transaction,
        finalTransactionData: xrpTransaction,
        multiSignature: signature.multiSignature,
        signatures: signature.signatures);
  }

  @override
  Future<List<IWalletTransaction<XRPWalletTransaction, IXRPAddress>>>
      buildWalletTransaction(
          {required IXRPSignedTransaction<IXRPTransactionData<TX>> signedTx,
          required SubmitTransactionSuccess txId}) async {
    final transaction = XRPWalletTransaction(
        txId: txId.txId,
        network: network,
        outputs: [XRPWalletTransactionOperationOutput(name: transactionType.value)]);
    return [IWalletTransaction(transaction: transaction, account: address)];
  }

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required IXRPSignedTransaction<IXRPTransactionData<TX>> signedTransaction}) async {
    final txResult = await broadcastTransaction(signedTransaction.finalTransactionData);
    if (!txResult.isSuccess) {
      return SubmitTransactionFailed(txResult.engineResult);
    }
    final txId = txResult.txJson.hash ?? signedTransaction.finalTransactionData.getHash();
    return SubmitTransactionSuccess(signedTransaction: signedTransaction, txId: txId);
  }

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required XRPNetworkClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await checkAccountPermission(address);
    int multiSigner = 0;
    if (address.multiSigAccount) {
      final IXRPMultisigAddress multiSigAddress = address as IXRPMultisigAddress;
      if (!multiSigAddress.multiSignatureAccount.isRegular) {
        multiSigner = multiSigAddress.multiSignatureAccount.signers.length;
      }
    }
    await initFee(multiSigner: multiSigner, type: transactionType);
    await super.initForm(client: client, context: context, updateAccount: updateAccount);
    return this;
  }
}
