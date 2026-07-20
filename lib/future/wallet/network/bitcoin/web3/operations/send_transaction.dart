import 'dart:async';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/controllers/fee.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/controllers/signer.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/controllers/utxos.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/web3/controllers/controllers.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/web3/pages/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/bitcoin/clients/bitcoin.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/others/models/receipt_address.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/bitcoin.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/constant/constants/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/params/models/send_transaction.dart';

class Web3BitcoinSendTransactionStateController
    extends Web3BitcoinTransactionStateController<
        String,
        BaseWeb3BitcoinSendTransaction,
        IWeb3BitcoinSendTransactionData,
        IWeb3BitcoinPaymentTransaction,
        IWeb3BitcoinSignedPaymentTransaction>
    with
        BtocinTransactionApiController,
        BitcoinTransactionFeeController,
        BitcoinTransactionUtxosController,
        BitcoinTransactionSignerController {
  @override
  bool get includeTokens => false;

  BasedUtxoNetwork get utxoNetwork => network.coinParam.transacationNetwork;
  StreamSubscription<void>? _feeListener;
  List<PsbtBitcoinOutputWithBalance> _requestOutputs = [];
  List<PsbtBitcoinOutputWithBalance> get requestOutputs => _requestOutputs;
  IBitcoinAddress? _requireAccount;
  List<BitcoinBaseOutput> _outputs = [];
  List<BitcoinUtxoInfo> _inputs = [];
  List<BitcoinUtxoInfo> get inputs => _inputs;

  Web3BitcoinSendTransactionStateController(
      {required super.walletProvider, required super.request});

  late final LiveFormField<BitcoinRemainTransferDetails, BitcoinRemainTransferDetails>
      remainingAmount = LiveFormField(
          title: "remaining_amount".tr,
          subtitle: "remaining_amount_and_receiver".tr,
          value: BitcoinRemainTransferDetails(
              recipient: account.getOrCreateReceiptFromNetworkAddressSync(
                  account: defaultAccount),
              network: network),
          optional: false);

  final LiveFormField<bool, bool> rbf = LiveFormField(
      title: "replace_by_fee".tr, subtitle: "bitcoin_rbf_error".tr, value: false);
  void onUpdateRBF(bool? rbf) {
    if (rbf == null) return;
    this.rbf.setValue(rbf);
  }

  void onUpdateRemainingAccount(IBitcoinAddress address) {
    final recipient = account.getOrCreateReceiptFromNetworkAddressSync(account: address);
    remainingAmount.value.onUpdateRecipient(recipient);
  }

  @override
  BigInt getMaxFeeInput() {
    return remainingAmount.value.amount.balance + txFee.fee.fee.balance;
  }

  void _buildOutputs() {
    final remain = remainingAmount.value.toOutput()?.output;
    _outputs = List<BitcoinBaseOutput>.unmodifiable([
      ..._requestOutputs.map((e) => e.toOutput()),
      if (remain != null) remain,
    ]);
  }

  void _onReceiptsUpdated() {
    final totalOutput = totalUtxos.value.balance;
    final totalAmounts = _requestOutputs.fold(
        BigInt.zero, (previousValue, element) => previousValue + element.balance.balance);
    remainingAmount.value
        .updateBalance(totalOutput - totalAmounts - txFee.fee.fee.balance);
    remainingAmount.notify();
    _buildOutputs();
  }

  void onFeeUpdated(void _) {
    if (txFee.isPending) return;
    _onReceiptsUpdated();
    onStateUpdated();
  }

  @override
  void onSelectedUtxosChanged(List<BitcoinUtxoInfo> utxos) {
    _inputs = utxos.toImutableList;
    _onReceiptsUpdated();
    onStateUpdated();
    estimateFee();
  }

  @override
  TransactionStateStatus getStateStatus() {
    if (totalUtxos.value.isZero) {
      return TransactionStateStatus.error();
    }
    if (txFee.isPending) {
      return TransactionStateStatus.error();
    }
    if (!txFee.hasFee) {
      return TransactionStateStatus.error(error: "fee_zero_validator_desc".tr);
    }
    final requireAccount = _requireAccount;
    if (requireAccount != null &&
        !_inputs.any((e) => e.address.viewAddress == requireAccount.viewAddress)) {
      return TransactionStateStatus.error(
          error: 'bitcoin_account_must_spend'.tr.replaceOne(requireAccount.viewAddress));
    }
    String? simulateError =
        txFee.fee.hasError ? "transaction_simulation_failed".tr : null;
    if (remainingAmount.value.amount.isNegative) {
      return TransactionStateStatus.insufficient(remainingAmount.value.amount);
    }
    return TransactionStateStatus.ready(warning: simulateError);
  }

  ReceiptAddress<BitcoinNetworkAddress>? _getReceiptAddress(
      BitcoinNetworkAddress? address) {
    if (address == null) return null;
    return account.getOrCreateReceiptFromNetworkAddressSync(address: address);
  }

  PsbtBitcoinOutputWithBalance _buildOutput(Web3BitcoinSendTransactionOutput output) {
    BitcoinNetworkAddress? address;
    if (output.address != null) {
      address = BitcoinNetworkAddress.parse(
          address: output.address!, network: network.coinParam.transacationNetwork);
    } else {
      address = account.findAddressFromScriptSync(output.scriptPubKey);
      if (address == null) {
        final addr =
            BitcoinScriptUtils.tryGenerateAddressFromScriptPubKey(output.scriptPubKey);
        if (addr != null) {
          address = BitcoinNetworkAddress.fromBaseAddress(
              address: addr, network: network.coinParam.transacationNetwork);
        }
      }
    }
    final receipt = _getReceiptAddress(address);
    return PsbtBitcoinOutputWithBalance(
      scriptPubKey: output.scriptPubKey,
      balance: output.value,
      network: network,
      address: receipt,
    );
  }

  @override
  Future<IWeb3BitcoinSendTransactionData> buildTransactionData(
      {bool simulate = false}) async {
    return IWeb3BitcoinSendTransactionData(
      fee: txFee.fee,
      ordering: BitcoinOrdering.none,
      enableRBF: rbf.output,
      requestOutputs: _requestOutputs,
      requireAccount: _requireAccount,
      utxos: _inputs.map((e) => e.toUtxoWithAdress()).toList(),
      outputs: _outputs,
    );
  }

  @override
  Future<List<IWalletTransaction<BitcoinWalletTransaction, IBitcoinAddress>>>
      buildWalletTransaction(
          {required IWeb3BitcoinSignedPaymentTransaction signedTx,
          required SubmitTransactionSuccess? txId}) async {
    if (txId == null) return [];
    List<IWalletTransaction<BitcoinWalletTransaction, IBitcoinAddress>> transactions = [];
    final accounts = signedTx.transaction.accounts.toSet();
    for (final i in accounts) {
      final totalInputs =
          inputs.where((e) => e.address == i).map((e) => e.utxo.utxo.value).toList().sum;
      if (totalInputs == BigInt.zero) continue;
      final tx = BitcoinWalletTransaction(
          txId: txId.txId,
          totalOutput:
              WalletTransactionIntegerAmount(amount: totalInputs, network: network),
          scriptHash: i.networkAddress.pubKeyHash(),
          web3Client: web3ClientInfo(),
          type: WalletTransactionType.web3,
          network: network);
      transactions.add(IWalletTransaction(transaction: tx, account: i));
    }
    return transactions;
  }

  @override
  Future<IWeb3BitcoinPaymentTransaction> buildTransaction({bool simulate = false}) async {
    final transactionData = await buildTransactionData(simulate: simulate);
    final transaction = switch (network.coinParam.isForked) {
      true => ForkedTransactionBuilder(
          utxos: transactionData.utxos,
          enableRBF: transactionData.enableRBF,
          outPuts: transactionData.outputs,
          network: network.coinParam.transacationNetwork,
          fee: transactionData.fee.fee.balance,
          inputOrdering: transactionData.ordering,
          outputOrdering: transactionData.ordering,
          isFakeTransaction: simulate),
      false => BitcoinTransactionBuilder(
          utxos: transactionData.utxos,
          enableRBF: transactionData.enableRBF,
          outPuts: transactionData.outputs,
          network: network.coinParam.transacationNetwork,
          fee: transactionData.fee.fee.balance,
          inputOrdering: transactionData.ordering,
          outputOrdering: transactionData.ordering,
          isFakeTransaction: simulate)
    };
    final List<IBitcoinAddress> signers = [];
    for (final i in transactionData.utxos) {
      final IBitcoinAddress utxosAcount = accounts.firstWhere(
          (element) =>
              element.networkAddress.baseAddress.addressProgram ==
              i.ownerDetails.address.addressProgram,
          orElse: () => throw Web3RequestExceptionConst.missingPermission);
      signers.add(utxosAcount);
    }
    return IWeb3BitcoinPaymentTransaction(
        account: defaultAccount,
        transactionData: transactionData,
        accounts: signers,
        transnaction: transaction);
  }

  @override
  Future<IWeb3BitcoinSignedPaymentTransaction> signTransaction(
      IWeb3BitcoinPaymentTransaction transaction,
      {bool fakeSignature = false}) async {
    final List<IBitcoinAddress> signers = transaction.accounts;
    final signedTx = await signTransactionInternal(
        transaction: transaction.transnaction,
        signers: signers,
        fakeSignature: fakeSignature);
    return IWeb3BitcoinSignedPaymentTransaction(
        transaction: transaction,
        signatures: signedTx.signatures,
        finalTransactionData: signedTx.transaction);
  }

  @override
  Future<
          Web3RequestTransactionResponseData<String,
              SubmitTransactionSuccess<IWeb3BitcoinSignedPaymentTransaction>>>
      getResponse() async {
    final transaction = await buildSignAndSendTransaction();
    return Web3RequestTransactionResponseData.submitTx(
        response: transaction.txId, txIds: [transaction]);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3BitcoinSendTransactionStateView(form: this);
  }

  @override
  Future<BtcTransaction> buildSimulateTransaction() async {
    final transaction = await buildTransaction(simulate: true);
    final signedTx = await signTransaction(transaction, fakeSignature: true);
    return signedTx.finalTransactionData;
  }

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required IWeb3BitcoinSignedPaymentTransaction signedTransaction}) async {
    final transaction = signedTransaction.finalTransactionData;
    final txId = await client.sendTransaction(transaction);
    return SubmitTransactionSuccess(txId: txId, signedTransaction: signedTransaction);
  }

  @override
  Future<void> initForm(BitcoinNetworkClient<IBitcoinAddress> client) async {
    await super.initForm(client);
    if (accounts.isEmpty) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    if (accounts.map((e) => e.network).toSet().length != 1) {
      throw Web3BitcoinExceptionConstant.invalidRequestAccounts;
    }
    if (params.requiredAccount != null) {
      final requiredAccount = params.requiredAccount?.addressStr;
      _requireAccount =
          accounts.firstWhereOrNull((e) => e.viewAddress == requiredAccount);
      if (_requireAccount == null) {
        throw Web3RequestExceptionConst.missingPermission;
      }
    }
    final rOutputs = request.params.outputs;
    if (rOutputs.isEmpty) {
      throw Web3BitcoinExceptionConstant.emptyOutput;
    }
    _requestOutputs = rOutputs.map(_buildOutput).toImutableList;
    await initAccountUtxos(addresses: accounts);
    _feeListener = txFee.stream.listen(onFeeUpdated);
  }

  @override
  void dispose() {
    super.dispose();
    _feeListener?.cancel();
    _feeListener = null;
    remainingAmount.value.dispose();
    remainingAmount.dispose();
    rbf.dispose();
  }
}
