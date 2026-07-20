import 'dart:async';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

import 'fee.dart';
import 'memo.dart';
import 'signer.dart';

abstract class SubstrateTransactionStateController<T extends ISubstrateTransactionData>
    extends BaseSubstrateTransactionController<T>
    with
        SubstrateTransactionApiController,
        SubstrateTransactionFeeController,
        SubstrateTransactionMemoController,
        SubstrateTransactionSignerController {
  late SubstrateTransferToken _nativeToken = SubstrateTransferToken(
      tokenDetails: SubstrateTokenDetails(
        internalAsset: GenericBaseSubstrateNativeAsset.withParaLocation(
            name: network.token.name,
            decimals: network.token.decimal,
            symbol: network.token.symbol,
            version: XCMVersion.v4,
            excutionPallet: SubtrateMetadataPallet.balances),
        asset: null,
        balance: address.addressData.balance,
      ),
      transferMethod: metadata.nativeTransferMethods);
  SubstrateTransferToken get nativeToken => _nativeToken;
  List<SubstrateTransferToken> _transferAssets = [];
  List<SubstrateTransferToken> _feeTokens = [];
  List<SubstrateTransferToken> get tokens => _transferAssets;
  List<SubstrateTransferToken> get feeTokens => _feeTokens;
  SubstrateChainMetadata get metadata => client.metadata;
  bool get supportRemarks => client.metadata.supportRemarks;
  bool get supportBatch => client.metadata.supportBatch;

  SubstrateTransactionStateController(
      {required super.walletProvider, required super.account, required super.address});

  late final LiveFormField<SubstrateTransferToken?, SubstrateTransferToken?> feeToken =
      LiveFormField(
          optional: false,
          value: null,
          title: "transaction_fee_token".tr,
          subtitle: "choose_token_for_fee_payment".tr);

  void onUpdateFeeToken(SubstrateTransferToken? token) {
    if (_feeTokens.isEmpty || token == null || token == feeToken.value) return;
    feeToken.setValue(token);
    onStateUpdated();
    estimateFee();
  }

  @override
  void onUpdateMemo(String? memo) {
    if (memo == null) return;
    super.onUpdateMemo(memo);
    onStateUpdated();
    estimateFee();
  }

  @override
  void onRemoveMemo(String memo) {
    super.onRemoveMemo(memo);
    onStateUpdated();
    estimateFee();
  }

  Future<ExtrinsicInfo> createSignedExtrinsic({
    required ExtrinsicPayloadInfo transaction,
    required List<int> signature,
  }) async {
    return metadata.createExtrinsic(
        signature: signature,
        address: address.networkAddress,
        algorithm: address.coin.conf.type,
        payload: transaction);
  }

  @override
  Future<ISubstrateSignedTransaction<T>> signTransaction(
      ISubstrateTransaction<T> transaction,
      {bool fakeSignature = false}) async {
    final signedTransaction = await signTransactionInternal(
        payloadBytes: transaction.payload.payloadBytes,
        signer: address,
        fakeSignature: fakeSignature);
    final extrinsic = await createSignedExtrinsic(
        transaction: transaction.payload, signature: signedTransaction.signatures[0]);
    return ISubstrateSignedTransaction<T>(
        transaction: transaction,
        signatures: signedTransaction.signatures,
        finalTransactionData: extrinsic);
  }

  @override
  Future<SubstrateEstimateTransaction> simulateTransaction() async {
    final transaction = await buildTransaction();
    final signexTx = await signTransaction(transaction, fakeSignature: true);

    return SubstrateEstimateTransaction(
        extrinsic: signexTx.finalTransactionData,
        owner: address.networkAddress,
        fee: transaction.transactionData.feeAssetConfig);
  }

  @override
  Future<SubmitSubstrateTransactionSuccess<T>> submitTransaction(
      {required ISubstrateSignedTransaction<T> signedTransaction}) async {
    final txId = await client
        .broadcastTransaction(signedTransaction.finalTransactionData.serialize());
    return SubmitSubstrateTransactionSuccess(
        txId: txId.txId, block: txId.block, signedTransaction: signedTransaction);
  }

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required SubstrateNetworkClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await super.initForm(
        context: context,
        client: client,
        updateAccount: updateAccount,
        updateTokens: true);
    final bool isTransfer = operation == SubstrateTransactionOperations.transfer;
    final metadataWithExtrinsic = client.metadata.metadataWithExtrinsic();
    final controller = client.metadata.controller;
    List<SubstrateTransferToken> transferAssets = [];
    XCMVersionedLocation? baseFeeLocation;
    final natvieMethods =
        SubstrateNetworkControllerLocalAssetTransferBuilder.transferMethods(
            metadata: metadataWithExtrinsic, asset: controller?.defaultNativeAsset)
          ..removeWhere((e) => e.isTransferAll);
    if (controller != null && client.metadata.supportTransferLocalToken) {
      final assets = await controller.getAccountAssets(
          address: address.networkAddress,
          knownAssetIds: addressTokens.map((e) => e.assetIdentifier).toList());

      baseFeeLocation = metadata.chargeAssetTxPaymentNativeLocation();
      _nativeToken = SubstrateTransferToken(
          tokenDetails: SubstrateTokenDetails(
              internalAsset: controller.defaultNativeAsset,
              asset: null,
              balance: address.addressData.balance),
          transferMethod: natvieMethods);
      transferAssets.add(_nativeToken);
      for (final i in assets.assets) {
        if (i.identifier == null || i.type.isNative) continue;
        final accountAsset =
            addressTokens.firstWhereOrNull((a) => i.identifierEqual(a.assetIdentifier));
        if (accountAsset == null) continue;
        final SubstrateFeeConfig? fee = () {
          if (i.chargeAssetTxPayment && i.location != null && baseFeeLocation != null) {
            final location = i.getAssetId(
                reserveNetwork: controller.network,
                version: controller.network.defaultXcmVersion);
            final feeId = i.asChargeTxPaymentAssetId(
                network: controller.network,
                version: controller.network.defaultXcmVersion);
            if (feeId != null) {
              return SubstrateFeeConfig(
                  feeId: feeId,
                  assetLocation: location,
                  baseFee: baseFeeLocation,
                  token: accountAsset.token);
            }
            return null;
          }
        }();
        final assetMethods =
            SubstrateNetworkControllerLocalAssetTransferBuilder.transferMethods(
                metadata: metadataWithExtrinsic, asset: i)
              ..removeWhere((e) => e.isTransferAll);
        if (isTransfer && assetMethods.isEmpty) continue;
        transferAssets.add(SubstrateTransferToken(
            tokenDetails: SubstrateTokenDetails(
                internalAsset: i,
                asset: accountAsset,
                balance: accountAsset.streamBalance),
            feeConfig: fee,
            transferMethod: assetMethods));
      }
    } else {
      transferAssets.add(_nativeToken);
    }
    _transferAssets = transferAssets.immutable;
    if (baseFeeLocation != null) {
      _feeTokens = transferAssets
          .where((e) => e.tokenDetails.isNativeAsset || e.feeConfig != null)
          .toImutableList;
      feeToken.setValue(_nativeToken);
    }
    return this;
  }

  @override
  void dispose() {
    super.dispose();
    _transferAssets = [];
    _feeTokens = [];
  }
}
