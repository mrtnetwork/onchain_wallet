import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/web3/controllers/controllers.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/web3/pages/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart'
    show Web3RequestExceptionConst;
import 'package:on_chain_wallet/web3/web3/networks/stellar/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/stellar/params/models/transaction.dart';
import 'package:stellar_dart/stellar_dart.dart';

class WebStellarSignTransactionStateController
    extends Web3StellarTransactionStateController<Web3StellarSendTransactionResponse,
        Web3StellarSendTransaction, IWeb3StellarTransactionRawData> {
  IWeb3StellarTransactionRawData? _transactionData;
  IWeb3StellarTransactionRawData get transactionData => _transactionData!;

  WebStellarSignTransactionStateController(
      {required super.walletProvider, required super.request});

  bool get isExcute => request.params.method == Web3StellarRequestMethods.sendTransaction;

  @override
  Future<IWeb3StellarTransaction<IWeb3StellarTransactionRawData>> buildTransaction(
      {bool simulate = false}) async {
    final transactionData = await buildTransactionData(simulate: simulate);
    return IWeb3StellarTransaction(
        account: defaultAccount, transactionData: transactionData);
  }

  @override
  Future<IWeb3StellarTransactionRawData> buildTransactionData(
      {bool simulate = false}) async {
    final tx = MethodUtils.fallbackOnException(
        () => Envelope.fromXdr(request.params.transaction));
    if (tx == null) {
      throw Web3RequestExceptionConst.invalidTransaction;
    }
    final accountResponse = await client.getAccount(defaultAccount.networkAddress);
    if (accountResponse == null) {
      throw Web3RequestExceptionConst.inactiveAccount;
    }
    final transactionInfo = await getWeb3TransactionInfo(
        envlope: tx,
        chain: account,
        signer: defaultAccount,
        signerAccountInfo: accountResponse);
    return IWeb3StellarTransactionRawData(
        transaction: tx, accountInfo: accountResponse, transactionInfo: transactionInfo);
  }

  @override
  Future<List<IWalletTransaction<StellarWalletTransaction, IStellarAddress>>>
      buildWalletTransaction(
          {required IWeb3StellarSignedTransaction<IWeb3StellarTransactionRawData>
              signedTx,
          required SubmitTransactionSuccess<
                  IWeb3StellarSignedTransaction<IWeb3StellarTransactionRawData>>?
              txId}) async {
    if (txId == null) return [];
    final transaction = StellarWalletTransaction(
        txId: txId.txId,
        network: network,
        web3Client: web3ClientInfo(),
        type: WalletTransactionType.web3Tx);
    return [
      IWalletTransaction(transaction: transaction, account: signedTx.transaction.account)
    ];
  }

  @override
  Future<
          Web3RequestTransactionResponseData<
              Web3StellarSendTransactionResponse,
              SubmitTransactionSuccess<
                  IWeb3StellarSignedTransaction<IWeb3StellarTransactionRawData>>>>
      getResponse() async {
    if (isExcute) {
      final txId = await buildSignAndSendTransaction();
      return Web3RequestTransactionResponseData.submitTx(
          response: Web3StellarSendTransactionResponse(
              envlope: txId.signedTransaction.finalTransactionData.toVariantXDRBase64(),
              txHash: txId.txId),
          txIds: [txId]);
    }
    final transaction = await buildTransaction();
    final signedTransaction = await signTransaction(transaction);
    return Web3RequestTransactionResponseData(
        response: Web3StellarSendTransactionResponse(
            envlope: signedTransaction.finalTransactionData.toVariantXDRBase64()));
  }

  @override
  Future<IWeb3StellarSignedTransaction<IWeb3StellarTransactionRawData>> signTransaction(
      IWeb3StellarTransaction<IWeb3StellarTransactionRawData> transaction,
      {bool fakeSignature = false}) async {
    final envlope = transaction.transactionData.transaction;
    final signedTx = await signTransactionInternal(
        address: transaction.account,
        transaction:
            transaction.transactionData.transaction.tx.cast<StellarTransactionV1>());
    return IWeb3StellarSignedTransaction(
        transaction: transaction,
        signatures: signedTx.signatures.map((e) => e.signature).toList(),
        finalTransactionData: TransactionV1Envelope(
            tx: signedTx.tx,
            signatures: [...envlope.signatures, ...signedTx.signatures]));
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3StellarSignTransactionStateView(this);
  }

  @override
  Future<void> initForm(StellarClient client) async {
    await super.initForm(client);
    _transactionData = await buildTransactionData();
  }
}
