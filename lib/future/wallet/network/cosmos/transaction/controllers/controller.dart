import 'dart:async';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cosmos_sdk/proto_messages/cosmos/base/v1beta1/src/coin.dart';
import 'package:cosmos_sdk/proto_messages/cosmos/tx/v1beta1/models.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/controllers/signer.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

import 'fee.dart';
import 'memo.dart';

abstract class CosmosTransactionStateController2 extends BaseCosmosTransactionController
    with
        CosmosTransactionFeeController,
        CosmosTransactionMemoController,
        CosmosTransactionApiController,
        CosmosTransactionSignerController {
  CosmosTransactionRequirment _transactionRequirment = CosmosTransactionRequirment();

  List<CW20Token> _tokens = [];
  List<CW20Token> get tokens => _tokens;
  late CW20Token _nativeToken;
  CW20Token get nativeToken => _nativeToken;
  @override
  CosmosTransactionRequirment get transactionRequirment => _transactionRequirment;

  CosmosTransactionStateController2(
      {required super.walletProvider, required super.account, required super.address});

  @override
  Future<void> estimateFee() async {
    if (!fieldsReady) return;
    return super.estimateFee();
  }

  @override
  bool onUpdateMemo(String? memo) {
    final updated = super.onUpdateMemo(memo);
    if (updated) {
      estimateFee();
    }
    return updated;
  }

  @override
  void onRemoveMemo() {
    super.onRemoveMemo();
    estimateFee();
  }

  @override
  Future<ICosmosTransaction> buildTransaction({bool simulate = false}) async {
    final transaction = await buildTransactionData(simulate: simulate);
    final txBody = TxBody(
        messages: transaction.messages.map((e) => e.message.toAny()).toList(),
        memo: transaction.memo);
    return ICosmosTransaction(
        account: address, transaction: txBody, transactionData: transaction);
  }

  @override
  Future<ICosmosSignedTransaction> signTransaction(ICosmosTransaction transaction,
      {bool fakeSignature = false}) async {
    final address = transaction.account;
    final txBody = transaction.transaction;
    final fee = transaction.transactionData.fee;
    final feeDenom = transaction.transactionData.feeDenom;
    final authInfo = AuthInfo(
        signerInfos: [
          address.signerInfo.copyWith(sequence: transaction.transactionData.sequence)
        ],
        fee: Fee(amount: [
          if (network.coinParam.networkType != CosmosNetworkTypes.thorAndForked)
            Coin(denom: feeDenom, amount: "${fee.fee.balance}"),
        ], gasLimit: fee.gasLimit));
    final SignDoc signDoc = SignDoc(
        bodyBytes: txBody.toBuffer(),
        authInfoBytes: authInfo.toBuffer(),
        chainId: network.coinParam.chainId,
        accountNumber: transaction.transactionData.accountNumber);
    final signature = await signTransactionInternal(
        payload: signDoc.toBuffer().asImmutableBytes,
        signer: address,
        fakeSignature: fakeSignature);
    final txRaw = TxRaw(
        bodyBytes: txBody.toBuffer(),
        authInfoBytes: authInfo.toBuffer(),
        signatures: [signature.signature]);
    return ICosmosSignedTransaction(
        transaction: transaction,
        signatures: [signature.signature],
        finalTransactionData: txRaw,
        auth: authInfo);
  }

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required ICosmosSignedTransaction signedTransaction}) async {
    final txId = await client
        .broadcastTransaction(signedTransaction.finalTransactionData.toBuffer());
    return SubmitTransactionSuccess(txId: txId, signedTransaction: signedTransaction);
  }

  @override
  Future<List<IWalletTransaction<CosmosWalletTransaction, ICosmosAddress>>>
      buildWalletTransaction(
          {required ICosmosSignedTransaction<ICosmosTransactionData> signedTx,
          required SubmitTransactionSuccess txId}) async {
    final txData = signedTx.transaction.transactionData;
    final payments = txData.payments ?? [];
    final memo = txData.getWalletTxMemo();
    final outputs = payments.map((e) {
      final token = e.token.denom == network.coinParam.denom ? null : e.token;
      return CosmosWalletTransactionTransferOutput(
          to: e.recipient,
          amount: WalletTransactionIntegerAmount(
              amount: e.amount,
              token: token?.token,
              network: network,
              tokenIdentifier: token?.denom));
    }).toList();
    final totalNative = payments.fold<BigInt>(
        BigInt.zero,
        (p, e) =>
            p + (e.token.denom == network.coinParam.denom ? e.amount : BigInt.zero));
    final transaction = CosmosWalletTransaction(
        txId: txId.txId,
        time: DateTime.now(),
        outputs: outputs,
        memos: [if (memo != null) memo],
        totalOutput:
            WalletTransactionIntegerAmount(amount: totalNative, network: network),
        network: network);
    return [IWalletTransaction(transaction: transaction, account: address)];
  }

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required CosmosNetworkClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await super.initForm(context: context, client: client, updateAccount: updateAccount);
    _transactionRequirment = await getTransactionRequirment(owner: address);
    await initFee();
    _nativeToken = CW20Token.create(
        balance: address.addressData.currencyBalance,
        token: network.token,
        denom: network.coinParam.denom);
    _tokens = [
      _nativeToken,
      ...addressTokens,
    ].toImutableList;
    return this;
  }

  @override
  void dispose() {
    super.dispose();
    for (final i in _tokens) {
      i.streamBalance.dispose();
    }
    for (final i in transactionRequirment.feeTokens) {
      i.streamBalance.dispose();
    }
  }
}
