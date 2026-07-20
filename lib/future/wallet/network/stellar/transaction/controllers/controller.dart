import 'dart:async';

import 'package:blockchain_utils/utils/string/string.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/types/operations.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/widgets/operations/operations.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:stellar_dart/stellar_dart.dart';

import 'fee.dart';
import 'memo.dart';
import 'provider.dart';
import 'signer.dart';

class StellarTransactionStateController extends BaseStellarTransactionController
    with
        StellarTransactionApiController,
        StellarTransactionFeeController,
        StellarTransactionMemoontroller,
        StellarTransactionSignerController {
  StellarAccountResponse? _accountData;
  StellarAccountResponse get accountData => _accountData!;
  late IntegerBalance _noneActiveAccountRequiredAmount =
      IntegerBalance.token(BigInt.zero, network.token);
  IntegerBalance get noneActiveAccountRequiredAmount => _noneActiveAccountRequiredAmount;

  StellarTransactionStateController._(
      {required super.walletProvider, required super.account, required super.address});
  factory StellarTransactionStateController(
      {required WalletProvider walletProvider,
      required StellarChain account,
      required IStellarAddress address,
      OperationType? operation,
      StellarIssueToken? token}) {
    final instance = StellarTransactionStateController._(
        walletProvider: walletProvider, account: account, address: address);
    if (token != null && (operation == null || operation == OperationType.payment)) {
      instance._onCreatePaymentOperation(token: token);
    } else if (operation != null) {
      instance.onCreateNewOperation(operation);
    }
    return instance;
  }

  final LiveFormFields<StellarTransactionOperationData> operations =
      LiveFormFields(title: "operations".tr, optional: false);
  final LiveFormField<StellarTransactionOperationForm?, StellarTransactionOperationForm>
      pendingOperation =
      LiveFormField(title: "operation".tr, value: null, optional: true);
  final LiveFormField<TransactionTimeBound, TransactionTimeBound> timebound =
      LiveFormField(
          title: "time_bound".tr,
          subtitle: "stellar_time_bound_desc".tr,
          value: TransactionTimeBound.auto());

  void onUpdateTimeBound(TransactionTimeBound? timebound) {
    if (timebound == null) return;
    this.timebound.setValue(timebound);
  }

  void onSkipOperation() {
    final operation = pendingOperation.value;
    if (operation == null) return;
    pendingOperation.setValue(null);
    operation.dispose();
  }

  void onCreateNewOperation(OperationType? type) {
    if (type == null || pendingOperation.hasValue) return;
    final form = StellarTransactionOperationForm.create(controller: this, type: type);
    pendingOperation.setValue(form);
  }

  void _onCreatePaymentOperation({StellarIssueToken? token}) {
    if (pendingOperation.hasValue) return;
    final asset = StellarPickedIssueAsset(
        asset: token?.toStellarAsset() ?? StellarAssetNative(),
        network: network,
        issueToken: token);
    final form = StellarPaymentOperationForm(controller: this);
    form.onUpdateAsset(asset);
    pendingOperation.setValue(form);
  }

  void onEditOperation(StellarTransactionOperationData operation) {
    if (pendingOperation.hasValue) return;
    final form = operation.form;
    pendingOperation.setValue(form);
    operations.removeValue(operation);
  }

  void onUpdateOperations() {
    final form = pendingOperation.value;
    if (form == null) return;
    form.onStateUpdated();
    if (!form.status.value.isReady) return;
    final operation = form.toOperation();
    final data = StellarTransactionOperationData(operation: operation, form: form);
    operations.addValue(data);
    onStateUpdated();
    estimateFee();
    pendingOperation.setValue(null);
  }

  @override
  Future<void> estimateFee({int operations = 1}) async {
    if (!fieldsReady) return;
    if (this.operations.value.isNotEmpty) {
      operations = this.operations.value.length;
    }
    return super.estimateFee(operations: operations);
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;
    if (pendingOperation.hasValue) {
      return TransactionStateStatus.error();
    }
    final total = operations.value.fold(BigInt.zero, (p, c) => p + c.operation.value);
    final balance = address.addressData.currencyBalance;
    final remain = balance - total - txFee.fee.fee.balance;
    if (remain.isNegative) {
      return TransactionStateStatus.insufficient(
          IntegerBalance.token(remain, network.token));
    }
    final payments = operations.value
        .map((e) => e.operation)
        .whereType<StellarPaymentOperation>()
        .where((e) => !e.asset.asset.type.isNative);
    for (final i in payments) {
      final balance = i.asset.tokenBalance;
      if (balance == null) continue;
      final total = payments
          .where((e) => e.asset.asset == i.asset.asset)
          .fold(BigInt.zero, (p, c) => p + c.amount.balance);
      final remain = balance.balance - total;
      if (remain.isNegative) {
        return TransactionStateStatus.insufficient(
            IntegerBalance.token(remain, i.asset.token));
      }
    }

    return TransactionStateStatus.ready();
  }

  @override
  void onUpdateMemo(StellarMemo? memo) {
    super.onUpdateMemo(memo);
    onStateUpdated();
    estimateFee();
  }

  @override
  void onRemoveMemo() {
    super.onRemoveMemo();
    onStateUpdated();
    estimateFee();
  }

  @override
  Future<IStellarTransactionData> buildTransactionData({bool simulate = false}) async {
    final operations = this.operations.value.map((e) => e.operation).toList();
    operations.sort((a, b) {
      if (a.type == OperationType.createAccount) {
        return -1;
      } else if (b.type == OperationType.createAccount) {
        return 1;
      }
      return 0;
    });
    return IStellarTransactionData(
        fee: txFee.fee,
        operations: operations,
        timeboundCondition: timebound.value.condition(),
        memo: memo.value?.memo ?? const StellarMemoNone(),
        sequence: accountData.sequence + BigInt.one);
  }

  @override
  Future<IStellarTransaction> buildTransaction({bool simulate = false}) async {
    final transactionData = await buildTransactionData(simulate: simulate);
    final transaction = StellarTransactionV1(
        sourceAccount: address.networkAddress.toMuxedAccount(),
        fee: transactionData.fee.fee.balance.toInt(),
        seqNum: transactionData.sequence,
        cond: transactionData.timeboundCondition,
        operations: transactionData.operations.map((e) => e.toOperation()).toList(),
        memo: transactionData.memo);
    return IStellarTransaction(
        transaction: transaction, transactionData: transactionData, account: address);
  }

  @override
  Future<IStellarSignedTransaction> signTransaction(IStellarTransaction transaction,
      {bool fakeSignature = false}) async {
    final signedTx = await signTransactionInternal(
        address: transaction.account, transaction: transaction.transaction);
    return IStellarSignedTransaction(
        signatures: signedTx.signatures.map((e) => e.signature).toList(),
        finalTransactionData: signedTx,
        transaction: transaction);
  }

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required IStellarSignedTransaction signedTransaction}) async {
    final envelopeXdr = signedTransaction.finalTransactionData.toVariantXDRBase64();
    final submissionResult =
        await IResult.call(() async => await client.submitTx(envelopeXdr));

    if (submissionResult.isErr) {
      return SubmitTransactionFailed(submissionResult.unwrapErr().localizationError);
    }
    final success = submissionResult.unwrap()?.successful ?? true;
    if (!success) {
      final result = MethodUtils.fallbackOnException(
        () => submissionResult.unwrap()?.getResult().toJson(),
        mode: LoggerMode.danger,
        onError: (exception, trace) => AppLogData(
          runtime: runtimeType,
          function: "submitTransaction",
          msg: "Failed to get submission result.",
          err: exception,
          trace: trace.toString(),
        ),
      );
      if (result == null) {
        return SubmitTransactionFailed("submit_transaction_error".tr.replaceOne(''));
      }
      return SubmitTransactionFailed(
          "submit_transaction_error".tr.replaceOne("\n${StringUtils.fromJson(result)}"));
    }
    final String txId = submissionResult.unwrap()?.id ??
        signedTransaction.finalTransactionData
            .txId(network.coinParam.stellarChainType.passphraseHash);
    return SubmitTransactionSuccess(
        txId: txId,
        warning: submissionResult.unwrap() == null
            ? "tx_submit_response_failed_desc".tr
            : null,
        signedTransaction: signedTransaction);
  }

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required StellarClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await super.initForm(context: context, client: client, updateAccount: updateAccount);

    _accountData = await getAccount(address.networkAddress);
    if (_accountData == null) {
      throw AppException("account_not_found");
    }
    final baseReserve = await getBaseReserve();
    await initFee();
    _noneActiveAccountRequiredAmount = IntegerBalance.token(
        BigInt.from(baseReserve), network.token,
        allowNegative: false, immutable: true);
    return this;
  }

  @override
  Future<List<IWalletTransaction<StellarWalletTransaction, IStellarAddress>>>
      buildWalletTransaction(
          {required IStellarSignedTransaction signedTx,
          required SubmitTransactionSuccess txId}) async {
    final txData = signedTx.transaction.transactionData;
    final memo = txData.getWalletTxMemo();
    final outputs =
        txData.operations.map((e) => e.toWalletTransactionOutput(network)).toList();
    final totalOut = outputs
        .whereType<StellarWalletTransactionTransferOutput>()
        .where((e) => e.amount.isNativeToken)
        .fold<BigInt>(BigInt.zero, (p, c) => p + (c.amount.amount.balance));
    final transaction = StellarWalletTransaction(
        txId: txId.txId,
        network: network,
        memos: [if (memo != null) memo],
        outputs: outputs,
        totalOutput: WalletTransactionIntegerAmount(amount: totalOut, network: network));
    return [IWalletTransaction(transaction: transaction, account: address)];
  }

  @override
  Future<TransactionStateController> cloneController(IStellarAddress address) async {
    return StellarTransactionStateController(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  TransactionOperations get operation => StellarTransactionOperations.transfer;

  @override
  Widget widgetBuilder(BuildContext context) {
    return StellarTransactionGlobalOperationWidget(form: this);
  }

  @override
  List<LiveFormField<Object?, Object?>> get fields =>
      [operations, pendingOperation, timebound];

  @override
  void dispose() {
    for (final i in operations.value) {
      i.form.dispose();
    }
    pendingOperation.value?.dispose();
    super.dispose();
  }
}
