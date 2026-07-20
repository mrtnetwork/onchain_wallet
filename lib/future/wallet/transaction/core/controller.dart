import 'dart:async';

import 'package:blockchain_utils/networks/types/address.dart';
import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:flutter/widgets.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/future/wallet/transaction/pages/state_warning.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

mixin TransactionStatePageController<
    SUCCESS extends SubmitTransactionSuccess,
    SIGNEDTX,
    CHAINTRANSACTION extends ChainTransaction,
    ACCOUNT extends APPCHAIN> on DisposableMixin {
  WalletNetwork get network;
  final StreamPageProgressController pageKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);

  void setPageIdle() {
    pageKey.backToIdle();
  }

  void setPageProgress(String text, {LivePercentProgressBar? progressBar}) {
    pageKey.progressText(text, progressBar: progressBar);
  }

  Widget onTxCompleteWidget({
    required CHAINTRANSACTION? transaction,
    required SUCCESS txId,
    required ACCOUNT account,
  }) {
    return SuccessTransactionTextView(
        txId: txId.txId,
        warning: txId.warning,
        account: account,
        transaction: transaction);
  }

  void setTxComplete({
    required CHAINTRANSACTION? transaction,
    required SUCCESS txId,
    required ACCOUNT account,
  }) {
    pageKey.success(
        progressWidget:
            onTxCompleteWidget(transaction: transaction, txId: txId, account: account),
        backToIdle: false);
    final txUrl = network.getTransactionExplorer(txId.txId);
    Logging.debug(
      fn: () => AppLogData(
          runtime: runtimeType,
          function: "setTxComplete",
          msg: "txID: ${txId.txId}. $txUrl"),
    );
  }

  void setPageError(String error, {bool backToIdle = false, bool showBackButton = true}) {
    pageKey.errorText(error, backToIdle: backToIdle, showBackButton: showBackButton);
  }

  @override
  void dispose() {
    pageKey.dispose();
    super.dispose();
  }
}

enum TransactionStateControllerEventType { transaction, signedTx, submitTx, walletTxs }

class TransactionStateControllerEvent<
    ACCOUNT extends ChainAccount,
    TRANSACTIONDATA extends ITransactionData,
    TRANSACTION extends ITransaction<TRANSACTIONDATA, ACCOUNT>,
    SIGNEDTX extends ISignedTransaction<TRANSACTION, Object>,
    T extends ChainTransaction,
    SUCCESS extends SubmitTransactionSuccess<SIGNEDTX>> {
  final TransactionStateControllerEventType type;
  final TRANSACTION? tx;
  final SIGNEDTX? signedTx;
  final SUCCESS? submitTx;
  final List<IWalletTransaction<T, ACCOUNT>>? walletTxs;
  const TransactionStateControllerEvent(
      {required this.type, this.tx, this.signedTx, this.submitTx, this.walletTxs});
}

abstract class TransactionStateController<
        TOKEN extends TokenCore,
        NETWORK extends WalletNetwork,
        ACCOUNT extends ChainAccount<IAddress, TOKEN, NFTCore, ChainTransaction, NETWORK>,
        CLIENT extends CLIENTNWORK<NETWORK>,
        C extends APPCHAINTOKENNETWORKACCOUNTCLIENT<TOKEN, NETWORK, ACCOUNT, CLIENT>,
        TRANSACTIONDATA extends ITransactionData,
        TRANSACTION extends ITransaction<TRANSACTIONDATA, ACCOUNT>,
        SIGNEDTX extends ISignedTransaction<TRANSACTION, Object>,
        T extends ChainTransaction,
        SUCCESS extends SubmitTransactionSuccess<SIGNEDTX>,
        FEE extends TransactionFeeData>
    with
        DisposableMixin,
        StreamStateController,
        TransactionStatePageController<SUCCESS, SIGNEDTX, T, C> {
  List<TOKEN> _addressTokens = [];
  List<TOKEN> get addressTokens => _addressTokens;
  final lock = SafeAtomicLock();
  StreamSubscription<void>? _feeListener;
  StreamSubscription<IntegerBalance>? _accountListener;
  late final StreamValue<TransactionStateStatus> stateStatus =
      StreamValue(TransactionStateStatus.error(), name: "$runtimeType");
  late final SafeStreamController<
          TransactionStateControllerEvent<ACCOUNT, TRANSACTIONDATA, TRANSACTION, SIGNEDTX,
              T, SUCCESS>> _event =
      SafeStreamController.broadcast(name: "TransactionStateController.$runtimeType");
  Stream<
      TransactionStateControllerEvent<ACCOUNT, TRANSACTIONDATA, TRANSACTION, SIGNEDTX, T,
          SUCCESS>> onStateEvent({TransactionStateControllerEventType? type}) {
    if (type == null) return _event.stream();
    return _event.stream().where((e) => e.type == type);
  }

  FEE get txFee;
  TransactionOperations get operation;
  final ACCOUNT address;
  late CLIENT _client;
  CLIENT get client => _client;
  final WalletProvider walletProvider;
  final C account;
  @override
  final NETWORK network;
  bool get swtichAddressEnabled => true;
  TransactionStateController(
      {required this.walletProvider, required this.account, required this.address})
      : network = account.network;
  Future<TransactionStateController> cloneController(ACCOUNT address);
  Widget widgetBuilder(BuildContext context);
  Future<TRANSACTION> buildTransaction({bool simulate = false});
  Future<SIGNEDTX> signTransaction(TRANSACTION transaction, {bool fakeSignature = false});
  Future<SubmitTransactionResult> submitTransaction(
      {required SIGNEDTX signedTransaction});
  Future<List<IWalletTransaction<T, ACCOUNT>>> buildWalletTransaction(
      {required SIGNEDTX signedTx, required SUCCESS txId});
  Future<TRANSACTIONDATA> buildTransactionData({bool simulate = false});
  Future<void> estimateFee();
  BigInt getMaxFeeInput() {
    return address.addressData.currencyBalance;
  }

  void onFeeUpdated(void _) {
    onStateUpdated();
  }

  void onAccountUpdated() {
    onStateUpdated();
  }

  TransactionStateStatus getStateStatus() {
    if (!fieldsFiled) {
      return TransactionStateStatus.error();
    }
    if (!txFee.fee.isManual && txFee.isPending) {
      return TransactionStateStatus.error();
    }

    final fieldsError = this.fieldsError;
    if (fieldsError != null) {
      return TransactionStateStatus.error();
    }
    if (txFee.feeMode.isDynamicFee && !txFee.hasFee) {
      return TransactionStateStatus.error(error: "fee_zero_validator_desc".tr);
    }
    return TransactionStateStatus.ready();
  }

  Future<TransactionStateController> initForm({
    required BuildContext context,
    required CLIENT client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    _feeListener = txFee.stream.listen(onFeeUpdated);
    _accountListener =
        account.addressSync.addressData.balance.stream.listen((_) => onAccountUpdated());
    if (updateAccount || updateTokens) {
      account.updateAddressBalance(address, tokens: updateTokens);
    }
    return this;
  }

  Future<List<IWalletTransaction<T, ACCOUNT>>> _buildWalletTransaction(
      {required TRANSACTION transaction,
      required SIGNEDTX signedTx,
      required SUCCESS txId}) async {
    final txes = await buildWalletTransaction(signedTx: signedTx, txId: txId);
    for (final i in txes) {
      await account.saveTransaction(address: i.account, transaction: i.transaction);
    }

    return txes;
  }

  Future<IResult<TRANSACTION>> onTranactionCreatedInternal({
    required TRANSACTION transaction,
    required BuildContext context,
  }) async {
    return ResultOk(transaction);
  }

  Future<void> signAndSendTransaction({
    required BuildContext context,
    Future<TRANSACTION?> Function(TRANSACTION)? onTransactionCreated,
    Future<SIGNEDTX?> Function(SIGNEDTX)? onTransactionSigned,
  }) async {
    stateStatus.value = getStateStatus();
    if (stateStatus.value.status.hasError) return;
    final warning = stateStatus.value.warning;
    if (warning != null) {
      final accept = await context.openSliverDialog(
          widget: (context) => TransactionStateWarningView(warning: warning));
      if (accept != true) return;
    }
    setPageProgress("creating_transaction".tr);
    final result = await IResult.call(() async {
      TRANSACTION? transaction = await buildTransaction();
      if (onTransactionCreated != null) {
        transaction = await onTransactionCreated(transaction);
      }
      if (transaction == null || closed) return null;
      final txInternal =
          await onTranactionCreatedInternal(transaction: transaction, context: context);
      transaction = txInternal.unwrap();
      _event.add(TransactionStateControllerEvent(
          type: TransactionStateControllerEventType.transaction, tx: transaction));
      setPageProgress("signing_transaction_please_wait".tr);
      SIGNEDTX? signedTransaction = await signTransaction(transaction);
      if (onTransactionSigned != null) {
        signedTransaction = await onTransactionSigned(signedTransaction);
      }
      if (signedTransaction == null || closed) return null;

      _event.add(TransactionStateControllerEvent(
          type: TransactionStateControllerEventType.signedTx,
          signedTx: signedTransaction));
      setPageProgress("broadcast_to_the_network_please_wait".tr);
      if (closed) return null;
      SubmitTransactionResult result =
          await submitTransaction(signedTransaction: signedTransaction);
      return (transaction, signedTransaction, result);
    }, delay: APPConst.animationDuraion);
    if (result.isErr) {
      Logging.error(
          fn: () => AppLogData(
                runtime: runtimeType,
                function: "signAndSendTransaction",
                err: result.unwrapErr().exception,
              ));

      if (result.err()?.exception == WalletExceptionConst.rejectSigning) {
        setPageIdle();
      } else {
        setPageError(result.unwrapErr().localizationError);
      }
      return;
    }
    final txResult = result.unwrap();
    if (txResult == null) {
      if (closed) return;
      if (pageKey.status.inProgress) setPageIdle();
      return;
    }
    final submittionResult = txResult.$3;
    if (submittionResult.status.isFailed) {
      final error = (submittionResult as SubmitTransactionFailed).error;
      Logging.error(
        fn: () => AppLogData(
            runtime: runtimeType, function: "signAndSendTransaction", msg: error),
      );
      setPageError(error.tr);
      return;
    }
    final successResult = submittionResult as SUCCESS;
    _event.add(TransactionStateControllerEvent(
        type: TransactionStateControllerEventType.submitTx, submitTx: successResult));
    final walletTxs = await _buildWalletTransaction(
        transaction: txResult.$1, signedTx: txResult.$2, txId: successResult);
    IWalletTransaction<T, ACCOUNT>? currentTx;
    if (walletTxs.isNotEmpty) {
      currentTx = walletTxs.firstWhere((e) => e.account == address,
          orElse: () => walletTxs.first);
      _event.add(TransactionStateControllerEvent(
          type: TransactionStateControllerEventType.walletTxs, walletTxs: walletTxs));
    }

    setTxComplete(
        transaction: currentTx?.transaction, txId: successResult, account: account);
  }

  void onStateUpdated() {
    final status = getStateStatus();
    stateStatus.value = status;
  }

  Widget onPageBuilder(BuildContext context) {
    return APPStreamBuilder(
        value: notifier, builder: (_, value) => widgetBuilder(context));
  }

  Future<TransactionStateController> init(BuildContext context) async {
    final client = await account.client();
    final init = await client.andThenAsync((client) async {
      final tokens = await address.getAccountTokens();
      return tokens.mapCatchAsync((tokens) async {
        _client = client;
        _addressTokens = tokens;
        final controller = await initForm(client: _client, context: context);
        onStateUpdated();
        estimateFee();
        return controller;
      });
    });
    return init.fold(
      onErr: (error) {
        Logging.error(
          fn: () => AppLogData(
              runtime: runtimeType,
              function: "init",
              err: error.exception,
              trace: error.trace),
        );
        setPageError(error.localizationError, backToIdle: false, showBackButton: false);
        return this;
      },
      onOk: (value) {
        setPageIdle();
        return value;
      },
    );
  }

  bool get fieldsReady => fieldsError == null;
  String? get fieldsError {
    for (final i in fields) {
      final fieldError = i.validate;
      if (fieldError != null) return fieldError;
    }
    return null;
  }

  bool get fieldsFiled {
    for (final i in fields) {
      final filed = i.complete;
      if (!filed) return false;
    }
    return true;
  }

  List<LiveFormField> get fields;
  @override
  void dispose() {
    super.dispose();
    _event.close();
    _accountListener?.cancel();
    _feeListener?.cancel();
    for (final i in fields) {
      i.dispose();
    }
  }
}
