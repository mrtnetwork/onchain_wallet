import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/signing.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/web3/controllers/controllers.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/web3/pages/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/wallet/api/client/client.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/utxos.dart';
import 'package:on_chain_wallet/wallet/models/signing/signing.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/zcash.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/zcash.dart';
import 'package:zcash_dart/zcash.dart';

class WebZcashSignTransactionStateController extends Web3ZcashTransactionStateController<
    Web3ZcashTransactionResponse, Web3ZcashSendTransaction> {
  IZcashTransactionData? _fixedTransactionData;
  IZcashTransactionData get fixedTransactionData => _fixedTransactionData!;
  List<ZcashUtxoWithBalanceInfo> _inputs = [];
  WebZcashSignTransactionStateController(
      {required super.walletProvider, required super.request});
  StreamSubscription<void>? _feeListener;
  late final LiveFormField<ZcashRemainTransferDetails, ZcashRemainTransferDetails>
      remainingAmount = LiveFormField(
          title: "remaining_amount".tr,
          subtitle: "remaining_amount_and_receiver".tr,
          value: ZcashRemainTransferDetails(
              protocols: ZcashProtocol.values,
              recipient: account.getOrCreateReceiptFromNetworkAddressSync(
                  account: defaultAccount),
              network: network,
              addressProtocol: defaultAccount.networkAddress.supportedProtocols.first),
          optional: false);

  @override
  Future<ZcashTransactionFeeInfo> buildFeeData() async {
    final txData = await buildTransactionData();
    return ZcashTransactionFeeInfo(inputs: txData.utxos, outputs: txData.toOutputs());
  }

  @override
  BigInt getMaxFeeInput() {
    return totalUtxos.value.balance;
  }

  @override
  Future<IZcashTransaction> buildTransaction({bool simulate = false}) async {
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
        account: defaultAccount,
        transactionData: data,
        accounts: data.utxos.map((e) => e.account).toSet().toList(),
        outputs: outputs,
        inputs: utxos);
  }

  Future<IZcashTransactionData> _buildFixedTransactionData() async {
    return IZcashTransactionData(
      fee: txFee.fee,
      utxos: [],
      transparentMemos: params.transparentMemos
          .map((e) => ZcashTransactionTransparentMemo.fromScript(e))
          .toList(),
      recipients: params.destintions
          .map((e) => switch (e.protocol) {
                ZcashProtocol.orchard ||
                ZcashProtocol.sapling =>
                  ZcashTransactionShieldOutput(
                      address: getOrCreateAddressInfo(e.destination),
                      protocol: e.protocol,
                      amount: IntegerBalance.token(e.amount, network.token,
                          allowNegative: false, immutable: true),
                      memo: switch (e.memo) {
                        null => null,
                        String memo => ZcashTransactionMemoShielded(content: memo)
                      }),
                ZcashProtocol.transparent => ZcashTransactionTransparentOutput(
                    address: getOrCreateAddressInfo(e.destination),
                    amount: IntegerBalance.token(e.amount, network.token,
                        allowNegative: false, immutable: true)),
              })
          .toList(),
    );
  }

  @override
  Future<IZcashTransactionData> buildTransactionData({bool simulate = false}) async {
    final fixedRecipients = fixedTransactionData.recipients;
    final memos = fixedTransactionData.transparentMemos;
    final remainingOutput = remainingAmount.value.toOutput();
    return IZcashTransactionData(
        fee: txFee.fee,
        utxos: _inputs,
        transparentMemos: memos,
        recipients: [...fixedRecipients, if (remainingOutput != null) remainingOutput]);
  }

  @override
  Future<List<IWalletTransaction<ZcashWalletTransaction, IZcashAddress>>>
      buildWalletTransaction(
          {required IZcashSignedTransaction signedTx,
          required SubmitTransactionSuccess<IZcashSignedTransaction>? txId}) async {
    if (txId == null) return [];
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
          web3Client: web3ClientInfo(),
          type: WalletTransactionType.web3,
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
  Future<
      Web3RequestTransactionResponseData<Web3ZcashTransactionResponse,
          SubmitTransactionSuccess<IZcashSignedTransaction>>> getResponse() async {
    final result = await buildSignAndSendTransaction();
    return Web3RequestTransactionResponseData.submitTx(
        response: Web3ZcashTransactionResponse(result.txId), txIds: [result]);
  }

  String? filterRemainAccount(IZcashAddress address) {
    // if (address.networkAddress == remainingAmount.value.recipient.networkAddress ||
    //     transactionData.destinations
    //         .any((e) => e.recipient.networkAddress == address.networkAddress)) {
    //   return "address_already_exist".tr;
    // }
    return null;
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

  void _onReceiptsUpdated() {
    final totalOutput = totalUtxos.value.balance;
    final totalAmounts = fixedTransactionData.recipients.fold(
        BigInt.zero, (previousValue, element) => previousValue + element.amount.balance);
    remainingAmount.value
        .updateBalance(totalOutput - totalAmounts - txFee.fee.fee.balance);
  }

  @override
  Future<void> estimateFee() async {
    if (_inputs.isEmpty) return;
    return super.estimateFee();
  }

  @override
  TransactionStateStatus getStateStatus() {
    if (_inputs.isEmpty) return TransactionStateStatus.error();
    if (!txFee.fee.isManual && txFee.isPending) {
      return TransactionStateStatus.error();
    }
    if (!txFee.hasFee) {
      return TransactionStateStatus.error(error: "fee_zero_validator_desc".tr);
    }
    String? simulateError =
        txFee.fee.hasError ? "transaction_simulation_failed".tr : null;
    return TransactionStateStatus.insufficient(remainingAmount.value.amount,
        warning: simulateError);
  }

  @override
  void onSelectedUtxosChanged(List<ZcashUtxoWithBalanceInfo> utxos) {
    _inputs = utxos;
    _onReceiptsUpdated();
    onStateUpdated();
    estimateFee();
  }

  @override
  Future<IZcashSignedTransaction> signTransaction(IZcashTransaction transaction,
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
  Widget widgetBuilder(BuildContext context) {
    return Web3ZcashSignTransactionStateView(this);
  }

  void onFeeUpdated(void _) {
    if (txFee.isPending) return;
    _onReceiptsUpdated();
    onStateUpdated();
  }

  @override
  Future<void> initForm(ZcashNetworkClient client) async {
    await super.initForm(client);
    _fixedTransactionData = await _buildFixedTransactionData();
    final syncing = await account.getSyncing();
    await syncing.foldAsync(
      onErr: (error) => throw error.exception,
      onOk: (value) async {
        final height = await client.getLatestBlockHeight();
        await initAccountUtxos(
            addresses: request.accounts,
            syncing: value,
            client: client,
            latestHeight: height,
            privacy: switch (request.params.privacy) {
              Web3ZcashTransferPrivacy.shieldedOnly =>
                ZcashTransactionSpenderPrivacy.shieldOnly,
              Web3ZcashTransferPrivacy.auto => ZcashTransactionSpenderPrivacy.auto,
            });
        _feeListener = txFee.stream.listen(onFeeUpdated);
        return this;
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _feeListener?.cancel();
    _feeListener = null;
    remainingAmount.value.dispose();
    remainingAmount.dispose();
  }
}

/// mineraddress=t1YourTransparentAddress
