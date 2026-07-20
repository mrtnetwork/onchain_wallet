import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:zcash_dart/zcash.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/messages.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/transaction/widgets/transfer.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/utxos.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class ZcashTransactionTransferOperation extends ZcashTransactionStateController {
  ZcashTransactionTransferOperation(
      {required super.walletProvider, required super.account, required super.address});
  ZcashTransferDetails? _lockedMax;
  List<IZcashTransactionOutput> _outputs = [];
  List<ZcashUtxoWithBalanceInfo> _inputs = [];
  List<ZcashUtxoWithBalanceInfo> get inputs => _inputs;
  String? _validateRecipients(List<ZcashTransferDetails> recipients) {
    if (recipients.isEmpty) {
      return "at_least_one_recipient_required".tr;
    }
    for (final i in recipients) {
      if (!i.hasAmount) return "some_amount_fields_not_filled".tr;
    }
    return null;
  }

  late final LiveFormField<ZcashRemainTransferDetails, ZcashRemainTransferDetails>
      remainingAmount = LiveFormField(
          title: "remaining_amount".tr,
          subtitle: "remaining_amount_and_receiver".tr,
          value: ZcashRemainTransferDetails(
              protocols: ZcashProtocol.values,
              recipient:
                  account.getOrCreateReceiptFromNetworkAddressSync(account: address),
              network: network,
              addressProtocol: address.networkAddress.supportedProtocols.first),
          optional: false);

  late final LiveFormFields<ZcashTransferDetails> recipients =
      LiveFormFields<ZcashTransferDetails>(
    optional: false,
    title: "list_of_recipients".tr,
    subtitle: "amount_for_each_output".tr,
    onValidateError: (field, value) => _validateRecipients(value),
  );

  BigInt getMaxInput([ZcashTransferDetails? transfer]) {
    final remain =
        remainingAmount.value.amount.balance + (transfer?.amount.balance ?? BigInt.zero);
    if (remain.isNegative) return BigInt.zero;
    return remain;
  }

  BigInt getMinInput() {
    return BigInt.zero;
  }

  @override
  BigInt getMaxFeeInput() {
    return totalUtxos.value.balance;
  }

  @override
  Future<void> estimateFee() async {
    if (!fieldsReady || !recipients.value.every((e) => e.status.isReady)) {
      return;
    }
    await super.estimateFee();
  }

  String? filterAccount(ZcashAddress address) {
    return null;
  }

  void _buildOutputs() {
    final r = remainingAmount.value.toOutput();
    _outputs = [
      ...recipients.value.map<IZcashTransactionOutput>((e) => e.toOutput()),
      if (r != null) r,
      ...memos.value.map((e) => e)
    ];
  }

  void _onReceiptsUpdated() {
    final totalOutput = totalUtxos.value.balance;
    final totalAmounts = recipients.value.fold(
        BigInt.zero, (previousValue, element) => previousValue + element.amount.balance);
    remainingAmount.value
        .updateBalance(totalOutput - totalAmounts - txFee.fee.fee.balance);
    _buildOutputs();
  }

  @override
  void onSelectedUtxosChanged(List<ZcashUtxoWithBalanceInfo> utxos) {
    _lockedMax = null;
    _inputs = utxos.toImutableList;
    _onReceiptsUpdated();
    onStateUpdated();
    estimateFee();
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
      lockedMax.updateBalance(amount);
      _onReceiptsUpdated();
      _lockedMax = null;
    }

    onStateUpdated();
  }

  @override
  bool onUpdateMemo(String? memo) {
    if (super.onUpdateMemo(memo)) {
      _buildOutputs();
      onStateUpdated();
      estimateFee();
      return true;
    }
    return false;
  }

  @override
  void onRemoveMemo(ZcashTransactionTransparentMemo memo) {
    super.onRemoveMemo(memo);
    _buildOutputs();
    onStateUpdated();
    estimateFee();
  }

  void onUpdateRecipients(
      List<ReceiptAddress<ZcashAddress>> addressess, StringVoid onErr) {
    List<ZcashProtocol> supportedProtocols = account.supportedProtocols();
    _lockedMax = null;
    List<ZcashTransferDetails> recipients = [];
    for (final e in addressess) {
      final recipient = ZcashTransferDetails.build(
          recipient: e, token: network.token, supportedProtocols: supportedProtocols);
      if (recipient == null) {
        onErr("unsupported_address_type");
        return;
      }
      recipients.add(recipient);
    }
    this.recipients.addValues(recipients);
    _buildOutputs();
    onStateUpdated();
    estimateFee();
  }

  void onUpdateRecipientAmount(ZcashTransferDetails recipient, BigInt amount, bool max) {
    _lockedMax = max ? recipient : null;
    recipient.updateBalance(amount);
    _onReceiptsUpdated();
    onStateUpdated();
    estimateFee();
  }

  void onUpdateRecipientProtocol(
      ZcashTransferDetails recipient, ZcashProtocol? protocol) {
    if (protocol == null) return;
    recipient.onChangeAddressProtocol(protocol);
    _onReceiptsUpdated();
    onStateUpdated();
    estimateFee();
  }

  void onRemoveRecipients(ZcashTransferDetails recipient) {
    _lockedMax = null;
    recipients.removeValue(recipient);
    recipient.dispose();
    _onReceiptsUpdated();
    onStateUpdated();
    estimateFee();
  }

  void onUpdateRemainingAccount(IZcashAddress address) {
    final recipient = account.getOrCreateReceiptFromNetworkAddressSync(account: address);
    remainingAmount.value.onUpdateRecipient(recipient);
    _onReceiptsUpdated();
    onStateUpdated();
    estimateFee();
  }

  void onUpdateRemainingPorocol(ZcashProtocol? protocol) {
    if (protocol == null) return;
    remainingAmount.value.onChangeAddressProtocol(protocol);
    _onReceiptsUpdated();
    onStateUpdated();
    estimateFee();
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;
    if (!fieldsReady) {
      return TransactionStateStatus.error();
    }
    for (final i in recipients.value) {
      final status = i.status;
      if (!status.isReady) return status;
    }
    final totalReceipts = recipients.value.length;
    final duplicate =
        recipients.value.map((e) => e.inProtocolAddress).toSet().length != totalReceipts;
    String? warning;
    if (txFee.fee.hasError) {
      warning = "transaction_simulation_failed".tr;
    }
    if (duplicate) {
      warning ??= "duplicate_recipients_detected".tr;
    }
    return TransactionStateStatus.insufficient(remainingAmount.value.amount,
        warning: warning);
  }

  @override
  Future<IZcashTransactionData> buildTransactionData({bool simulate = false}) async {
    final transfableOutputs =
        _outputs.whereType<IZcashTransfableTransactionOutput>().toList();
    final memos = _outputs.whereType<ZcashTransactionTransparentMemo>().toList();
    assert(
        transfableOutputs.length + memos.length == _outputs.length, "Unexpected types.");
    return IZcashTransactionData(
        fee: txFee.fee,
        transparentMemos: memos,
        recipients: transfableOutputs,
        utxos: _inputs);
  }

  @override
  Future<ZcashTransactionFeeInfo> buildFeeData() async {
    final txData = await buildTransactionData();
    return ZcashTransactionFeeInfo(inputs: txData.utxos, outputs: txData.toOutputs());
  }

  @override
  Future<IZcashTransaction<IZcashTransactionData>> buildTransaction(
      {bool simulate = false}) async {
    final data = await buildTransactionData(simulate: simulate);
    final outputs = data.toOutputs().map((e) => e.toOutput()).toList();
    final accounts = data.utxos.map((e) => e.address).toSet().toList();
    List<ZcashUtxosWithAccountInfo> utxos = [];
    for (final i in accounts) {
      final accountUtxos =
          data.utxos.where((e) => e.address == i).map((e) => e.utxo).toList();
      if (accountUtxos.isEmpty) continue;
      utxos.add(ZcashUtxosWithAccountInfo(account: i, utxos: accountUtxos));
    }
    return IZcashTransaction(
        account: address,
        transactionData: data,
        accounts: data.utxos.map((e) => e.account).toSet().toList(),
        outputs: outputs,
        inputs: utxos);
  }

  @override
  Future<List<IWalletTransaction<ZcashWalletTransaction, IZcashAddress>>>
      buildWalletTransaction(
          {required IZcashSignedTransaction<IZcashTransactionData> signedTx,
          required SubmitTransactionSuccess<
                  IZcashSignedTransaction<IZcashTransactionData>>
              txId}) async {
    List<IWalletTransaction<ZcashWalletTransaction, IZcashAddress>> transactions = [];
    final accounts = signedTx.transaction.accounts.toSet();
    final outputs = signedTx.transaction.outputs
        .map((e) {
          final address = e.address;
          if (address == null) return null;
          return ZcashWalletTransactionOutput(
              amount: WalletTransactionIntegerAmount(amount: e.amount, network: network),
              to: address,
              memo: switch (e.memo?.content) {
                null => null,
                String memo => WalletTransactionMemo.fromString(memo),
              });
        })
        .whereType<ZcashWalletTransactionOutput>()
        .toList();
    final transparentMemos = signedTx.transaction.outputs
        .where((e) => e.address == null)
        .map((e) => e.memo)
        .whereType<List<int>>()
        .map((e) => WalletTransactionMemo(e))
        .toList();
    for (final i in accounts) {
      final totalInputs = signedTx.transaction.inputs
          .where((e) => i.account.receivers.contains(e.account))
          .expand((e) => e.utxos)
          .map((e) => e.utxo.amount)
          .sum;
      if (totalInputs == BigInt.zero) continue;
      final tx = ZcashWalletTransaction(
          txId: txId.txId,
          time: DateTime.now(),
          memos: transparentMemos,
          totalOutput:
              WalletTransactionIntegerAmount(amount: totalInputs, network: network),
          outputs: outputs,
          network: network);
      transactions.add(IWalletTransaction(transaction: tx, account: i));
    }
    return transactions;
  }

  @override
  Future<ZcashTransactionTransferOperation> cloneController(IZcashAddress address) async {
    return ZcashTransactionTransferOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Future<IZcashSignedTransaction<IZcashTransactionData>> signTransaction(
      IZcashTransaction<IZcashTransactionData> transaction,
      {bool fakeSignature = false}) async {
    final latestBlock = await client.getLatestBlockHeight();
    final treeState = await account.getTrackerMerkleColumn();
    final result = await walletProvider.wallet.signTransaction(
        params: WalletActionSign(
            request: WalletSigningRequest(
      addresses: transaction.accounts,
      network: network,
      sign: (generateSignature) async {
        final request = ZcashSingningRequest(
            chainStateColumn: treeState.unwrap(),
            provider: client.networkProvider.provider,
            targetHeight: latestBlock,
            utxos: transaction.inputs,
            outputs: transaction.outputs,
            zcashNetwork: network.coinParam.network,
            fee: transaction.transactionData.fee.fee.balance);
        final response = await generateSignature(request);
        return response;
      },
    )));
    final txData = result.unwrap();
    return IZcashSignedTransaction(
        transaction: transaction,
        signatures: [],
        finalTransactionData: txData.txData,
        txId: ZcashTxId(txData.txHash).txId);
  }

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required IZcashSignedTransaction<IZcashTransactionData> signedTransaction}) async {
    final txId = await client.submitTransaction(signedTransaction.finalTransactionData);
    return SubmitTransactionSuccess(
        txId: txId ?? signedTransaction.txId, signedTransaction: signedTransaction);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return ZcashTransactionTransferTokenWidget(
      form: this,
      mainContext: context,
    );
  }

  @override
  TransactionOperations get operation => ZcashTransactionOperations.transfer;

  @override
  List<LiveFormField<Object?, Object?>> get fields => [recipients, remainingAmount];

  @override
  void dispose() {
    for (final i in recipients.value) {
      i.dispose();
    }
    recipients.clear();
    remainingAmount.value.dispose();
    _inputs = [];
    _outputs = [];
    super.dispose();
  }
}
