import 'dart:async';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/widgets/multisig.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

class SubstrateTransactionMultisigOperation
    extends SubstrateTransactionStateController<ISubstrateMiltisigTransactionData> {
  final SubstrateMultisigTransactionData? multisig;
  bool get immutable => multisig != null;
  @override
  bool get swtichAddressEnabled => !immutable;
  final TransactionResourceRequirementSubstrateMultisig resource =
      TransactionResourceRequirementSubstrateMultisig();

  List<MultisigCallPalletMethod> _availableMethods = [];
  List<MultisigCallPalletMethod> get availableMethods => _availableMethods;
  SubstrateTransactionMultisigOperation(
      {required super.walletProvider,
      required super.account,
      required super.address,
      this.multisig});
  IntegerBalance? _existentialDeposit;
  String? validateAccount(ISubstrateAddress address) {
    if (address.multiSigAccount) return null;
    return "please_choose_a_multisig_account".tr;
  }

  String get title {
    switch (multisigMethod.value) {
      case MultisigCallPalletMethod.asMulti:
        return "multisig_call_data".tr;
      default:
        return "multisig_call_hash".tr;
    }
  }

  String get subtitle {
    switch (multisigMethod.value) {
      case MultisigCallPalletMethod.asMulti:
        return "multisig_call_data_desc".tr;
      default:
        return "multisig_call_hash_desc".tr;
    }
  }

  final LiveFormField<MultisigCallPalletMethod, MultisigCallPalletMethod> multisigMethod =
      LiveFormField(
          title: "method_name".tr, value: MultisigCallPalletMethod.asMultiThreshold1);

  final LiveFormField<ISubstrateMultiSigAddress?, ISubstrateMultiSigAddress>
      multisigAccount = LiveFormField(title: "multisig_account".tr, value: null);

  late final LiveFormField<SubstrateMultisigCallData?, SubstrateMultisigCallData>
      callOrHash = LiveFormField(
    title: "call_data".tr,
    subtitle: "call_data_desc".tr,
    optional: false,
    value: null,
  );

  late final LiveFormField<SubstrateWeightV2?, SubstrateWeightV2> weight = LiveFormField(
      title: "weight".tr,
      subtitle: "transaction_weight_const".tr,
      optional: true,
      onValidateError: (field, value) {
        if (value != null) return null;
        switch (multisigMethod.value) {
          case MultisigCallPalletMethod.approveAsMulti:
          case MultisigCallPalletMethod.asMulti:
            return "field_is_required".tr.replaceOne(field.title);
          default:
        }
        return null;
      },
      value: null);

  Future<void> onFieldChanged() async {
    resource.clearState();
    final mSigAccount = multisigAccount.value;
    final hash = callOrHash.value;
    if (mSigAccount != null && hash != null) {
      await resource.getResource(
          client: client,
          callData: hash,
          address: mSigAccount.cast(),
          signer: address,
          method: multisigMethod.value,
          account: account);
      if (resource.status.isSuccess && !weight.hasValue) {
        weight.setValue(resource.value.callData.weight);
      }
      estimateFee();
    }
    onStateUpdated();
  }

  /// MultisigCallPalletMethod
  void onUpdateTransferMethod(MultisigCallPalletMethod? method) {
    if (immutable) return;
    if (method == null || method == multisigMethod.value) {
      return;
    }
    multisigMethod.setValue(method);
    final bool hasCall = callOrHash.value?.call.callData != null;
    if (!hasCall) {
      switch (method) {
        case MultisigCallPalletMethod.asMulti:
        case MultisigCallPalletMethod.approveAsMulti:
        case MultisigCallPalletMethod.asMultiThreshold1:
          callOrHash.setValue(null);
          break;
        default:
      }
    }
    onFieldChanged();
    onStateUpdated();
  }

  void onUpdateCallOrHash(SubstrateMultisigCallData? callOrHash) {
    if (callOrHash == null || immutable) return;
    this.callOrHash.setValue(callOrHash);
    onFieldChanged();
    onStateUpdated();
  }

  void onUpdateMultisignatureAccount(ISubstrateAddress? address) {
    if (immutable || address == null || !address.multiSigAccount) return;
    multisigAccount.setValue(address.cast());
    onFieldChanged();
    onStateUpdated();
  }

  void onUpdateWeight(SubstrateWeightV2? weight) {
    if (weight == null) return;
    this.weight.setValue(weight);
    onStateUpdated();
    estimateFee();
  }

  @override
  void onFeeUpdated(void _) {
    onStateUpdated();
  }

  @override
  Future<void> estimateFee() async {
    if (!fieldsReady || !resource.status.isSuccess) return;
    return super.estimateFee();
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;
    if (!resource.status.isSuccess) {
      return TransactionStateStatus.error(error: resource.error);
    }
    final feeToken = this.feeToken.value;

    final deposit = resource.value.depositAmount?.balance ?? BigInt.zero;
    BigInt r = address.addressData.currencyBalance - deposit;
    if (feeToken == null || feeToken.isNativeAsset) {
      r -= txFee.fee.fee.balance;
    }
    String? simulateError =
        txFee.fee.hasError ? "transaction_simulation_failed".tr : null;
    if (r.isNegative) {
      return TransactionStateStatus.insufficient(IntegerBalance.token(r, network.token),
          warning: simulateError);
    }
    if (feeToken != null && !feeToken.isNativeAsset) {
      final amount = feeToken.tokenDetails.balance.value.balance - txFee.fee.fee.balance;
      if (amount.isNegative) {
        return TransactionStateStatus.insufficient(
            IntegerBalance.token(amount, feeToken.token),
            warning: simulateError);
      }
    }
    // final feeAmount = txFee.fee.fee.balance;

    final existentialDeposit = _existentialDeposit;
    if (existentialDeposit != null) {
      if (r < existentialDeposit.balance) {
        return TransactionStateStatus.ready(
            warning: "account_will_be_deactivated_after_transaction".tr);
      }
    }

    return TransactionStateStatus.ready(warning: simulateError);
  }

  MultisigCallPallet _buildOperation() {
    final method = multisigMethod.value;
    final mSigAccount = multisigAccount.value!;
    final callData = resource.value;
    final callBytes = callData.callData.call.callData;
    final callHash = callData.callData.call.callHash;
    final signers = mSigAccount.multiSignatureAddress.signers;
    final otherSignatures = SubstrateAddressUtils.otherSignatories(
        addresses: signers, signer: address.networkAddress);
    final timepoint = resource.value.callData.multisig?.when;
    switch (method) {
      case MultisigCallPalletMethod.asMultiThreshold1:
        return MultisigCallPalletAsMultiThreshold1(
            otherSignatories: otherSignatures, call: callBytes!);
      case MultisigCallPalletMethod.asMulti:
        return MultisigCallPalletAsMulti(
            otherSignatories: otherSignatures,
            call: callBytes!,
            maxWeight: weight.value!,
            threshold: mSigAccount.multiSignatureAddress.threshold,
            maybeTimepoint: timepoint);
      case MultisigCallPalletMethod.approveAsMulti:
        return MultisigCallPalletApproveAsMulti(
            otherSignatories: otherSignatures,
            callHash: callHash,
            maxWeight: weight.value!,
            threshold: mSigAccount.multiSignatureAddress.threshold,
            maybeTimepoint: timepoint);
      case MultisigCallPalletMethod.pokeDeposit:
        return MultisigCallPalletPokeDeposit(
            otherSignatories: otherSignatures,
            callHash: callHash,
            threshold: mSigAccount.multiSignatureAddress.threshold);
      case MultisigCallPalletMethod.cancelAsMulti:
        return MultisigCallPalletCancelAsMulti(
            otherSignatories: otherSignatures,
            callHash: callHash,
            threshold: mSigAccount.multiSignatureAddress.threshold,
            timepoint: timepoint!);
    }
  }

  Future<SubstrateCallPallet> _toCalls(MultisigCallPallet operation) async {
    final memos = this.memos.value;
    final remarks =
        memos.map((e) => SystemCallPalletRemark(value: StringUtils.toBytes(e)));
    final calls = [operation, ...remarks];
    final bool batch = calls.length > 1;
    if (batch) {
      return UtilityCallPalletBatchAll(calls: calls);
    }
    return calls.first;
  }

  @override
  Future<ISubstrateTransaction<ISubstrateMiltisigTransactionData>> buildTransaction(
      {bool simulate = false}) async {
    final transactionData = await buildTransactionData(simulate: simulate);
    BigInt nonce = BigInt.zero;
    if (!simulate) {
      nonce = await getAccountNonce(address.networkAddress);
    }
    final blockInfo = await finalizeBlockWithEra();
    final List<int> genesis = metadata.genesisBytes();
    final call = await _toCalls(transactionData.call);
    final List<int> messageBytes =
        call.encodeCall(extrinsic: metadata.metadataWithExtrinsic());
    final extrinsic = DynamicExtrinsicBuilder(
        era: blockInfo.era,
        nonce: nonce,
        specVersion: metadata.runtimeVersion.specVersion,
        transactionVersion: metadata.runtimeVersion.transactionVersion,
        genesis: genesis,
        chargeAssetTxPayment: transactionData.feeAssetConfig?.feeId,
        mortality: blockInfo.blockHashBytes,
        metadataFields: metadata.extrinsic);
    final extraFields = extrinsic.encodeExtrinsicPayload(metadata.metadata);
    final List<int> encodeBytes = [...messageBytes, ...extraFields].asImmutableBytes;
    final extrinsicInfo = ExtrinsicPayloadInfo(
        serializedExtrinsic: encodeBytes, method: messageBytes, extrinsic: extrinsic);
    return ISubstrateTransaction(
        account: address, transactionData: transactionData, payload: extrinsicInfo);
  }

  @override
  Future<ISubstrateMiltisigTransactionData> buildTransactionData(
      {bool simulate = false}) async {
    final op = _buildOperation();
    return ISubstrateMiltisigTransactionData(
        fee: txFee.fee,
        call: op,
        address: multisigAccount.output,
        feeAssetConfig: feeToken.value?.feeConfig);
  }

  IWalletTransaction<SubstrateWalletTransaction, ISubstrateAddress>?
      _buildMultisigWalletTx(
          {required SubstrateWalletTransaction finalApprove,
          required ISubstrateMiltisigTransactionData transactionData}) {
    final call = transactionData.call;
    List<int>? methodBytes;
    switch (call.type) {
      case MultisigCallPalletMethod.approveAsMulti:
      case MultisigCallPalletMethod.pokeDeposit:
        return null;
      case MultisigCallPalletMethod.asMulti:
        methodBytes = call.cast<MultisigCallPalletAsMulti>().call;
        break;
      case MultisigCallPalletMethod.asMultiThreshold1:
        methodBytes = call.cast<MultisigCallPalletAsMultiThreshold1>().call;
        break;
      default:
    }
    if (methodBytes != null) {
      final decode = metadata.metadata.decodeCall(methodBytes);
      final operations = SubstrateKnownCallMethods.parseTxMethod(
          data: decode.toJson(), network: network);
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
      final tx = SubstrateWalletTransaction(
          block: finalApprove.block,
          txId: finalApprove.txId,
          network: network,
          totalOutput:
              WalletTransactionIntegerAmount(amount: totalAmount, network: network),
          outputs: outputs,
          extrinsics: finalApprove.extrinsics);

      return IWalletTransaction(transaction: tx, account: transactionData.address);
    }
    final tx = SubstrateWalletTransaction(
        block: finalApprove.block,
        txId: finalApprove.txId,
        network: network,
        totalOutput: null,
        outputs: [
          SubstrateWalletTransactionOperationOutput(name: transactionData.call.type.name)
        ],
        extrinsics: finalApprove.extrinsics);
    return IWalletTransaction(transaction: tx, account: transactionData.address);
  }

  @override
  Future<List<IWalletTransaction<SubstrateWalletTransaction, ISubstrateAddress>>>
      buildWalletTransaction(
          {required ISubstrateSignedTransaction<ISubstrateMiltisigTransactionData>
              signedTx,
          required SubmitSubstrateTransactionSuccess<ISubstrateMiltisigTransactionData>
              txId}) async {
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
    final multisigTx = _buildMultisigWalletTx(
        finalApprove: transaction, transactionData: signedTx.transaction.transactionData);
    return [
      IWalletTransaction(transaction: transaction, account: signedTx.transaction.account),
      if (multisigTx != null) multisigTx
    ];
  }

  @override
  Future<TransactionStateController> cloneController(ISubstrateAddress address) async {
    return SubstrateTransactionMultisigOperation(
        walletProvider: walletProvider,
        account: account,
        address: address,
        multisig: multisig);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return SubstrateTransactionMultisigOperationWidget(form: this);
  }

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required SubstrateNetworkClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await super.initForm(context: context, client: client, updateAccount: updateAccount);
    _availableMethods = metadata.multisigMethods();
    if (address.multiSigAccount) {
      throw WalletExceptionConst.featureUnavailableForMultiSignature;
    }
    if (_availableMethods.isEmpty) {
      throw AppExceptionConst.unsupportedNetworkFeature;
    }
    final multisig = this.multisig;
    if (multisig != null) {
      final update = await resource.setValue(
          client: client, info: multisig, signer: address, account: account);
      multisigAccount.setValue(update.address);
      if (_availableMethods.contains(update.method)) {
        multisigMethod.setValue(update.method);
      }
      weight.setValue(update.callData.weight);
      callOrHash.setValue(update.callData);
      estimateFee();
    }
    return this;
  }

  @override
  List<LiveFormField<Object?, Object>> get fields =>
      [callOrHash, multisigAccount, multisigMethod, weight];

  @override
  void dispose() {
    super.dispose();
    resource.dispose();
  }

  @override
  TransactionOperations get operation =>
      SubstrateTransactionOperations.multiSignatureOperation;
}
