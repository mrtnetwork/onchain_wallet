import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/controllers/memo.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/controllers/signer.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'fee.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

import 'provider.dart';

abstract class SolanaTransactionStateController extends BaseSolanaTransactionController
    with
        SolanaTransactionApiController,
        SolanaTransactionFeeController,
        SolanaTransactionMemoController,
        SolanaTransactionSignerController {
  SolanaTransactionStateController(
      {required super.walletProvider, required super.account, required super.address});

  @override
  void onFeeUpdated(void _) {
    onStateUpdated();
  }

  @override
  bool onUpdateMemo(String? memo) {
    final updated = super.onUpdateMemo(memo);
    if (updated) {
      estimateFee();
    }
    return updated;
  }

  @override
  void onRemoveMemo() {
    super.onRemoveMemo();
    estimateFee();
  }

  @override
  Future<void> estimateFee({BigInt? accountBalance, BigInt? totalTxLamports}) async {
    if (!fieldsReady) {
      setDefaultFee();
      return;
    }
    return super.estimateFee(
        accountBalance: address.addressData.currencyBalance,
        totalTxLamports: totalTxLamports ?? BigInt.zero);
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;

    String? simulateError =
        txFee.fee.hasError ? "transaction_simulation_failed".tr : null;
    final r = address.addressData.currencyBalance - txFee.fee.fee.balance;
    return TransactionStateStatus.insufficient(IntegerBalance.token(r, network.token),
        warning: simulateError);
  }

  @override
  Future<ISolanaTransaction> buildTransaction({bool simulate = false}) async {
    final transactionData = await buildTransactionData(simulate: simulate);
    final memo = transactionData.memo;
    final transaction = SolanaTransaction(
        payerKey: address.networkAddress,
        instructions: [
          ...transactionData.instructions,
          if (memo != null)
            MemoProgram(layout: MemoLayout(memoBytes: StringUtils.toBytes(memo))),
        ],
        recentBlockhash: transactionData.blockHash);
    return ISolanaTransaction(
        account: address, transaction: transaction, transactionData: transactionData);
  }

  @override
  Future<ISolanaSignedTransaction> signTransaction(ISolanaTransaction transaction,
      {bool fakeSignature = false}) async {
    final solanaTransaction = transaction.transaction;
    final signersAddresses = solanaTransaction.message.accountKeys
        .sublist(0, solanaTransaction.message.header.numRequiredSignatures)
        .map((e) => e.address)
        .toList();
    final signerAccounts = account.addresses
        .where((element) => signersAddresses.contains(element.networkAddress.address))
        .toList();
    final signature = await signTransactionInternal(
        transaction: solanaTransaction, signers: signerAccounts);
    return ISolanaSignedTransaction(
        transaction: transaction,
        signatures: signature.signatures,
        finalTransactionData: signature.transaction);
  }

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required ISolanaSignedTransaction signedTransaction}) async {
    final txId = await client.sendTransaction(signedTransaction.finalTransactionData,
        encoding: SolanaRequestEncoding.base58);
    return SubmitTransactionSuccess(txId: txId, signedTransaction: signedTransaction);
  }

  @override
  Future<List<IWalletTransaction<SolanaWalletTransaction, ISolanaAddress>>>
      buildWalletTransaction(
          {required ISolanaSignedTransaction signedTx,
          required SubmitTransactionSuccess txId}) async {
    final memo = signedTx.transaction.transactionData.getWalletTxMemo();
    final transaction = SolanaWalletTransaction(
        txId: txId.txId,
        memos: [if (memo != null) memo],
        outputs: [SolanaWalletTransactionOperationOutput(name: operation.value.tr)],
        network: network);
    return [IWalletTransaction(transaction: transaction, account: address)];
  }
}

abstract class SolanaTransactionTransferStateController2
    extends SolanaTransactionStateController {
  Token get transferToken;

  SolanaTransactionTransferStateController2(
      {required super.walletProvider, required super.account, required super.address});

  late final LiveFormFields<SolanaTransferDetails> recipients =
      LiveFormFields<SolanaTransferDetails>(
          optional: false,
          title: "list_of_recipients".tr,
          subtitle: "amount_for_each_output".tr,
          onValidateError: (field, value) => _validateRecipients(value));

  String? _validateRecipients(List<SolanaTransferDetails> recipients) {
    if (recipients.isEmpty) {
      return "at_least_one_recipient_required".tr;
    }
    for (final i in recipients) {
      if (!i.hasAmount) return "some_amount_fields_not_filled".tr;
    }
    return null;
  }

  String? filterAccount(SolAddress address) {
    if (address == this.address.networkAddress ||
        recipients.value.any((e) => e.recipient.networkAddress == address)) {
      return "address_already_exist".tr;
    }
    return null;
  }

  void onUpdateRecipients(List<ReceiptAddress<SolAddress>> addressess) {
    final recipients = addressess
        .map((e) => SolanaTransferDetails(recipient: e, token: transferToken))
        .toList();
    this.recipients.addValues(recipients);
    onStateUpdated();
    estimateFee();
  }

  void onRemoveRecipients(SolanaTransferDetails recipient) {
    recipients.removeValue(recipient);
    recipient.dispose();
    onStateUpdated();
    estimateFee();
  }

  @override
  void dispose() {
    super.dispose();
    for (final i in [...recipients.value]) {
      i.dispose();
    }
  }

  @override
  List<LiveFormField<Object?, Object>> get fields => [recipients];
}
