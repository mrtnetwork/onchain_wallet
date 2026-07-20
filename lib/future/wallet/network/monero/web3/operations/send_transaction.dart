import 'dart:async';
import 'package:flutter/material.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/web3/controllers/controllers.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/web3/pages/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/monero/monero.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/monero.dart';
import 'package:on_chain_wallet/web3/web3/networks/monero/params/models/transaction.dart';

class WebMoneroSignTransactionStateController
    extends Web3MoneroTransactionStateController<Web3MoneroTransactionResponse,
        Web3MoneroSendTransaction> {
  IMoneroTransactionData? _transactionData;
  IMoneroTransactionData get transactionData => _transactionData!;
  List<MoneroUtxoWithBalanceInfo> _utxos = [];
  StreamSubscription<void>? _feeListener;

  WebMoneroSignTransactionStateController(
      {required super.walletProvider, required super.request});

  late final LiveFormField<MoneroTransferDetails, MoneroTransferDetails> remainingAmount =
      LiveFormField(
          title: "remaining_amount".tr,
          subtitle: "remaining_amount_and_receiver".tr,
          value: MoneroTransferDetails(
              allowNegativeAmount: true,
              recipientUpdateble: true,
              recipient: account.getOrCreateReceiptFromNetworkAddressSync(
                  account: defaultAccount),
              token: network.token),
          optional: false);

  BigInt maxFeeInput() {
    return totalUtxos.value.balance;
  }

  @override
  Future<IMoneroTransaction> buildTransaction({bool simulate = false}) async {
    final transactionData = await buildTransactionData(simulate: simulate);
    final payments = transactionData.payments.map((e) => e.toLockedPayment()).toList();
    final spendablePayment = await buildRingOutput(payments);
    return IMoneroTransaction(
        account: defaultAccount,
        transactionData: transactionData,
        fee: txFee.fee.fee.balance,
        spendablePayment: spendablePayment);
  }

  @override
  Future<IMoneroTransactionData> buildTransactionData({bool simulate = false}) async {
    return IMoneroTransactionData(
      change: remainingAmount.value.hasAmount
          ? MoneroTxDestination(
              amount: remainingAmount.value.amount.balance,
              address: remainingAmount.value.recipient.networkAddress)
          : null,
      payments: _utxos,
      destinations: params.destintions
          .map((e) => IMoneroTransactionDataTransfer(
              recipient: getOrCreateAddressInfo(e.destination),
              amount: IntegerBalance.token(e.amount, network.token,
                  allowNegative: false, immutable: true)))
          .toList(),
    );
  }

  @override
  Future<List<IWalletTransaction<MoneroWalletTransaction, IMoneroAddress>>>
      buildWalletTransaction(
          {required IMoneroSignedTransaction signedTx,
          required SubmitTransactionSuccess<IMoneroSignedTransaction>? txId}) async {
    if (txId == null) return [];
    final List<IWalletTransaction<MoneroWalletTransaction, IMoneroAddress>> transactions =
        [];
    final signers =
        signedTx.transaction.transactionData.payments.map((e) => e.account).toSet();
    final destinations = signedTx.transaction.transactionData.destinations
        .map((e) => MoneroWalletTransactionOutput(
            amount: WalletTransactionIntegerAmount(
                amount: e.amount.balance, network: network),
            to: e.recipient.networkAddress))
        .toList();
    for (final i in signers) {
      final payments = signedTx.transaction.transactionData.payments
          .where((e) => e.account == i)
          .toList();
      final transaction = MoneroWalletTransaction(
          txId: txId.txId,
          time: DateTime.now(),
          network: network,
          totalOutput: WalletTransactionIntegerAmount(
              amount: payments.fold<BigInt>(BigInt.zero, (p, c) => p + c.utxo.amount),
              network: network),
          outputs: destinations,
          txKeys: signedTx.finalTransactionData.txData.txKeys.map((e) => e.key).toList());
      transactions.add(IWalletTransaction(transaction: transaction, account: i));
    }
    return transactions;
  }

  @override
  Future<
      Web3RequestTransactionResponseData<Web3MoneroTransactionResponse,
          SubmitTransactionSuccess<IMoneroSignedTransaction>>> getResponse() async {
    final result = await buildSignAndSendTransaction();
    return Web3RequestTransactionResponseData.submitTx(
        response: Web3MoneroTransactionResponse(
            proofs: result.signedTransaction.finalTransactionData.destinations
                .map((e) => Web3MoneroTransactionProofsResponse(
                    address: e.destination.address.address, proof: e.proof!))
                .toList(),
            txId: result.txId),
        txIds: [result]);
  }

  String? filterRemainAccount(IMoneroAddress address) {
    if (address.networkAddress == remainingAmount.value.recipient.networkAddress ||
        transactionData.destinations
            .any((e) => e.recipient.networkAddress == address.networkAddress)) {
      return "address_already_exist".tr;
    }
    return null;
  }

  void onUpdateRemainingAccount(IMoneroAddress? address) {
    if (address == null || filterRemainAccount(address) != null) return;
    final recipient = account.getOrCreateReceiptFromNetworkAddressSync(account: address);
    remainingAmount.value.updateRecipientAddress(recipient);
    remainingAmount.notify();
    onStateUpdated();
  }

  void _onReceiptsUpdated() {
    final totalOutput = totalUtxos.value.balance;
    final totalAmounts = transactionData.destinations.fold(
        BigInt.zero, (previousValue, element) => previousValue + element.amount.balance);
    remainingAmount.value
        .updateBalance(totalOutput - totalAmounts - txFee.fee.fee.balance);
    remainingAmount.notify();
  }

  @override
  Future<void> estimateFee() async {
    if (_utxos.isEmpty) return;
    return super.estimateFee();
  }

  @override
  TransactionStateStatus getStateStatus() {
    if (_utxos.isEmpty) return TransactionStateStatus.error();
    if (!txFee.fee.isManual && txFee.isPending) {
      return TransactionStateStatus.error();
    }
    final accounts = [
      ..._transactionData?.destinations.map((e) => e.recipient.networkAddress) ?? [],
      remainingAmount.value.recipient.networkAddress
    ];
    if (accounts.toSet().length != accounts.length) {
      return TransactionStateStatus.error(
          error: "duplicate_output_addresses_not_allowed".tr);
    }
    if (!txFee.hasFee) {
      return TransactionStateStatus.error(error: "fee_zero_validator_desc".tr);
    }
    String? simulateError =
        txFee.fee.hasError ? "transaction_simulation_failed".tr : null;
    return TransactionStateStatus.insufficient(remainingAmount.value.amount,
        warning: simulateError);
  }

  @override
  void onSelectedUtxosChanged(List<MoneroUtxoWithBalanceInfo> utxos) {
    _utxos = utxos;
    _onReceiptsUpdated();
    onStateUpdated();
    estimateFee();
  }

  @override
  Future<IMoneroSignedTransaction> signTransaction(IMoneroTransaction transaction,
      {bool fakeSignature = false}) async {
    return await signTransactionInternal(transaction, withProof: true);
  }

  @override
  Future<IMoneroTransactionData> simulateTransaction() async {
    return await buildTransactionData(simulate: true);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3MoneroSignTransactionStateView(this);
  }

  void onFeeUpdated(void _) {
    _onReceiptsUpdated();
    onStateUpdated();
  }

  @override
  Future<void> initForm(MoneroNetworkClient client) async {
    await super.initForm(client);
    _transactionData = await buildTransactionData();
    final syncing = await account.getSyncing();
    final addresses = await syncing.andThenAsync((e) async {
      final related = await account.getPrimaryAccountAddresses(defaultAccount);
      return related.map((addresses) => (syncing: e, addresses: addresses));
    });
    await addresses.foldAsync(
      onErr: (error) => throw error.exception,
      onOk: (value) async {
        final syncing = value.syncing;
        if (syncing == null) {
          throw AppException("transaction_required_syncing_desc");
        }
        final height = await client.getHeight();
        await initAccountUtxos(
            addresses: value.addresses, syncing: syncing, latestHeight: height);
        _feeListener = txFee.stream.listen(onFeeUpdated);
        return this;
      },
    );
    // await initAccountUtxos(account: account, address: defaultAccount);

    // estimateFee();
  }

  @override
  void dispose() {
    super.dispose();
    _feeListener?.cancel();
    _feeListener = null;
  }
}
