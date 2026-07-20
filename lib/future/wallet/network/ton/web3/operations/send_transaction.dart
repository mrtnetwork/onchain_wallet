import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/transaction/controllers/fee.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/transaction/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/transaction/controllers/signer.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/web3/controllers/controllers.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/web3/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/web3/pages/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/ton/params/models/transaction.dart';
import 'package:ton_dart/ton_dart.dart';

class WebTonSendTransactionStateController extends Web3TonTransactionStateController<
        Web3TonSendTransactionResponse,
        Web3TonSendTransaction,
        IWeb3TonTransactionRawData>
    with
        TonWeb3TransactionApiController,
        TonTransactionApiController,
        TonTransactionFeeController,
        TonTransactionSignerController {
  IWeb3TonTransactionRawData? _transactionRawData;
  IWeb3TonTransactionRawData get transactionData => _transactionRawData!;
  bool get isExcute => params.isExcute;
  StreamSubscription<void>? _feeListener;
  WebTonSendTransactionStateController(
      {required super.walletProvider, required super.request});

  @override
  Future<IWeb3TonTransaction<IWeb3TonTransactionRawData>> buildTransaction(
      {bool simulate = false}) async {
    final walletContract = defaultAccount.toWalletContract();
    final transactionData = await buildTransactionData(simulate: simulate);
    final seqno = await getAccountSeqno(walletContract);
    final state = walletContract.state!;
    final transaction = defaultAccount.context.buildTransaction(
      actions: transactionData.messages
          .map((e) => OutActionSendMsg(outMessage: e.toMessage()))
          .toList(),
      state: state,
      seqno: seqno,
      timeout: transactionData.timeout,
    );
    return IWeb3TonTransaction(
        account: defaultAccount,
        transactionData: transactionData,
        stateInit: seqno == 0 ? state.initialState() : null,
        transaction: transaction);
  }

  @override
  Future<IWeb3TonTransactionRawData> buildTransactionData({bool simulate = false}) async {
    return _transactionRawData ??= await () async {
      final List<TonWeb3TransactionMessageInfo> messages = [];
      for (final i in params.messages) {
        final msgInfo = await getWeb3TransactionMessageInfo(
            address: defaultAccount, account: account, message: i);
        messages.add(msgInfo);
      }
      final totalAmount = messages.fold(BigInt.zero,
          (p, c) => p + (c.amount.balance + (c.payload?.tonAmount ?? BigInt.zero)));
      return IWeb3TonTransactionRawData(
          messages: messages,
          timeout: params.validUntil,
          totalAmount: IntegerBalance.token(totalAmount, network.token));
    }();
  }

  @override
  Future<IWeb3TonSignedTransaction<IWeb3TonTransactionRawData>> signTransaction(
      IWeb3TonTransaction<IWeb3TonTransactionRawData> transaction,
      {bool fakeSignature = false}) async {
    final signedTx = await signTransactionInternal(
        transaction: transaction.transaction,
        signer: defaultAccount,
        fakeSignature: fakeSignature,
        stateInit: transaction.stateInit);
    return IWeb3TonSignedTransaction(
        transaction: transaction,
        signatures: signedTx.signatures,
        finalTransactionData: signedTx.message);
  }

  @override
  Future<List<IWalletTransaction<TonWalletTransaction, ITonAddress>>>
      buildWalletTransaction(
          {required IWeb3TonSignedTransaction<IWeb3TonTransactionRawData> signedTx,
          required SubmitTransactionSuccess? txId}) async {
    if (txId == null) return [];
    final total =
        signedTx.transaction.transactionData.messages.map((e) => e.amount.balance).sum;
    final transaction = TonWalletTransaction(
        txId: txId.txId,
        network: network,
        totalOutput: WalletTransactionIntegerAmount(amount: total, network: network));
    return [
      IWalletTransaction(transaction: transaction, account: signedTx.transaction.account)
    ];
  }

  @override
  Future<
          Web3RequestTransactionResponseData<
              Web3TonSendTransactionResponse,
              SubmitTransactionSuccess<
                  IWeb3TonSignedTransaction<IWeb3TonTransactionRawData>>>>
      getResponse() async {
    if (isExcute) {
      final txId = await buildSignAndSendTransaction();
      return Web3RequestTransactionResponseData.submitTx(
          txIds: [txId],
          response: Web3TonSendTransactionResponse(
              message: txId.signedTransaction.externalMessage.toBase64(),
              txHash: txId.txId));
    }
    final transaction = await buildTransaction();
    final signedTransaction = await signTransaction(transaction);
    return Web3RequestTransactionResponseData(
        response: Web3TonSendTransactionResponse(
            message: signedTransaction.externalMessage.toBase64()));
  }

  @override
  Future<TonSimulateTransaction> simulateTransaction() async {
    final transaction = await buildTransaction(simulate: true);
    final signedTransaction = await signTransaction(transaction, fakeSignature: true);
    return TonSimulateTransaction(
        message: signedTransaction.finalTransactionData,
        messages: transactionData.messages
            .map((e) => OutActionSendMsg(outMessage: e.toMessage()))
            .toList(),
        address: transaction.account);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3TonSignTransactionStateView(this);
  }

  void onFeeUpdated(void _) {
    onStateUpdated();
  }

  @override
  TransactionStateStatus getStateStatus() {
    if (txFee.isPending) return TransactionStateStatus.error();

    final remain = defaultAccount.addressData.currencyBalance -
        transactionData.totalAmount.balance -
        txFee.fee.fee.balance;
    if (!remain.isNegative) {
      return TransactionStateStatus.ready();
    }
    final error =
        TransactionStateStatus.insufficient(IntegerBalance.token(remain, network.token))
            .error;

    return TransactionStateStatus.ready(warning: error);
  }

  @override
  Future<void> initForm(TonNetworkClient client) async {
    await super.initForm(client);
    _transactionRawData = await buildTransactionData();
    _feeListener = txFee.stream.listen(onFeeUpdated);
    estimateFee();
  }

  @override
  void dispose() {
    super.dispose();
    _feeListener?.cancel();
    _feeListener = null;
  }
}
