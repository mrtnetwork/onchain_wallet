import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/substrate/substrate.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/chain_config.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

import 'xcm_types.dart';

enum SubstrateKnownCallMethodsType {
  transfer,
  remark,
  unknown;
}

abstract class SubstrateKnownCallMethods {
  final SubstrateKnownCallMethodsType type;
  const SubstrateKnownCallMethods(this.type);
  BigInt get value => BigInt.zero;
  String get name => type.name;
  static SubstrateKnownCallMethods _parseRemark(Map<String, dynamic> data) {
    try {
      return SubstrateRemarkMethod.fromJson(data);
    } catch (e) {
      final Map<String, dynamic>? methodData =
          StringUtils.tryToJson(data[SubtrateMetadataPallet.system.name]);
      return SubstrateUnknownMethod(
          methodName: methodData?.keys.firstOrNull, content: data);
    }
  }

  static SubstrateKnownCallMethods _parseTransafer(
      {required Map<String, dynamic> data, required WalletSubstrateNetwork network}) {
    try {
      return SubstrateTransferMethod.fromJson(data, network);
    } catch (e) {
      final Map<String, dynamic>? methodData =
          StringUtils.tryToJson(data[SubtrateMetadataPallet.balances.name]);
      return SubstrateUnknownMethod(
          methodName: methodData?.keys.firstOrNull, content: data);
    }
  }

  static List<SubstrateKnownCallMethods> _parseUtility(
      {required Map<String, dynamic> data, required WalletSubstrateNetwork network}) {
    try {
      if (data.containsKey(SubtrateMetadataPallet.utility.name)) {
        final List<Map<String, dynamic>>? r = StringUtils.tryToJson(
            MethodUtils.fallbackOnException(
                () => data[SubtrateMetadataPallet.utility.name]
                    ?[APPSubstrateConst.utilityBatchVariantName],
                logOnDebug: false));
        if (r != null) {
          return r
              .map((e) => parseTxMethod(data: e, network: network))
              .expand((e) => e)
              .toList();
        }
      }
    } catch (_) {}
    final Map<String, dynamic>? methodData =
        StringUtils.tryToJson(data[SubtrateMetadataPallet.utility.name]);
    return [
      SubstrateUnknownMethod(methodName: methodData?.keys.firstOrNull, content: data)
    ];
  }

  static List<SubstrateKnownCallMethods> parseTxMethod(
      {required Map<String, dynamic> data, required WalletSubstrateNetwork network}) {
    List<SubstrateKnownCallMethods> knownMethods = [];
    if (data.containsKey(SubtrateMetadataPallet.utility.name)) {
      final method = _parseUtility(data: data, network: network);
      knownMethods.addAll(method);
    } else if (data.containsKey(SubtrateMetadataPallet.system.name)) {
      final method = _parseRemark(data);
      knownMethods.add(method);
    } else if (data.containsKey(SubtrateMetadataPallet.balances.name)) {
      final method = _parseTransafer(data: data, network: network);
      knownMethods.add(method);
    } else {
      final Map<String, dynamic>? methodData = StringUtils.tryToJson(data.values.first);
      final method = SubstrateUnknownMethod(
          methodName: methodData?.keys.firstOrNull, content: methodData ?? data);
      knownMethods.add(method);
    }
    return knownMethods;
  }
}

class SubstrateRemarkMethod extends SubstrateKnownCallMethods {
  final String? content;
  final String data;
  const SubstrateRemarkMethod({required this.data, required this.content})
      : super(SubstrateKnownCallMethodsType.remark);
  factory SubstrateRemarkMethod.fromJson(Map<String, dynamic> json) {
    if (json.containsKey(SubtrateMetadataPallet.system.name)) {
      json = json[SubtrateMetadataPallet.system.name];
    }
    final String data = json[APPSubstrateConst.systemRemarkVariantName];
    return SubstrateRemarkMethod(
        data: data, content: StringUtils.tryDecode(BytesUtils.fromHexString(data)));
  }
}

class SubstrateTransferMethod extends SubstrateKnownCallMethods {
  final ReceiptAddress<BaseSubstrateAddress> receiver;
  final IntegerBalance amount;
  final BalancesCallPalletMethod transferType;
  SubstrateTransferMethod copyWith(
      {ReceiptAddress<BaseSubstrateAddress>? receiver,
      IntegerBalance? amount,
      BalancesCallPalletMethod? transferType}) {
    return SubstrateTransferMethod(
        receiver: receiver ?? this.receiver,
        amount: amount ?? this.amount,
        transferType: transferType ?? this.transferType);
  }

  @override
  BigInt get value => amount.balance;
  const SubstrateTransferMethod(
      {required this.receiver, required this.amount, required this.transferType})
      : super(SubstrateKnownCallMethodsType.transfer);
  factory SubstrateTransferMethod.fromJson(
      Map<String, dynamic> json, WalletSubstrateNetwork network) {
    Map<String, dynamic> data = json;
    if (data.containsKey(SubtrateMetadataPallet.balances.name)) {
      data = json[SubtrateMetadataPallet.balances.name];
    }
    BaseSubstrateAddress receiver;
    BalancesCallPalletMethod type = BalancesCallPalletMethod.transferAllowDeath;
    if (data.containsKey(BalancesCallPalletMethod.transferAllowDeath.method)) {
      data = data[BalancesCallPalletMethod.transferAllowDeath.method];
    } else {
      data = data[BalancesCallPalletMethod.transferKeepAlive.method];
      type = BalancesCallPalletMethod.transferKeepAlive;
    }
    if (network.coinParam.substrateChainType.isEthereum) {
      receiver =
          SubstrateEthereumAddress.fromBytes(BytesUtils.fromHexString(data["dest"]));
    } else {
      receiver = SubstrateAddress.fromBytes(BytesUtils.fromHexString(data["dest"]!["Id"]),
          ss58Format: network.coinParam.ss58Format);
    }
    return SubstrateTransferMethod(
        receiver: ReceiptAddress(view: receiver.address, networkAddress: receiver),
        amount: IntegerBalance.token(BigintUtils.parse(data["value"]), network.token,
            allowNegative: false, immutable: true),
        transferType: type);
  }
}

class SubstrateUnknownMethod extends SubstrateKnownCallMethods {
  final Map<String, dynamic> content;
  final String? methodName;
  const SubstrateUnknownMethod({required this.content, required this.methodName})
      : super(SubstrateKnownCallMethodsType.unknown);
  @override
  String get name => methodName ?? type.name;
}

class SubstrateTokenDetails with Equality {
  final BaseSubstrateNetworkAsset internalAsset;
  final SubstrateToken? asset;
  final StreamValue<IntegerBalance> balance;
  bool get isNativeAsset => asset == null;
  const SubstrateTokenDetails({
    required this.internalAsset,
    required this.asset,
    required this.balance,
  });
  Token get token => balance.value.token;

  @override
  List get variables => [internalAsset, isNativeAsset];
}

class SubstrateTransferToken {
  final List<SubstrateCallPalletTransferMethod> transferMethod;
  final SubstrateTokenDetails tokenDetails;
  final SubstrateFeeConfig? feeConfig;
  bool get isNativeAsset => tokenDetails.isNativeAsset;
  Token get token => tokenDetails.token;
  const SubstrateTransferToken(
      {required this.tokenDetails, required this.transferMethod, this.feeConfig});
}

class SubstrateTransferDetails with DisposableMixin, StreamStateController {
  SubstrateTransferToken _token;
  SubstrateTransferToken get token => _token;
  IntegerBalance _amount;
  IntegerBalance get amount => _amount;
  final ReceiptAddress<BaseSubstrateAddress> recipient;
  bool get hasAmount => amount.largerThanZero;
  bool get isReady => hasAmount;
  SubstrateCallPalletTransferMethod? _method;
  SubstrateCallPalletTransferMethod? get method => _method;
  SubstrateTransferDetails({
    required this.recipient,
    required SubstrateTransferToken token,
  })  : _amount = IntegerBalance.zero(token.token, allowNegative: false),
        _token = token,
        _method = token.transferMethod.firstOrNull;

  void onUpdateStatus() {
    notify();
  }

  void onUpdateTransferMethod(SubstrateCallPalletTransferMethod method) {
    assert(token.transferMethod.contains(method));
    _method = method;
    onUpdateStatus();
  }

  void onUpdateBalance(BigInt amount) {
    assert(!amount.isNegative, "Invalid transfer amount.");
    if (amount.isNegative) return;
    this.amount.updateBalance(amount);
    onUpdateStatus();
  }

  void onUpdateToken(SubstrateTransferToken token) {
    _token = token;
    _method = token.transferMethod.firstOrNull;
    _amount = IntegerBalance.zero(token.token, allowNegative: false);
    onUpdateStatus();
    // SubstrateTransferToken
  }

  Future<SubstrateCallPallet> createCall(
      {required MetadataWithProvider metadata,
      required BaseSubstrateAddress owner,
      BaseSubstrateNetworkController? controller}) async {
    final transfer = SubstrateLocalTransferAssetParams(
        asset: token.tokenDetails.internalAsset,
        amount: amount.balance,
        method: method?.method,
        destinationAddress: recipient.networkAddress);
    if (token.isNativeAsset && controller == null) {
      return SubstrateNetworkControllerLocalAssetTransferBuilder.createLocalTransfer(
              params: transfer, metadata: metadata.metadata)
          .transfer;
    }
    if (controller == null) {
      throw AppInternalError.internalError("SubstrateTransferDetails.createCall");
    }
    final assetTransfer = await controller.assetTransfer(params: transfer);
    return assetTransfer.transfer;
  }
}

enum SubstrateTransactionOperations implements TransactionOperations {
  transfer("transfer"),
  extrinsic("extrinsic"),
  multiSignatureOperation("multisig_operations"),
  xcmTransfer("xcm_transfer");

  @override
  final String value;
  const SubstrateTransactionOperations(this.value);
}

class SubstrateTransactionAssetFee {
  final SubstrateFeeConfig config;
  final IntegerBalance? convertedAmount;
  SubstrateTransactionAssetFee({required this.config, BigInt? amount})
      : convertedAmount = amount == null
            ? null
            : IntegerBalance.token(amount, config.token,
                allowNegative: false, immutable: true);
  bool get success => convertedAmount != null;
}

class SubstrateTransactionFee extends DefaultTransactionFee {
  final SubstrateWeightV2? weight;
  final SubstrateDispatchResult<CallDryRunEffects>? dryRun;
  final Map<String, dynamic> dryRunInfo;
  final SubstrateTransactionAssetFee? assetFeeInfo;
  final bool isSimulate;
  final IntegerBalance? xcmDeliveriesFee;
  late final bool dryRunSuccess =
      dryRun == null ? true : (dryRun?.ok?.executionResult.type.isOk ?? false);

  SubstrateTransactionFee copyWith(
      {SubstrateWeightV2? weight,
      SubstrateDispatchResult<CallDryRunEffects>? dryRun,
      SubstrateTransactionAssetFee? assetFeeInfo,
      bool? isSimulate,
      String? error,
      IntegerBalance? fee,
      IntegerBalance? xcmDeliveriesFee}) {
    return SubstrateTransactionFee(
        fee: fee ?? this.fee,
        isSimulate: isSimulate ?? this.isSimulate,
        weight: weight ?? this.weight,
        dryRun: dryRun ?? this.dryRun,
        assetFeeInfo: assetFeeInfo ?? this.assetFeeInfo,
        error: error ?? this.error,
        xcmDeliveriesFee: xcmDeliveriesFee ?? this.xcmDeliveriesFee);
  }

  SubstrateTransactionFee(
      {required super.fee,
      required this.isSimulate,
      this.weight,
      this.dryRun,
      this.xcmDeliveriesFee,
      this.assetFeeInfo,
      super.error})
      : dryRunInfo = dryRun?.toJson() ?? {};
  factory SubstrateTransactionFee.init(Token token, {String? error}) {
    return SubstrateTransactionFee(
        fee: IntegerBalance.zero(token), isSimulate: false, error: error);
  }
  factory SubstrateTransactionFee.fromFeeDetails(
      {required WalletSubstrateNetwork network,
      required QueryFeeInfo info,
      required SubstrateDispatchResult<CallDryRunEffects>? dryRun,
      SubstrateTransactionAssetFee? assetFeeInfo}) {
    final BigRational totalFee = BigRational(info.partialFee);
    IntegerBalance fee = IntegerBalance.token(
        (totalFee * APPSubstrateConst.feeRate).toBigInt(), network.token);

    if (assetFeeInfo != null) {
      fee =
          assetFeeInfo.convertedAmount ?? IntegerBalance.zero(assetFeeInfo.config.token);
    }
    return SubstrateTransactionFee(
        fee: fee,
        isSimulate: true,
        weight: info.weight,
        dryRun: dryRun,
        assetFeeInfo: assetFeeInfo);
  }

  @override
  List get variables => [...super.variables, fee, isSimulate, xcmDeliveriesFee];
}

class SubstrateTransactionFeeData
    extends TransactionDefaultFeeData<SubstrateTransactionFee> {
  SubstrateTransactionFeeData({required super.select, required super.feeToken});
}

abstract class BaseSubstrateTransactionController<T extends ISubstrateTransactionData>
    extends TransactionStateController<
        SubstrateToken,
        WalletSubstrateNetwork,
        ISubstrateAddress,
        SubstrateNetworkClient,
        SubstrateChain,
        T,
        ISubstrateTransaction<T>,
        ISubstrateSignedTransaction<T>,
        SubstrateWalletTransaction,
        SubmitSubstrateTransactionSuccess<T>,
        SubstrateTransactionFeeData>
    with
        ChainConfigStateController<SubstrateChain, SubstrateChainConfig,
            SubstrateNetworkController> {
  BaseSubstrateTransactionController(
      {required super.walletProvider, required super.account, required super.address});
}

class ISubstrateTransactionData extends ITransactionData {
  final SubstrateTransactionFee fee;
  final SubstrateFeeConfig? feeAssetConfig;

  final List<ISubstrateTransactionDataTokenTransfer>? payment;
  ISubstrateTransactionData(
      {required this.fee,
      required this.feeAssetConfig,
      List<ISubstrateTransactionDataTokenTransfer>? payment})
      : payment = payment?.immutable;
}

class SubstrateXCMTransferEncodedParamsWithControllers {
  final SubstrateXCMTransferEncodedParams xcmParams;
  final BaseSubstrateNetworkController origin;
  final BaseSubstrateNetworkController destination;
  SubstrateXCMTransferEncodedParamsWithControllers(
      {required this.origin, required this.destination, required this.xcmParams});
}

class ISubstrateXCMTransactionData extends ISubstrateTransactionData {
  final SubstrateXCMTransferEncodedParamsWithControllers xcmParams;
  final SubstrateChain destination;
  ISubstrateXCMTransactionData(
      {required super.fee,
      required super.feeAssetConfig,
      required this.xcmParams,
      required this.destination,
      super.payment});
}

class ISubstrateMiltisigTransactionData extends ISubstrateTransactionData {
  final MultisigCallPallet call;
  final ISubstrateMultiSigAddress address;

  ISubstrateMiltisigTransactionData(
      {required super.fee,
      required super.feeAssetConfig,
      required this.call,
      required this.address});
}

class ISubstrateTransactionDataTokenTransfer {
  final BaseSubstrateAddress recipient;
  final BigInt amount;
  final SubstrateToken? token;
  const ISubstrateTransactionDataTokenTransfer(
      {required this.recipient, required this.amount, this.token});
}

class SubstrateFeeConfig {
  final Token token;
  final Object feeId;
  final XCMVersionedLocation baseFee;
  final XCMAssetId assetLocation;
  const SubstrateFeeConfig(
      {required this.feeId,
      required this.baseFee,
      required this.token,
      required this.assetLocation});
}

class SubstrateEstimateTransaction {
  final ExtrinsicInfo extrinsic;
  final SubstrateFeeConfig? fee;
  final BaseSubstrateAddress owner;
  const SubstrateEstimateTransaction(
      {required this.extrinsic, this.fee, required this.owner});
}

class ISubstrateTransaction<T extends ISubstrateTransactionData>
    extends ITransaction<T, ISubstrateAddress> {
  final ExtrinsicPayloadInfo payload;
  const ISubstrateTransaction(
      {required super.account, required super.transactionData, required this.payload});
}

class ISubstrateSignedTransaction<T extends ISubstrateTransactionData>
    extends ISignedTransaction<ISubstrateTransaction<T>, ExtrinsicInfo> {
  ISubstrateSignedTransaction(
      {required super.transaction,
      required super.signatures,
      required super.finalTransactionData});
}

class SubstrateSignedTransaction {
  final List<List<int>> signatures;
  final List<int> payload;
  SubstrateSignedTransaction(
      {required List<List<int>> signatures, required List<int> payload})
      : signatures = signatures.map((e) => e.asImmutableBytes).toImutableList,
        payload = payload.asImmutableBytes;
}

class SubstrateMultisigTransactionData {
  final SubstrateMultisigCallData callData;
  final bool needTimepoint;
  final bool needWeight;
  final MultisigCallPalletMethod method;
  final ISubstrateMultiSigAddress address;
  final IntegerBalance? depositAmount;
  SubstrateMultisigTransactionData copyWith({
    SubstrateMultisigCallData? callData,
    bool? needTimepoint,
    bool? needWeight,
    MultisigCallPalletMethod? method,
    ISubstrateMultiSigAddress? address,
    IntegerBalance? depositAmount,
  }) {
    return SubstrateMultisigTransactionData._(
      needTimepoint: needTimepoint ?? this.needTimepoint,
      needWeight: needWeight ?? this.needWeight,
      callData: callData ?? this.callData,
      method: method ?? this.method,
      address: address ?? this.address,
      depositAmount: depositAmount ?? this.depositAmount,
    );
  }

  SubstrateMultisigTransactionData._({
    required this.needTimepoint,
    required this.needWeight,
    required this.callData,
    required this.method,
    required this.address,
    required this.depositAmount,
  });

  factory SubstrateMultisigTransactionData({
    required SubstrateMultisigCallData callData,
    required MultisigCallPalletMethod method,
    required ISubstrateMultiSigAddress address,
    IntegerBalance? depositAmount,
  }) {
    bool needWeight = false;
    bool needTimepoint = true;
    switch (method) {
      case MultisigCallPalletMethod.cancelAsMulti:
        needWeight = false;
        needTimepoint = true;
        break;
      case MultisigCallPalletMethod.pokeDeposit:
        needWeight = false;
        needTimepoint = false;
        break;
      case MultisigCallPalletMethod.asMulti:
        needWeight = true;
        needTimepoint = true;
        break;
      case MultisigCallPalletMethod.approveAsMulti:
        needWeight = true;
        needTimepoint = callData.multisig != null;
        break;
      case MultisigCallPalletMethod.asMultiThreshold1:
        needWeight = false;
        needTimepoint = false;
        break;
    }
    return SubstrateMultisigTransactionData._(
        needTimepoint: needTimepoint,
        needWeight: needWeight,
        callData: callData,
        method: method,
        depositAmount: depositAmount,
        address: address);
  }
}

class TransactionResourceRequirementSubstrateMultisig
    with DisposableMixin, StreamStateController
    implements TransactionResourceRequirement<SubstrateMultisigTransactionData> {
  final lock = SafeAtomicLock();
  final Cancelable _cancelable = Cancelable();
  TransactionResourceRequirementSubstrateMultisig();
  TransactionResourceRequirementFetchStatus _status =
      TransactionResourceRequirementFetchStatus.idle;
  @override
  TransactionResourceRequirementFetchStatus get status => _status;
  SubstrateMultisigTransactionData? _value;
  @override
  SubstrateMultisigTransactionData get value => _value!;
  String? _error;
  @override
  String? get error => _error;
  void clearState() {
    _cancelable.cancel();
    _status = TransactionResourceRequirementFetchStatus.idle;
    _error = null;
    _value = null;
    notify();
  }

  void _setResource(SubstrateMultisigTransactionData value) {
    assert(_status != TransactionResourceRequirementFetchStatus.success);
    _error = null;
    _value = value;
    _status = TransactionResourceRequirementFetchStatus.success;
    notify();
  }

  void _setError({String? error}) {
    assert(_status == TransactionResourceRequirementFetchStatus.pending);
    _error = error;
    _status = TransactionResourceRequirementFetchStatus.failed;
    notify();
  }

  void _setPendig() {
    _status = TransactionResourceRequirementFetchStatus.pending;
    notify();
  }

  Future<SubstrateMultisigTransactionData> setValue(
      {required SubstrateNetworkClient client,
      required SubstrateMultisigTransactionData info,
      required ISubstrateAddress signer,
      required SubstrateChain account}) async {
    if (_status.canRetry) _setPendig();

    final address = info.address;
    final callBytes = info.callData.call.callData;
    SubstrateWeightV2? weight = info.callData.weight;
    if (callBytes != null) {
      final fee = await IResult.call(() async => client.callQueryInfo(
          call: callBytes,
          owner: address.networkAddress,
          fakeSignatureAlgorithm: SubstrateKeyAlgorithm.ecdsa));
      assert(fee.isOk, "estimate fialed: ${fee.err()?.localizationError}");
      weight = fee.ok()?.weight;
    }
    final method = info.method;
    final value = info.callData.multisig;
    final int approvals = value?.approvals.length ?? 0;
    final threshold = address.multiSignatureAddress.threshold;
    final signerRawAddress = signer.networkAddress.toHex();
    bool signed =
        value?.approvals.any((e) => StringUtils.hexEqual(e.toHex(), signerRawAddress)) ??
            false;
    IntegerBalance? depositAmount;
    String? error;
    switch (method) {
      case MultisigCallPalletMethod.asMulti:
        if (value == null) {
          error = "transaction_not_found".tr;
        } else if (approvals + 1 < threshold) {
          error = "transaction_not_ready_for_execution".tr.replaceOne(method.name);
        } else if (signed) {
          error = "your_account_approved_transaction".tr;
        } else if (threshold == 1) {
          error = "unsupported_multisig_account_operation".tr.replaceOne(method.name);
        }
        break;
      case MultisigCallPalletMethod.approveAsMulti:
        if (value == null) {
          final deposit = SubstrateUtils.multisigDepositAmount(
              baseDeposit: client.metadata.baseDeposit ?? BigInt.zero,
              depositFactor: client.metadata.depositFactor ?? BigInt.zero,
              signers: address.multiSignatureAddress.signers.length);
          depositAmount = IntegerBalance.token(deposit, account.network.token);
        }
        if (threshold == 1) {
          error = "unsupported_multisig_account_operation".tr.replaceOne(method.name);
        } else if (value != null) {
          if (signed) {
            error = "your_account_approved_transaction".tr;
          }
        } // 2008800000
        break;
      case MultisigCallPalletMethod.asMultiThreshold1:
        if (threshold != 1) {
          error = "unsupported_multisig_account_operation".tr.replaceOne(method.name);
        }
        break;
      case MultisigCallPalletMethod.pokeDeposit:
      case MultisigCallPalletMethod.cancelAsMulti:
        if (value == null) {
          error = "transaction_not_found".tr;
        }
        break;
    }
    if (error != null) {
      _setError(error: error);
      return info;
    } else {
      final update = info.copyWith(
          callData: info.callData.copyWith(weight: weight), depositAmount: depositAmount);
      _setResource(update);
      return update;
    }
  }

  Future<void> getResource(
      {required SubstrateNetworkClient client,
      required SubstrateChain account,
      required ISubstrateMultiSigAddress address,
      required MultisigCallPalletMethod method,
      required ISubstrateAddress signer,
      required SubstrateMultisigCallData callData}) async {
    _setPendig();
    final result = await IResult.call(() async =>
        await client.getMultisig(call: callData.call, address: address.networkAddress));
    if (result.err()?.canceled() ?? false) return;
    if (result.isErr) {
      _setError(error: result.unwrapErr().localizationError);
      return;
    }
    await setValue(
        client: client,
        signer: signer,
        account: account,
        info: SubstrateMultisigTransactionData(
            callData: result.unwrap(), method: method, address: address));
  }
}

class SubmitSubstrateTransactionSuccess<T extends ISubstrateTransactionData>
    extends SubmitTransactionSuccess<ISubstrateSignedTransaction<T>> {
  final List<IWalletTransaction<SubstrateWalletTransaction, ISubstrateAddress>> txes;
  final SubmitedXCMTransferDestinationTracker? xcmTransferDestinationTracker;
  SubmitSubstrateTransactionSuccess(
      {required super.signedTransaction,
      required super.txId,
      this.xcmTransferDestinationTracker,
      List<IWalletTransaction<SubstrateWalletTransaction, ISubstrateAddress>> txes =
          const [],
      super.warning,
      super.block})
      : txes = txes.immutable;
}
