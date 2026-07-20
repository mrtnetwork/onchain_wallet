import 'dart:async';

import 'package:blockchain_utils/networks/types/address.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/transaction/pages/state_warning.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';
import 'package:on_chain_wallet/app/core.dart';

class Web3RequestTransactionResponseData<RESPONSE,
    SUCCESS extends SubmitTransactionSuccess> extends Web3RequestResponseData<RESPONSE> {
  final List<SubmitTransactionResult>? txIds;
  Web3RequestTransactionResponseData(
      {required super.response, super.message, this.txIds});
  factory Web3RequestTransactionResponseData.submitTx(
      {required RESPONSE response, required List<SubmitTransactionResult> txIds}) {
    assert(txIds.isNotEmpty);
    return Web3RequestTransactionResponseData(
        response: response, txIds: txIds.isEmpty ? null : txIds);
  }
}

abstract class Web3TransactionStateController<
    RESPONSE,
    NETWORKADDRESS extends IAddress,
    NETWORK extends WalletNetwork,
    ACCOUNT extends ACCOUNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
    CLIENT extends CLIENTNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
    OUTCLIENT extends CLIENT?,
    C extends APPCHAINADDRESSNETWORKACCOUNTCLIENT<NETWORKADDRESS, NETWORK, ACCOUNT,
        CLIENT>,
    CHANACCOUNT extends Web3ChainAccount<NETWORKADDRESS>,
    PARAMS extends Web3RequestParams<RESPONSE, NETWORKADDRESS, ACCOUNT, C, CHANACCOUNT>,
    WEB3REQUEST extends Web3NetworkRequest<RESPONSE, NETWORKADDRESS, ACCOUNT, C,
        CHANACCOUNT, PARAMS>,
    TRANSACTIONDATA extends ITransactionData,
    TRANSACTION extends ITransaction<TRANSACTIONDATA, ACCOUNT>,
    SIGNEDTX extends ISignedTransaction<TRANSACTION, Object>,
    T extends ChainTransaction,
    SUCCESS extends SubmitTransactionSuccess<
        SIGNEDTX>> extends Web3StateController<
    RESPONSE,
    NETWORKADDRESS,
    NETWORK,
    CLIENT,
    OUTCLIENT,
    ACCOUNT,
    C,
    CHANACCOUNT,
    PARAMS,
    WEB3REQUEST,
    Web3RequestTransactionResponseData<RESPONSE, SUCCESS>,
    T> {
  Web3TransactionStateController({required super.walletProvider, required super.request});

  List<StreamSubscription<IntegerBalance>> _listeners = [];

  Future<TRANSACTIONDATA> buildTransactionData({bool simulate = false});
  Future<TRANSACTION> buildTransaction({bool simulate = false});
  Future<SIGNEDTX> signTransaction(TRANSACTION transaction, {bool fakeSignature = false});
  Future<SubmitTransactionResult> submitTransaction(
      {required SIGNEDTX signedTransaction});
  Future<List<IWalletTransaction<T, ACCOUNT>>> buildWalletTransaction(
      {required SIGNEDTX signedTx, required SUCCESS? txId});

  WalletWeb3ClientTransaction web3ClientInfo() {
    return WalletWeb3ClientTransaction(
        name: request.info.client?.name ?? request.authenticated.name,
        applicationId: request.authenticated.applicationId,
        image: request.info.client?.image ?? request.authenticated.icon);
  }

  Future<SUCCESS> buildSignAndSendTransaction() async {
    final transaction = await buildTransaction();
    final signedTransaction = await signTransaction(transaction);
    final txId = await submitTransaction(signedTransaction: signedTransaction);
    Logging.debug(
      fn: () => AppLogData(
          runtime: runtimeType,
          function: "buildSignAndSendTransaction",
          msg: txId.toString()),
    );
    if (txId.status.isFailed) {
      final error = txId.cast<SubmitTransactionFailed>();
      throw Web3RequestExceptionConst.excuteTransactionFailed(error.error);
    }
    return txId.cast<SUCCESS>();
  }

  void onAccountUpdated(ACCOUNT e) {}

  @override
  Future<void> initForm(OUTCLIENT client) async {
    for (final i in accounts) {
      final sub = i.addressData.balance.stream.listen((e) => onAccountUpdated(i));
      _listeners.add(sub);
    }
    await super.initForm(client);
    account.updateAccountBalances(addresses: accounts);
  }

  @override
  Future<void> acceptRequest({BuildContext? context}) async {
    try {
      if (!stateStatus.value.isReady) return;
      final warning = stateStatus.value.warning;
      if (context != null && warning != null) {
        final accept = await context.openSliverDialog(
            widget: (context) => TransactionStateWarningView(warning: warning));
        if (accept != true) return;
      }
      pageKey.processs(text: "processing_request".tr);
      final response = await getResponse();
      request.completeResponse(response.response);
      final txIds = response.txIds;
      List<IWalletTransaction<T, ACCOUNT>> walletTxes = [];
      if (txIds != null) {
        for (final i in txIds) {
          if (i.status.isFailed) continue;
          final successResult = i.cast<SUCCESS>();
          walletTxes = await buildWalletTransaction(
              signedTx: successResult.signedTransaction, txId: successResult);
          for (final i in walletTxes) {
            await account.saveTransaction(address: i.account, transaction: i.transaction);
          }
          Logging.debug(
            fn: () => AppLogData(
                runtime: runtimeType,
                function: "submit transaction",
                msg: successResult.txId),
          );
        }
        pageKey.responseTx(
            txIds: txIds,
            transactions: walletTxes.map((e) => e.transaction).toList(),
            account: account);
      } else {
        pageKey.response(text: response.message);
      }
    } on Web3RequestException catch (e, s) {
      pageKey.errorResponse(error: e);
      request.error(e);
      Logging.error(
        fn: () => AppLogData(
            runtime: runtimeType, function: "acceptRequest", err: e, trace: s.toString()),
      );
    } on AppException catch (e, s) {
      pageKey.error(error: e, showBackButton: true);
      Logging.error(
        fn: () => AppLogData(
            runtime: runtimeType, function: "acceptRequest", err: e, trace: s.toString()),
      );
    } catch (e, s) {
      Logging.error(
        fn: () => AppLogData(
            runtime: runtimeType, function: "acceptRequest", err: e, trace: s.toString()),
      );
      final error = IExceptionUtils.findError(e);
      pageKey.errorResponse(error: error);
      request.error(error);
    }
  }

  @override
  void dispose() {
    super.dispose();
    for (final i in [..._listeners]) {
      i.cancel();
    }
    _listeners = [];
  }
}
