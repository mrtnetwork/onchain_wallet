import 'dart:async';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/controllers/utxos.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

import 'fee.dart';
import 'memo.dart';
import 'provider.dart';
import 'signer.dart';

abstract class BitcoinTransactionStateController extends BaseBitcoinTransactionController
    with
        BitcoinTransactionUtxosController,
        BtocinTransactionApiController,
        BitcoinTransactionFeeController,
        BitcoinTransactionMempController,
        BitcoinTransactionSignerController {
  late final bool supportCashToken = network.coinParam.isBCH;

  BitcoinTransactionStateController(
      {required super.walletProvider, required super.account, required super.address});

  @override
  Future<IBitcoinTransaction> buildTransaction({bool simulate = false}) async {
    final transactionData = await buildTransactionData(simulate: simulate);
    final transaction = switch (network.coinParam.isForked) {
      true => ForkedTransactionBuilder(
          utxos: transactionData.utxos,
          enableRBF: transactionData.enableRBF,
          outPuts: transactionData.outputs.map((e) => e.output).toList(),
          network: network.coinParam.transacationNetwork,
          fee: transactionData.fee.fee.balance,
          inputOrdering: transactionData.ordering,
          outputOrdering: transactionData.ordering,
          isFakeTransaction: simulate),
      false => BitcoinTransactionBuilder(
          utxos: transactionData.utxos,
          enableRBF: transactionData.enableRBF,
          outPuts: transactionData.outputs.map((e) => e.output).toList(),
          network: network.coinParam.transacationNetwork,
          fee: transactionData.fee.fee.balance,
          inputOrdering: transactionData.ordering,
          outputOrdering: transactionData.ordering,
          isFakeTransaction: simulate)
    };
    final List<IBitcoinAddress> signers = [];
    for (final i in transactionData.utxos) {
      final IBitcoinAddress utxosAcount = account.addresses.firstWhere((element) =>
          element.networkAddress.baseAddress.addressProgram ==
          i.ownerDetails.address.addressProgram);
      signers.add(utxosAcount);
    }
    return IBitcoinTransaction(
        account: address,
        transactionData: transactionData,
        transaction: transaction,
        accounts: signers);
  }

  @override
  Future<IBitcoinSignedTransaction> signTransaction(IBitcoinTransaction transaction,
      {bool fakeSignature = false}) async {
    final List<IBitcoinAddress> signers = transaction.accounts;
    final signedTx = await signTransactionInternal(
        transaction: transaction.transaction,
        signers: signers,
        fakeSignature: fakeSignature);
    return IBitcoinSignedTransaction(
        transaction: transaction,
        finalTransactionData: signedTx.transaction,
        signatures: signedTx.signatures);
  }

  @override
  Future<BtcTransaction> buildSimulateTransaction() async {
    final transaction = await buildTransaction(simulate: true);
    final signedTransaction = await signTransaction(transaction, fakeSignature: true);
    return signedTransaction.finalTransactionData;
  }

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required IBitcoinSignedTransaction signedTransaction}) async {
    final txId = await client.sendTransaction(signedTransaction.finalTransactionData);
    return SubmitTransactionSuccess(txId: txId, signedTransaction: signedTransaction);
  }

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required BitcoinNetworkClient<IBitcoinAddress> client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await super.initForm(context: context, client: client, updateAccount: false);
    await initAccountUtxos(addresses: account.addresses);
    return this;
  }
}
