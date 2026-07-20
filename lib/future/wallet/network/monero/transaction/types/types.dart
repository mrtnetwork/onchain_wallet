import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/extension/app_extensions/string.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

enum MoneroTransactionOperations implements TransactionOperations {
  transfer("transfer"),
  tokenTransfer("transfer_token");

  @override
  final String value;
  const MoneroTransactionOperations(this.value);
}

class MoneroTransactionFee extends TransactionFee {
  MoneroTransactionFee({required super.type, required super.fee, super.error});

  @override
  String toString() {
    return "MoneroTransactionFee({type:$type, fee:$fee, error:$error})";
  }

  MoneroTransactionFee copyWith({TxFeeTypes? type, IntegerBalance? fee, String? error}) {
    return MoneroTransactionFee(
        type: type ?? this.type, fee: fee ?? this.fee, error: error ?? this.error);
  }
}

class MoneroTransactionFeeData extends TransactionDynamicFeeData<MoneroTransactionFee> {
  MoneroTransactionFeeData({required super.select, required super.feeToken});

  @override
  MoneroTransactionFee createManualFee(BigInt amount) {
    return MoneroTransactionFee(
        type: TxFeeTypes.manually, fee: IntegerBalance.token(amount, feeToken));
  }
}

abstract class BaseMoneroTransactionController extends TransactionStateController<
    TokenCore,
    WalletMoneroNetwork,
    IMoneroAddress,
    MoneroNetworkClient,
    MoneroChain,
    IMoneroTransactionData,
    IMoneroTransaction,
    IMoneroSignedTransaction,
    MoneroWalletTransaction,
    SubmitTransactionSuccess<IMoneroSignedTransaction>,
    MoneroTransactionFeeData> {
  BaseMoneroTransactionController(
      {required super.walletProvider, required super.account, required super.address});
}

sealed class MoneroAccountUtxosStatus {
  bool get isSuccess => false;
  bool get isPending => false;
  bool get isError => false;
  bool get retryable => false;
  const MoneroAccountUtxosStatus();
}

class MoneroAccountUtxosStatusPending extends MoneroAccountUtxosStatus {
  const MoneroAccountUtxosStatusPending();
  @override
  bool get isPending => true;
}

class MoneroAccountUtxosStatusSuccess extends MoneroAccountUtxosStatus {
  const MoneroAccountUtxosStatusSuccess();
  @override
  bool get isSuccess => true;
}

class MoneroAccountUtxosStatusErr extends MoneroAccountUtxosStatus {
  final String message;
  @override
  bool get isError => true;
  @override
  final bool retryable;
  const MoneroAccountUtxosStatusErr(this.message, {this.retryable = true});
}

class MoneroAccountFetchedUtxos with DisposableMixin, Equality, StreamStateController {
  final lock = SafeAtomicLock();
  final IMoneroAddress address;
  MoneroAccountFetchedUtxos({required this.address})
      : totalUtxo = IntegerBalance.token(BigInt.zero, address.network.token,
            allowNegative: false);
  MoneroAccountUtxosStatus status = MoneroAccountUtxosStatusPending();
  MoneroAccountWithUtxos? _utxos;
  MoneroAccountWithUtxos? get utxos => _utxos;
  List<MoneroUtxoWithBalanceInfo> _selectedUtxos = [];
  List<MoneroUtxoWithBalanceInfo> get selectedUtxos => _selectedUtxos;
  bool get isSuccess => status.isSuccess;
  bool get isPending => status.isPending;
  bool get hasUtxos => isSuccess && _utxos!.utxosWithBalance.isNotEmpty;
  bool _allSelected = false;
  int _totalSelected = 0;
  bool get allSelected => _allSelected;
  int get totalSelected => _totalSelected;
  final IntegerBalance totalUtxo;
  bool isSelected(MoneroUtxoWithBalanceInfo utxo) {
    return _selectedUtxos.contains(utxo);
  }

  void _update() {
    _totalSelected = _selectedUtxos.length;
    _allSelected = _selectedUtxos.length == utxos?.utxosWithBalance.length;
    totalUtxo.updateBalance(
        _selectedUtxos.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.balance));
    notify();
  }

  Future<bool> addUtxo(MoneroUtxoWithBalanceInfo utxo, StringVoid onErr,
      {bool allowRemove = true}) async {
    return await lock.run(() async {
      final utxos = _utxos;
      assert(utxos != null && utxos.utxosWithBalance.contains(utxo),
          "utxo does not exists.");
      if (utxos == null) return false;
      bool updated = false;
      if (!allowRemove) {
        if (_selectedUtxos.contains(utxo)) return false;
        _selectedUtxos.add(utxo);
        updated = true;
      } else {
        if (!_selectedUtxos.remove(utxo)) {
          if (!utxo.utxo.confirmation.confirmed) {
            onErr("utxos_is_not_confirmed_yet".tr);
          } else {
            _selectedUtxos.add(utxo);
            updated = true;
          }
        }
      }
      _update();
      return updated;
    }, lockId: LockId.two);
  }

  Future<bool> merge(MoneroAccountWithUtxos utxos) async {
    return await lock.run(() async {
      if (status.isPending) return false;
      if (status.isError) {
        _utxos = utxos;
        status = MoneroAccountUtxosStatusSuccess();
        notify();
        return true;
      }
      final cUtxos = _utxos;
      if (cUtxos == null) return false;
      assert(utxos.address == _utxos?.address);
      bool changed = false;

      final List<MoneroUtxoWithBalanceInfo> selectedUtxos = [];
      for (final i in _selectedUtxos) {
        final updatedUtxo = utxos.utxosWithBalance.firstWhereOrNull((e) => e == i);
        if (updatedUtxo == null) {
          changed = true;
        } else {
          selectedUtxos.add(updatedUtxo);
        }
      }
      _utxos = utxos;
      _selectedUtxos = selectedUtxos;
      _update();
      return changed;
    }, lockId: LockId.two);
  }

  Future<void> onHeightUpdated(int blockHeight) async {
    return await lock.run(() async {
      final utxos = _utxos;
      if (utxos == null) return;
      final update = utxos.updateUtxosConfirmation(blockHeight);
      final List<MoneroUtxoWithBalanceInfo> selectedUtxos = [];
      for (final i in _selectedUtxos) {
        final newHeight = update.utxosWithBalance.firstWhereNullable((e) => e == i);
        assert(newHeight != null);
        if (newHeight == null) {
          continue;
        }
        selectedUtxos.add(newHeight);
      }
      _utxos = update;
      _selectedUtxos = selectedUtxos;
      _update();
    }, lockId: LockId.two);
  }

  Future<void> removeAllSelectedUtxos() async {
    await lock.run(() async {
      _selectedUtxos = [];
      _update();
    }, lockId: LockId.two);
  }

  Future<void> setUtxos(MoneroAccountWithUtxos utxos) async {
    await lock.run(() async {
      assert(!status.isSuccess);
      _utxos = utxos;
      status = MoneroAccountUtxosStatusSuccess();
      notify();
    }, lockId: LockId.two);
  }

  void setError(MoneroAccountUtxosStatusErr error) {
    lock.run(() {
      if (isSuccess) return;
      status = error;
      notify();
    }, lockId: LockId.two);
  }

  Future<void> setPending() async {
    await lock.run(() async {
      if (isPending || isSuccess) return;
      status = MoneroAccountUtxosStatusPending();
      notify();
    }, lockId: LockId.two);
  }

  @override
  List get variables => [address];
}

class MoneroTransferDetails extends TransferOutputDetails<MoneroAddress> {
  final bool allowNegativeAmount;
  MoneroTransferDetails({
    required super.recipient,
    required Token token,
    super.recipientUpdateble = false,
    this.allowNegativeAmount = false,
  }) : super(amount: IntegerBalance.zero(token, allowNegative: allowNegativeAmount));

  @override
  void updateBalance(BigInt amount) {
    assert(allowNegativeAmount || !amount.isNegative, "invalid amount.");
    if (amount.isNegative && !allowNegativeAmount) return;
    this.amount.updateBalance(amount);
    notify();
  }

  @override
  List get variables => [recipient];

  IMoneroTransactionDataTransfer toMoneroDestination() {
    return IMoneroTransactionDataTransfer(
        amount: amount.clone(immutable: true, allowNegative: false),
        recipient: recipient);
  }
}

class IMoneroTransactionData extends ITransactionData {
  final List<MoneroUtxoWithBalanceInfo> payments;
  final MoneroTxDestination? change;
  final List<IMoneroTransactionDataTransfer> destinations;
  IMoneroTransactionData(
      {required this.change,
      required List<MoneroUtxoWithBalanceInfo> payments,
      required List<IMoneroTransactionDataTransfer> destinations})
      : destinations = destinations.immutable,
        payments = payments.immutable;
}

class IMoneroTransactionDataTransfer {
  final ReceiptAddress<MoneroAddress> recipient;
  final IntegerBalance amount;
  IMoneroTransactionDataTransfer({required this.recipient, required this.amount});
}

class IMoneroTransaction extends ITransaction<IMoneroTransactionData, IMoneroAddress> {
  final List<SpendablePayment<MoneroLockedPayment>> spendablePayment;
  final BigInt fee;
  IMoneroTransaction({
    required super.account,
    required super.transactionData,
    required List<SpendablePayment<MoneroLockedPayment>> spendablePayment,
    required this.fee,
  }) : spendablePayment = spendablePayment.immutable;
}

class IMoneroSignedTransaction
    extends ISignedTransaction<IMoneroTransaction, MoneroSigningTxResponse> {
  IMoneroSignedTransaction(
      {required super.transaction,
      required super.signatures,
      required super.finalTransactionData});
}

class MoneroAccountWithUtxos {
  const MoneroAccountWithUtxos._(
      {required this.address, required this.utxosWithBalance, required this.sumOfUtxos});
  factory MoneroAccountWithUtxos(
      {required IMoneroAddress address, required MoneroUtxosWithAccountInfo utxo}) {
    final expandUtxos = utxo.utxos
        .map((e) => MoneroUtxoWithBalanceInfo(
            utxo: e, token: address.network.token, account: address))
        .toList();
    final IntegerBalance sumOfUtxos = IntegerBalance.token(
        expandUtxos.fold(BigInt.zero,
            (previousValue, element) => previousValue + element.amount.balance),
        address.network.token,
        immutable: true,
        allowNegative: false);
    return MoneroAccountWithUtxos._(
      address: address,
      sumOfUtxos: sumOfUtxos,
      utxosWithBalance: expandUtxos,
    );
  }
  final IMoneroAddress address;
  final List<MoneroUtxoWithBalanceInfo> utxosWithBalance;
  final IntegerBalance sumOfUtxos;

  MoneroAccountWithUtxos updateUtxosConfirmation(int blockHeight) {
    final update =
        utxosWithBalance.map((e) => e.updateConfirmation(blockHeight)).toList();
    return MoneroAccountWithUtxos._(
        address: address, utxosWithBalance: update, sumOfUtxos: sumOfUtxos);
  }

  MoneroAccountWithUtxos mergeProtocol(MoneroAccountWithUtxos other) {
    final utxos = [...utxosWithBalance, ...other.utxosWithBalance];
    final IntegerBalance sumOfUtxos = IntegerBalance.token(
        utxos.fold(BigInt.zero,
            (previousValue, element) => previousValue + element.amount.balance),
        this.sumOfUtxos.token,
        immutable: true,
        allowNegative: false);
    return MoneroAccountWithUtxos._(
        address: address, utxosWithBalance: utxos, sumOfUtxos: sumOfUtxos);
  }
}

class MoneroUtxoWithBalanceInfo with Equality {
  final MoneroUtxoWithSpendingInfo utxo;
  final IntegerBalance amount;
  final IMoneroAddress account;

  MoneroUtxoWithBalanceInfo(
      {required this.utxo, required Token token, required this.account})
      : amount = IntegerBalance.token(utxo.utxo.amount, token,
            immutable: true, allowNegative: false);
  MoneroUtxoWithBalanceInfo updateConfirmation(int blockHeight) {
    final newUtxo = MoneroUtxoWithSpendingInfo.fromBlockHeight(utxo.utxo, blockHeight);
    return MoneroUtxoWithBalanceInfo(
        utxo: newUtxo, token: amount.token, account: account);
  }

  MoneroLockedPayment toLockedPayment() {
    if (!utxo.confirmation.confirmed) {
      throw const WalletException.message("output_is_not_ready_for_spending");
    }
    return utxo.toLockedPayment();
  }

  MoneroUnLockedPayment toUnlockedFakePayment() {
    return utxo.toUnlockedFakePayment();
  }

  @override
  List<dynamic> get variables => [utxo];
}
