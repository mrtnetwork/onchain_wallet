import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/widgets/transfer_token.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class SolanaTransactionTransferTokenOperation
    extends SolanaTransactionTransferStateController2 {
  SolanaTransactionTransferTokenOperation(
      {required super.walletProvider,
      required super.account,
      required super.address,
      required this.token});
  StreamSubscription? _tokenBalanceListener;
  final SolanaSPLToken token;
  @override
  Token get transferToken => token.token;

  BigInt getMaxInput(SolanaTransferDetails recipient) {
    final total =
        recipients.value.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.balance);
    final max = token.balance.balance - total + recipient.amount.balance;
    if (max.isNegative) return BigInt.zero;
    return max;
  }

  void onUpdateAmount(SolanaTransferDetails recipient, BigInt amount, bool max) {
    recipient.updateBalance(amount);
    onStateUpdated();
    estimateFee();
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;
    String? simulateError =
        txFee.fee.hasError ? "transaction_simulation_failed".tr : null;
    BigInt total = address.addressData.currencyBalance - txFee.fee.fee.balance;
    if (total.isNegative) {
      return TransactionStateStatus.insufficient(
          IntegerBalance.token(total, network.token),
          warning: simulateError);
    }
    total = recipients.value.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.balance);
    final r = token.balance.balance - total;
    if (r.isNegative) {
      return TransactionStateStatus.insufficient(IntegerBalance.token(r, transferToken),
          warning: simulateError);
    }
    return TransactionStateStatus.ready(warning: simulateError);
  }

  @override
  Future<ISolanaTransactionData> buildTransactionData({bool simulate = false}) async {
    final blockhash = await getTransactionBlockHash(simulate: simulate);
    final instructions = (await Future.wait(recipients.value.map((e) =>
            e.instruction(owner: address.networkAddress, client: client, token: token))))
        .expand((e) => e)
        .toList();
    return ISolanaTransactionData(
        fee: txFee.fee,
        payment: recipients.value
            .map((e) => ISolanaTransactionDataTokenTransfer(
                recipient: e.recipient.networkAddress,
                amount: e.amount.balance,
                token: token))
            .toList(),
        memo: memo.value,
        instructions: instructions,
        blockHash: blockhash);
  }

  @override
  Future<List<IWalletTransaction<SolanaWalletTransaction, ISolanaAddress>>>
      buildWalletTransaction(
          {required ISolanaSignedTransaction signedTx,
          required SubmitTransactionSuccess txId}) async {
    final memo = signedTx.transaction.transactionData.getWalletTxMemo();
    final payments =
        signedTx.transaction.transactionData.payment?.where((e) => e.token == token) ??
            [];
    if (payments.isEmpty) {
      return super.buildWalletTransaction(signedTx: signedTx, txId: txId);
    }
    final outputs = payments
        .map((e) => SolanaWalletTransactionTransferOutput(
            to: e.recipient,
            amount: WalletTransactionIntegerAmount(
                amount: e.amount,
                network: network,
                token: e.token?.token,
                tokenIdentifier: e.token?.identifier)))
        .toList();

    final total =
        outputs.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.amount.balance);
    final transaction = SolanaWalletTransaction(
        txId: txId.txId,
        memos: [if (memo != null) memo],
        outputs: outputs,
        totalOutput: WalletTransactionIntegerAmount(
            amount: total,
            network: network,
            token: token.token,
            tokenIdentifier: token.identifier),
        network: network);
    return [IWalletTransaction(transaction: transaction, account: address)];
  }

  @override
  Future<TransactionStateController> cloneController(ISolanaAddress address) async {
    final tokens = (await address.getAccountTokens()).unwrap();
    final addressToken = tokens.firstWhere((e) => e.mint == token.mint,
        orElse: () => token.clone(balance: BigInt.zero));
    return SolanaTransactionTransferTokenOperation(
        walletProvider: walletProvider,
        account: account,
        address: address,
        token: addressToken);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return SolanaTransactionTransferTokenWidget(form: this);
  }

  @override
  TransactionOperations get operation => SolanaTransactionOperations.tokenTransfer;

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required SolanaNetworkClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await super.initForm(context: context, client: client, updateAccount: false);
    if (!addressTokens.contains(token)) {
      await account.updateTokenBalance(address: address, tokens: [token]);
    } else {
      account.updateTokenBalance(address: address, tokens: [token]);
    }
    _tokenBalanceListener = token.streamBalance.stream.listen((_) => onStateUpdated());
    return this;
  }

  @override
  void dispose() {
    super.dispose();
    _tokenBalanceListener?.cancel();
    _tokenBalanceListener = null;
    token.streamBalance.dispose();
  }
}
