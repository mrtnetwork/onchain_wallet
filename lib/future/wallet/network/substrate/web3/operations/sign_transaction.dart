import 'dart:async';

import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/controllers/signer.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/web3/controllers/controllers.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/web3/pages/sign_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/substrate/constant/constants/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/substrate/params/models/transaction.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

class WebSubstrateSignTransactionStateController
    extends Web3SubstrateTransactionStateController<
        Web3SubstrateSendTransactionResponse,
        Web3SubstrateSendTransaction,
        IWeb3SubstrateTransactionRawData> with SubstrateTransactionSignerController {
  StreamSubscription<void>? _feeListener;
  IWeb3SubstrateTransactionRawData? _transactionData;
  IWeb3SubstrateTransactionRawData get transactionData => _transactionData!;
  SubstrateChainMetadata get metadata => client.metadata;
  WebSubstrateSignTransactionStateController(
      {required super.walletProvider, required super.request});
  void onFeeUpdated(void _) {
    onStateUpdated();
  }

  @override
  Future<IWeb3SubstrateTransactionRawData> buildTransactionData(
      {bool simulate = false}) async {
    return _transactionData ??= await () async {
      if (params.specVersion != metadata.specVersion) {
        throw Web3SubstrateExceptionConstant.differentRuntimeMetadata;
      }
      if (!BytesUtils.bytesEqual(params.genesisHash, metadata.genesisBytes())) {
        throw Web3SubstrateExceptionConstant.differentRuntimeMetadata;
      }
      final decode = metadata.metadata.decodeCall<Map<String, dynamic>>(params.call);
      List<SubstrateKnownCallMethods> methods = SubstrateKnownCallMethods.parseTxMethod(
          data: decode.toJson(), network: network);
      methods = methods.map((e) {
        if (e is SubstrateTransferMethod) {
          return e.copyWith(
              receiver: account.getOrCreateReceiptFromNetworkAddressSync(
                  address: e.receiver.networkAddress));
        }
        return e;
      }).toList();
      final era = MortalEra(index: params.era[0], era: params.era[1]);
      final extrinsic = DynamicExtrinsicBuilder(
          era: era,
          nonce: params.nonce,
          mode: params.mode,
          metadataFields: metadata.extrinsic,
          specVersion: metadata.runtimeVersion.specVersion,
          transactionVersion: metadata.runtimeVersion.transactionVersion,
          genesis: params.genesisHash,
          mortality: params.blockHash,
          tip: params.tip,
          metadataHash: params.metadataHash,
          chargeAssetTxPaymentBytes: params.assetId);
      final extraFields = extrinsic.encodeExtrinsicPayload(metadata.metadata);
      final List<int> serializedExtrinsic =
          [...params.call, ...extraFields].asImmutableBytes;
      final extrinsicPayloadInfo = ExtrinsicPayloadInfo(
          serializedExtrinsic: serializedExtrinsic,
          method: params.call,
          payloadInfo: decode.data,
          extrinsic: extrinsic);
      return IWeb3SubstrateTransactionRawData(
          extrinsicPayloadInfo: extrinsicPayloadInfo, methods: methods);
    }();
  }

  @override
  Future<IWeb3SubstrateTransaction<IWeb3SubstrateTransactionRawData>> buildTransaction(
      {bool simulate = false}) async {
    return IWeb3SubstrateTransaction(
        account: defaultAccount, transactionData: transactionData);
  }

  @override
  Future<List<IWalletTransaction<SubstrateWalletTransaction, ISubstrateAddress>>>
      buildWalletTransaction(
          {required IWeb3SubstrateSignedTransaction<IWeb3SubstrateTransactionRawData>
              signedTx,
          required SubmitTransactionSuccess<
                  IWeb3SubstrateSignedTransaction<IWeb3SubstrateTransactionRawData>>?
              txId}) async {
    if (txId == null) return [];
    return [];
  }

  @override
  Future<
          Web3RequestTransactionResponseData<
              Web3SubstrateSendTransactionResponse,
              SubmitTransactionSuccess<
                  IWeb3SubstrateSignedTransaction<IWeb3SubstrateTransactionRawData>>>>
      getResponse() async {
    final transaction = await buildTransaction();
    final signedTransaction = await signTransaction(transaction);
    final withTx = params.withSignedTransaction ?? true;
    return Web3RequestTransactionResponseData(
        response: Web3SubstrateSendTransactionResponse(
            signature: signedTransaction.finalTransactionData.encodeSignature!,
            signedTransaction:
                withTx ? signedTransaction.finalTransactionData.serialize() : null));
  }

  @override
  Future<IWeb3SubstrateSignedTransaction<IWeb3SubstrateTransactionRawData>>
      signTransaction(
          IWeb3SubstrateTransaction<IWeb3SubstrateTransactionRawData> transaction,
          {bool fakeSignature = false}) async {
    final signedTransaction = await signTransactionInternal(
        payloadBytes: transaction.transactionData.extrinsicPayloadInfo.payloadBytes,
        signer: defaultAccount,
        fakeSignature: fakeSignature);
    final ExtrinsicInfo extrinsic = metadata.createExtrinsic(
        signature: signedTransaction.signatures[0],
        address: defaultAccount.networkAddress,
        algorithm: defaultAccount.coin.conf.type,
        payload: transaction.transactionData.extrinsicPayloadInfo);
    return IWeb3SubstrateSignedTransaction(
        transaction: transaction,
        signatures: signedTransaction.signatures,
        finalTransactionData: extrinsic);
  }

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required IWeb3SubstrateSignedTransaction<IWeb3SubstrateTransactionRawData>
          signedTransaction}) {
    throw UnimplementedError();
  }

  @override
  TransactionStateStatus getStateStatus() {
    if (txFee.isPending) return TransactionStateStatus.error();
    String? simulateError =
        txFee.fee.hasError ? "transaction_simulation_failed".tr : null;
    final total =
        transactionData.methods.fold<BigInt>(BigInt.zero, (p, c) => p + c.value);
    final r = defaultAccount.addressData.currencyBalance - total - txFee.fee.fee.balance;
    if (r.isNegative) {
      final error =
          TransactionStateStatus.insufficient(IntegerBalance.token(r, network.token))
              .error;
      return TransactionStateStatus.ready(warning: error);
    }
    return TransactionStateStatus.ready(warning: simulateError);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3SubstrateSignTransactionStateView(this);
  }

  @override
  Future<void> initForm(SubstrateNetworkClient client) async {
    await super.initForm(client);
    _transactionData = await buildTransactionData();
    _feeListener = txFee.stream.listen(onFeeUpdated);
    estimateFee();
  }

  @override
  Future<SubstrateEstimateTransaction> simulateTransaction() async {
    final transaction = await buildTransaction(simulate: true);
    final signedTransaction = await signTransaction(transaction, fakeSignature: true);
    return SubstrateEstimateTransaction(
        extrinsic: signedTransaction.finalTransactionData,
        owner: defaultAccount.networkAddress);
  }

  @override
  void dispose() {
    super.dispose();
    _feeListener?.cancel();
    _feeListener = null;
  }
}
