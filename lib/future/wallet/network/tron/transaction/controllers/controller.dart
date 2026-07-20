import 'dart:async';

import 'package:blockchain_utils/utils/string/string.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/tron/src/models/contract/base_contract/base_contract.dart';
import 'package:on_chain/tron/src/models/contract/transaction/any.dart';
import 'package:on_chain/tron/src/models/contract/transaction/transaction_contract.dart';
import 'package:on_chain/tron/src/models/contract/transaction/transaction_raw.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/tron/tron.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/controllers/memo.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

import 'fee.dart';
import 'provider.dart';
import 'signer.dart';

abstract class TronTransactionStateController2<CONTRACT extends TronBaseContract>
    extends BaseTronTransactionController<ITronTransactionData<CONTRACT>>
    with
        TronTransactionApiController,
        TronTransactionFeeController,
        TronTransactionMemoController<ITronTransactionData<CONTRACT>>,
        TronTransactionSignerController {
  TronAccountInfo? _accountInfo;
  TronAccountInfo? get accountInfo => _accountInfo;

  TronAccountResourceInfo? _accountResource;
  TronAccountResourceInfo? get accountResource => _accountResource;
  @override
  Future<ITronTransactionData<CONTRACT>> buildTransactionData({bool simulate = false});

  TronTransactionStateController2(
      {required super.walletProvider, required super.account, required super.address});

  @override
  BigInt getMaxFeeInput() {
    final balance = address.addressData.currencyBalance;
    if (balance > TronUtils.maxTronFeeLimit) return TronUtils.maxTronFeeLimit;
    return balance;
  }

  @override
  Future<TronSimulateTransaction> simulateTransaction() async {
    final transaction = await buildTransaction(simulate: true);
    final signature = await signTransaction(transaction, fakeSignature: true);
    final rawTransaction = signature.transaction.transaction;
    int totalSigner = 1;
    if (address.multiSigAccount) {
      final multiSigAccount = address as ITronMultisigAddress;
      totalSigner = multiSigAccount.multiSignatureAccount.signers.length;
    }
    return TronSimulateTransaction(
        transaction: rawTransaction,
        totalSigners: totalSigner,
        accountResource: _accountResource ?? TronAccountResourceInfo.empty());
  }

  @override
  Future<void> estimateFee() async {
    if (!fieldsReady) return;
    return super.estimateFee();
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) {
      return status;
    }
    final max = address.addressData.balance.value - txFee.fee.fee;
    if (max.isNegative) {
      return TransactionStateStatus.insufficient(max);
    }
    return TransactionStateStatus.ready();
  }

  @override
  bool onUpdateMemo(String? memo) {
    final updated = super.onUpdateMemo(memo);
    if (updated) {
      onStateUpdated();
      estimateFee();
    }
    return updated;
  }

  @override
  void onRemoveMemo() {
    super.onRemoveMemo();
    onStateUpdated();
    estimateFee();
  }

  @override
  Future<ITronTransaction<ITronTransactionData<CONTRACT>>> buildTransaction(
      {bool simulate = false}) async {
    final transactionData = await buildTransactionData(simulate: simulate);
    int? permissionId;
    if (address.multiSigAccount) {
      final multiSigAccount = address as ITronMultisigAddress;
      permissionId = multiSigAccount.multiSignatureAccount.permissionID;
    }
    final contract = transactionData.contract;
    final transactionContract = TransactionContract(
        type: contract.contractType,
        permissionId: permissionId,
        parameter: Any(typeUrl: contract.typeURL, value: contract));
    final memo = transactionData.memo;
    return ITronTransaction(
        account: address,
        transactionData: transactionData,
        transaction: TransactionRaw(
            refBlockBytes: transactionData.blockData.refBlockBytes,
            refBlockHash: transactionData.blockData.refBlockHash,
            expiration: transactionData.blockData.expiration,
            contract: [transactionContract],
            feeLimit: transactionData.feeLimit,
            data: memo == null ? null : StringUtils.toBytes(memo),
            timestamp: transactionData.blockData.timestamp));
  }

  @override
  Future<List<IWalletTransaction<TronWalletTransaction, ITronAddress>>>
      buildWalletTransaction(
          {required ITronSignedTransaction<ITronTransactionData<CONTRACT>> signedTx,
          required SubmitTransactionSuccess txId}) async {
    final txData = signedTx.transaction.transactionData;
    final txMemo = txData.getMemo();

    final transaction = TronWalletTransaction(txId: txId.txId, network: network, memos: [
      if (txMemo != null) txMemo
    ], outputs: [
      TronWalletTransactionOperationOutput(name: txData.contract.contractType.name)
    ]);

    return [
      IWalletTransaction(transaction: transaction, account: signedTx.transaction.account)
    ];
  }

  @override
  Future<ITronSignedTransaction<ITronTransactionData<CONTRACT>>> signTransaction(
      ITronTransaction<ITronTransactionData<CONTRACT>> transaction,
      {bool fakeSignature = false}) async {
    final transactionRaw = transaction.transaction;
    final signedTx = await signTransactionInternal(
        transaction: transactionRaw, address: address, fakeSignature: fakeSignature);
    return ITronSignedTransaction(
        transaction: transaction,
        signatures: signedTx.signature,
        finalTransactionData: signedTx);
  }

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required ITronSignedTransaction<ITronTransactionData<CONTRACT>>
          signedTransaction}) async {
    final result =
        await client.sendTransaction(signedTransaction.finalTransactionData.toHex);
    if (result.result) {
      return SubmitTransactionSuccess(
          txId: result.txid, signedTransaction: signedTransaction);
    }
    return SubmitTransactionFailed(result.message ?? "submit_transaction_failed".tr);
  }

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required TronClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    _accountInfo = (await address.getAccountInfo_()).unwrap();
    _accountResource = (await address.getAccountResource_()).unwrap();
    await super.initForm(
        context: context, client: client, updateAccount: _accountResource != null);
    // await address.getAccountInfo();
    // await address.getAccountResource();
    if (_accountResource == null) {
      await account.updateAddressBalance(address, tokens: false);
      _accountInfo = (await address.getAccountInfo_()).unwrap();
      _accountResource = (await address.getAccountResource_()).unwrap();
    }
    if (_accountResource == null || _accountInfo == null) {
      throw AppException("account_not_found");
    }
    final permission = checkAccountPermission(
        address: address, transactionType: transactionType, account: _accountInfo);
    if (!permission) {
      if (!address.multiSigAccount) {
        throw AppException("multi_sig_account_does_not_supported");
      } else {
        throw AppException("tron_account_permission_not_access_desc");
      }
    }
    return this;
  }
}
