import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_chain/aptos/src/address/address/address.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/transaction/widgets/transfer_token.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/models/networks/aptos/models/types.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class AptosTransactionTransferTokenOperation
    extends AptosTransactionStateController<IAptosTransactionDataTokenTransfer> {
  AptosTransactionTransferTokenOperation(
      {required super.walletProvider,
      required super.account,
      required super.address,
      required this.token});
  StreamSubscription? _tokenBalanceListener;
  final AptosFATokens token;
  @override
  Token get transferToken => token.token;

  BigInt getMaxInput(AptosTransferDetails recipient) {
    final total =
        recipients.value.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.balance);
    final max = token.balance.balance - total + recipient.amount.balance;
    if (max.isNegative) return BigInt.zero;
    return max;
  }

  @override
  void onUpdateRecipients(List<ReceiptAddress<AptosAddress>> addressess) {
    if (recipients.hasValue) return;
    super.onUpdateRecipients(addressess);
  }

  void onUpdateAmount(AptosTransferDetails recipient, BigInt amount, bool max) {
    recipient.updateBalance(amount);
    onStateUpdated();
    estimateFee();
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;
    String? simulateError =
        txFee.fee.hasError ? "transaction_simulation_failed".tr : null;
    BigInt total = address.addressData.currencyBalance - txFee.fee.requiredFee;
    if (total.isNegative) {
      return TransactionStateStatus.insufficient(
          IntegerBalance.token(total, network.token),
          warning: simulateError);
    }
    total = recipients.value.map((c) => c.amount.balance).sum;
    final r = token.balance.balance - total;
    return TransactionStateStatus.insufficient(IntegerBalance.token(r, transferToken),
        warning: simulateError);
  }

  @override
  Future<IAptosTransactionDataTokenTransfer> buildTransactionData(
      {bool simulate = false}) async {
    final receipt = recipients.value.first;
    return IAptosTransactionDataTokenTransfer(
        recipient: ITransactionDataTransferTokenRecipient(
            recipient: receipt.recipient.networkAddress,
            amount: receipt.amount.balance,
            token: token),
        fee: txFee.fee);
  }

  @override
  Future<List<IWalletTransaction<AptosWalletTransaction, IAptosAddress>>>
      buildWalletTransaction(
          {required IAptosSignedTransaction<IAptosTransactionDataTokenTransfer> signedTx,
          required SubmitTransactionSuccess txId}) async {
    final transactionData = signedTx.transaction.transactionData;
    final outputs = AptosWalletTransactionTransferOutput(
        to: transactionData.recipient.recipient,
        amount: WalletTransactionIntegerAmount(
            amount: transactionData.recipient.amount,
            network: network,
            token: transactionData.recipient.token.token,
            tokenIdentifier: transactionData.recipient.token.identifier));
    final transaction = AptosWalletTransaction(
        txId: txId.txId,
        outputs: [outputs],
        totalOutput: WalletTransactionIntegerAmount(
            amount: transactionData.recipient.amount,
            network: network,
            token: transactionData.recipient.token.token,
            tokenIdentifier: transactionData.recipient.token.identifier),
        network: network);
    return [IWalletTransaction(transaction: transaction, account: address)];
  }

  @override
  Future<TransactionStateController> cloneController(IAptosAddress address) async {
    final tokens = (await address.getAccountTokens()).unwrap();
    final addressToken = tokens.firstWhere((e) => e.assetType == token.assetType,
        orElse: () => token.clone(balance: BigInt.zero));
    return AptosTransactionTransferTokenOperation(
        walletProvider: walletProvider,
        account: account,
        address: address,
        token: addressToken);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return AptosTransactionTransferTokenWidget(form: this);
  }

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required AptosNetworkClient client,
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
  TransactionOperations get operation => AptosTransactionOperations.tokenTransfer;

  @override
  void dispose() {
    super.dispose();
    _tokenBalanceListener?.cancel();
    _tokenBalanceListener = null;
    token.streamBalance.dispose();
  }
}
