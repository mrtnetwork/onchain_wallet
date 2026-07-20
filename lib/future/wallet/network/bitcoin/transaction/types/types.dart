import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/bitcoin/bitcoin.dart';
import 'package:on_chain_wallet/crypto/networks/bitcoin_cash/bitcoin_cash_utils.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

enum TransactionOrdering {
  bip69("bip_69_desc"),
  shuffle("shuffle_desc"),
  none("none_ordering_transaction_desc"),
  manually("manually_ordering_transaction_desc");

  const TransactionOrdering(this.desc);
  final String desc;

  BitcoinOrdering get ordering {
    switch (this) {
      case TransactionOrdering.none:
      case TransactionOrdering.manually:
        return BitcoinOrdering.none;
      case TransactionOrdering.shuffle:
        return BitcoinOrdering.shuffle;
      default:
        return BitcoinOrdering.bip69;
    }
  }
}

enum BitcoinTransactionOperations implements TransactionOperations {
  transfer("transfer");

  @override
  final String value;
  const BitcoinTransactionOperations(this.value);
}

class BitcoinAccountWithUtxos {
  const BitcoinAccountWithUtxos._(
      {required this.address,
      required this.utxoAddressDetails,
      required this.utxosWithBalance,
      required this.sumOfUtxos});
  factory BitcoinAccountWithUtxos(
      {required IBitcoinAddress address,
      required UtxoAddressDetails addressDetails,
      required List<BitcoinUtxoWithSpendingInfo> utxos,
      required WalletBitcoinNetwork network}) {
    final List<BitcoinUtxoInfo> utxosWithBalance = utxos
        .map((e) => BitcoinUtxoInfo(address: address, network: network, utxo: e))
        .toList();
    final IntegerBalance sumOfUtxos = IntegerBalance.token(
        utxos.fold(
            BigInt.zero, (previousValue, element) => previousValue + element.utxo.value),
        network.token,
        immutable: true,
        allowNegative: false);
    return BitcoinAccountWithUtxos._(
        address: address,
        sumOfUtxos: sumOfUtxos,
        utxosWithBalance: utxosWithBalance,
        utxoAddressDetails: addressDetails);
  }
  final IBitcoinAddress address;
  final UtxoAddressDetails utxoAddressDetails;
  final List<BitcoinUtxoInfo> utxosWithBalance;
  final IntegerBalance sumOfUtxos;

  void updateUtxosConfirmation(int blockHeight) {
    for (final i in utxosWithBalance) {
      i.updateConfirmation(blockHeight);
    }
  }
}

class BitcoinPsbtInputWithAccount {
  final UtxoAddressDetails? owner;
  final ReceiptAddress<BitcoinNetworkAddress> address;
  final IBitcoinAddress? ownerAddress;
  final TxInput input;
  final int index;
  final IntegerBalance balance;
  final int sighash;
  final bool hasChangableOutput;
  BitcoinPsbtInputWithAccount(
      {required this.owner,
      required this.input,
      required this.index,
      required this.address,
      required this.sighash,
      required this.ownerAddress,
      required WalletBitcoinNetwork network,
      BigInt? value})
      : balance = IntegerBalance.token(value ?? BigInt.zero, network.token,
            allowNegative: false, immutable: true),
        hasChangableOutput = PsbtUtils.canChangeOutput(sighash);
  BitcoinPsbtInputWithAccount copyWith(
      {required WalletBitcoinNetwork network,
      UtxoAddressDetails? owner,
      TxInput? input,
      int? index,
      ReceiptAddress<BitcoinNetworkAddress>? address,
      BigInt? value,
      int? sighash,
      IBitcoinAddress? ownerAddress,
      bool? hasChangableOutput}) {
    return BitcoinPsbtInputWithAccount(
        network: network,
        owner: owner ?? this.owner,
        input: input ?? this.input,
        index: index ?? this.index,
        address: address ?? this.address,
        value: value ?? balance.balance,
        sighash: sighash ?? this.sighash,
        ownerAddress: ownerAddress ?? this.ownerAddress);
  }
}

class BitcoinUtxoInfo with Equality {
  BitcoinUtxoInfo({
    required this.utxo,
    required WalletBitcoinNetwork network,
    required this.address,
  })  : balance = IntegerBalance.token(utxo.utxo.value, network.token,
            allowNegative: false, immutable: true),
        cashToken = utxo.utxo.token == null
            ? null
            : BCHCashToken(cashToken: utxo.utxo.token!, txHash: utxo.utxo.txHash);

  final BitcoinUtxoWithSpendingInfo utxo;
  final IBitcoinAddress address;
  final IntegerBalance balance;
  String get txHash => utxo.utxo.txHash;
  int get index => utxo.utxo.vout;
  final BCHCashToken? cashToken;

  int get blockHeight => utxo.utxo.blockHeight;
  bool get inMempool => utxo.confirmation.inMempool;

  UtxoWithAddress toUtxoWithAdress() {
    return UtxoWithAddress(utxo: utxo.utxo, ownerDetails: address.toUtxoRequest);
  }

  void updateConfirmation(int blockHeight) {
    utxo.confirmation.update(blockHeight);
  }

  @override
  List get variables => [utxo];
}

class PsbtBitcoinOutputWithBalance {
  PsbtBitcoinOutputWithBalance._(
      {required this.balance,
      required this.address,
      required this.script,
      required this.change,
      required this.scriptPubKey,
      this.opReturns});

  factory PsbtBitcoinOutputWithBalance({
    required Script scriptPubKey,
    required BigInt balance,
    required WalletBitcoinNetwork network,
    ReceiptAddress<BitcoinNetworkAddress>? address,
  }) {
    final scriptHex = scriptPubKey.toHex();
    if (address != null) {
      return PsbtBitcoinOutputWithBalance._(
          balance: IntegerBalance.token(balance, network.token,
              allowNegative: false, immutable: true),
          address: address,
          script: scriptHex,
          change: address.isAccount,
          scriptPubKey: scriptPubKey);
    }
    final isOpReturn = BitcoinScriptUtils.isOpReturn(scriptPubKey);
    List<String>? opReturns;
    if (isOpReturn && scriptPubKey.script.length > 1) {
      opReturns = scriptPubKey.script
          .sublist(1)
          .map((e) =>
              StringUtils.tryDecode(BytesUtils.tryFromHexString(e.toString())) ??
              e.toString())
          .toList();
    }
    return PsbtBitcoinOutputWithBalance._(
        balance: IntegerBalance.token(balance, network.token,
            allowNegative: false, immutable: true),
        address: address,
        script: scriptHex,
        opReturns: opReturns?.join(", "),
        change: false,
        scriptPubKey: scriptPubKey);
  }

  final IntegerBalance balance;
  final ReceiptAddress<BitcoinNetworkAddress>? address;
  final String script;
  final Script scriptPubKey;
  final String? opReturns;
  final bool change;
  BitcoinBaseOutput toOutput() {
    if (address == null) {
      return BitcoinScriptOutput(script: scriptPubKey, value: balance.balance);
    }
    return BitcoinOutput(
        address: address!.networkAddress.baseAddress, value: balance.balance);
  }
}

class BCHCashToken {
  final String? txHash;
  factory BCHCashToken({required CashToken cashToken, String? txHash}) {
    final balance = IntegerBalance.token(cashToken.amount,
        Token(name: cashToken.category, symbol: cashToken.category, decimal: 0),
        immutable: true);
    String? commitment = cashToken.commitmentInHex;
    if (commitment != null) {
      commitment = StringUtils.tryDecode(cashToken.commitment) ?? commitment;
    }
    return BCHCashToken._(
        cashToken: cashToken, balance: balance, commitment: commitment, txHash: txHash);
  }
  BCHCashToken._(
      {required this.cashToken,
      required this.balance,
      required this.commitment,
      required this.txHash});

  final CashToken cashToken;
  final IntegerBalance balance;
  final String? commitment;
  Token get token => balance.token;
  bool get hasCommitment => cashToken.hasCommitment;
  CashTokenCapability? get capability => cashToken.capability;

  late final bool isImmutable =
      cashToken.hasNFT && capability == CashTokenCapability.noCapability;

  late final bool isMutable =
      cashToken.hasNFT && cashToken.capability == CashTokenCapability.mutable;
  bool get hasAmount => cashToken.hasAmount;
  bool get isNFT => cashToken.hasNFT;
}

class BitcoinTransactionFee extends TransactionFee {
  final int? satoshiPerByte;
  static IntegerBalance getEstimate(
      {required int txSize, required BigInt feePerKB, required Token feeToken}) {
    final trSizeBigInt = BigInt.from(txSize);
    return IntegerBalance.token((trSizeBigInt * feePerKB) ~/ BigInt.from(1000), feeToken,
        allowNegative: false, immutable: true);
  }

  BitcoinTransactionFee._({
    required super.type,
    required super.fee,
    required this.satoshiPerByte,
    super.error,
  }) : super(description: satoshiPerByte == null ? null : "$satoshiPerByte sat/vB");
  factory BitcoinTransactionFee(
      {required Token feeToken,
      required TxFeeTypes type,
      required BigInt feePerKB,
      required int transactionSize,
      String? error}) {
    if (feePerKB == BigInt.zero) {
      return BitcoinTransactionFee._(
          type: type,
          fee: IntegerBalance.zero(feeToken),
          satoshiPerByte: 0,
          error: error);
    }
    final fee =
        getEstimate(txSize: transactionSize, feePerKB: feePerKB, feeToken: feeToken);
    final int satoshiPerByte = (feePerKB ~/ BigInt.from(1000)).toInt();
    return BitcoinTransactionFee._(
        type: type, fee: fee, satoshiPerByte: satoshiPerByte, error: error);
  }
  factory BitcoinTransactionFee.manual(
      {required Token feeToken, required BigInt fee, int? transactionSize}) {
    if (transactionSize == null) {
      return BitcoinTransactionFee._(
          fee: IntegerBalance.token(fee, feeToken, allowNegative: false, immutable: true),
          type: TxFeeTypes.manually,
          satoshiPerByte: null);
    }
    final int satoshiPerByte = (fee ~/ BigInt.from(transactionSize)).toInt();
    return BitcoinTransactionFee._(
      type: TxFeeTypes.manually,
      fee: IntegerBalance.token(fee, feeToken, allowNegative: false, immutable: true),
      satoshiPerByte: satoshiPerByte,
    );
  }
}

class BitcoinMemo {
  factory BitcoinMemo(String memo) {
    return BitcoinMemo._(
        memo,
        BitcoinScriptOutput(script: BTCUtils.toOpreturn([memo]), value: BigInt.zero),
        true);
  }
  BitcoinMemo._(this.memo, this.script, this.removable);
  factory BitcoinMemo.fromScript(BitcoinScriptOutput script, String memo) {
    return BitcoinMemo._(memo, script, false);
  }
  final String memo;
  final BitcoinScriptOutput script;
  final bool removable;

  IBitcoinOutput toOutput() {
    return MemoTxOutput(memo: memo, output: script);
  }
}

typedef ONPSBTSIGNINGREQUEST = Future<List<int>> Function(PsbtSigningInputDigest);

class BitcoonPsbtSigner extends PsbtBtcSigner<SignInputResponse, PsbtSigningInputDigest> {
  final ONPSBTSIGNINGREQUEST signer;
  BitcoonPsbtSigner._({required this.signer, required this.signerPublicKey});
  factory BitcoonPsbtSigner(
      {required ECPublic publicKey, required ONPSBTSIGNINGREQUEST signer}) {
    return BitcoonPsbtSigner._(signer: signer, signerPublicKey: publicKey);
  }
  @override
  SignInputResponse btcSignInput(PsbtSignInputDigest digest) {
    throw UnimplementedError('use btcSignInputAsync for signing.');
  }

  @override
  Future<SignInputResponse> btcSignInputAsync(PsbtSigningInputDigest digest) async {
    final signature = await signer(digest);
    return SignInputResponse(signature: signature, signerPublicKey: signerPublicKey);
  }

  @override
  final ECPublic signerPublicKey;
}

class BitcoinTransactionFeeData extends TransactionDynamicFeeData<BitcoinTransactionFee> {
  int? _transactionSize;
  int? get transactionSize => _transactionSize;

  BitcoinTransactionFeeData({
    required super.select,
    required super.feeToken,
    int? transactionSize,
  });

  void onUpdateTransactionSize(int transactionSize) {
    _transactionSize = transactionSize;
    if (fee.isManual) {
      setManualFee(BitcoinTransactionFee.manual(
          feeToken: feeToken, fee: fee.fee.balance, transactionSize: transactionSize));
    }
  }

  @override
  BitcoinTransactionFee createManualFee(BigInt amount) {
    return BitcoinTransactionFee.manual(
        feeToken: feeToken, fee: amount, transactionSize: transactionSize);
  }
}

abstract class BaseBitcoinTransactionController extends TransactionStateController<
    TokenCore,
    WalletBitcoinNetwork,
    IBitcoinAddress,
    BitcoinNetworkClient,
    BitcoinChain,
    IBitcoinTransactionData,
    IBitcoinTransaction,
    IBitcoinSignedTransaction,
    BitcoinWalletTransaction,
    SubmitTransactionSuccess<IBitcoinSignedTransaction>,
    BitcoinTransactionFeeData> {
  BaseBitcoinTransactionController(
      {required super.walletProvider, required super.account, required super.address});
}

class IBitcoinTransactionData extends ITransactionData {
  final List<UtxoWithAddress> utxos;
  final bool enableRBF;
  final BitcoinOrdering ordering;
  final List<IBitcoinTransactionDataTransfer> destinations;
  final BitcoinTransactionFee fee;
  final List<IBitcoinOutput> outputs;
  IBitcoinTransactionData(
      {required this.fee,
      required this.ordering,
      required this.enableRBF,
      required List<UtxoWithAddress> utxos,
      required List<IBitcoinTransactionDataTransfer> destinations,
      required List<IBitcoinOutput> outputs})
      : destinations = destinations.immutable,
        outputs = outputs.immutable,
        utxos = utxos.immutable;
}

class IBitcoinTransactionDataTransfer {
  final BitcoinNetworkAddress recipient;
  final BigInt amount;
  final BCHCashToken? token;
  IBitcoinTransactionDataTransfer({
    required this.recipient,
    required this.amount,
    this.token,
  });
}

class IBitcoinTransaction extends ITransaction<IBitcoinTransactionData, IBitcoinAddress> {
  final BasedBitcoinTransacationBuilder transaction;
  final List<IBitcoinAddress> accounts;
  const IBitcoinTransaction(
      {required super.account,
      required super.transactionData,
      required this.transaction,
      required this.accounts});
}

class IBitcoinSignedTransaction
    extends ISignedTransaction<IBitcoinTransaction, BtcTransaction> {
  IBitcoinSignedTransaction(
      {required super.transaction,
      required super.signatures,
      required super.finalTransactionData});
}

sealed class BitcoinAccountUtxosStatus {
  bool get isSuccess => false;
  bool get isPending => false;
  bool get isError => false;
  bool get retryable => false;
  const BitcoinAccountUtxosStatus();
}

class BitcoinAccountUtxosStatusPending extends BitcoinAccountUtxosStatus {
  const BitcoinAccountUtxosStatusPending();
  @override
  bool get isPending => true;
}

class BitcoinAccountUtxosStatusSuccess extends BitcoinAccountUtxosStatus {
  const BitcoinAccountUtxosStatusSuccess();
  @override
  bool get isSuccess => true;
}

class BitcoinAccountUtxosStatusErr extends BitcoinAccountUtxosStatus {
  final String message;
  @override
  bool get isError => true;
  @override
  final bool retryable;
  const BitcoinAccountUtxosStatusErr(this.message, {this.retryable = true});
}

class BitcoinAccountFetchedUtxos with DisposableMixin, Equality, StreamStateController {
  final lock = SafeAtomicLock();
  final IBitcoinAddress address;
  BitcoinAccountFetchedUtxos({required this.address})
      : totalUtxo = IntegerBalance.token(BigInt.zero, address.network.token,
            allowNegative: false);
  BitcoinAccountUtxosStatus status = BitcoinAccountUtxosStatusPending();
  BitcoinAccountWithUtxos? _utxos;
  BitcoinAccountWithUtxos? get utxos => _utxos;
  List<BitcoinUtxoInfo> _selectedUtxos = [];
  List<BitcoinUtxoInfo> get selectedUtxos => _selectedUtxos;
  bool get isSuccess => status.isSuccess;
  bool get isPending => status.isPending;
  bool get hasUtxos => isSuccess && _utxos!.utxosWithBalance.isNotEmpty;
  bool _allSelected = false;
  int _totalSelected = 0;
  bool get allSelected => _allSelected;
  int get totalSelected => _totalSelected;

  final IntegerBalance totalUtxo;
  bool isSelected(BitcoinUtxoInfo utxo) {
    return _selectedUtxos.contains(utxo);
  }

  void _update() {
    _totalSelected = _selectedUtxos.length;
    _allSelected = _selectedUtxos.length == utxos?.utxosWithBalance.length;
    totalUtxo.updateBalance(
        _selectedUtxos.fold<BigInt>(BigInt.zero, (p, c) => p + c.utxo.utxo.value));
    notify();
  }

  void onHeightUpdated(int blockHeight) async {
    utxos?.updateUtxosConfirmation(blockHeight);
    notify();
  }

  Future<void> addUtxo(BitcoinUtxoInfo utxo, StringVoid onErr) async {
    await lock.run(() async {
      final utxos = _utxos;
      assert(utxos != null && utxos.utxosWithBalance.contains(utxo),
          "utxo does not exists.");
      if (utxos == null) return;
      if (!_selectedUtxos.remove(utxo)) {
        if (!utxo.utxo.confirmation.confirmed) {
          onErr("utxos_is_not_confirmed_yet".tr);
        } else {
          _selectedUtxos.add(utxo);
        }
      }
      _update();
    }, lockId: LockId.two);
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
        onErr("select_all_utxos_failed_due_unconfirmation_desc".tr);
      }
    }, lockId: LockId.two);
  }

  void _selectAll() {
    final utxos = _utxos;
    assert(utxos != null, "utxo does not exists.");
    if (utxos == null) {
      return;
    }

    final confirmedUtxos =
        utxos.utxosWithBalance.where((e) => e.utxo.confirmation.confirmed).toList();
    _selectedUtxos = confirmedUtxos;
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
        onErr("select_all_utxos_failed_due_unconfirmation_desc".tr);
      }
    }, lockId: LockId.two);
  }

  Future<void> setUtxos(BitcoinAccountWithUtxos utxos) async {
    await lock.run(() async {
      assert(!status.isSuccess);
      _utxos = utxos;
      status = BitcoinAccountUtxosStatusSuccess();
      notify();
    }, lockId: LockId.two);
  }

  void setError(BitcoinAccountUtxosStatusErr err) {
    lock.run(() {
      if (isSuccess) return;
      status = err;
      notify();
    }, lockId: LockId.two);
  }

  Future<void> setPending() async {
    await lock.run(() async {
      if (!status.retryable) return;
      status = BitcoinAccountUtxosStatusPending();
      notify();
    }, lockId: LockId.two);
  }

  Future<bool> merge({required BitcoinAccountWithUtxos utxos}) async {
    return await lock.run(() async {
      if (status.isPending) return false;
      if (status.isError) {
        _utxos = utxos;
        status = BitcoinAccountUtxosStatusSuccess();
        notify();
        return true;
      }
      final cUtxos = _utxos;
      if (cUtxos == null) return false;
      assert(utxos.address == _utxos?.address);
      bool changed = false;
      final List<BitcoinUtxoInfo> selectedUtxos = [];
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

  @override
  List get variables => [address];
}

class BitcoinTransferDetails with DisposableMixin, StreamStateController {
  TransactionStateStatus _status = TransactionStateStatus.error();
  TransactionStateStatus get status => _status;
  BitcoinCashCashTokenTransfer? _token;
  BitcoinCashCashTokenTransfer? get token => _token;
  bool get hasToken => _token != null;
  final ReceiptAddress<BitcoinNetworkAddress> recipient;
  bool get hasAmount => amount.largerThanZero;
  bool get isReady => _status.isReady;
  final IntegerBalance amount;

  List<IBitcoinTransactionDataTransfer> toTransferInfo() {
    final token = this.token;
    assert(isReady);
    return [
      IBitcoinTransactionDataTransfer(
        recipient: recipient.networkAddress,
        amount: amount.balance,
      ),
      if (token != null)
        IBitcoinTransactionDataTransfer(
            recipient: recipient.networkAddress,
            amount: amount.balance,
            token: token.cashToken),
    ];
  }

  TransactionStateStatus getStateStatus() {
    if (!hasAmount) return TransactionStateStatus.error();
    final token = this.token;

    if (token == null) return TransactionStateStatus.ready();
    if (!token.isReady) return TransactionStateStatus.error();
    if (amount.balance < BCHUtils.minimumOutput) {
      final miniumAmount = "${BCHUtils.minimumOutput} ${amount.token.symbol}";
      return TransactionStateStatus.error(
          error: "price_greather_than".tr.replaceOne(miniumAmount));
    }
    if (token.cashToken.hasAmount &&
        !token.cashToken.isImmutable &&
        token.tokenAmount.value.isZero) {
      return TransactionStateStatus.error(error: "amount_must_be_greater_than_zero".tr);
    }
    switch (recipient.networkAddress.type) {
      case P2pkhAddressType.p2pkhwt:
      case P2shAddressType.p2pkhInP2sh32wt:
      case P2shAddressType.p2pkInP2sh32wt:
      case P2shAddressType.p2pkhInP2shwt:
      case P2shAddressType.p2pkInP2shwt:
        if (amount.balance > BCHUtils.maxTokenOutputNativAmount) {
          return TransactionStateStatus.ready(
              warning: "sending_large_bch_to_token_address_desc".tr);
        }
      default:
        return TransactionStateStatus.ready(
            warning: "sending_token_to_non_bitcoin_cash_token_address_desc".tr);
    }
    return TransactionStateStatus.ready();
  }

  void onUpdateStatus() {
    _status = getStateStatus();
    notify();
  }

  BitcoinTransferDetails({
    required this.recipient,
    required Token token,
    bool allowNegative = false,
  }) : amount = IntegerBalance.zero(token, allowNegative: allowNegative);

  void updateBalance(BigInt amount) {
    this.amount.updateBalance(amount);
    onUpdateStatus();
  }

  void onUpdateToken(BitcoinCashCashTokenTransfer token) {
    _token = token;
    onUpdateStatus();
  }

  void onRemoveToken(BCHCashToken token) {
    assert(this.token != null && this.token?.cashToken == token);
    _token = null;
    onUpdateStatus();
  }

  IBitcoinOutput toOutput() {
    final token = this.token;
    if (token != null) {
      return SpendableTxOutput(
          output: token.toOutput(
              recipient: recipient.networkAddress.baseAddress, amount: amount.balance),
          address: recipient.networkAddress);
    }
    return SpendableTxOutput(
        output: BitcoinOutput(
            address: recipient.networkAddress.baseAddress, value: amount.balance),
        address: recipient.networkAddress);
  }

  List get variables => [recipient.view];
}

class BitcoinRemainTransferDetails with DisposableMixin, StreamStateController {
  ReceiptAddress<BitcoinNetworkAddress> _recipient;
  ReceiptAddress<BitcoinNetworkAddress> get recipient => _recipient;
  bool get hasAmount => amount.largerThanZero;
  bool get isReady => hasAmount;
  final IntegerBalance amount;
  BitcoinRemainTransferDetails({
    required ReceiptAddress<BitcoinNetworkAddress> recipient,
    required WalletBitcoinNetwork network,
  })  : amount = IntegerBalance.zero(network.token),
        _recipient = recipient;

  void updateBalance(BigInt amount) {
    this.amount.updateBalance(amount);
    notify();
  }

  void onUpdateRecipient(ReceiptAddress<BitcoinNetworkAddress> recipient) {
    _recipient = recipient;
    notify();
  }

  IBitcoinOutput? toOutput() {
    if (!hasAmount) return null;
    final recipient = _recipient.networkAddress;
    return SpendableTxOutput(
        output: BitcoinOutput(address: recipient.baseAddress, value: amount.balance),
        address: recipient);
  }
}

class BitcoinRemainCashTokenTransferDetails with DisposableMixin, StreamStateController {
  final WalletBitcoinNetwork network;
  final List<BitcoinCashCashTokenOperation> _transfers = [];
  final List<BitcoinCashCashTokenBurn> _burns = [];
  List<BitcoinCashCashTokenBurn> get burns => _burns;
  List<BCHCashToken> _tokens = [];
  List<BCHCashToken> get tokens => _tokens;
  List<BitcoinCashCashTokenRemainTransfer> _tokenRemains = [];
  List<BitcoinCashCashTokenRemainTransfer> get tokenRemains => _tokenRemains;
  ReceiptAddress<BitcoinNetworkAddress> _recipient;
  ReceiptAddress<BitcoinNetworkAddress> get recipient => _recipient;
  BitcoinRemainCashTokenTransferDetails({
    required ReceiptAddress<BitcoinNetworkAddress> recipient,
    required this.network,
  }) : _recipient = recipient;
  List<IBitcoinOutput> toOutputs() {
    return [
      ..._burns.map((e) => e.toOutput()),
      ..._tokenRemains.map((e) => e.toOutput(recipient.networkAddress)),
    ];
  }

  BigInt totalNativeAmount() {
    return _tokenRemains.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.balance);
  }

  BigInt getTokenRemainAmount(BitcoinCashCashTokenOperation transfer) {
    final remain = _tokenRemains.firstWhereOrNull((e) => e.token == transfer.cashToken);
    if (remain == null) return transfer.amount;
    final amount = remain.getTokenRemainAmount();
    return amount + transfer.amount;
  }

  void _clearState() {
    for (final i in [..._burns]) {
      i.dispose();
    }
    for (final i in [..._transfers]) {
      i.dispose();
    }
    for (final i in [..._tokenRemains]) {
      i.dispose();
    }
    _burns.clear();
    _transfers.clear();
    _tokens = [];
    _tokenRemains = [];
  }

  BigInt _getTokenTotalUsed(BCHCashToken token) {
    BigInt tokenTransfers = _transfers
        .where((e) => e.cashToken == token)
        .fold<BigInt>(BigInt.zero, (p, c) => p + c.amount);
    final burn = burns.firstWhereOrNull((e) => e.cashToken == token);
    if (burn != null) {
      tokenTransfers += burn.amount;
    }
    return tokenTransfers;
  }

  void onUpdateRecipient(ReceiptAddress<BitcoinNetworkAddress> recipient) {
    _recipient = recipient;
    notify();
  }

  void onUpdateTokenUtxos(List<BCHCashToken> tokens) {
    final List<BCHCashToken> nftTokens =
        tokens.where((element) => element.isNFT).toList();
    final List<BCHCashToken> ftTokens =
        tokens.where((element) => !element.isNFT).toList();
    final Map<String, CashToken> sumFtTokens = {};
    for (final i in ftTokens) {
      final amount = sumFtTokens[i.cashToken.category]?.amount ?? BigInt.zero;
      sumFtTokens[i.cashToken.category] =
          i.cashToken.copyWith(amount: amount + i.cashToken.amount);
    }
    _clearState();
    _tokens = [
      ...nftTokens,
      ...sumFtTokens.values.map((e) => BCHCashToken(cashToken: e))
    ];
    _tokenRemains = _tokens
        .map((e) => BitcoinCashCashTokenRemainTransfer(token: e, network: network))
        .toList();
    notify();
  }

  void onUpdateTransferAmount(BitcoinCashCashTokenTransfer transfer, BigInt amount) {
    assert(_transfers.contains(transfer));
    assert(!transfer.isImmutable && transfer.cashToken.hasAmount);
    if (transfer.isImmutable || !transfer.cashToken.hasAmount) return;
    BigInt tokenTransfers = _getTokenTotalUsed(transfer.cashToken);
    BigInt total = transfer.cashToken.balance.balance - tokenTransfers - amount;
    assert(!total.isNegative);
    if (total.isNegative) return;
    transfer.onUpdateAmount(amount);
    BitcoinCashCashTokenRemainTransfer? remain =
        _tokenRemains.firstWhereOrNull((e) => e.token == transfer.cashToken);
    if (total > BigInt.zero && remain == null) {
      remain =
          BitcoinCashCashTokenRemainTransfer(token: transfer.cashToken, network: network);
      _tokenRemains.add(remain);
    }
    if (total == BigInt.zero) {
      _tokenRemains.remove(remain);
      remain?.dispose();
    } else {
      remain?.onUpdateRemaindTokenAmount(total);
    }

    notify();
  }

  void onRemoveToken(BitcoinCashCashTokenOperation transfer) {
    assert(_tokens.contains(transfer.cashToken), "unknown token");
    assert(_transfers.contains(transfer));
    _transfers.remove(transfer);
    if (transfer.isImmutable || !transfer.cashToken.hasAmount) {
      assert(!_tokenRemains.any((e) => e.token == transfer.cashToken),
          "somthing wrong, token already exists");
      _tokenRemains.add(BitcoinCashCashTokenRemainTransfer(
          token: transfer.cashToken, network: network));
    } else {
      BitcoinCashCashTokenRemainTransfer? remain =
          _tokenRemains.firstWhereOrNull((e) => e.token == transfer.cashToken);
      BigInt tokenTransfers = _getTokenTotalUsed(transfer.cashToken);
      final total = transfer.cashToken.balance.balance - tokenTransfers;
      assert(total > BigInt.zero);
      if (remain == null && total > BigInt.zero) {
        remain = BitcoinCashCashTokenRemainTransfer(
            token: transfer.cashToken, network: network);
        _tokenRemains.add(remain);
      }
      remain?.onUpdateRemaindTokenAmount(total);
    }
    notify();
  }

  void onUpdateTransferToken(BitcoinTransferDetails recipient, BCHCashToken? token) {
    assert(_tokens.contains(token), "unknown token");
    if (token == null || !_tokens.contains(token)) return;
    final remain = _tokenRemains.firstWhereOrNull((e) => e.token == token);
    assert(remain != null);
    if (remain == null) return;
    final tokenTransfer = BitcoinCashCashTokenTransfer(cashToken: token);
    if (tokenTransfer.isImmutable || !tokenTransfer.cashToken.hasAmount) {
      _tokenRemains.remove(remain);
      remain.dispose();
    }
    recipient.onUpdateToken(tokenTransfer);
    _transfers.add(tokenTransfer);
    notify();
  }

  void onUpdateBurn(BitcoinCashCashTokenRemainTransfer remain, {BigInt? amount}) {
    assert(_tokenRemains.contains(remain));
    if (remain.token.isImmutable || !remain.token.hasAmount) {
      assert(amount == null);
      _burns.add(BitcoinCashCashTokenBurn(cashToken: remain.token));
      _tokenRemains.remove(remain);
      remain.dispose();
    } else {
      assert(amount != null, "amount required for burning ft tokens");
      if (amount == null || amount.isNegative) return;
      BitcoinCashCashTokenBurn? burn =
          burns.firstWhereOrNull((e) => e.cashToken == remain.token);
      if (burn == null) {
        burn = BitcoinCashCashTokenBurn(
            cashToken: remain.token, burn: IntegerBalance.zero(remain.token.token));
        burns.add(burn);
      }
      burn.onUpdateAmount(amount + burn.amount);
      BigInt tokenTransfers = _getTokenTotalUsed(remain.token);
      final total = remain.token.balance.balance - tokenTransfers;
      assert(!total.isNegative);
      if (total == BigInt.zero) {
        _tokenRemains.remove(remain);
        remain.dispose();
      } else {
        remain.onUpdateRemaindTokenAmount(total);
      }
    }
    notify();
  }

  void onRemoveBurn(BitcoinCashCashTokenBurn burn) {
    assert(_burns.contains(burn), "unknown burn operation.");
    _burns.remove(burn);
    burn.dispose();
    if (burn.isImmutable || !burn.cashToken.hasAmount) {
      assert(!_tokenRemains.any((e) => e.token == burn.cashToken),
          "somthing wrong. token exists.");
      tokenRemains.add(
          BitcoinCashCashTokenRemainTransfer(token: burn.cashToken, network: network));
    } else {
      BigInt tokenTransfers = _getTokenTotalUsed(burn.cashToken);
      final total = burn.cashToken.balance.balance - tokenTransfers;
      assert(!total.isNegative);
      BitcoinCashCashTokenRemainTransfer? remain =
          _tokenRemains.firstWhereOrNull((e) => e.token == burn.cashToken);
      if (total > BigInt.zero && remain == null) {
        remain ??=
            BitcoinCashCashTokenRemainTransfer(token: burn.cashToken, network: network);
        _tokenRemains.add(remain);
      }
      remain?.onUpdateRemaindTokenAmount(total);
    }
    notify();
  }

  @override
  void dispose() {
    super.dispose();
    _clearState();
  }
}

abstract class BitcoinCashCashTokenOperation {
  final BCHCashToken cashToken;
  BigInt get amount;
  bool get hasCommint => cashToken.hasCommitment;
  bool get isNFT => cashToken.isNFT;
  bool get isImmutable => cashToken.isImmutable;
  bool get isMutable => cashToken.isMutable;
  BitcoinCashCashTokenOperation({required this.cashToken});

  void dispose() {}
}

class BitcoinCashCashTokenBurn extends BitcoinCashCashTokenOperation {
  final IntegerBalance? burn;
  BitcoinCashCashTokenBurn({required super.cashToken, this.burn});
  late final IntegerBalance? viewAmount = () {
    {
      if (cashToken.hasAmount) {
        if (cashToken.isImmutable) return cashToken.balance;
        return burn;
      }
      return null;
    }
  }();
  void onUpdateAmount(BigInt amount) {
    assert(burn != null);
    burn?.updateBalance(amount);
  }

  @override
  BigInt get amount => (burn?.balance ?? BigInt.zero);

  IBitcoinOutput toOutput() {
    BigInt? amount;
    if (cashToken.hasAmount) {
      if (cashToken.isImmutable) {
        amount = cashToken.balance.balance;
      } else {
        amount = burn?.balance;
      }
    }
    return SpendableTxOutput(
        address: null,
        output: BitcoinBurnableOutput(
            categoryID: cashToken.cashToken.category,
            utxoHash: cashToken.txHash,
            value: amount));
  }
}

class BitcoinCashCashTokenTransfer extends BitcoinCashCashTokenOperation {
  bool _isReady = false;
  bool get isReady => _isReady;
  late final LiveFormField<IntegerBalance, IntegerBalance> tokenAmount = LiveFormField(
      title: "amount".tr,
      value: IntegerBalance.zero(cashToken.token, allowNegative: false));
  late final LiveFormField<String?, String?> commitment =
      LiveFormField(title: "commitment".tr, value: cashToken.commitment);
  late final LiveFormField<CashTokenCapability?, CashTokenCapability?> capability =
      LiveFormField(title: "capability".tr, value: cashToken.capability);

  late final IntegerBalance? viewAmount = () {
    {
      if (cashToken.hasAmount) {
        if (cashToken.isImmutable) return cashToken.balance;
        return tokenAmount.value;
      }
      return null;
    }
  }();

  BitcoinCashCashTokenTransfer({required super.cashToken}) : _isReady = cashToken.isNFT;

  @override
  BigInt get amount => tokenAmount.value.balance;
  void onUpdateCommitment(String? commitment) {
    final isValid = isNFT && !isImmutable && onValidateCommitment(commitment) == null;
    assert(isValid);
    if (!isValid) return;
    this.commitment.setValue(commitment);
  }

  void onUpdateCapability(CashTokenCapability? capability) {
    final isValid = isNFT && !isImmutable;
    assert(isValid);
    if (!isValid) return;
    this.capability.setValue(capability);
  }

  void onUpdateAmount(BigInt amount) {
    final isValid = cashToken.hasAmount && !isImmutable;
    assert(isValid);
    if (!isValid) return;
    tokenAmount.value.updateBalance(amount);
    tokenAmount.notify();
    _isReady = isNFT || tokenAmount.value.largerThanZero;
  }

  String? onValidateCommitment(String? v) {
    if (BCHUtils.commitmentValidate(v)) {
      return null;
    }
    return "commitment_validate_desc".tr;
  }

  BitcoinBaseOutput toOutput(
      {required BitcoinBaseAddress recipient, required BigInt amount}) {
    final commitment = cashToken.isNFT && !cashToken.isImmutable
        ? StringUtils.tryToBytes(this.commitment.output)
        : null;
    BigInt? tokenAmount;
    if (cashToken.hasAmount) {
      if (cashToken.isImmutable) {
        tokenAmount = cashToken.balance.balance;
      } else {
        tokenAmount = this.tokenAmount.value.balance;
      }
    }
    final updateToken = cashToken.cashToken.copyWith(
        amount: tokenAmount,
        commitment: commitment,
        bitfield: CashTokenUtils.buildBitfield(
            hasAmount: cashToken.hasAmount,
            capability: cashToken.isNFT ? capability.output : null,
            hasNFT: cashToken.isNFT,
            hasCommitmentLength: (commitment != null && commitment.isNotEmpty)));
    return BitcoinTokenOutput(
        address: recipient,
        value: amount,
        token: updateToken,
        utxoHash: cashToken.txHash);
  }

  @override
  void dispose() {
    super.dispose();
    tokenAmount.dispose();
    commitment.dispose();
    capability.dispose();
  }
}

class BitcoinCashCashTokenRemainTransfer with DisposableMixin, StreamStateController {
  bool get hasCommint => token.hasCommitment;
  bool get isNFT => token.isNFT;
  bool get isImmutable => token.isImmutable;
  bool get isMutable => token.isMutable;
  bool get hasAmount => token.hasAmount;
  bool get hasNativeAmount => amount.largerThanZero;
  final BCHCashToken token;
  final IntegerBalance tokenAmount;
  final IntegerBalance amount;

  BitcoinCashCashTokenRemainTransfer._(
      {required this.token, required this.tokenAmount, required this.amount});
  factory BitcoinCashCashTokenRemainTransfer(
      {required BCHCashToken token, required WalletBitcoinNetwork network}) {
    return BitcoinCashCashTokenRemainTransfer._(
        token: token,
        amount: IntegerBalance.token(BCHUtils.minimumSatoshiTokenOutput, network.token,
            allowNegative: false),
        tokenAmount: IntegerBalance.token(
            token.hasAmount ? token.balance.balance : BigInt.zero, token.token,
            allowNegative: false));
  }

  void onUpdateAmount(BigInt amount) {
    this.amount.updateBalance(amount);
    notify();
  }

  void onUpdateRemaindTokenAmount(BigInt amount) {
    tokenAmount.updateBalance(amount);
    notify();
  }

  BigInt getTokenRemainAmount() {
    if (hasAmount && !token.isImmutable) return tokenAmount.balance;
    return BigInt.zero;
  }

  IBitcoinOutput toOutput(BitcoinNetworkAddress address) {
    return SpendableTxOutput(
        address: address,
        output: BitcoinTokenOutput(
            address: address.baseAddress,
            value: amount.balance,
            token: token.cashToken.copyWith(
              amount:
                  (token.hasAmount && !token.isImmutable) ? tokenAmount.balance : null,
            ),
            utxoHash: token.txHash));
  }
}

class BitcoinSignedTransactionBuilder {
  final BtcTransaction transaction;
  final List<List<int>> signatures;
  BitcoinSignedTransactionBuilder(
      {required this.transaction, required List<List<int>> signatures})
      : signatures = signatures.map((e) => e.asImmutableBytes).toImutableList;
}

class BitcoinSignedPsbt {
  final String psbt;
  final List<List<int>> signatures;
  BitcoinSignedPsbt({required this.psbt, required List<List<int>> signatures})
      : signatures = signatures.map((e) => e.asImmutableBytes).toImutableList;
}

sealed class IBitcoinOutput {
  final BitcoinBaseOutput output;
  final BitcoinNetworkAddress? address;
  const IBitcoinOutput({required this.output, required this.address});
}

class SpendableTxOutput extends IBitcoinOutput {
  const SpendableTxOutput({required super.output, required super.address});

  BitcoinWalletTransactionOutput? toWalletTxOutput(WalletNetwork network) {
    final address = this.address;
    if (address == null) return null;
    return BitcoinWalletTransactionTransferOutput(
        amount: WalletTransactionIntegerAmount(amount: output.value, network: network),
        to: address);
  }
}

class MemoTxOutput extends IBitcoinOutput {
  final String memo;
  const MemoTxOutput({required this.memo, required super.output}) : super(address: null);

  WalletTransactionMemo toWalletTxOutput() {
    return WalletTransactionMemo.from(
        memo,
        switch (StringUtils.isHexBytes(memo)) {
          true => WalletTransactionMemoType.binary,
          false => WalletTransactionMemoType.string
        });
  }
}
