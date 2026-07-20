import 'dart:async';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/metadata/forms/metadata.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/widgets/extrinsic.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

class _ExtrinsicConstants {
  static const List<String> knownNoncesFields = ["nonce", "CheckNonce", "T::Nonce"];
  static const String checkTxVersion = "CheckTxVersion";
  static const String checkSpecVersion = "CheckSpecVersion";
  static const String checkGenesis = "CheckGenesis";
  static const String chargeTransactionPayment = "ChargeTransactionPayment";
  static const String checkMetadataHash = "CheckMetadataHash";
  static const String balanceOf = "BalanceOf<T>";
  static const String mode = "mode";
  static const String noneVariantName = "None";
  static const String disabledVariantName = "Disabled";
  static const String checkMortality = "CheckMortality";
  static const String era = "Era";
  static const String some = "Some";
}

enum BuildExtrinsicPage { payload, extrinsic, review }

class SubstrateTransactionExtrinsicOperation
    extends SubstrateTransactionStateController<ISubstrateTransactionData> {
  SubstrateTransactionExtrinsicOperation(
      {required super.walletProvider, required super.account, required super.address});
  TransactionExtrinsicInfo get extrinsicLookupField => metadata.extrinsic.extrinsicInfo;
  List<MetadataFormValidator> get extrinsicValidators => _extrinsicValidators;
  List<MetadataFormValidator> get extrinsicPayloadValidators => _payloadValidators;
  List<MetadataFormValidator> _extrinsicValidators = [];
  List<MetadataFormValidator> _payloadValidators = [];
  ExtrinsicPayloadInfo? _payload;
  ExtrinsicPayloadInfo get payload => _payload!;
  ExtrinsicInfo? _extrinsicInfo;
  ExtrinsicInfo get extrinsic => _extrinsicInfo!;
  final LiveFormField<BuildExtrinsicPage, BuildExtrinsicPage> page =
      LiveFormField(title: "payload".tr, value: BuildExtrinsicPage.payload);

  E? _getPayloadField<E extends MetadataFormValidator>(String name) {
    try {
      for (final i in extrinsicPayloadValidators) {
        final field = i.findField<E>(name);
        if (field != null) return field;
      }
    } catch (_) {}
    return null;
  }

  E? _getExtrinsicField<E extends MetadataFormValidator>(String name) {
    try {
      for (final i in extrinsicValidators) {
        final field = i.findField<E>(name);
        if (field != null) return field;
      }
    } catch (_) {}
    return null;
  }

  MetadataFormValidatorNumeric? _getNoncePayloadField() {
    for (final i in _ExtrinsicConstants.knownNoncesFields) {
      final field = _getPayloadField<MetadataFormValidatorNumeric>(i);
      if (field != null) return field;
    }
    return null;
  }

  void _onPayloadNonceChanged(BigRational? nonce) {
    if (nonce != null) {
      final exNonce = _getExtrinsicField<MetadataFormValidatorNumeric>("CheckNonce");
      exNonce?.setValue(nonce);
    }
  }

  void _onPayloadEraChanged(MetadataFormValidator? validator) {
    if (validator == null) return;
    final exEra = _getExtrinsicField<MetadataFormValidatorVariant>(
        _ExtrinsicConstants.checkMortality);
    if (exEra != null) {
      final eraVariant =
          exEra.info.variants.firstWhereNullable((e) => e.name == validator.info.name);
      if (eraVariant != null) {
        final indexType = metadata.getTypeInfo(eraVariant);
        exEra.setVariant(variant: eraVariant, type: indexType);
        MethodUtils.fallbackOnException(() {
          exEra.validator.value
              ?.cast<MetadataFormValidatorNumeric>()
              .setValue(validator.cast<MetadataFormValidatorNumeric>().value.value);
        });
      }
    }
  }

  void _onPayloadModeChanged(MetadataFormValidator? validator) {
    if (validator == null) return;
    final field =
        _getExtrinsicField<MetadataFormValidatorVariant>(_ExtrinsicConstants.mode);
    field?.trySetVariant(name: validator.info.name, metadata: metadata);
  }

  void _onPayloadTipChanged(BigRational? tip) {
    if (tip != null) {
      final exTip = _getExtrinsicField<MetadataFormValidatorBigInt>("tip") ??
          _getExtrinsicField<MetadataFormValidatorBigInt>("Tip");
      exTip?.setValue(tip);
    }
  }

  void _updateExtrinsicFields() {
    final era = _getPayloadField<MetadataFormValidatorVariant>(_ExtrinsicConstants.era) ??
        _getPayloadField<MetadataFormValidatorVariant>(
            _ExtrinsicConstants.checkMortality);
    _onPayloadEraChanged(era?.validator.value);
    final nonceField = _getNoncePayloadField();
    _onPayloadNonceChanged(nonceField?.value.value);
    final mode = _getPayloadField<MetadataFormValidatorVariant>(_ExtrinsicConstants.mode);
    mode?.trySetVariant(
        name: _ExtrinsicConstants.disabledVariantName, metadata: metadata);
    _onPayloadModeChanged(mode?.validator.value);
    final tip = _getPayloadField<MetadataFormValidatorBigInt>("tip") ??
        _getPayloadField<MetadataFormValidatorBigInt>("Tip");
    _onPayloadTipChanged(tip?.value.value);
  }

  Future<void> _filedPayloadFields(ISubstrateAddress address) async {
    final finalizeBlock = await client.finalizeBlockWithEra();
    final nonce = await client.getAccountNonce(address.networkAddress);
    _getPayloadField<MetadataFormValidatorBytes>(_ExtrinsicConstants.checkMortality)
        ?.setValue(finalizeBlock.block);
    final era = _getPayloadField<MetadataFormValidatorVariant>(_ExtrinsicConstants.era) ??
        _getPayloadField<MetadataFormValidatorVariant>(
            _ExtrinsicConstants.checkMortality);
    final eraVariant =
        era?.info.variants.firstWhereNullable((e) => e.name == finalizeBlock.eraIndex);
    if (eraVariant != null) {
      final indexType = metadata.getTypeInfo(eraVariant);
      era?.setVariant(variant: eraVariant, type: indexType);
      era?.validator.value
          ?.cast<MetadataFormValidatorNumeric>()
          .setValue(BigRational.from(finalizeBlock.eraValue));
    }
    final nonceField = _getNoncePayloadField();
    nonceField?.setBigIntIntValue(nonce);
    _onPayloadNonceChanged(nonceField?.value.value);
    _getPayloadField<MetadataFormValidatorNumeric>(_ExtrinsicConstants.checkTxVersion)
        ?.setIntValue(metadata.runtimeVersion.transactionVersion);
    _getPayloadField<MetadataFormValidatorNumeric>(_ExtrinsicConstants.checkSpecVersion)
        ?.setIntValue(metadata.runtimeVersion.specVersion);
    _getPayloadField<MetadataFormValidatorBytes>(_ExtrinsicConstants.checkGenesis)
        ?.setValue(client.genesisBlock);
    _getPayloadField<MetadataFormValidatorNumeric>(
            _ExtrinsicConstants.chargeTransactionPayment)
        ?.setIntValue(0);
    _getPayloadField<MetadataFormValidatorVariant>(_ExtrinsicConstants.checkMetadataHash)
        ?.trySetVariant(name: _ExtrinsicConstants.noneVariantName, metadata: metadata);
    _getPayloadField<MetadataFormValidatorNumeric>(_ExtrinsicConstants.balanceOf)
        ?.setIntValue(0);
    final mode = _getPayloadField<MetadataFormValidatorVariant>(_ExtrinsicConstants.mode);
    mode?.trySetVariant(
        name: _ExtrinsicConstants.disabledVariantName, metadata: metadata);
    final tip = _getPayloadField<MetadataFormValidatorBigInt>("tip") ??
        _getPayloadField<MetadataFormValidatorBigInt>("Tip");
    tip?.setValue(BigRational.zero);
  }

  String? _getFromsError() {
    for (final i in extrinsicPayloadValidators) {
      final err = i.error;
      if (err != null) return err.errorMessage;
    }
    for (final i in extrinsicValidators) {
      final err = i.error;
      if (err != null) return err.errorMessage;
    }
    return null;
  }

  void onCreatePayload() {
    onStateUpdated();
    if (!stateStatus.value.isReady) return;
    _payload = _buildTransaction();
    _updateExtrinsicFields();
    page.setValue(BuildExtrinsicPage.extrinsic);
  }

  void onCreateExtrinsic() async {
    onStateUpdated();
    final payload = _payload;
    if (!stateStatus.value.isReady || payload == null) return;
    _extrinsicInfo = _createSignedExtrinsic(transaction: payload);
    page.setValue(BuildExtrinsicPage.review);
    estimateFee();
  }

  @override
  Future<void> estimateFee() async {
    if (_extrinsicInfo == null) return;
    return super.estimateFee();
  }

  void onEditPayload() {
    if (page.value == BuildExtrinsicPage.review) {
      page.setValue(BuildExtrinsicPage.extrinsic);
      _extrinsicInfo = null;
      return;
    }
    page.setValue(BuildExtrinsicPage.payload);
    _payload = null;
    _extrinsicInfo = null;
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;
    switch (page.value) {
      case BuildExtrinsicPage.payload:
        for (final i in extrinsicPayloadValidators) {
          final err = i.error;
          if (err != null) {
            return TransactionStateStatus.error(error: err.errorMessage);
          }
        }
        return TransactionStateStatus.ready();
      case BuildExtrinsicPage.extrinsic:
        for (final i in extrinsicValidators) {
          final err = i.error;
          if (err != null) {
            return TransactionStateStatus.error(error: err.errorMessage);
          }
        }
      default:
        final error = _getFromsError();
        if (error != null) {
          return TransactionStateStatus.error(error: error);
        }
    }

    String? simulateError =
        txFee.fee.hasError ? "transaction_simulation_failed".tr : null;

    final r = address.addressData.currencyBalance - txFee.fee.fee.balance;
    if (r.isNegative) {
      return TransactionStateStatus.insufficient(IntegerBalance.token(r, network.token),
          warning: simulateError);
    }
    return TransactionStateStatus.ready(warning: simulateError);
  }

  ExtrinsicInfo _createSignedExtrinsic(
      {required ExtrinsicPayloadInfo transaction, List<int>? signature}) {
    final buffer = DynamicByteTracker();
    List<int>? encodeSignature;
    if (signature != null) {
      final encodedAddress = metadata.extrinsic
          .encodeSigner(address: address.networkAddress, metadata: metadata.metadata);
      encodeSignature = List<int>.from(metadata.extrinsic.encodeSignature(
          algorithm: address.coin.conf.type,
          signature: signature,
          metadata: metadata.metadata));
      buffer.add(encodedAddress);
      buffer.add(encodeSignature);
    }
    final Map<String, dynamic> extrinsicInfo = {};
    final lookupids = [
      ...extrinsicLookupField.extrinsic.map((e) => e.id),
    ];
    for (int i = 0; i < extrinsicValidators.length; i++) {
      final form = extrinsicValidators[i];
      final lookupId = lookupids[i];
      final input = form.getResult();

      final encodeData = metadata.metadata
          .encodeLookup(id: lookupId, value: input, fromTemplate: false)
          .asImmutableBytes;
      final decode = metadata.metadata.decodeLookup(lookupId, encodeData);
      if (form.info.name != null) {
        extrinsicInfo[form.info.name!] = decode;
      }
      buffer.add(encodeData);
    }
    final encodeBytes = buffer.toBytes().asImmutableBytes;
    final encodeData = BytesUtils.toHexString(encodeBytes);
    return ExtrinsicInfo(
        payload: transaction,
        serializedExtrinsic: encodeData,
        version: extrinsicLookupField.version,
        encodeSignature: encodeSignature);
  }

  @override
  Future<ExtrinsicInfo> createSignedExtrinsic(
      {required ExtrinsicPayloadInfo transaction, required List<int> signature}) async {
    return _createSignedExtrinsic(transaction: transaction, signature: signature);
  }

  (DynamicByteTracker, Map<String, dynamic>) _encodeCallPayload() {
    final byte = DynamicByteTracker();
    final Map<String, dynamic> extrinsicInfo = {};
    final form = extrinsicPayloadValidators[0] as MetadataFormValidatorVariant;
    final callInput = form.getResult();
    int? callLookupId = extrinsicLookupField.callType;
    if (callLookupId != null) {
      final encodeData = metadata.metadata
          .encodeLookup(id: callLookupId, value: callInput, fromTemplate: false)
          .asImmutableBytes;
      final decode = metadata.metadata.decodeLookup(callLookupId, encodeData);
      if (form.info.name != null) {
        extrinsicInfo[form.info.name!] = decode;
      }
      byte.add(encodeData);
    } else {
      callLookupId = form.variant!.fields[0].type;
      List<int> encodeData = metadata.metadata
          .encodeLookup(
              id: callLookupId,
              value: form.validator.value!.getResult(),
              fromTemplate: false)
          .asImmutableBytes;
      final decode = metadata.metadata.decodeLookup(callLookupId, encodeData);
      if (form.info.name != null) {
        extrinsicInfo[form.info.name!] = {form.variant!.name: decode};
      }
      encodeData = [form.variant!.index, ...encodeData];
      byte.add(encodeData);
    }
    return (byte, extrinsicInfo);
  }

  ExtrinsicPayloadInfo _buildTransaction() {
    final callEncode = _encodeCallPayload();
    final byte = callEncode.$1;
    final List extrinsicInfo = [callEncode.$2];
    final List<int> callData = byte.toBytes().asImmutableBytes;
    for (int i = 1; i < extrinsicPayloadValidators.length; i++) {
      final form = extrinsicPayloadValidators[i];
      final input = form.getResult();
      final lookupId = extrinsicLookupField.payloadExtrinsic[i - 1].id;
      final encodeData = metadata.metadata
          .encodeLookup(id: lookupId, value: input, fromTemplate: false)
          .asImmutableBytes;
      final decode = metadata.metadata.decodeLookup(lookupId, encodeData);
      if (form.info.name != null) {
        extrinsicInfo.add({form.info.name: decode});
      } else {
        extrinsicInfo.add(decode);
      }
      byte.add(encodeData);
    }
    final encodeBytes = byte.toBytes().asImmutableBytes;
    return ExtrinsicPayloadInfo(
        serializedExtrinsic: encodeBytes, method: callData, payloadInfo: extrinsicInfo);
  }

  SubstrateFeeConfig? _getFeeConfig() {
    final nativeAssetLocation = metadata.chargeAssetTxPaymentNativeLocation();
    if (nativeAssetLocation == null) return null;

    // if()
    final assetId = _getExtrinsicField<MetadataFormValidatorVariant>("asset_id");
    if (assetId == null) return null;
    final value = assetId.toJson();
    if (value is Map && value.containsKey(_ExtrinsicConstants.some)) {
      final assetIdentifier = value[_ExtrinsicConstants.some];
      SubstrateFeeConfig? token = feeTokens
          .firstWhereOrNull(
              (e) => Equality.deepEqual(assetIdentifier, e.feeConfig?.feeId))
          ?.feeConfig;
      return token;
    }
    return null;
  }

  @override
  Future<ISubstrateTransactionData> buildTransactionData({bool simulate = false}) async {
    return ISubstrateTransactionData(fee: txFee.fee, feeAssetConfig: _getFeeConfig());
  }

  @override
  Future<ISubstrateTransaction> buildTransaction({bool simulate = false}) async {
    final transactionData = await buildTransactionData(simulate: simulate);
    //  final assetId = _getPayloadField<MetadataFormValidatorVariant>("asset_id");
    return ISubstrateTransaction(
        account: address, transactionData: transactionData, payload: payload);
  }

  @override
  Future<List<IWalletTransaction<SubstrateWalletTransaction, ISubstrateAddress>>>
      buildWalletTransaction(
          {required ISubstrateSignedTransaction signedTx,
          required SubmitSubstrateTransactionSuccess txId}) async {
    final methodBytes =
        BytesUtils.fromHexString(signedTx.finalTransactionData.payload.method);
    final decode = metadata.metadata.decodeCall(methodBytes);
    final operations =
        SubstrateKnownCallMethods.parseTxMethod(data: decode.toJson(), network: network);
    final outputs = operations.map((e) {
      if (e is SubstrateTransferMethod) {
        return SubstrateWalletTransactionTransferOutput(
            to: e.receiver.networkAddress,
            amount: WalletTransactionIntegerAmount(
                amount: e.amount.balance, network: network));
      } else {
        return SubstrateWalletTransactionOperationOutput(name: e.name.camelCase);
      }
    }).toList();

    final totalAmount = operations
        .whereType<SubstrateTransferMethod>()
        .fold<BigInt>(BigInt.zero, (p, c) => p + c.value);
    final transaction = SubstrateWalletTransaction(
        block: txId.block!,
        txId: txId.txId,
        network: network,
        totalOutput:
            WalletTransactionIntegerAmount(amount: totalAmount, network: network),
        outputs: outputs,
        extrinsics: signedTx.finalTransactionData.serializeHex());
    return [
      IWalletTransaction(transaction: transaction, account: signedTx.transaction.account)
    ];
  }

  @override
  Future<TransactionStateController> cloneController(ISubstrateAddress address) async {
    return SubstrateTransactionExtrinsicOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return SubstrateTransactionExtrinsicWidget(form: this, mainContext: context);
  }

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required SubstrateNetworkClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await super.initForm(context: context, client: client, updateAccount: updateAccount);
    final fields = metadata.extrinsic;
    _extrinsicValidators = [
      ...fields.extrinsicValidators.map((e) => MetadataFormValidator.fromType(e))
    ].immutable;
    _payloadValidators = [
      MetadataFormValidator.fromType(fields.call),
      ...fields.extrinsicPayloadValidators.map((e) => MetadataFormValidator.fromType(e))
    ].immutable;
    await _filedPayloadFields(address);
    return this;
  }

  @override
  TransactionOperations get operation => SubstrateTransactionOperations.extrinsic;

  @override
  List<LiveFormField<Object?, Object>> get fields => [page];

  @override
  void dispose() {
    super.dispose();
    for (final i in _extrinsicValidators) {
      i.dispose();
    }
    for (final i in _payloadValidators) {
      i.dispose();
    }
    _extrinsicValidators = [];
    _payloadValidators = [];
  }
}
