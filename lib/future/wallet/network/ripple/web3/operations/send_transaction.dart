import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/controllers/signer.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/web3/controllers/controllers.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/web3/pages/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class WebXRPSendTransactionStateController extends Web3XRPTransactionStateController<
    Web3XRPTransactionResponse,
    Web3XRPSendTransaction,
    IWeb3XRPTransactionRawData> with RippleTransactionSignerController {
  Web3SecurityLevel _securityLevel = Web3SecurityLevel.minimal;
  @override
  Web3SecurityLevel get securityLevel => _securityLevel;
  StreamSubscription<void>? _feeListener;
  IWeb3XRPTransactionRawData? _transactionData;
  IWeb3XRPTransactionRawData get transactionData => _transactionData!;
  WebXRPSendTransactionStateController(
      {required super.walletProvider, required super.request});

  bool get isExcute => params.method == Web3XRPRequestMethods.sendTransaction;

  @override
  Future<IWeb3XRPTransaction<IWeb3XRPTransactionRawData>> buildTransaction(
      {bool simulate = false}) async {
    final transactionData = await buildTransactionData(simulate: simulate);
    final transaction = await buildTransactionData(simulate: simulate);
    await filledTransactionRequirment(transaction.transaction,
        force: transaction.signingMode.isFull);
    transaction.transaction.setFee(txFee.fee.fee.balance);
    return IWeb3XRPTransaction(account: defaultAccount, transactionData: transactionData);
  }

  @override
  Future<IWeb3XRPTransactionRawData> buildTransactionData({bool simulate = false}) async {
    return _transactionData ??= await () async {
      final transaction = MethodUtils.fallbackOnException(
        () => SubmittableTransaction.fromBytes(params.txBlob),
        mode: LoggerMode.danger,
        onError: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "buildTransactionData",
            msg: "Failed to decode transaction.",
            err: exception,
            trace: trace.toString()),
      );
      if (transaction == null) {
        throw Web3XRPExceptionConstant.invalidTransaction;
      }
      final owner = XRPBaseAddress(transaction.account);
      final ownerInfo = getOrCreateAddressInfo(owner);
      final accountInfo = await getWeb3TransactionAccountInfo(ownerInfo);
      final signMode = canSignTransaction(
          owner: accountInfo, address: defaultAccount, method: params.method);
      if (signMode == null) {
        throw Web3XRPExceptionConstant.insufficientAccountPermissions;
      }
      final info = await getWeb3TransactionInfo(
          account: account, address: defaultAccount, transaction: transaction);
      return IWeb3XRPTransactionRawData(
          transaction: transaction,
          content: StringUtils.fromJson(transaction.toXrpl(),
              toStringEncodable: true, indent: ''),
          memos: transaction.memos,
          signingMode: signMode,
          info: info);
    }();
  }

  @override
  Future<List<IWalletTransaction<XRPWalletTransaction, IXRPAddress>>>
      buildWalletTransaction(
          {required IWeb3XRPSignedTransaction<IWeb3XRPTransactionRawData> signedTx,
          required SubmitTransactionSuccess<
                  IWeb3XRPSignedTransaction<IWeb3XRPTransactionRawData>>?
              txId}) async {
    if (txId == null) return [];
    final transaction = XRPWalletTransaction(
        web3Client: web3ClientInfo(),
        type: WalletTransactionType.web3Tx,
        txId: txId.txId,
        network: network,
        outputs: [
          XRPWalletTransactionOperationOutput(
              name: signedTx.finalTransactionData.transactionType.value)
        ]);
    return [
      IWalletTransaction(transaction: transaction, account: signedTx.transaction.account)
    ];
  }

  BigInt maxInputFee() {
    if (transactionData.signingMode.isFull) {
      return defaultAccount.addressData.currencyBalance;
    }
    return BigInt.zero;
  }

  @override
  Future<
          Web3RequestTransactionResponseData<
              Web3XRPTransactionResponse,
              SubmitTransactionSuccess<
                  IWeb3XRPSignedTransaction<IWeb3XRPTransactionRawData>>>>
      getResponse() async {
    if (isExcute) {
      final result = await buildSignAndSendTransaction();
      final tx = result.signedTransaction;
      final signature = tx.signature;
      final mutliSignature = tx.multiSignature;
      return Web3RequestTransactionResponseData.submitTx(
          response: Web3XRPTransactionResponse(
              txId: result.txId,
              signature: signature != null
                  ? Web3XRPTransactionSignatureResponse(
                      txnSignature: signature.signature!,
                      signingPubKey: signature.signingPubKey)
                  : Web3XRPTransactionSignatureResponse.multiSigner(mutliSignature!
                      .map((e) => Web3XRPTransactionSignatureMultiSignerResponse(
                          txnSignature: e.txnSignature!,
                          signingPubKey: e.signingPubKey,
                          account: e.account))
                      .toList()),
              txBlob: result.signedTransaction.finalTransactionData.toTransactionBlob()),
          txIds: [result]);
    }
    final transaction = await buildTransaction();
    final signedTx = await signTransaction(transaction);
    final signature = signedTx.signature;
    final mutliSignature = signedTx.multiSignature;
    return Web3RequestTransactionResponseData(
        response: Web3XRPTransactionResponse(
            signature: signature != null
                ? Web3XRPTransactionSignatureResponse(
                    txnSignature: signature.signature!,
                    signingPubKey: signature.signingPubKey)
                : Web3XRPTransactionSignatureResponse.multiSigner(mutliSignature!
                    .map((e) => Web3XRPTransactionSignatureMultiSignerResponse(
                        txnSignature: e.txnSignature!,
                        signingPubKey: e.signingPubKey,
                        account: e.account))
                    .toList()),
            txBlob: signedTx.finalTransactionData.toTransactionBlob()));
  }

  @override
  Future<IWeb3XRPSignedTransaction<IWeb3XRPTransactionRawData>> signTransaction(
      IWeb3XRPTransaction<IWeb3XRPTransactionRawData> transaction,
      {bool fakeSignature = false}) async {
    final signMode = transaction.transactionData.signingMode;
    final submittableTx = transaction.transactionData.transaction;
    XRPSignedTransaction signature;
    if (signMode == XRPWeb3SigningMode.part) {
      signature = await signTransactionInternalPart(
          transaction: submittableTx, address: defaultAccount);
    } else {
      signature = await signTransactionInternalFull(
          transaction: submittableTx, address: defaultAccount);
    }
    return IWeb3XRPSignedTransaction(
        signature: signature.signature,
        transaction: transaction,
        finalTransactionData: submittableTx,
        multiSignature: signature.multiSignature,
        signatures: signature.signatures);
  }

  void onFeeUpdated(void _) {
    onStateUpdated();
  }

  @override
  TransactionStateStatus getStateStatus() {
    if (!txFee.fee.isManual && txFee.isPending) {
      return TransactionStateStatus.error();
    }
    if (!txFee.hasFee && transactionData.signingMode.isFull) {
      return TransactionStateStatus.error(error: "fee_zero_validator_desc".tr);
    }
    if (!txFee.hasFee) {
      return TransactionStateStatus.ready(warning: "fee_zero_validator_desc".tr);
    }
    return super.getStateStatus();
  }

  @override
  Future<SubmittableTransaction> simulateTransaction() async {
    final transaction = await buildTransaction(simulate: true);
    return transaction.transactionData.transaction;
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3XRPSignTransactionStateView(this);
  }

  @override
  Future<void> initForm(XRPNetworkClient client) async {
    await super.initForm(client);
    _transactionData = await buildTransactionData();
    int multiSigner = 0;
    if (transactionData.signingMode == XRPWeb3SigningMode.full) {
      if (defaultAccount.multiSigAccount) {
        final IXRPMultisigAddress multiSigAddress = defaultAccount as IXRPMultisigAddress;
        if (!multiSigAddress.multiSignatureAccount.isRegular) {
          multiSigner = multiSigAddress.multiSignatureAccount.signers.length;
        }
      }
    }
    _feeListener = txFee.stream.listen(onFeeUpdated);
    await initFee(
        multiSigner: multiSigner, type: transactionData.transaction.transactionType);

    estimateFee();
    final fee = transactionData.transaction.fee ?? BigInt.zero;
    if (transactionData.signingMode.isFull) {
      if (fee > BigInt.zero) {
        final feeData = RippleTransactionFee(
            fee: IntegerBalance.token(fee, network.token), type: TxFeeTypes.manually);
        txFee.setManualFee(feeData);
      }
    } else {
      final feeData = RippleTransactionFee(
          fee: IntegerBalance.token(fee, network.token), type: TxFeeTypes.manually);
      txFee.setManualFee(feeData);
      txFee.setAllowSwitchFee(false);
    }
    switch (transactionData.transaction.transactionType) {
      case SubmittableTransactionType.setRegularKey:
      case SubmittableTransactionType.signerListSet:
        _securityLevel = Web3SecurityLevel.critical;
      default:
    }
  }

  @override
  void dispose() {
    super.dispose();
    _feeListener?.cancel();
    _feeListener = null;
  }
}
