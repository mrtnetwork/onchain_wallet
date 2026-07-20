import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/types/operations.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:stellar_dart/stellar_dart.dart';

class StellarPickedIssueAsset {
  final StellarAsset asset;
  final Token token;
  final String? issuer;
  final StellarIssueToken? issueToken;
  StellarPickedIssueAsset._({
    required this.asset,
    required this.token,
    this.issuer,
    this.issueToken,
    IntegerBalance? tokenBalance,
  }) : tokenBalance = tokenBalance ?? issueToken?.balance;
  Token get currentToken => issueToken?.token ?? token;
  final IntegerBalance? tokenBalance;

  factory StellarPickedIssueAsset(
      {required StellarAsset asset,
      required WalletStellarNetwork network,
      required StellarIssueToken? issueToken,
      IntegerBalance? tokenBalance}) {
    switch (asset.type) {
      case AssetType.creditAlphanum4:
        final assetCode4 = asset.cast<StellarAssetCreditAlphanum4>();
        return StellarPickedIssueAsset._(
            asset: asset,
            issueToken: issueToken,
            token: Token(
                name: assetCode4.code,
                symbol: assetCode4.code,
                decimal: network.coinParam.decimal),
            issuer: assetCode4.issuer.toAddress().toString(),
            tokenBalance: tokenBalance);
      case AssetType.creditAlphanum12:
        final assetCode12 = asset.cast<StellarAssetCreditAlphanum12>();
        return StellarPickedIssueAsset._(
            asset: asset,
            token: Token(
                name: assetCode12.code,
                symbol: assetCode12.code,
                decimal: network.coinParam.decimal),
            issuer: assetCode12.issuer.toAddress().baseAddress,
            issueToken: issueToken,
            tokenBalance: tokenBalance);
      case AssetType.poolShare:
        final pool = asset.cast<StellarAssetPoolShare>();
        final poolId = BytesUtils.toHexString(pool.poolID);
        return StellarPickedIssueAsset._(
            asset: asset,
            token:
                Token(name: poolId, symbol: poolId, decimal: network.coinParam.decimal),
            issuer: poolId,
            issueToken: issueToken,
            tokenBalance: tokenBalance);
      case AssetType.native:
        return StellarPickedIssueAsset._(
            asset: asset,
            token: network.token,
            issueToken: issueToken,
            tokenBalance: tokenBalance);
      default:
        throw WalletExceptionConst.unsuportedFeature;
    }
  }
}

enum AccountReceivementStatus {
  idle,
  pending,
  active,
  error,
  inactive;

  bool get canTry => this == idle || this == error;
  bool get canUpdateStatus => this != active && this != inactive;
  bool get isInactive => this == inactive;
  bool get isActive => this == active;
  bool get isError => this == error;
  bool get isPending => this == pending;
}

class StellarReceiptWithActivityStatus {
  StellarReceiptWithActivityStatus(this.address);
  AccountReceivementStatus _status = AccountReceivementStatus.idle;
  AccountReceivementStatus get status => _status;
  StellarAccountResponse? get accountInfo => _accountInfo;
  StellarAccountResponse? _accountInfo;
  String? _error;
  String? get error => _error;
  bool get hasError => _error != null;

  void setError(String? err) {
    _error = err;
  }

  void setStatus(AccountReceivementStatus status, {StellarAccountResponse? accountInfo}) {
    if (!this.status.canUpdateStatus) return;
    assert(
        (!status.isActive && accountInfo == null) ||
            (status.isActive && accountInfo != null),
        "Update status must be contain a valid account info.");
    _accountInfo = accountInfo;
    _status = status;
  }

  void setPending() {
    if (!status.canTry) return;
    _status = AccountReceivementStatus.pending;
  }

  final ReceiptAddress<StellarAddress> address;
}

class StellarMemoDetils {
  final StellarMemo memo;
  final String? val;
  const StellarMemoDetils._(this.memo, this.val);
  factory StellarMemoDetils(StellarMemo memo) {
    String? val;
    switch (memo.type) {
      case MemoType.text:
        val = (memo.cast<StellarMemoText>()).text;
        break;
      case MemoType.hash:
        val = BytesUtils.toHexString((memo.cast<StellarMemoHash>()).hash, prefix: "0x");
        break;
      case MemoType.returnHash:
        val = BytesUtils.toHexString((memo.cast<StellarMemoReturnHash>()).hash,
            prefix: "0x");
        break;
      case MemoType.id:
        val = (memo.cast<StellarMemoID>()).id.toString();
        break;
      default:
    }
    return StellarMemoDetils._(memo, val);
  }
}

enum TransactiomTimeBoundType {
  manual,
  auto,
  none;

  bool get isManual => this == manual;
}

class TransactionTimeBound {
  final TransactiomTimeBoundType type;
  final DateTime? time;
  const TransactionTimeBound._({required this.type, this.time});
  const TransactionTimeBound.auto()
      : type = TransactiomTimeBoundType.auto,
        time = null;
  factory TransactionTimeBound({required TransactiomTimeBoundType type, DateTime? time}) {
    if (type.isManual && time == null) {
      throw AppInternalError.internalError("TransactionTimeBound");
    }
    if (!type.isManual && time != null) {
      throw AppInternalError.internalError("TransactionTimeBound");
    }
    return TransactionTimeBound._(type: type, time: time);
  }

  bool get isExpired {
    if (!type.isManual) return false;
    return time!.isBefore(DateTime.now().toLocal());
  }

  Preconditions condition() {
    final DateTime time =
        this.time?.toUtc() ?? DateTime.now().toUtc().add(StellarConst.defaultTimeBound);
    final secondsEpoch = DateTimeUtils.secondsSinceEpoch(time);
    return switch (type) {
      TransactiomTimeBoundType.none => const PrecondNone(),
      _ =>
        PrecondTime(TimeBounds(minTime: BigInt.zero, maxTime: BigInt.from(secondsEpoch))),
    };
  }
}

class StellarTransactionOperations with Equality implements TransactionOperations {
  static const StellarTransactionOperations transfer =
      StellarTransactionOperations._("transfer");

  @override
  final String value;
  const StellarTransactionOperations._(this.value);

  @override
  List get variables => [value];
}

class StellarTransactionFee extends TransactionFee {
  StellarTransactionFee({required super.fee, required super.type, super.error});
  StellarTransactionFee copyWith({IntegerBalance? fee, TxFeeTypes? type, String? error}) {
    return StellarTransactionFee(
        fee: fee ?? this.fee, type: type ?? this.type, error: error);
  }
}

class StellarTransactionFeeData extends TransactionDynamicFeeData<StellarTransactionFee> {
  StellarTransactionFeeData({required super.select, required super.feeToken});

  @override
  StellarTransactionFee createManualFee(BigInt amount) {
    return StellarTransactionFee(
        fee: IntegerBalance.token(amount, feeToken), type: TxFeeTypes.manually);
  }
}

abstract class BaseStellarTransactionController extends TransactionStateController<
    StellarIssueToken,
    WalletStellarNetwork,
    IStellarAddress,
    StellarClient,
    StellarChain,
    IStellarTransactionData,
    IStellarTransaction,
    IStellarSignedTransaction,
    StellarWalletTransaction,
    SubmitTransactionSuccess<IStellarSignedTransaction>,
    StellarTransactionFeeData> {
  BaseStellarTransactionController(
      {required super.walletProvider, required super.account, required super.address});
}

class IStellarTransactionData extends ITransactionData {
  final List<StellarTransactionOperation> operations;
  final StellarTransactionFee fee;
  final StellarMemo memo;
  final Preconditions timeboundCondition;
  final BigInt sequence;

  WalletTransactionMemo? getWalletTxMemo() {
    return switch (memo) {
      StellarMemoReturnHash(:final hash) ||
      StellarMemoReturnHash(:final hash) =>
        WalletTransactionMemo.binary(hash),
      StellarMemoID(:final id) =>
        WalletTransactionMemo.from("$id", WalletTransactionMemoType.string),
      StellarMemoText(:final text) => WalletTransactionMemo.from(
          text,
          switch (StringUtils.isHexBytes(text)) {
            true => WalletTransactionMemoType.binary,
            false => WalletTransactionMemoType.string,
          }),
      _ => null
    };
  }

  IStellarTransactionData(
      {required this.fee,
      required List<StellarTransactionOperation> operations,
      required this.memo,
      required this.timeboundCondition,
      required this.sequence})
      : operations = operations.immutable;
}

class IStellarTransaction extends ITransaction<IStellarTransactionData, IStellarAddress> {
  final StellarTransactionV1 transaction;
  const IStellarTransaction(
      {required super.account,
      required super.transactionData,
      required this.transaction});
}

class IStellarSignedTransaction
    extends ISignedTransaction<IStellarTransaction, TransactionV1Envelope> {
  IStellarSignedTransaction(
      {required super.transaction,
      required super.signatures,
      required super.finalTransactionData});
}

class StellarFetchedFeeStats {
  final StellarFeeStatsResponse stats;
  final int operations;
  const StellarFetchedFeeStats({required this.stats, required this.operations});
}

class StellarTransactionOperationData {
  final StellarTransactionOperation operation;
  final StellarTransactionOperationForm form;
  const StellarTransactionOperationData({required this.operation, required this.form});
}
