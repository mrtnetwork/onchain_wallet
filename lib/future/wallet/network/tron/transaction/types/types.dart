import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain/tron/tron.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/tron/tron.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class TronTransactionOperations with Equality implements TransactionOperations {
  factory TronTransactionOperations.fromTransactionType(TransactionContractType type) {
    return TronTransactionOperations._(type.name);
  }

  @override
  final String value;
  const TronTransactionOperations._(this.value);

  @override
  List get variables => [value];
}

class TronTransactionFee extends DefaultTransactionFee {
  TronTransactionFee._({
    required this.burnBandwidth,
    required this.burnEnergy,
    required this.consumedBandwidth,
    required this.connsumedEnergy,
    required this.totalBurn,
    required this.burnedForResource,
    required super.fee,
    super.error,
    this.isSimulate = false,
  });
  final bool isSimulate;
  final int burnBandwidth;
  final int burnEnergy;
  final int consumedBandwidth;
  final int connsumedEnergy;

  late final int stackedBandWidth = consumedBandwidth - burnBandwidth;
  late final int stackedEnergy = connsumedEnergy - burnEnergy;
  final IntegerBalance burnedForResource;
  final IntegerBalance totalBurn;
  TronTransactionFee setCustomFeeLimit({IntegerBalance? customFeeLimit}) {
    return TronTransactionFee._(
        burnBandwidth: burnBandwidth,
        burnedForResource: burnedForResource,
        burnEnergy: burnEnergy,
        consumedBandwidth: consumedBandwidth,
        connsumedEnergy: connsumedEnergy,
        totalBurn: totalBurn,
        fee: fee,
        isSimulate: isSimulate);
  }

  factory TronTransactionFee.defaultFee({required Token feeToken, String? error}) {
    return TronTransactionFee._(
        burnBandwidth: 0,
        burnEnergy: 0,
        consumedBandwidth: 0,
        connsumedEnergy: 0,
        totalBurn: IntegerBalance.zero(feeToken),
        burnedForResource: IntegerBalance.zero(feeToken),
        fee: IntegerBalance.zero(feeToken),
        error: error);
  }
  factory TronTransactionFee.calculate(
      {required TransactionRaw raw,
      required TronChainParameters chainParameters,
      required TronAccountResourceInfo? resource,
      required WalletTronNetwork network,
      int signature = 1,
      bool isNewAccount = false,
      int consumedEnergy = 0,
      bool hasMemo = false}) {
    final tr = Transaction(
        rawData: raw,
        signature: List.generate(
            signature, (index) => List<int>.filled(TronUtils.signatureLength, 1)));
    final BigInt transactionFee = BigInt.from(chainParameters.getTransactionFee!);
    final size = tr.length + TronUtils.tronFeeRequiredSize;
    BigInt totalBurn = BigInt.zero;
    BigInt energy = BigInt.from(consumedEnergy);
    BigInt bandWidth = BigInt.from(size);
    BigInt burnedForResource = BigInt.zero;
    if (isNewAccount) {
      burnedForResource += BigInt.from(chainParameters.getCreateAccountFee!);
      totalBurn += BigInt.from(chainParameters.getCreateNewAccountFeeInSystemContract!);
    }
    if (hasMemo) {
      totalBurn += BigInt.from(chainParameters.getMemoFee!);
    }
    if (signature > 1) {
      totalBurn += BigInt.from(chainParameters.getMultiSignFee!);
    }
    switch (raw.contract.first.type) {
      case TransactionContractType.assetIssueContract:
        totalBurn += chainParameters.getAssetIssueFee!;
        break;
      case TransactionContractType.accountPermissionUpdateContract:
        totalBurn += chainParameters.getUpdateAccountPermissionFee!;
        break;
      case TransactionContractType.witnessCreateContract:
        totalBurn += chainParameters.getAccountUpgradeCost!;
        break;
      default:
    }
    final resourceEnergy = resource?.howManyEnergy ?? BigInt.zero;
    final resourceBandWidth = resource?.howManyBandwIth ?? BigInt.zero;
    energy = energy - resourceEnergy;
    if (energy.isNegative) {
      energy = BigInt.zero;
    }

    final BigInt consumedBandwidth = bandWidth;
    if (resourceBandWidth > bandWidth && signature == 1) {
      bandWidth = BigInt.zero;
    }
    final totalBandWidth = bandWidth;
    totalBurn += totalBandWidth * transactionFee;
    totalBurn += burnedForResource;
    totalBurn += energy * BigInt.from(chainParameters.getEnergyFee!);
    final fee = IntegerBalance.token(totalBurn, network.token);
    return TronTransactionFee._(
        burnBandwidth: totalBandWidth.toInt(),
        burnEnergy: energy.toInt(),
        consumedBandwidth: consumedBandwidth.toInt(),
        connsumedEnergy: consumedEnergy,
        totalBurn: fee,
        burnedForResource: IntegerBalance.token(burnedForResource, network.token),
        fee: fee,
        isSimulate: true);
  }

  @override
  bool get hasFee => isSimulate;
  @override
  List get variables => [
        ...super.variables,
        isSimulate,
        burnBandwidth,
        burnEnergy,
        consumedBandwidth,
        connsumedEnergy
      ];
}

class TronTransactionFeeData extends TransactionDefaultFeeData<TronTransactionFee> {
  TronTransactionFeeData({required super.select, required super.feeToken});
}

abstract class BaseTronTransactionController<T extends ITronTransactionData>
    extends TransactionStateController<
        TronToken,
        WalletTronNetwork,
        ITronAddress,
        TronClient,
        TronChain,
        T,
        ITronTransaction<T>,
        ITronSignedTransaction<T>,
        TronWalletTransaction,
        SubmitTransactionSuccess<ITronSignedTransaction<T>>,
        TronTransactionFeeData> {
  TransactionContractType get transactionType;
  late final bool isTriggerSmartContract =
      transactionType == TransactionContractType.triggerSmartContract;
  @override
  late final TransactionOperations operation =
      TronTransactionOperations.fromTransactionType(transactionType);

  BaseTronTransactionController(
      {required super.walletProvider, required super.account, required super.address});
}

class TronSignedTransaction {
  final List<List<int>> signatures;
  final Transaction transaction;
  final TronBaseContract contract;
  TronSignedTransaction(
      {required List<List<int>> signatures,
      required this.transaction,
      required this.contract})
      : signatures = signatures.map((e) => e.asImmutableBytes).toImutableList;
}

class TransactionResourceRequirementTronDelegatedResource
    with DisposableMixin, StreamStateController
    implements TransactionResourceRequirement<DelegatedAccountResourceInfo?> {
  final lock = SafeAtomicLock();
  final ReceiptAddress<TronAddress> address;
  TransactionResourceRequirementTronDelegatedResource(this.address);
  TransactionResourceRequirementFetchStatus _status =
      TransactionResourceRequirementFetchStatus.idle;
  @override
  TransactionResourceRequirementFetchStatus get status => _status;
  DelegatedAccountResourceInfo? _value;
  @override
  DelegatedAccountResourceInfo? get value => _value;
  String? _error;
  @override
  String? get error => _error;

  void setResource(DelegatedAccountResourceInfo value) {
    assert(_status != TransactionResourceRequirementFetchStatus.success);
    _error = null;
    _value = value;
    _status = TransactionResourceRequirementFetchStatus.success;
    notify();
  }

  void setError({String? error}) {
    assert(_status == TransactionResourceRequirementFetchStatus.pending);
    _error = error;
    _status = TransactionResourceRequirementFetchStatus.failed;
    notify();
  }

  void setPendig() {
    assert(_status.canRetry);
    _status = TransactionResourceRequirementFetchStatus.pending;
    notify();
  }
}

class ITronTransactionDataRequirment {
  final List<int> refBlockBytes;
  final List<int> refBlockHash;
  final BigInt expiration;
  final BigInt timestamp;

  ITronTransactionDataRequirment({
    required List<int> refBlockBytes,
    required List<int> refBlockHash,
    required this.expiration,
    required this.timestamp,
  })  : refBlockBytes = refBlockBytes.asImmutableBytes,
        refBlockHash = refBlockHash.asImmutableBytes;
}

class ITronTransactionDataTokenTransfer {
  final TronAddress recipient;
  final BigInt amount;
  final TronToken? token;
  ITronTransactionDataTokenTransfer(
      {required this.recipient, required this.amount, this.token});
}

class ITronTransactionData<T extends TronBaseContract> extends ITransactionData {
  final TronTransactionFee fee;
  final T contract;
  final ITronTransactionDataRequirment blockData;
  final BigInt? feeLimit;
  final String? memo;
  final ITronTransactionDataTokenTransfer? tokenTransfer;
  ITronTransactionData({
    required this.fee,
    required this.contract,
    required this.blockData,
    this.feeLimit,
    required this.memo,
    this.tokenTransfer,
  });

  WalletTransactionMemo? getMemo() {
    final memo = this.memo;
    if (memo == null) return null;
    return WalletTransactionMemo.from(
        memo,
        switch (StringUtils.isHexBytes(memo)) {
          true => WalletTransactionMemoType.binary,
          false => WalletTransactionMemoType.string,
        });
  }
}

class ITronTransaction<TXDATA extends ITronTransactionData>
    extends ITransaction<TXDATA, ITronAddress> {
  final TransactionRaw transaction;
  const ITronTransaction(
      {required super.account,
      required super.transactionData,
      required this.transaction});
}

class ITronSignedTransaction<TXDATA extends ITronTransactionData>
    extends ISignedTransaction<ITronTransaction<TXDATA>, Transaction> {
  ITronSignedTransaction(
      {required super.transaction,
      required super.signatures,
      required super.finalTransactionData});
}

class TronSimulateTransaction {
  final TransactionRaw transaction;
  final int totalSigners;
  final TronAccountResourceInfo accountResource;
  const TronSimulateTransaction(
      {required this.transaction,
      required this.totalSigners,
      required this.accountResource});
}
