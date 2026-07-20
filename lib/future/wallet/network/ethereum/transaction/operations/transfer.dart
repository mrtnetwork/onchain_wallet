import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_chain/ethereum/ethereum.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/transaction/widgets/transfer.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/ethereum.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/transaction/types/types.dart';

class EthereumTransactionTransferOperation
    extends EthereumTransactionStateController<IEthereumTransactionData> {
  EthereumTransactionTransferOperation(
      {required super.address, required super.account, required super.walletProvider});
  String? filterAccount(ETHAddress address) {
    if (address == this.address.networkAddress) {
      return "address_already_exist".tr;
    }
    return null;
  }

  @override
  BigInt getMaxInput() {
    final totalAmount = txFee.fee.fee.balance;
    final max = address.addressData.currencyBalance - totalAmount;
    if (max.isNegative) return BigInt.zero;
    return max;
  }

  @override
  void onFeeUpdated(void _) {
    if (!txFee.isPending && lockedMax) {
      amount.value.updateBalance(getMaxInput());
      amount.notify();
    }
    onStateUpdated();
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return EthereumTransactionTransferWidget(form: this);
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;
    final totalAmount = amount.value.balance + txFee.fee.fee.balance;
    final r = address.addressData.currencyBalance - totalAmount;
    return TransactionStateStatus.insufficient(IntegerBalance.token(r, network.token));
  }

  @override
  Map<String, dynamic> buildEstimateTx() {
    final estimate = ETHTransaction(
            from: address.networkAddress,
            to: receipt.value?.networkAddress ?? address.networkAddress,
            nonce: 0,
            gasLimit: BigInt.zero,
            data: memoBytes() ?? [],
            value: BigInt.zero,
            chainId: network.coinParam.chainId)
        .toEstimate();
    return estimate;
  }

  @override
  Future<IEthereumTransactionData> buildTransactionData({bool simulate = false}) async {
    final nonce = await client.getAccountNonce(address.networkAddress);
    return IEthereumTransactionData(
        recipient: receipt.output.networkAddress,
        amount: amount.output.balance,
        fee: txFee.fee,
        nonce: nonce,
        data: memoBytes());
  }

  @override
  Future<List<IWalletTransaction<EthWalletTransaction, IEthereumAddress>>>
      buildWalletTransaction(
          {required IEthereumSignedTransaction<IEthereumTransactionData> signedTx,
          required SubmitTransactionSuccess txId}) async {
    final txData = signedTx.transaction.transactionData;
    final transaction = EthWalletTransaction(
        txId: txId.txId,
        outputs: [
          EthWalletTransactionTransferOutput(
              to: txData.recipient,
              amount:
                  WalletTransactionIntegerAmount(amount: txData.amount, network: network))
        ],
        totalOutput:
            WalletTransactionIntegerAmount(amount: txData.amount, network: network),
        network: network);
    return [
      IWalletTransaction(transaction: transaction, account: address),
    ];
  }

  @override
  Future<EthereumTransactionTransferOperation> cloneController(
      IEthereumAddress address) async {
    return EthereumTransactionTransferOperation(
        address: address, account: account, walletProvider: walletProvider);
  }

  @override
  Token get transferToken => network.token;

  @override
  TransactionOperations get operation => EthereumTransactionOperations.transfer;
}
