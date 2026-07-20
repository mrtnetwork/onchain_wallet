import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/widgets/transfer.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class ADATransactionTransferOperation extends ADATransactionStateController {
  ADATransactionTransferOperation(
      {required super.walletProvider, required super.account, required super.address});
  ADATransferDetails? _lockedMax;
  @override
  Token get transferToken => network.token;
  List<CardanoAccountUtxo> _utxos = [];

  late final LiveFormFields<ADATransferDetails> recipients =
      LiveFormFields<ADATransferDetails>(
          optional: false,
          title: "list_of_recipients".tr,
          subtitle: "amount_for_each_output".tr,
          onValidateError: (_, value) => _validateRecipients(value));

  late final LiveFormField<ADARemainTransferDetails, ADARemainTransferDetails>
      remainingAmount = LiveFormField(
          title: "remaining_amount".tr,
          subtitle: "remaining_amount_and_receiver".tr,
          value: ADARemainTransferDetails(
              recipient:
                  account.getOrCreateReceiptFromNetworkAddressSync(account: address),
              token: network.token),
          optional: false);

  @override
  BigInt getMaxFeeInput() {
    return totalUtxos.value.balance;
  }

  void _onReceiptsUpdated() {
    final totalOutput = totalUtxos.value.balance;
    BigInt totalAmounts = recipients.value.fold(
        BigInt.zero, (previousValue, element) => previousValue + element.amount.balance);
    totalAmounts = deposit.fold(
        totalAmounts, (previousValue, element) => previousValue + element.fee.balance);
    totalAmounts = refund.fold(
        totalAmounts, (previousValue, element) => previousValue - element.fee.balance);
    remainingAmount.value
        .updateBalance(totalOutput - totalAmounts - txFee.fee.fee.balance);

    remainingAmount.notify();
  }

  @override
  void onSelectedUtxosChanged(List<CardanoAccountUtxo> utxos) {
    _utxos = utxos;
    final assets = _utxos.fold<MultiAsset>(MultiAsset.empty, (p, c) => p + c.multiAsset);

    for (final i in recipients.value) {
      i.onRemoveAssets();
    }
    remainingAmount.value.onUpdateAssets(assets);
    _lockedMax = null;
    _onReceiptsUpdated();
    onStateUpdated();
    estimateFee();
  }

  void onUpdateRecipients(List<ReceiptAddress<ADAAddress>> addressess) {
    _lockedMax = null;
    final recipients = addressess
        .map((e) => ADATransferDetails(
            recipient: e, token: network.token, protocolParams: latestEpochParams))
        .toList();
    this.recipients.addValues(recipients);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateRecipientAmount(ADATransferDetails recipient, BigInt amount, bool max) {
    _lockedMax = max ? recipient : null;
    recipient.onUpdateBalance(amount);
    _onReceiptsUpdated();
    onStateUpdated();
    estimateFee();
  }

  void onRemoveRecipients(ADATransferDetails recipient) {
    _lockedMax = null;
    final assets = recipient.transfers;
    for (final i in assets) {
      remainingAmount.value.onRemoveTransferAsset(i);
    }
    recipients.removeValue(recipient);
    recipient.dispose();
    _onReceiptsUpdated();
    onStateUpdated();
    estimateFee();
  }

  String? onRemainingAccountFilter(ICardanoAddress address) {
    if (address.isRewardAddress) {
      return "cannot_send_ada_to_stake_address".tr;
    }
    return null;
  }

  void onUpdateRemainingAccount(ICardanoAddress? address) {
    if (address == null || address.isRewardAddress) return;
    final recipient = account.getOrCreateReceiptFromNetworkAddressSync(account: address);
    remainingAmount.value.updateRecipientAddress(recipient);
    remainingAmount.notify();
  }

  void onUpdateTransferAsset(
      ADATransferDetails transfer, ADATransferAssetDetails? asset) {
    if (asset == null) return;
    remainingAmount.value.onUpdateTransferAsset(transfer, asset);
    remainingAmount.notify();
    onStateUpdated();
    estimateFee();
  }

  void onRemoveTransferAsset(
      ADATransferDetails recipient, ADATransferAssetDetails asset) {
    remainingAmount.value.onRemoveTransferAsset(asset);
    recipient.onRemoveAssetTransfer(asset);
    remainingAmount.notify();
    onStateUpdated();
    estimateFee();
  }

  void onUpdateTrasferAssetAmount(
      ADATransferDetails recipient, ADATransferAssetDetails asset, BigInt amount) {
    remainingAmount.value.onUpdateTransferAssetAmount(recipient, asset, amount);
    remainingAmount.notify();
    onStateUpdated();
    estimateFee();
  }

  @override
  void onUpdateCertificate(ADATransactionCertificate? newCertificate) {
    if (newCertificate == null) return;
    super.onUpdateCertificate(newCertificate);
    _onReceiptsUpdated();
    onStateUpdated();
    estimateFee();
  }

  @override
  void onRemoveCertificate(ADATransactionCertificate certificate) {
    super.onRemoveCertificate(certificate);
    _onReceiptsUpdated();
    onStateUpdated();
    estimateFee();
  }

  @override
  bool onUpdateMemo(ADATransactionMemo? memo) {
    if (super.onUpdateMemo(memo)) {
      onStateUpdated();
      estimateFee();
      return true;
    }
    return false;
  }

  @override
  void onRemoveMemo(ADATransactionMemo memo) {
    super.onRemoveMemo(memo);
    onStateUpdated();
    estimateFee();
  }

  @override
  Future<void> estimateFee() async {
    if (_utxos.isEmpty || !fieldsReady) {
      return;
    }
    final amount = remainingAmount.value.amount.balance + txFee.fee.fee.balance;
    if (amount.isNegative) {
      return;
    }
    return super.estimateFee();
  }

  String? _validateRecipients(List<ADATransferDetails> recipients) {
    if (recipients.isEmpty) {
      return "at_least_one_recipient_required".tr;
    }
    for (final i in recipients) {
      if (!i.hasAmount) return "some_amount_fields_not_filled".tr;
    }
    return null;
  }

  String? filterAccount(ADAAddress address) {
    if (address.isRewardAddress) return "cannot_send_ada_to_stake_address".tr;
    if (recipients.value.any((e) => e.recipient.networkAddress == address)) {
      return "address_already_exist".tr;
    }
    return null;
  }

  BigInt getMaxInput(ADATransferDetails recipient) {
    final total = recipients.value.map<BigInt>((c) => c.amount.balance).sum;
    final max = totalUtxos.value.balance -
        total +
        recipient.amount.balance -
        txFee.fee.fee.balance;
    if (max.isNegative) return BigInt.zero;
    return max;
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;
    if (!remainingAmount.value.status.isReady) {
      return TransactionStateStatus.error();
    }
    for (final i in recipients.value) {
      final status = i.status;
      if (!status.isReady) return TransactionStateStatus.error();
    }
    String? simulateError =
        txFee.fee.hasError ? "transaction_simulation_failed".tr : null;
    return TransactionStateStatus.insufficient(remainingAmount.value.amount,
        warning: simulateError);
  }

  @override
  void onFeeUpdated(void _) {
    if (txFee.isPending) return;
    final lockedMax = _lockedMax;
    _onReceiptsUpdated();
    if (txFee.proccessed && lockedMax != null) {
      final remain = remainingAmount.value.amount.balance;
      BigInt amount = lockedMax.amount.balance;
      if (remain.isNegative) {
        amount -= remain.abs();
      } else {
        amount += remain;
      }
      if (amount.isNegative) {
        amount = BigInt.zero;
      }
      lockedMax.onUpdateBalance(amount);
      _onReceiptsUpdated();
    }
    _lockedMax = null;
    onStateUpdated();
  }

  NativeScripts? buildNativeScripts({required List<ADAAddress> addresses}) {
    Set<NativeScript> scripts = {};
    for (final i in addresses) {
      final address = account.addresses.firstWhere(
          (e) => e.networkAddress == i || e.rewardAddress == i,
          orElse: () => throw WalletExceptionConst.signerAccountNotFound);
      bool isRewardOfBaseAddress = address.rewardAddress == i;
      if (!address.multiSigAccount) continue;
      final mAccount = address as ICardanoMultiSigAddress;
      final BaseCardanoMultiSignatureCredential? cred = switch (isRewardOfBaseAddress) {
        true => mAccount.addressInfo.stakeCredential,
        false => mAccount.addressInfo.credential
      };
      if (cred == null) {
        throw WalletExceptionConst.invalidAccountData("buildNativeScripts");
      }
      if (cred.type == CardanoCredentialType.script) {
        final script = cred as CardanoMultiSignatureScript;
        scripts.add(script.script);
      }

      ///187633
    }
    if (scripts.isEmpty) return null;
    return NativeScripts(scripts.toList());
  }

  @override
  Future<IADATransactionData> buildTransactionData({bool simulate = false}) async {
    final remain = remainingAmount.value.toOutput();
    final nativeScript = buildNativeScripts(addresses: [
      ..._utxos.map((e) => e.address.networkAddress),
      ...certificateBuilders.map((e) => e.signer).whereType<ADAAddress>()
    ]);
    return IADATransactionData(
        fee: txFee.fee,
        utxos: _utxos,
        outputs: [
          ...recipients.value.map((e) => e.toOutput()),
          if (remain != null) remain
        ],
        metadata: buildTransactionMemo(),
        certificates: certificateBuilders,
        deposits: deposit.map((e) => e.toDepositBuilder()).toList(),
        refundDeposits: refund.map((e) => e.toDepositBuilder()).toList(),
        nativeScript: nativeScript);
  }

  @override
  Future<IADATransaction> buildTransaction({bool simulate = false}) async {
    final transaction = await buildTransactionData(simulate: simulate);
    final builder = ADATransactionBuilder(
        utxos: transaction.utxos.map((e) => e.utxo).toList(),
        outputs: transaction.outputs,
        certificates: transaction.certificates,
        deposits: transaction.deposits,
        metadata: transaction.metadata,
        mints: transaction.mints,
        nativeScripts: transaction.nativeScript,
        refundDeposits: transaction.refundDeposits);
    builder.setFee(transaction.fee.fee.balance);
    return IADATransaction(
        account: address, transactionData: transaction, transaction: builder);
  }

  @override
  Future<List<IWalletTransaction<ADAWalletTransaction, ICardanoAddress>>>
      buildWalletTransaction(
          {required IADASignedTransaction signedTx,
          required SubmitTransactionSuccess txId}) async {
    List<IWalletTransaction<ADAWalletTransaction, ICardanoAddress>> transactions = [];
    final transactionData = signedTx.transaction.transactionData;
    final signers = transactionData.utxos.map((e) => e.address).toSet().toList();
    for (final i in signers) {
      final totalAmount = signedTx.transaction.transactionData.utxos
          .where((e) => e.address == i)
          .map((e) => e.utxoBalance.balance)
          .sum;
      final transaction = IWalletTransaction(
          transaction: ADAWalletTransaction(
              txId: txId.txId,
              time: DateTime.now(),
              outputs: [],
              totalOutput:
                  WalletTransactionIntegerAmount(amount: totalAmount, network: network),
              network: network),
          account: i);
      transactions.add(transaction);
    }
    return transactions;
  }

  @override
  Future<TransactionStateController> cloneController(ICardanoAddress address) async {
    return ADATransactionTransferOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return ADATransactionTransferWidget(form: this);
  }

  @override
  TransactionOperations get operation => ADATransactionOperations.transfer;

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required ADANetworkClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await super.initForm(context: context, client: client, updateAccount: updateAccount);
    remainingAmount.value.onUpdateProtocolParams(latestEpochParams);
    return this;
  }

  @override
  void dispose() {
    super.dispose();
    for (final i in recipients.value) {
      i.dispose();
    }
    remainingAmount.value.dispose();
  }

  @override
  List<LiveFormField<Object?, Object?>> get fields => [recipients, remainingAmount];
}
