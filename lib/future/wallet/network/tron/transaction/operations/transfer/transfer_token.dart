import 'dart:async';

import 'package:blockchain_utils/utils/string/string.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/tron/tron.dart';
import 'package:on_chain_wallet/crypto/networks/utils.dart';
import 'package:on_chain_wallet/future/state_managment/extension/app_extensions/string.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/widgets/widgets/transfer.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/tron/client/tron.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/token_core.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/tron.dart';

import 'transfer.dart';

abstract class TronTransactionBaseTransferTokenOperation<TOKEN extends TronToken,
        CONTRACT extends TronBaseContract>
    extends TronTransactionBaseTransferOperation<CONTRACT> {
  final TOKEN token;
  @override
  Token get transferToken => token.token;
  StreamSubscription<IntegerBalance>? _tokenBalanceListener;

  TronTransactionBaseTransferTokenOperation(
      {required super.walletProvider,
      required super.account,
      required super.address,
      required this.token});

  @override
  BigInt getMaxInput() {
    return token.balance.balance;
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) {
      return status;
    }
    IntegerBalance total = address.addressData.balance.value - txFee.fee.fee;
    if (total.isNegative) {
      return TransactionStateStatus.insufficient(total);
    }
    total = token.balance - amount.value;
    if (total.isNegative) {
      return TransactionStateStatus.insufficient(total);
    }
    return TransactionStateStatus.ready();
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return TronTransactionTransferWidget(form: this, token: token);
  }

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required TronClient client,
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
    token.streamBalance.dispose();
    _tokenBalanceListener?.cancel();
    _tokenBalanceListener = null;
  }
}

class TronTransactionTransferTRC10TokenOperation
    extends TronTransactionBaseTransferTokenOperation<TronTRC10Token,
        TransferAssetContract> {
  TronTransactionTransferTRC10TokenOperation(
      {required super.walletProvider,
      required super.account,
      required super.address,
      required super.token});

  @override
  TransactionContractType get transactionType {
    return TransactionContractType.transferAssetContract;
  }

  @override
  Future<List<IWalletTransaction<TronWalletTransaction, ITronAddress>>>
      buildWalletTransaction(
          {required ITronSignedTransaction<ITronTransactionData<TransferAssetContract>>
              signedTx,
          required SubmitTransactionSuccess txId}) async {
    final txData = signedTx.transaction.transactionData;
    final transfer = txData.tokenTransfer;
    final token = transfer?.token;
    assert(transfer != null && token != null);
    if (transfer == null || token == null) {
      return super.buildWalletTransaction(signedTx: signedTx, txId: txId);
    }

    final txMemo = txData.getMemo();
    final transaction = TronWalletTransaction(
        txId: txId.txId,
        network: network,
        memos: [if (txMemo != null) txMemo],
        totalOutput: WalletTransactionIntegerAmount(
            amount: transfer.amount,
            network: network,
            token: token.token,
            tokenIdentifier: token.identifier),
        outputs: [
          TronWalletTransactionTransferOutput(
            to: transfer.recipient,
            amount: WalletTransactionIntegerAmount(
                amount: transfer.amount,
                network: network,
                token: token.token,
                tokenIdentifier: token.identifier),
          ),
        ]);
    return [
      IWalletTransaction(transaction: transaction, account: signedTx.transaction.account)
    ];
  }

  @override
  Future<ITronTransactionData<TransferAssetContract>> buildTransactionData(
      {bool simulate = false}) async {
    final blockData = await transactionBlockRequirment(simulate: simulate);
    return ITronTransactionData(
      fee: txFee.fee,
      blockData: blockData,
      memo: memo.value,
      tokenTransfer: ITronTransactionDataTokenTransfer(
          recipient: receipt.value!.networkAddress,
          amount: amount.value.balance,
          token: token),
      contract: TransferAssetContract(
          assetName: StringUtils.encode(token.tokenID),
          ownerAddress: address.networkAddress,
          toAddress: receipt.value!.networkAddress,
          amount: amount.value.balance),
    );
  }

  @override
  Future<TransactionStateController> cloneController(ITronAddress address) async {
    final tokens = (await address.getAccountTokens()).unwrap();
    final token = tokens.whereType<TronTRC10Token>().firstWhere(
        (e) => e.identifier == this.token.identifier,
        orElse: () => this.token.clone());
    return TronTransactionTransferTRC10TokenOperation(
        walletProvider: walletProvider, account: account, address: address, token: token);
  }
}

class TronTransactionTransferTRC20TokenOperation
    extends TronTransactionBaseTransferTokenOperation<TronTRC20Token,
        TriggerSmartContract> {
  @override
  bool get isTrc20Transfer => true;
  StreamSubscription<IntegerBalance>? _listener;

  void _onFeeLimitUpdated(IntegerBalance _) {
    onStateUpdated();
    estimateFee();
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;
    if (!txFee.fee.hasError &&
        txFee.hasFee &&
        feeLimit.value.balance < txFee.fee.fee.balance) {
      return TransactionStateStatus.ready(warning: 'low_fee_limit_desc'.tr);
    }
    return status;
  }

  TronTransactionTransferTRC20TokenOperation(
      {required super.walletProvider,
      required super.account,
      required super.address,
      required super.token});

  @override
  TransactionContractType get transactionType {
    return TransactionContractType.triggerSmartContract;
  }

  @override
  Future<ITronTransactionData<TriggerSmartContract>> buildTransactionData(
      {bool simulate = false}) async {
    final blockData = await transactionBlockRequirment(simulate: simulate);
    return ITronTransactionData(
        fee: txFee.fee,
        blockData: blockData,
        tokenTransfer: ITronTransactionDataTokenTransfer(
            recipient: receipt.value!.networkAddress,
            amount: amount.value.balance,
            token: token),
        memo: memo.value,
        feeLimit: simulate ? TronUtils.maxTronFeeLimit : feeLimit.value.balance,
        contract: TriggerSmartContract(
          ownerAddress: address.networkAddress,
          contractAddress: token.contractAddress,
          data: SolidityContractUtils.erc20Transfer
              .encode([receipt.value!.networkAddress, amount.value.balance]),
        ));
  }

  @override
  Future<List<IWalletTransaction<TronWalletTransaction, ITronAddress>>>
      buildWalletTransaction(
          {required ITronSignedTransaction<ITronTransactionData<TriggerSmartContract>>
              signedTx,
          required SubmitTransactionSuccess txId}) async {
    final txData = signedTx.transaction.transactionData;

    final transfer = txData.tokenTransfer;
    final token = transfer?.token;
    assert(transfer != null && token != null);
    if (transfer == null || token == null) {
      return super.buildWalletTransaction(signedTx: signedTx, txId: txId);
    }
    final txMemo = txData.getMemo();
    final transaction = TronWalletTransaction(
        txId: txId.txId,
        network: network,
        memos: [if (txMemo != null) txMemo],
        totalOutput: WalletTransactionIntegerAmount(
            amount: transfer.amount,
            network: network,
            token: token.token,
            tokenIdentifier: token.identifier),
        outputs: [
          TronWalletTransactionTransferOutput(
            to: transfer.recipient,
            amount: WalletTransactionIntegerAmount(
                amount: transfer.amount,
                network: network,
                token: token.token,
                tokenIdentifier: token.identifier),
          ),
        ]);
    return [
      IWalletTransaction(transaction: transaction, account: signedTx.transaction.account)
    ];
  }

  @override
  Future<TransactionStateController> cloneController(ITronAddress address) async {
    final tokens = (await address.getAccountTransactions()).unwrap();
    final token = tokens.whereType<TronTRC20Token>().firstWhere(
        (e) => e.identifier == this.token.identifier,
        orElse: () => this.token.clone());
    return TronTransactionTransferTRC20TokenOperation(
        walletProvider: walletProvider, account: account, address: address, token: token);
  }

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required TronClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await super.initForm(context: context, client: client, updateAccount: updateAccount);
    _listener = feeLimit.live.stream.listen(_onFeeLimitUpdated);
    return this;
  }

  @override
  void dispose() {
    super.dispose();
    _listener?.cancel();
    _listener = null;
  }
}
