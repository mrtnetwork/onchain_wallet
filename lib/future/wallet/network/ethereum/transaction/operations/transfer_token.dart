import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_chain/ethereum/src/transaction/eth_transaction.dart';
import 'package:on_chain_wallet/crypto/networks/solidity/solidity.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/transaction/widgets/transfer_token.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/ethereum/client/ethereum.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/erc20.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/ethereum.dart';

class EthereumTransactionTransferTokenOperation
    extends EthereumTransactionStateController<IEthereumTransactionTokenTransferData> {
  EthereumTransactionTransferTokenOperation(
      {required super.address,
      required super.account,
      required super.walletProvider,
      required this.token});
  final ETHERC20Token token;
  StreamSubscription? _tokenBalanceListener;

  @override
  BigInt getMaxInput() {
    return token.balance.balance;
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;
    BigInt totalAmount = txFee.fee.fee.balance;
    BigInt r = address.addressData.currencyBalance - totalAmount;
    if (r.isNegative) {
      return TransactionStateStatus.insufficient(IntegerBalance.token(r, network.token));
    }
    totalAmount = amount.value.balance;
    r = token.balance.balance - totalAmount;
    return TransactionStateStatus.insufficient(IntegerBalance.token(r, token.token));
  }

  @override
  Future<IEthereumTransactionTokenTransferData> buildTransactionData(
      {bool simulate = false}) async {
    final nonce = await client.getAccountNonce(address.networkAddress);
    return IEthereumTransactionTokenTransferData(
        recipient: token.contractAddress,
        amount: BigInt.zero,
        fee: txFee.fee,
        nonce: nonce,
        data: _encodeTxData(),
        token: token,
        tokenAmount: amount.output.balance);
  }

  List<int> _encodeTxData() {
    List<int> transactionData = [];
    if (receipt.hasValue && amount.hasValue) {
      transactionData = SolidityContractUtils.erc20Transfer
          .encode([receipt.value!.networkAddress, amount.value.balance]);
    }
    if (memo.hasValue) {
      transactionData = List<int>.from([...transactionData, ...memoBytes() ?? <int>[]]);
    }
    return transactionData;
  }

  @override
  Map<String, dynamic>? buildEstimateTx() {
    if (!receipt.hasValue || !amount.hasValue) return null;
    final fee = txFee.fee;
    final estimate = ETHTransaction(
            type: fee.ethereumFeeMode.isEIP1559
                ? ETHTransactionType.eip1559
                : ETHTransactionType.legacy,
            from: address.networkAddress,
            to: token.contractAddress,
            nonce: 0,
            gasLimit: BigInt.zero,
            data: _encodeTxData(),
            value: BigInt.zero,
            chainId: network.coinParam.chainId)
        .toEstimate();
    return estimate;
  }

  @override
  Future<List<IWalletTransaction<EthWalletTransaction, IEthereumAddress>>>
      buildWalletTransaction(
          {required IEthereumSignedTransaction<IEthereumTransactionTokenTransferData>
              signedTx,
          required SubmitTransactionSuccess txId}) async {
    final txData = signedTx.transaction.transactionData;
    final transaction = EthWalletTransaction(
        txId: txId.txId,
        outputs: [
          EthWalletTransactionTransferOutput(
              to: txData.recipient,
              amount: WalletTransactionIntegerAmount(
                  amount: txData.tokenAmount,
                  network: network,
                  token: txData.token.token,
                  tokenIdentifier: txData.token.identifier))
        ],
        network: network);
    return [IWalletTransaction(transaction: transaction, account: address)];
  }

  @override
  Future<EthereumTransactionTransferTokenOperation> cloneController(
      IEthereumAddress address) async {
    final tokens = (await address.getAccountTokens()).unwrap();
    final addressToken = tokens.firstWhere(
        (e) => e.contractAddress == token.contractAddress,
        orElse: () => token.clone(balance: BigInt.zero));
    return EthereumTransactionTransferTokenOperation(
        address: address,
        account: account,
        walletProvider: walletProvider,
        token: addressToken);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return EthereumTransactionTransferTokenWidget(form: this);
  }

  @override
  Token get transferToken => token.token;

  @override
  TransactionOperations get operation => EthereumTransactionOperations.tokenTransfer;

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required EthereumNetworkClient client,
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
  void dispose() {
    super.dispose();
    _tokenBalanceListener?.cancel();
    _tokenBalanceListener = null;
    token.streamBalance.dispose();
  }
}
