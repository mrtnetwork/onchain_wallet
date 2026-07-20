import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/models/files/picked_file_data.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/bitcoin_cash/bitcoin_cash_utils.dart';
import 'package:on_chain_wallet/future/state_managment/extension/app_extensions/string.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/account.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/utxos.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:zcash_dart/zcash.dart';

enum ZcashTransactionOperations implements TransactionOperations {
  transfer("transfer");

  @override
  final String value;
  const ZcashTransactionOperations(this.value);
}

class ZcashTransactionFee extends TransactionFee {
  ZcashTransactionFee({
    required super.type,
    required super.fee,
    super.error,
  });
}

class ZcashTransactionFeeData extends TransactionDynamicFeeData<ZcashTransactionFee> {
  final OrchardBundleType orchardBundle = OrchardBundleType.defaultBundle();
  final SaplingBundleType saplingBundle = SaplingBundleType.defaultBundle();
  ZcashTransactionFeeData({
    required super.select,
    required super.feeToken,
  });

  @override
  ZcashTransactionFee createManualFee(BigInt amount) {
    return ZcashTransactionFee(
      type: TxFeeTypes.manually,
      fee: IntegerBalance.token(amount, feeToken),
    );
  }
}

abstract class BaseZcashTransactionController<TXDATA extends IZcashTransactionData>
    extends TransactionStateController<
        TokenCore,
        WalletZcashNetwork,
        IZcashAddress,
        ZcashNetworkClient,
        ZcashChain,
        TXDATA,
        IZcashTransaction<TXDATA>,
        IZcashSignedTransaction<TXDATA>,
        ZcashWalletTransaction,
        SubmitTransactionSuccess<IZcashSignedTransaction<TXDATA>>,
        ZcashTransactionFeeData> {
  BaseZcashTransactionController(
      {required super.walletProvider, required super.account, required super.address});
}

class IZcashTransactionData extends ITransactionData {
  final List<ZcashUtxoWithBalanceInfo> utxos;
  final List<IZcashTransfableTransactionOutput> recipients;
  final List<ZcashTransactionTransparentMemo> transparentMemos;
  final ZcashTransactionFee fee;

  IZcashTransactionData({
    required List<ZcashUtxoWithBalanceInfo> utxos,
    required List<IZcashTransfableTransactionOutput> recipients,
    required List<ZcashTransactionTransparentMemo> transparentMemos,
    required this.fee,
  })  : utxos = utxos.immutable,
        recipients = recipients.immutable,
        transparentMemos = transparentMemos.immutable;

  List<IZcashTransactionOutput> toOutputs() => [...recipients, ...transparentMemos];
}

class IZcashTransaction<TXDATA extends IZcashTransactionData>
    extends ITransaction<TXDATA, IZcashAddress> {
  final List<IZcashAddress> accounts;
  final List<ZcashTransactionOutput> outputs;
  final List<ZcashUtxosWithAccountInfo> inputs;
  final bool hasOrchard;
  bool get hasSapling => hasSaplingSpend || hasSaplingOutput;
  final bool hasSaplingSpend;
  final bool hasSaplingOutput;
  IZcashTransaction._(
      {required super.account,
      required super.transactionData,
      required this.accounts,
      required this.outputs,
      required this.inputs,
      required this.hasOrchard,
      required this.hasSaplingSpend,
      required this.hasSaplingOutput});
  factory IZcashTransaction({
    required IZcashAddress account,
    required TXDATA transactionData,
    required List<IZcashAddress> accounts,
    required List<ZcashUtxosWithAccountInfo> inputs,
    required List<ZcashTransactionOutput> outputs,
  }) {
    final bool hasOrchard = inputs.any((e) => e.account.protocol.isOrchard) ||
        outputs.any((e) => e.protocol.isOrchard);

    return IZcashTransaction._(
        account: account,
        transactionData: transactionData,
        accounts: accounts,
        outputs: outputs,
        inputs: inputs,
        hasOrchard: hasOrchard,
        hasSaplingOutput: outputs.any((e) => e.protocol.isSapling),
        hasSaplingSpend: inputs.any((e) => e.account.protocol.isSapling));
  }
}

class IZcashSignedTransaction<TXDATA extends IZcashTransactionData>
    extends ISignedTransaction<IZcashTransaction<TXDATA>, List<int>> {
  final String txId;
  IZcashSignedTransaction(
      {required super.transaction,
      required super.signatures,
      required super.finalTransactionData,
      required this.txId});
}

class ZcashRemainTransferDetails with DisposableMixin, StreamStateController {
  ReceiptAddress<ZcashAddress> _recipient;
  ReceiptAddress<ZcashAddress> get recipient => _recipient;
  ZcashProtocol _addrProtocol = ZcashProtocol.transparent;
  ZcashProtocol get addrProtocol => _addrProtocol;
  final List<ZcashProtocol> protocols;
  bool _hasMultipleProtocol = false;
  bool get hasMultipleProtocol => _hasMultipleProtocol;
  bool get hasAmount => amount.largerThanZero;
  bool get isReady => hasAmount;
  final IntegerBalance amount;
  List<ZcashProtocol> _supportedProtocols;
  List<ZcashProtocol> get supportedProtocols => _supportedProtocols;
  ZcashTransactionMemoShielded? _memo;
  ZcashTransactionMemoShielded? get memo => _memo;
  bool get hasMemo => memo != null;
  bool get allowMemo => _addrProtocol.sheilded;

  ZcashRemainTransferDetails({
    required ReceiptAddress<ZcashAddress> recipient,
    required ZcashProtocol addressProtocol,
    required WalletZcashNetwork network,
    required this.protocols,
  })  : amount = IntegerBalance.zero(network.token),
        _recipient = recipient,
        _addrProtocol = addressProtocol,
        _supportedProtocols = recipient.networkAddress.supportedProtocols
            .where((e) => protocols.contains(e))
            .toList(),
        _hasMultipleProtocol = recipient.networkAddress.supportedProtocols.length > 1;

  void updateBalance(BigInt amount) {
    this.amount.updateBalance(amount);
    notify();
  }

  void onUpdateRecipient(ReceiptAddress<ZcashAddress> recipient) {
    final supportedProtocols = recipient.networkAddress.supportedProtocols
        .where((e) => protocols.contains(e))
        .toList();
    if (supportedProtocols.isEmpty) return;
    _hasMultipleProtocol = supportedProtocols.length > 1;
    _recipient = recipient;
    _supportedProtocols = supportedProtocols;
    _addrProtocol = supportedProtocols.firstWhere((e) => e == _addrProtocol,
        orElse: () => supportedProtocols.first);
    notify();
  }

  String? onValidateMemo(String? memo) {
    if (memo == null) return null;
    const length = NoteEncryptionConst.memoLength;
    final inBytesLength = StrUtils.getStringBytesLength(memo);
    if (inBytesLength <= length) return null;
    return "character_length_max_validator".tr.replaceOne(length.toString());
  }

  void onUpdateMemo(String? memo) {
    if (memo == null) return;
    assert(addrProtocol.sheilded, "Unsupported memo");
    if (!addrProtocol.sheilded) return;

    _memo = ZcashTransactionMemoShielded(content: memo);
    notify();
  }

  void onRemoveMemo() {
    _memo = null;
    notify();
  }

  void onChangeAddressProtocol(ZcashProtocol protocol) {
    assert(supportedProtocols.contains(protocol), "Unsupported protocol.");
    if (!supportedProtocols.contains(protocol)) return;
    _addrProtocol = protocol;
    if (!addrProtocol.sheilded) {
      _memo = null;
    }
    notify();
  }

  IZcashTransfableTransactionOutput? toOutput() {
    if (!hasAmount) return null;
    final inProtocolAddress = recipient.networkAddress.toProtocolAddress(addrProtocol);
    if (inProtocolAddress == null) {
      throw AppException("unsupported_address_type");
    }
    final addr = ReceiptAddress<ZcashAddress>(
        view: inProtocolAddress.address,
        networkAddress: inProtocolAddress,
        contact: recipient.contact,
        account: recipient.account);
    return switch (addrProtocol) {
      ZcashProtocol.transparent => ZcashTransactionTransparentOutput(
          address: addr, amount: amount.clone(immutable: true, allowNegative: false)),
      _ => ZcashTransactionShieldOutput(
          address: addr,
          protocol: addrProtocol,
          amount: amount.clone(immutable: true, allowNegative: false),
          memo: memo)
    };
  }
}

class ZcashTransferDetails with DisposableMixin, StreamStateController {
  TransactionStateStatus _status = TransactionStateStatus.error();
  TransactionStateStatus get status => _status;
  final ReceiptAddress<ZcashAddress> recipient;
  final List<ZcashProtocol> supportedProtocols;
  ZcashAddress _inProtocolAddress;
  ZcashAddress get inProtocolAddress => _inProtocolAddress;
  ZcashProtocol _addrProtocol = ZcashProtocol.transparent;
  ZcashProtocol get addrProtocol => _addrProtocol;
  bool get allowMemo => addrProtocol.sheilded;
  final bool hasMultipleProtocol;
  ZcashTransactionMemoShielded? _memo;
  ZcashTransactionMemoShielded? get memo => _memo;
  bool get hasMemo => _memo != null;

  List<ZcashProtocol> get protocols => recipient.networkAddress.supportedProtocols;
  bool get hasAmount => amount.largerThanZero;
  bool get isReady => _status.isReady;
  final IntegerBalance amount;
  ZcashTransferDetails._({
    required this.recipient,
    required ZcashProtocol protocol,
    required Token token,
    required List<ZcashProtocol> supportedProtocols,
    required ZcashAddress inProtocolAddress,
    bool allowNegative = false,
  })  : amount = IntegerBalance.zero(token, allowNegative: allowNegative),
        supportedProtocols = supportedProtocols.immutable,
        _addrProtocol = protocol,
        hasMultipleProtocol = supportedProtocols.length > 1,
        _inProtocolAddress = inProtocolAddress;

  static ZcashTransferDetails? build(
      {required ReceiptAddress<ZcashAddress> recipient,
      required Token token,
      List<ZcashProtocol> supportedProtocols = const []}) {
    final protocols = recipient.networkAddress.supportedProtocols
        .where((e) => supportedProtocols.contains(e))
        .toList();
    if (protocols.isEmpty) return null;
    final protocol = protocols.firstWhere((e) => e.isOrchard, orElse: () => protocols[0]);
    final inProtocolAddress = recipient.networkAddress.toProtocolAddress(protocol);
    assert(inProtocolAddress != null, "should not be happend.");
    if (inProtocolAddress == null) return null;
    return ZcashTransferDetails._(
        recipient: recipient,
        protocol: protocol,
        token: token,
        supportedProtocols: protocols,
        inProtocolAddress: inProtocolAddress);
  }

  ZcashTransactionShieldOutput toTransferInfo() {
    assert(isReady);
    return ZcashTransactionShieldOutput(
        address: ReceiptAddress<ZcashAddress>(
            view: _inProtocolAddress.address,
            networkAddress: _inProtocolAddress,
            contact: recipient.contact,
            account: recipient.account),
        amount: amount.clone(immutable: true, allowNegative: false),
        protocol: addrProtocol,
        memo: memo);
  }

  TransactionStateStatus getStateStatus() {
    if (!hasAmount) return TransactionStateStatus.error();
    if (amount.balance < BCHUtils.minimumOutput) {
      final miniumAmount = "${BCHUtils.minimumOutput} ${amount.token.symbol}";
      return TransactionStateStatus.error(
          error: "price_greather_than".tr.replaceOne(miniumAmount));
    }
    return TransactionStateStatus.ready();
  }

  String? onValidateMemo(String? memo) {
    if (memo == null) return null;
    const length = NoteEncryptionConst.memoLength;
    final inBytesLength = StrUtils.getStringBytesLength(memo);
    if (inBytesLength <= length) return null;
    return "character_length_max_validator".tr.replaceOne(length.toString());
  }

  void onUpdateMemo(String? memo) {
    if (memo == null) return;
    assert(addrProtocol.sheilded, "Unsupported memo");
    if (!addrProtocol.sheilded) return;

    _memo = ZcashTransactionMemoShielded(content: memo);
    onUpdateStatus();
  }

  void onRemoveMemo() {
    _memo = null;
    onUpdateStatus();
  }

  void onUpdateStatus() {
    _status = getStateStatus();
    notify();
  }

  void updateBalance(BigInt amount) {
    this.amount.updateBalance(amount);
    onUpdateStatus();
  }

  void onChangeAddressProtocol(ZcashProtocol protocol) {
    assert(protocols.contains(protocol), "Unsupported protocol.");

    if (!protocols.contains(protocol) || protocol == _addrProtocol) return;
    final protocolAddr = recipient.networkAddress.toProtocolAddress(protocol);
    assert(protocolAddr != null, "Should not be happend");
    if (protocolAddr == null) return;
    _addrProtocol = protocol;
    _inProtocolAddress = protocolAddr;
    if (!addrProtocol.sheilded) {
      _memo = null;
    }
    onUpdateStatus();
  }

  IZcashTransactionOutput toOutput() {
    final addr = ReceiptAddress<ZcashAddress>(
        view: _inProtocolAddress.address,
        networkAddress: _inProtocolAddress,
        contact: recipient.contact,
        account: recipient.account);
    return switch (addrProtocol) {
      ZcashProtocol.transparent => ZcashTransactionTransparentOutput(
          address: addr, amount: amount.clone(immutable: true, allowNegative: false)),
      _ => ZcashTransactionShieldOutput(
          address: addr,
          protocol: addrProtocol,
          amount: amount.clone(immutable: true, allowNegative: false),
          memo: memo)
    };
  }

  List get variables => [recipient.view, addrProtocol];
}

class IZcashTransactionDataTransfer {
  final ZcashAddress recipient;
  final ZcashProtocol protocol;
  final BigInt amount;
  IZcashTransactionDataTransfer({
    required this.recipient,
    required this.amount,
    required this.protocol,
  });
}

// enum ZcashAccountUtxosStatus {
//   failed,
//   success,
//   pending;

// }
sealed class ZcashAccountUtxosStatus {
  bool get isSuccess => false;
  bool get isPending => false;
  bool get isError => false;
  bool get retryable => false;
  const ZcashAccountUtxosStatus();
}

class ZcashAccountUtxosStatusPending extends ZcashAccountUtxosStatus {
  const ZcashAccountUtxosStatusPending();
  @override
  bool get isPending => true;
}

class ZcashAccountUtxosStatusSuccess extends ZcashAccountUtxosStatus {
  const ZcashAccountUtxosStatusSuccess();
  @override
  bool get isSuccess => true;
}

class ZcashAccountUtxosStatusErr extends ZcashAccountUtxosStatus {
  final String message;
  @override
  bool get isError => true;
  @override
  final bool retryable;
  const ZcashAccountUtxosStatusErr(this.message, {this.retryable = true});
}

class ZcashUtxoWithBalanceInfo with Equality {
  final ZcashUtxoWithSpendingInfo utxo;
  final IntegerBalance amount;
  final ZcashAccountInfo address;
  final IZcashAddress account;

  ZcashProtocol get protocol => utxo.utxo.protocol;

  ZcashUtxoWithBalanceInfo(
      {required this.utxo,
      required Token token,
      required this.address,
      required this.account})
      : amount = IntegerBalance.token(utxo.utxo.amount, token,
            immutable: true, allowNegative: false);
  void updateConfirmation(int blockHeight) {
    utxo.confirmation.update(blockHeight);
  }

  @override
  List<dynamic> get variables => [address, utxo];
}

class ZcashAccountFetchedUtxos with DisposableMixin, Equality, StreamStateController {
  final lock = SafeAtomicLock();
  final IZcashAddress address;
  final ZcashTransactionSpenderPrivacy privacy;
  final bool accountSynced;
  ZcashAccountFetchedUtxos(
      {required this.address, required this.privacy, required this.accountSynced})
      : totalUtxo = IntegerBalance.token(BigInt.zero, address.network.token,
            allowNegative: false);
  ZcashAccountUtxosStatus status = ZcashAccountUtxosStatusPending();
  ZcashAccountWithUtxos? _utxos;
  ZcashAccountWithUtxos? get utxos => _utxos;
  List<ZcashUtxoWithBalanceInfo> _selectedUtxos = [];
  List<ZcashUtxoWithBalanceInfo> get selectedUtxos => _selectedUtxos;
  bool get isSuccess => status.isSuccess;
  bool get isPending => status.isPending;
  bool get hasUtxos => isSuccess && _utxos!.utxosWithBalance.isNotEmpty;
  bool _allSelected = false;
  int _totalSelected = 0;
  bool get allSelected => _allSelected;
  int get totalSelected => _totalSelected;

  final IntegerBalance totalUtxo;
  bool isSelected(ZcashUtxoWithBalanceInfo utxo) {
    return _selectedUtxos.contains(utxo);
  }

  void _update() {
    _totalSelected = _selectedUtxos.length;
    _allSelected = _selectedUtxos.length == utxos?.utxosWithBalance.length;
    totalUtxo.updateBalance(
        _selectedUtxos.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.balance));
    notify();
  }

  Future<void> addUtxo(ZcashUtxoWithBalanceInfo utxo, StringVoid onErr) async {
    await lock.run(() async {
      final utxos = _utxos;
      assert(utxos != null && utxos.utxosWithBalance.contains(utxo),
          "utxo does not exists.");
      if (utxos == null) return;
      if (!_selectedUtxos.remove(utxo)) {
        if (utxo.protocol.isTransparent && privacy.isShieldOnly) {
          onErr("utxo_restricted_by_tx_privacy_desc".tr);
        } else if (!utxo.utxo.confirmation.confirmed) {
          onErr("utxos_is_not_confirmed_yet".tr);
        } else if (utxo.protocol.sheilded && !accountSynced) {
          onErr("spending_sheild_utxos_synchronization_required_desc".tr);
        } else {
          _selectedUtxos.add(utxo);
        }
      }
      _update();
    }, lockId: LockId.two);
  }

  Future<bool> merge(
      {required ZcashAccountWithUtxos utxos, ZcashProtocol? protocol}) async {
    return await lock.run(() async {
      if (status.isPending) return false;
      if (status.isError) {
        _utxos = utxos;
        status = ZcashAccountUtxosStatusSuccess();
        notify();
        return true;
      }
      final cUtxos = _utxos;
      if (cUtxos == null) return false;
      assert(utxos.address == _utxos?.address);
      assert(protocol == null ||
          utxos.utxosWithBalance.every((e) => e.utxo.protocol == protocol));
      bool changed = false;
      final List<ZcashUtxoWithBalanceInfo> selectedUtxos = [];
      utxos = _utxos = switch (protocol) {
        ZcashProtocol protocol => cUtxos.mergeProtocol(utxos, protocol),
        _ => utxos
      };
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

  void onHeightUpdated(int blockHeight) async {
    utxos?.updateUtxosConfirmation(blockHeight);
    notify();
  }

  void _selectAll() {
    final utxos = _utxos;
    assert(utxos != null, "utxo does not exists.");
    if (utxos == null) {
      return;
    }

    List<ZcashUtxoWithBalanceInfo> confirmedUtxos =
        utxos.utxosWithBalance.where((e) => e.utxo.confirmation.confirmed).toList();
    if (!accountSynced) {
      confirmedUtxos = confirmedUtxos.where((e) => e.protocol.isTransparent).toList();
    }
    _selectedUtxos = switch (privacy) {
      ZcashTransactionSpenderPrivacy.auto => confirmedUtxos,
      ZcashTransactionSpenderPrivacy.shieldOnly =>
        confirmedUtxos.where((e) => e.protocol.sheilded).toList(),
    };
  }

  Future<void> selectAll(StringVoid onErr, {bool select = false}) async {
    await lock.run(() async {
      if (!select) {
        _selectedUtxos = [];
      } else {
        _selectAll();
      }
      _update();
      if (select && !_allSelected) {
        onErr("zcash_select_all_utxos_failed_desc".tr);
      }
    }, lockId: LockId.two);
  }

  Future<void> toggleAll(StringVoid onErr) async {
    bool allSelected = this.allSelected;
    await lock.run(() async {
      if (allSelected) {
        _selectedUtxos = [];
      } else {
        _selectAll();
      }
      _update();
      if (!allSelected && !this.allSelected) {
        onErr("zcash_select_all_utxos_failed_desc".tr);
      }
    }, lockId: LockId.two);
  }

  Future<void> setUtxos(ZcashAccountWithUtxos utxos) async {
    await lock.run(() async {
      assert(!status.isSuccess);
      _utxos = utxos;
      status = ZcashAccountUtxosStatusSuccess();
      notify();
    }, lockId: LockId.two);
  }

  void setError(ZcashAccountUtxosStatusErr err) {
    lock.run(() {
      if (isSuccess) return;
      status = err;
      notify();
    }, lockId: LockId.two);
  }

  Future<void> setPending() async {
    await lock.run(() async {
      if (!status.retryable) return;
      status = ZcashAccountUtxosStatusPending();
      notify();
    }, lockId: LockId.two);
  }

  @override
  List get variables => [address];
}

class ZcashAccountWithUtxos {
  const ZcashAccountWithUtxos._(
      {required this.address, required this.utxosWithBalance, required this.sumOfUtxos});
  factory ZcashAccountWithUtxos(
      {required IZcashAddress address, required List<ZcashUtxosWithAccountInfo> utxos}) {
    final expandUtxos = utxos
        .expand((w) => w.utxos.map((e) => ZcashUtxoWithBalanceInfo(
            utxo: e, token: address.network.token, address: w.account, account: address)))
        .toList();
    final IntegerBalance sumOfUtxos = IntegerBalance.token(
        expandUtxos.fold(BigInt.zero,
            (previousValue, element) => previousValue + element.amount.balance),
        address.network.token,
        immutable: true,
        allowNegative: false);
    return ZcashAccountWithUtxos._(
      address: address,
      sumOfUtxos: sumOfUtxos,
      utxosWithBalance: expandUtxos,
    );
  }
  final IZcashAddress address;
  final List<ZcashUtxoWithBalanceInfo> utxosWithBalance;
  final IntegerBalance sumOfUtxos;

  void updateUtxosConfirmation(int blockHeight) {
    for (final i in utxosWithBalance) {
      i.updateConfirmation(blockHeight);
    }
  }

  ZcashAccountWithUtxos mergeProtocol(
      ZcashAccountWithUtxos other, ZcashProtocol protocol) {
    assert(address == other.address);
    assert(other.utxosWithBalance.every((e) => e.utxo.protocol == protocol));
    final utxos = [
      ...utxosWithBalance.where((e) => e.utxo.protocol != protocol),
      ...other.utxosWithBalance
    ];
    final IntegerBalance sumOfUtxos = IntegerBalance.token(
        utxos.fold(BigInt.zero,
            (previousValue, element) => previousValue + element.amount.balance),
        this.sumOfUtxos.token,
        immutable: true,
        allowNegative: false);
    return ZcashAccountWithUtxos._(
        address: address, utxosWithBalance: utxos, sumOfUtxos: sumOfUtxos);
  }
}

sealed class IZcashTransactionOutput {
  ZcashTransactionOutput toOutput();
}

sealed class IZcashTransfableTransactionOutput implements IZcashTransactionOutput {
  IntegerBalance get amount;
  ReceiptAddress<ZcashAddress> get address;
  ZcashProtocol get protocol;
  ZcashTransactionMemo? get memo;
}

class ZcashTransactionShieldOutput implements IZcashTransfableTransactionOutput {
  @override
  final ReceiptAddress<ZcashAddress> address;
  @override
  final ZcashProtocol protocol;
  @override
  final IntegerBalance amount;
  @override
  final ZcashTransactionMemoShielded? memo;
  final ZcashAccountInfoShield? change;
  const ZcashTransactionShieldOutput(
      {required this.address,
      required this.protocol,
      required this.amount,
      this.change,
      this.memo});

  @override
  ZcashTransactionOutput toOutput() {
    return ZcashTransactionOutputShielded(
        address: address.networkAddress,
        amount: amount.balance,
        protocol: protocol,
        memo: memo,
        change: change);
  }
}

sealed class IZcashTransparentOutput extends IZcashTransactionOutput {
  @override
  ZcashTransactionOutputTransparent toOutput();
}

class ZcashTransactionTransparentOutput
    implements IZcashTransparentOutput, IZcashTransfableTransactionOutput {
  @override
  final ReceiptAddress<ZcashAddress> address;
  @override
  final ZcashProtocol protocol;
  @override
  final IntegerBalance amount;
  const ZcashTransactionTransparentOutput({
    required this.address,
    // required this.protocol,
    required this.amount,
  }) : protocol = ZcashProtocol.transparent;

  @override
  ZcashTransactionOutputTransparent toOutput() =>
      ZcashTransactionOutputTransparent.transfer(
          address: address.networkAddress, amount: amount.balance);

  @override
  ZcashTransactionMemo<dynamic>? get memo => null;
}

class ZcashTransactionTransparentMemo implements IZcashTransparentOutput {
  factory ZcashTransactionTransparentMemo(ZcashTransactionMemoTransparent memo) {
    return ZcashTransactionTransparentMemo._(memo);
  }
  factory ZcashTransactionTransparentMemo.fromScript(Script script) {
    final contentBytes = BitcoinScriptUtils.getOpRetrunContentBytes(script);
    String? content;
    if (contentBytes != null) {
      content = StringUtils.tryDecode(contentBytes);
    }
    return ZcashTransactionTransparentMemo._(
        ZcashTransactionMemoTransparent.fromScript(script, content: content));
  }

  ZcashTransactionTransparentMemo._(this.memo);

  final ZcashTransactionMemoTransparent memo;

  @override
  ZcashTransactionOutputTransparent toOutput() =>
      ZcashTransactionOutputTransparent.opReturn(memo);
}

class ZcashTransactionFeeInfo {
  final int trasparentInputSizes;
  final int transparentOutputSizes;
  final int saplingInputCount;
  final int saplingOutputCount;
  final int orchardInputCount;
  final int orchardOutputCount;
  const ZcashTransactionFeeInfo._(
      {required this.trasparentInputSizes,
      required this.transparentOutputSizes,
      required this.saplingInputCount,
      required this.saplingOutputCount,
      required this.orchardInputCount,
      required this.orchardOutputCount});
  factory ZcashTransactionFeeInfo(
      {required List<ZcashUtxoWithBalanceInfo> inputs,
      required List<IZcashTransactionOutput> outputs}) {
    return ZcashTransactionFeeInfo._(
        trasparentInputSizes: inputs.fold<int>(
            0,
            (p, c) =>
                p +
                switch (c.utxo.utxo) {
                  ZcashUtxoTransparent utxo => () {
                      final receiver = c.address.cast<ZcashAccountInfoTransparent>();
                      final tAddr = c.account.account.toTransparentAddress();
                      if (tAddr == null) {
                        throw AppInternalError.internalError("Invalid utxo accout info");
                      }
                      final scriptSig = TransparentPcztUtils.generateScriptSig(
                        TransparentPcztInput(
                          prevoutTxid: utxo.utxo.txId,
                          prevoutIndex: utxo.utxo.vout,
                          value: utxo.amount,
                          scriptPubkey: tAddr.toScriptPubKey(),
                          redeemScript: receiver.redeemScript,
                          sighashType: BitcoinOpCodeConst.sighashAll,
                        ),
                        fake: true,
                      );
                      final s = TransparentTxInput(
                          txId: utxo.utxo.txId,
                          txIndex: utxo.utxo.vout,
                          scriptSig: scriptSig);
                      return s.toSerializeBytes().length;
                    }(),
                  _ => 0
                }),
        transparentOutputSizes: outputs.fold<int>(
            0,
            (p, c) =>
                p +
                switch (c) {
                  ZcashTransactionShieldOutput() => 0,
                  IZcashTransparentOutput memo =>
                    memo.toOutput().toTxOutput().toSerializeBytes().length,
                }),
        saplingInputCount: inputs.where((e) => e.address.protocol.isSapling).length,
        saplingOutputCount: outputs
            .where((e) => switch (e) {
                  ZcashTransactionShieldOutput output => output.protocol.isSapling,
                  _ => false
                })
            .length,
        orchardOutputCount: outputs
            .where((e) => switch (e) {
                  ZcashTransactionShieldOutput output => output.protocol.isOrchard,
                  _ => false
                })
            .length,
        orchardInputCount: inputs.where((e) => e.address.protocol.isOrchard).length);
  }

  @override
  String toString() {
    return "trasparentInputSizes: $trasparentInputSizes, transparentOutputSizes: $transparentOutputSizes, saplingInputCount: $saplingInputCount, saplingOutputCount: $saplingOutputCount orchardInputCount: $orchardInputCount, orchardOutputCount: $orchardOutputCount";
  }
}

enum ZcashTransactionSpenderPrivacy {
  auto,
  shieldOnly;

  bool get isShieldOnly => this == shieldOnly;
}

sealed class SaplingPickParamOptions {}

class SaplingPickParamsDownload implements SaplingPickParamOptions {}

class SaplingPickParamsFile implements SaplingPickParamOptions {
  final ICrossFile file;
  const SaplingPickParamsFile(this.file);
}
