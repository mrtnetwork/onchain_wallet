import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/controllers/fee.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/controllers/signer.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/web3/controllers/controllers.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/web3/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/web3/pages/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/tron/params/models/transaction.dart';

class WebTronSendTransactionStateController extends Web3TronTransactionStateController<
        Transaction, Web3TronSignTransaction, IWeb3TronTransactionRawData>
    with
        SolidityWeb3TransactionApiController,
        TronWeb3TransactionApiController,
        TronTransactionApiController,
        TronTransactionSignerController,
        TronTransactionFeeController {
  IWeb3TronTransactionRawData? _transactionRawData;
  IWeb3TronTransactionRawData get transactionData => _transactionRawData!;
  StreamSubscription<void>? _feeListener;
  WebTronSendTransactionStateController(
      {required super.walletProvider, required super.request});

  void onFeeUpdated(void _) {
    onStateUpdated();
  }

  @override
  TransactionStateStatus getStateStatus() {
    if (txFee.isPending) return TransactionStateStatus.error();
    if (defaultAccount.networkAddress != transactionData.owner.networkAddress) {
      return TransactionStateStatus.ready();
    }
    final total = transactionData.transactionInfo.totalTrxAmount?.balance ??
        BigInt.zero + txFee.fee.totalBurn.balance;
    final remain = transactionData.accountData.balance - total;
    if (!remain.isNegative) {
      return TransactionStateStatus.ready();
    }
    final error =
        TransactionStateStatus.insufficient(IntegerBalance.token(remain, network.token))
            .error;

    return TransactionStateStatus.ready(warning: error);
  }

  @override
  Future<IWeb3TronTransactionRawData> buildTransactionData(
      {bool simulate = false}) async {
    return _transactionRawData ??= await () async {
      final transaction = MethodUtils.fallbackOnException(
          () => Transaction.deserialize(request.params.transaction));
      if (transaction == null) {
        throw Web3RequestExceptionConst.invalidTransaction;
      }
      if (request.params.txId != null &&
          request.params.txId != transaction.rawData.txID) {
        throw Web3RequestExceptionConst.invalidTransaction;
      }
      final account = await client.getAccount(transaction.rawData.ownerAddress);
      if (account == null) {
        throw WalletExceptionConst.accountDoesNotFound;
      }
      int totalSigner = 1;
      final id = transaction.rawData.permissionId();
      if (id == null) {
        totalSigner = account.ownerPermission.threshold.toInt();
      } else {
        final permission =
            account.activePermissions.firstWhereNullable((e) => e.id == id);
        totalSigner = permission?.threshold.toInt() ?? 1;
      }
      final accountResource =
          await client.getAccountResource(transaction.rawData.ownerAddress);
      final contractOwner = transaction.rawData.ownerAddress;
      final owner = getOrCreateAddressInfo(contractOwner);
      final transactionInfo = await getWeb3TransactionInfo(
          transaction: transaction.rawData, chain: this.account);
      if (defaultAccount.multiSigAccount) {
        final multiSigAddress = defaultAccount as ITronMultisigAddress;
        if (transaction.rawData.permissionId() !=
            multiSigAddress.multiSignatureAccount.permissionID) {
          throw Web3RequestExceptionConst.missingPermission;
        }
      }
      String? memo = BytesUtils.tryToHexString(transaction.rawData.data);
      if (memo != null) {
        memo = StringUtils.tryDecode(transaction.rawData.data) ?? memo;
      }
      final feeLimit = transaction.rawData.feeLimit;
      return IWeb3TronTransactionRawData(
          transaction: transaction,
          transactionInfo: transactionInfo,
          owner: owner,
          txId: transaction.rawData.txID,
          feeLimit:
              feeLimit == null ? null : IntegerBalance.token(feeLimit, network.token),
          accountResource: accountResource,
          totalSigners: totalSigner,
          memo: memo,
          accountData: account);
    }();
  }

  @override
  Future<IWeb3TronTransaction<IWeb3TronTransactionRawData>> buildTransaction(
      {bool simulate = false}) async {
    final transactionData = await buildTransactionData(simulate: simulate);
    return IWeb3TronTransaction(
        account: defaultAccount, transactionData: transactionData);
  }

  @override
  Future<IWeb3TronSignedTransaction<IWeb3TronTransactionRawData>> signTransaction(
      IWeb3TronTransaction<IWeb3TronTransactionRawData> transaction,
      {bool fakeSignature = false}) async {
    final signexTx = await signTransactionInternal(
        transaction: transaction.transactionData.transaction.rawData,
        address: defaultAccount,
        fakeSignature: fakeSignature);
    return IWeb3TronSignedTransaction(
      transaction: transaction,
      signatures: signexTx.signature,
      finalTransactionData: Transaction(rawData: signexTx.rawData, signature: [
        ...transaction.transactionData.transaction.signature,
        ...signexTx.signature
      ]),
    );
  }

  @override
  Future<List<IWalletTransaction<TronWalletTransaction, ITronAddress>>>
      buildWalletTransaction(
          {required IWeb3TronSignedTransaction<IWeb3TronTransactionRawData> signedTx,
          required SubmitTransactionSuccess? txId}) async {
    if (txId == null) return [];
    final transaction = TronWalletTransaction(
        web3Client: web3ClientInfo(),
        type: WalletTransactionType.web3Sign,
        txId: txId.txId,
        network: network,
        outputs: [
          TronWalletTransactionOperationOutput(
              name: signedTx.finalTransactionData.rawData.getContract().contractType.name)
        ]);

    return [
      IWalletTransaction(transaction: transaction, account: signedTx.transaction.account)
    ];
  }

  BigInt getMaxFeeInput() {
    return defaultAccount.addressData.currencyBalance;
  }

  @override
  Future<TronSimulateTransaction> simulateTransaction() async {
    final transaction = await buildTransaction(simulate: true);
    final signedTx = await signTransaction(transaction, fakeSignature: true);
    return TronSimulateTransaction(
        transaction: signedTx.finalTransactionData.rawData,
        totalSigners: transaction.transactionData.totalSigners,
        accountResource: transaction.transactionData.accountResource);
  }

  @override
  Future<
          Web3RequestTransactionResponseData<
              Transaction,
              SubmitTransactionSuccess<
                  IWeb3TronSignedTransaction<IWeb3TronTransactionRawData>>>>
      getResponse() async {
    final transaction = await buildTransaction();
    final signedTx = await signTransaction(transaction);
    return Web3RequestTransactionResponseData(response: signedTx.finalTransactionData);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3TronSignTransactionStateView(this);
  }

  @override
  void onAccountUpdated(ITronAddress e) {
    super.onAccountUpdated(e);
    if (e == defaultAccount) {
      estimateFee();
    }
  }

  @override
  Future<void> initForm(TronClient client) async {
    await super.initForm(client);
    _transactionRawData = await buildTransactionData();
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
