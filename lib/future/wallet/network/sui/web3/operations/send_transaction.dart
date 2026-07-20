import 'dart:async';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/sui/sui.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/transaction/controllers/fee.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/transaction/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/transaction/controllers/signer.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/web3/controllers/controllers.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/web3/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/web3/pages/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/sui/params/models/transaction.dart';

class WebSuiSignTransactionStateController extends Web3SuiTransactionStateController<
        Web3SuiSignOrExcuteTransactionResponse,
        Web3SuiSignOrExecuteTransaction,
        IWeb3SuiTransactionRawData>
    with
        SuiWeb3TransactionApiController,
        SuiTransactionSignerController,
        SuiTransactionApiController,
        SuiTransactionFeeController {
  StreamSubscription<void>? _feeListener;
  IWeb3SuiTransactionRawData? _transactionData;
  IWeb3SuiTransactionRawData get transactionData => _transactionData!;
  final StreamValue<List<SuiWeb3AccountChangeBalance>?> balanceChanged =
      StreamValue(null, name: "WebSuiSignTransactionStateController");
  WebSuiSignTransactionStateController(
      {required super.walletProvider, required super.request});
  bool get isExecute => request.params.isExecute;

  @override
  Future<SubmitSuiTransactionSuccess> submitTransaction(
      {required IWeb3SuiSignedTransaction<IWeb3SuiTransactionRawData>
          signedTransaction}) async {
    final txId = await client.executeWeb3Transaction(
        signatures: [signedTransaction.suiSignature.toVariantBcsBase64()],
        transactionBcs: signedTransaction.finalTransactionData.toVariantBcsBase64(),
        options: params.executeOptions,
        type: params.executeType);
    return SubmitSuiTransactionSuccess<IWeb3SuiTransactionRawData>(
        txId: txId.digest,
        excuteTransactionData: txId,
        signedTransaction: signedTransaction,
        warning: txId.error);
  }

  @override
  Future<IWeb3SuiTransactionRawData> buildTransactionData({bool simulate = false}) async {
    return _transactionData ??= await () async {
      final transaction = await resolveWeb3Transaction(
          transaction: params.transaction, address: defaultAccount);
      final gasData = params.transaction.gasData;
      final hasFee = gasData.hasFee;
      final owner = gasData.owner;
      bool isAccountFeePayer = true;
      ReceiptAddress<SuiAddress>? feePayer;
      ReceiptAddress<SuiAddress>? sender;
      if (owner != null && owner != defaultAccount.networkAddress) {
        isAccountFeePayer = false;
        feePayer = getOrCreateAddressInfo(owner);
      }
      if (transaction.sender != defaultAccount.networkAddress) {
        isAccountFeePayer = false;
        sender = getOrCreateAddressInfo(transaction.sender);
      }
      return IWeb3SuiTransactionRawData(
          transaction: transaction,
          hasFee: hasFee,
          isAccountFeePayer: isAccountFeePayer,
          feePayer: feePayer,
          owner: sender,
          txContent: StringUtils.fromJson(transaction.toJson(),
              indent: ' ', toStringEncodable: true));
    }();
  }

  @override
  Future<IWeb3SuiTransaction<IWeb3SuiTransactionRawData>> buildTransaction(
      {bool simulate = false}) async {
    SuiTransactionDataV1 transaction = transactionData.transaction;
    final fee = txFee.fee;
    if (fee.hasFee) {
      if (!transactionData.hasFee) {
        transaction = transaction.copyWith(
            gasData: params.transaction.gasData.toTransactionGasData(
                owner: defaultAccount.networkAddress,
                budget: fee.budget,
                price: fee.gasPrice));
      }
    }
    if (transaction.gasData.payment.isEmpty) {
      transaction = await filledGasPayment(transaction);
    }
    return IWeb3SuiTransaction(
        account: defaultAccount,
        transactionData: transactionData,
        transaction: transaction);
  }

  @override
  Future<List<IWalletTransaction<SuiWalletTransaction, ISuiAddress>>>
      buildWalletTransaction(
          {required IWeb3SuiSignedTransaction<IWeb3SuiTransactionRawData> signedTx,
          required SubmitTransactionSuccess<
                  IWeb3SuiSignedTransaction<IWeb3SuiTransactionRawData>>?
              txId}) async {
    if (txId == null) return [];
    final transaction = SuiWalletTransaction(
        txId: txId.txId,
        web3Client: web3ClientInfo(),
        network: network,
        type: WalletTransactionType.web3Tx);
    return [
      IWalletTransaction<SuiWalletTransaction, ISuiAddress>(
          account: signedTx.transaction.account, transaction: transaction)
    ];
  }

  @override
  Future<
      Web3RequestTransactionResponseData<Web3SuiSignOrExcuteTransactionResponse,
          SubmitSuiTransactionSuccess<IWeb3SuiTransactionRawData>>> getResponse() async {
    if (isExecute) {
      final result = await buildSignAndSendTransaction();

      return Web3RequestTransactionResponseData.submitTx(
        txIds: [result],
        response: Web3SuiSignAndExecuteTransactionResponse(
            digest: result.excuteTransactionData.digest,
            effects: result.excuteTransactionData.rawTransactionData ?? '',
            excuteResponse: result.excuteTransactionData.effects),
      );
    }
    final transaction = await buildTransaction();
    final signedTransaction = await signTransaction(transaction);
    return Web3RequestTransactionResponseData(
        response: Web3SuiSignTransactionResponse(
            transactionBytes: signedTransaction.finalTransactionData.toVariantBcs(),
            signature: signedTransaction.suiSignature.toVariantBcs(),
            digest: signedTransaction.finalTransactionData.txHash()));
  }

  @override
  Future<IWeb3SuiSignedTransaction<IWeb3SuiTransactionRawData>> signTransaction(
      IWeb3SuiTransaction<IWeb3SuiTransactionRawData> transaction,
      {bool fakeSignature = false}) async {
    final sign = await signTransactionInternal(
        transaction: transaction.transaction, signer: defaultAccount);
    return IWeb3SuiSignedTransaction(
        transaction: transaction,
        signatures: sign.signatures,
        finalTransactionData: sign.transaction,
        suiSignature: sign.suiSignature);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3SuiSignTransactionStateView(this);
  }

  @override
  Future<SuiTransactionDataV1> simulateTransaction(
      {required BigInt gasPrice, required BigInt budget}) async {
    final transaction = transactionData.transaction;
    if (transactionData.hasFee) {
      return transaction;
    }
    return transactionData.transaction.copyWith(
      gasData: params.transaction.gasData.toTransactionGasData(
          owner: defaultAccount.networkAddress, budget: budget, price: gasPrice),
    );
  }

  final Cancelable _cancelable = Cancelable();

  Future<void> _onBalanceChanged(SuiApiDryRunTransactionBlockResponse simulate) async {
    final balanceChanged = await IResult.call(() async {
      return getSimulateBalanceChanges(
          address: defaultAccount.networkAddress,
          changes: simulate.balanceChanges,
          account: account);
    }, cancelable: _cancelable);
    if (balanceChanged.isErr) return;
    this.balanceChanged.value = balanceChanged.unwrap();
  }

  @override
  Future<SuiTransactionFee> simulateFee() async {
    final gasPrice = await getGasPrice();
    final transaction =
        await simulateTransaction(gasPrice: gasPrice, budget: SuiTransactionConst.maxGas);
    final simulate = await client.simulateTransaction(transaction);
    final content = StringUtils.fromJson(simulate.toJson(), indent: ' ');
    if (simulate.effects.status.status != SuiApiExecutionStatusType.success) {
      return SuiTransactionFee(
          gasPrice: BigInt.zero,
          feeToken: network.token,
          simulateData: simulate,
          error: simulate.effects.status.error ?? "transaction_simulation_failed".tr,
          simulateContent: content);
    }
    return SuiTransactionFee(
        gasPrice: gasPrice,
        gasUsed: simulate.effects.gasUsed,
        feeToken: network.token,
        simulateData: simulate,
        simulateContent: content);
  }

  @override
  TransactionStateStatus getStateStatus() {
    if (txFee.isPending) {
      return TransactionStateStatus.error();
    }
    final r = defaultAccount.addressData.currencyBalance - txFee.fee.requiredFee;
    return TransactionStateStatus.warningInsufficient(
        IntegerBalance.token(r, network.token),
        warning: txFee.fee.hasError ? 'transaction_simulation_failed'.tr : null);
  }

  void onFeeUpdated(void _) {
    _cancelable.cancel();
    balanceChanged.value = null;
    if (txFee.isPending) return;
    if (txFee.hasFee && transactionData.owner == null) {
      final simulate = txFee.fee.simulateData;
      if (simulate != null) {
        _onBalanceChanged(simulate);
      }
    }
    onStateUpdated();
  }

  @override
  Future<void> initForm(SuiNetworkClient client) async {
    await super.initForm(client);
    _transactionData = await buildTransactionData();
    _feeListener = txFee.stream.listen(onFeeUpdated);
    estimateFee();
  }

  @override
  void dispose() {
    super.dispose();
    _feeListener?.cancel();
    _feeListener = null;
  }
}
