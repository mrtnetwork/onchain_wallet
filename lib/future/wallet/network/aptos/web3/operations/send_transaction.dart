import 'dart:async';

import 'package:blockchain_utils/utils/string/string.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/transaction/controllers/fee.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/transaction/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/transaction/controllers/signer.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/web3/controllers/controllers.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/web3/pages/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/aptos/params/models/transaction.dart';

class Web3AptosSignTransactionStateController extends Web3AptosTransactionStateController<
        List<int>, Web3AptosSendTransaction, IWeb3AptosTransactionRawData>
    with
        AptosTransactionSignerController,
        AptosTransactionApiController,
        AptosTransactionFeeController {
  IWeb3AptosTransactionRawData? _transactionData;
  IWeb3AptosTransactionRawData get transactionData => _transactionData!;
  StreamSubscription<void>? _feeListener;

  Web3AptosSignTransactionStateController(
      {required super.walletProvider, required super.request});

  @override
  Future<
          Web3RequestTransactionResponseData<
              List<int>,
              SubmitTransactionSuccess<
                  IWeb3AptosSignedTransaction<IWeb3AptosTransactionRawData>>>>
      getResponse() async {
    final transaction = await buildTransaction();
    final signature = await signTransaction(transaction);
    return Web3RequestTransactionResponseData(
        response: signature.accountAuthenticator.toVariantBcs());
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3AptosSendTransactionStateView(this);
  }

  @override
  TransactionStateStatus getStateStatus() {
    if (txFee.isPending) return TransactionStateStatus.error();
    String? simulateError =
        txFee.fee.hasError ? "transaction_simulation_failed".tr : null;

    final feePayer = _transactionData?.feePayer ?? _transactionData?.owner;
    if (feePayer != null && feePayer.networkAddress != defaultAccount.networkAddress) {
      return TransactionStateStatus.ready(warning: simulateError);
    }
    final r = defaultAccount.addressData.currencyBalance - txFee.fee.requiredFee;
    final error = TransactionStateStatus.insufficient(
        IntegerBalance.token(r, network.token),
        warning: simulateError);
    return TransactionStateStatus.ready(warning: error.error ?? error.warning);
  }

  @override
  Future<IWeb3AptosTransaction<IWeb3AptosTransactionRawData>> buildTransaction(
      {bool simulate = false}) async {
    final transactionData = await buildTransactionData(simulate: simulate);
    return IWeb3AptosTransaction(
        account: defaultAccount, transactionData: transactionData);
  }

  @override
  Future<IWeb3AptosTransactionRawData> buildTransactionData(
      {bool simulate = false}) async {
    return _transactionData ??= await () async {
      final rawTransaction = params.transaction;
      final transactionContent = StringUtils.fromJson(params.transaction.toJson(),
          indent: ' ', toStringEncodable: true);
      ReceiptAddress<AptosAddress>? owner;
      final address = findPermissionAccount(rawTransaction.sender);
      if (address == null) {
        owner = getOrCreateAddressInfo(rawTransaction.sender);
      }
      final sAddresses = params.secondarySignerAddresses;
      final secondarySignerAddresses =
          sAddresses?.map((e) => getOrCreateAddressInfo(e)).toList();
      final feePayerAddress = params.feePayer;
      final feePayer =
          feePayerAddress == null ? null : getOrCreateAddressInfo(feePayerAddress);
      final transactionType = rawTransaction.transactionPayload.type.name.camelCase;
      return IWeb3AptosTransactionRawData(
          transaction: rawTransaction,
          feePayer: feePayer,
          owner: owner,
          fee: IntegerBalance.token(
              rawTransaction.maxGasAmount * rawTransaction.gasUnitPrice,
              account.network.token),
          secondarySignerAddresses: secondarySignerAddresses,
          transactionContent: transactionContent,
          transactionType: transactionType);
    }();
  }

  @override
  Future<IWeb3AptosSignedTransaction<IWeb3AptosTransactionRawData>> signTransaction(
      IWeb3AptosTransaction<IWeb3AptosTransactionRawData> transaction,
      {bool fakeSignature = false}) async {
    final rawTransaction = transaction.transactionData.transaction;
    if (fakeSignature) {
      return IWeb3AptosSignedTransaction(
          transaction: transaction,
          signatures: [],
          accountAuthenticator: AptosAccountAuthenticatorNoAccountAuthenticator(),
          finalTransactionData: AptosSignedTransaction(
              rawTransaction: rawTransaction,
              authenticator: AptosTransactionAuthenticatorSignleSender(
                  AptosAccountAuthenticatorNoAccountAuthenticator())));
    }

    final signatures = await signTransactionInternal(
        rawTransaction: transaction.transactionData.transaction,
        address: transaction.account,
        feePayerAddress: transaction.transactionData.feePayer?.networkAddress,
        secondarySignerAddresses: transaction.transactionData.secondarySignerAddresses
            ?.map((e) => e.networkAddress)
            .toList(),
        fakeSignature: fakeSignature);
    final accountAuthenticators =
        transaction.account.createAccountAuthenticated(signatures);
    return IWeb3AptosSignedTransaction(
        transaction: transaction,
        signatures: signatures.map((e) => e.signatureBytes()).toList(),
        accountAuthenticator: accountAuthenticators,
        finalTransactionData: AptosSignedTransaction(
            rawTransaction: rawTransaction,
            authenticator:
                AptosTransactionAuthenticatorSignleSender(accountAuthenticators)));
  }

  @override
  Future<AptosSignedTransaction> simulateTransaction(
      {required BigInt maxGasAmount, required BigInt gasUnitPrice}) async {
    final transaction = await buildTransaction(simulate: true);
    final signedTransaction = await signTransaction(transaction, fakeSignature: true);
    return signedTransaction.finalTransactionData;
  }

  @override
  Future<List<IWalletTransaction<AptosWalletTransaction, IAptosAddress>>>
      buildWalletTransaction(
          {required IWeb3AptosSignedTransaction<IWeb3AptosTransactionData> signedTx,
          required SubmitTransactionSuccess? txId}) async {
    if (txId == null) return [];
    return [
      IWalletTransaction(
          transaction: AptosWalletTransaction(
              txId: txId.txId,
              outputs: [],
              web3Client: web3ClientInfo(),
              type: WalletTransactionType.web3,
              network: network),
          account: signedTx.transaction.account),
    ];
  }

  @override
  Future<void> initForm(AptosNetworkClient client) async {
    await super.initForm(client);
    _transactionData = await buildTransactionData(simulate: false);
    _feeListener = txFee.stream.listen((_) => onStateUpdated());
    estimateFee();
  }

  @override
  void dispose() {
    super.dispose();
    _feeListener?.cancel();
    _feeListener = null;
  }
}
