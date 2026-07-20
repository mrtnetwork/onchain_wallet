import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

abstract class TransactionOperations {
  abstract final String value;
}

enum TransactionStateStatusType {
  error,
  ready;

  bool get hasError => this == error;
}

enum SubmitTransactionResultStatus {
  success,
  failed;

  bool get isFailed => this == failed;
}

sealed class SubmitTransactionResult {
  const SubmitTransactionResult(this.status);
  final SubmitTransactionResultStatus status;

  T cast<T extends SubmitTransactionResult>() {
    if (this is! T) {
      throw AppInternalError.internalError("SubmitTransactionResult");
    }
    return this as T;
  }
}

class SubmitTransactionSuccess<SIGNEDTX extends ISignedTransaction>
    extends SubmitTransactionResult {
  final SIGNEDTX signedTransaction;
  final String txId;
  final String? warning;
  final int? block;
  const SubmitTransactionSuccess(
      {required this.txId, required this.signedTransaction, this.warning, this.block})
      : super(SubmitTransactionResultStatus.success);
  @override
  String toString() {
    return "TxID: $txId";
  }
}

class SubmitTransactionFailed extends SubmitTransactionResult {
  final String error;
  const SubmitTransactionFailed(this.error) : super(SubmitTransactionResultStatus.failed);
  @override
  String toString() {
    return "Error: $error";
  }
}

class TransactionStateStatus {
  final TransactionStateStatusType status;
  const TransactionStateStatus._(this.error, this.status, this.warning);
  final String? error;
  final String? warning;
  bool get isReady => status == TransactionStateStatusType.ready;
  TransactionStateStatus.ready({this.warning})
      : status = TransactionStateStatusType.ready,
        error = null;
  TransactionStateStatus.error({this.error})
      : status = TransactionStateStatusType.error,
        warning = null;
  factory TransactionStateStatus.insufficient(final BalanceCore balance,
      {String? warning}) {
    if (!balance.isNegative) {
      return TransactionStateStatus._(null, TransactionStateStatusType.ready, warning);
    }
    final String absBalance = balance.price.replaceFirst("-", "");
    return TransactionStateStatus.error(
        error: "insufficient_balance_error"
            .tr
            .replaceOne("$absBalance ${balance.token.symbol}"));
  }
  factory TransactionStateStatus.warningInsufficient(final BalanceCore balance,
      {String? warning}) {
    if (!balance.isNegative) {
      return TransactionStateStatus._(null, TransactionStateStatusType.ready, warning);
    }
    final String absBalance = balance.price.replaceFirst("-", "");
    return TransactionStateStatus._(
        null,
        TransactionStateStatusType.ready,
        "insufficient_balance_error"
            .tr
            .replaceOne("$absBalance ${balance.token.symbol}"));
  }
}

enum NetworkFeeMode {
  defaultFee,
  dynamicFee;

  bool get isDefaultFee => this == defaultFee;
  bool get isDynamicFee => this == dynamicFee;
}

enum TxFeeStatus { idle, pending, process }

enum TxFeeTypes {
  slow("slow"),
  normal("normal"),
  defaultFee("default"),
  high("high"),
  manually("manually");

  final String value;
  const TxFeeTypes(this.value);
}

abstract class TransactionFee with Equality {
  final String? error;
  final String? description;
  final TxFeeTypes type;
  bool get isManual => type == TxFeeTypes.manually;
  bool get isDefault => type == TxFeeTypes.defaultFee;
  bool get hasError => error != null;

  final IntegerBalance fee;
  const TransactionFee({
    required this.type,
    required this.fee,
    this.error,
    this.description,
  });
  bool get hasFee => fee.largerThanZero;

  @override
  List get variables => [type, fee, error, description];
}

abstract class DefaultTransactionFee extends TransactionFee {
  const DefaultTransactionFee({required super.fee, super.error})
      : super(type: TxFeeTypes.defaultFee);
}

abstract class TransactionFeeData<T extends TransactionFee>
    with DisposableMixin, StreamStateController {
  NetworkFeeMode get feeMode;
  Token _feeToken;
  Token get feeToken => _feeToken;
  TransactionFeeData({
    required Token feeToken,
    required T select,
  })  : _fee = select,
        _feeToken = feeToken;
  TxFeeStatus _status = TxFeeStatus.idle;
  bool get isPending => _status == TxFeeStatus.pending;
  bool get proccessed => _status == TxFeeStatus.process;
  bool get hasFee => _fee.fee.largerThanZero;
  TxFeeStatus get status => _status;
  T _fee;
  T get fee => _fee;

  void setPending() {
    _status = TxFeeStatus.pending;
    notify();
  }

  void setProcess() {
    _status = TxFeeStatus.process;
    notify();
  }
}

abstract class TransactionDefaultFeeData<T extends DefaultTransactionFee>
    extends TransactionFeeData<T> {
  @override
  NetworkFeeMode get feeMode => NetworkFeeMode.defaultFee;
  TransactionDefaultFeeData({required super.feeToken, required super.select});

  void setFee(T fee) {
    assert(fee.type == TxFeeTypes.defaultFee, "invalid default fee type");
    if (fee.type != TxFeeTypes.defaultFee) {
      return;
    }
    if (fee == _fee && proccessed) return;
    _fee = fee;
    setProcess();
  }
}

abstract class TransactionDynamicFeeData<T extends TransactionFee>
    extends TransactionFeeData<T> {
  bool _allowChangeFee = true;
  bool get allowChangeFee => _allowChangeFee;
  @override
  NetworkFeeMode get feeMode => NetworkFeeMode.dynamicFee;
  TransactionDynamicFeeData(
      {required super.feeToken, required super.select, List<T> fees = const []})
      : _fees = fees.immutable;

  List<T> _fees;
  List<T> get fees => _fees;

  T createManualFee(BigInt amount);

  void updateTokenFee(Token token, List<T> fees) {
    _feeToken = token;
    setDefaultFees(fees);
  }

  void setupManualFee(BigInt amount) {
    final fee = createManualFee(amount);
    setManualFee(fee);
  }

  void setFee(T fee) {
    assert(_fees.contains(fee), "fee does not exists.");
    if (!_fees.contains(fee)) return;
    if (this.fee.isManual) {
      _fees = fees.where((e) => !e.isManual).toImutableList;
    }
    _fee = fee;
    setProcess();
  }

  void setDefaultFees(List<T> fees) {
    bool isValidFee = fees.isNotEmpty &&
        fees.any((e) => e.type == TxFeeTypes.normal) &&
        !fees.any((e) => e.type == TxFeeTypes.manually) &&
        fees.every((e) => e.fee.token == feeToken);
    assert(isValidFee, "Invalid fee data");
    if (!isValidFee) return;
    _fees = fees.immutable;
    if (fee.isManual && fee.fee.token == feeToken) {
      _fees = [...fees, fee].immutable;
    } else {
      _fees = fees.immutable;
      _fee = fees.firstWhere((e) => e.type == fee.type,
          orElse: () => fees.firstWhere((e) => e.type == TxFeeTypes.normal));
    }
    setProcess();
  }

  void setManualFee(T fee) {
    bool isValud = fee.isManual;
    assert(isValud, "Invalid manual fee type.");
    _fee = fee;
    _fees = [...fees.where((e) => !e.isManual), fee].immutable;
    setProcess();
  }

  void setAllowSwitchFee(bool allow) {
    _allowChangeFee = allow;
    notify();
  }
}

class ITransactionDataTransferRecipient<T> {
  final T recipient;
  final BigInt amount;
  const ITransactionDataTransferRecipient(
      {required this.recipient, required this.amount});
}

class ITransactionDataTransferTokenRecipient<T, TOKEN extends TokenCore>
    extends ITransactionDataTransferRecipient<T> {
  final TOKEN token;
  final BigInt? nativeAmount;
  const ITransactionDataTransferTokenRecipient(
      {required super.amount,
      required super.recipient,
      required this.token,
      this.nativeAmount});
}

abstract class ITransactionData {
  const ITransactionData();
}

abstract class ITransaction<TXDATA extends ITransactionData,
    ADDRESS extends ChainAccount> {
  final ADDRESS account;
  final TXDATA transactionData;
  const ITransaction({required this.account, required this.transactionData});
}

abstract class ISignedTransaction<T extends ITransaction, SERIALIZEDTX extends Object> {
  final T transaction;
  final List<List<int>> signatures;
  final SERIALIZEDTX finalTransactionData;
  ISignedTransaction(
      {required this.transaction,
      required List<List<int>> signatures,
      required this.finalTransactionData})
      : signatures = signatures.map((e) => e.asImmutableBytes).toImutableList;
}

class IWalletTransaction<T extends ChainTransaction, C extends ChainAccount> {
  final T transaction;
  final C account;
  const IWalletTransaction({required this.transaction, required this.account});
}

enum TransactionResourceRequirementFetchStatus {
  manual,
  failed,
  idle,
  success,
  pending;

  bool get isPending => this == pending;
  bool get isIdle => this == idle;
  bool get isManual => this == manual;
  bool get isSuccess => this == success;
  bool get isError => this == failed;
  bool get canRetry => isError || isIdle;
}

abstract class TransactionResourceRequirement<T extends Object?> {
  final String? error;
  final TransactionResourceRequirementFetchStatus status;
  final T value;
  const TransactionResourceRequirement(
      {required this.value, required this.status, this.error});
}

typedef TRANSACTIONSTATECONTROLLERFEE<FEE extends TransactionFeeData>
    = TransactionStateController<
        TokenCore,
        WalletNetwork,
        ChainAccount,
        NetworkClient,
        APPCHAIN,
        ITransactionData,
        ITransaction<ITransactionData, ChainAccount>,
        ISignedTransaction<ITransaction, Object>,
        ChainTransaction,
        SubmitTransactionSuccess<ISignedTransaction>,
        FEE>;
