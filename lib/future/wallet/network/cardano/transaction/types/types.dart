import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class CardanoUtxo {
  final ADAAccountUTXOResponse utxo;
  final IntegerBalance utxoBalance;
  const CardanoUtxo._({required this.utxo, required this.utxoBalance});
  factory CardanoUtxo(
      {required ADAAccountUTXOResponse utxo, required WalletCardanoNetwork network}) {
    return CardanoUtxo._(
        utxo: utxo, utxoBalance: IntegerBalance.token(utxo.sumOflovelace, network.token));
  }
}

class ADAAssetToken with Equality {
  final PolicyID id;
  final AssetName name;
  final Token token;
  factory ADAAssetToken({required PolicyID id, required AssetName name}) {
    final assetName = name.name ?? name.toHex();
    return ADAAssetToken._(
        id: id, name: name, token: Token(name: assetName, symbol: assetName, decimal: 0));
  }
  ADAAssetToken._({required this.id, required this.name, required this.token});

  @override
  List get variables => [id, name];
}

enum ADATransactionCertificateType {
  deregistration("stake_deregistration"),
  registraction("stake_registration"),
  delegation("stake_delegation");

  final String viewName;
  const ADATransactionCertificateType(this.viewName);
}

class ADATransactionCertificate {
  final ADACertificateBuilder certificate;
  final ADATransactionCertificateType type;
  final ReceiptAddress<ADAAddress> rewardAccount;
  const ADATransactionCertificate(
      {required this.certificate, required this.type, required this.rewardAccount});
}

enum ADACustomFeeTypes {
  stakeRegistration("stake_registration");

  final String viewName;
  const ADACustomFeeTypes(this.viewName);
}

class ADATransactionDeposit {
  final ADACustomFeeTypes type;
  final IntegerBalance fee;
  ADADepositBuilder toDepositBuilder() {
    return ADADepositBuilder(deposit: fee.balance);
  }

  const ADATransactionDeposit({required this.type, required this.fee});
  factory ADATransactionDeposit.amount(
      {required ADACustomFeeTypes type,
      required BigInt fee,
      required WalletCardanoNetwork network}) {
    return ADATransactionDeposit(
        type: type, fee: IntegerBalance.token(fee, network.token, immutable: true));
  }
}

enum ADATransactionOperations implements TransactionOperations {
  transfer("transfer");

  @override
  final String value;
  const ADATransactionOperations(this.value);
}

class ADATransactionFee extends TransactionFee {
  ADATransactionFee({required super.type, required super.fee, super.error});
}

class ADATransactionFeeData extends TransactionDynamicFeeData<ADATransactionFee> {
  ADATransactionFeeData({required super.select, required super.feeToken});

  @override
  ADATransactionFee createManualFee(BigInt amount) {
    return ADATransactionFee(
        type: TxFeeTypes.manually, fee: IntegerBalance.token(amount, feeToken));
  }
}

class CardanoAccountUtxo with Equality {
  final TransactionUnspentOutput utxo;
  final IntegerBalance utxoBalance;
  final MultiAsset multiAsset;
  final ICardanoAddress address;
  final bool haveAssets;
  final bool hasScript;
  final bool hasReferenceScript;

  CardanoAccountUtxo._(
      {required this.utxo,
      required this.utxoBalance,
      required this.address,
      required this.multiAsset,
      required this.haveAssets,
      required this.hasScript,
      required this.hasReferenceScript});
  factory CardanoAccountUtxo({
    required ADAAddressUtxo utxo,
    required WalletCardanoNetwork network,
    required ICardanoAddress address,
  }) {
    final asset = utxo.output.amount.multiAsset ?? MultiAsset.empty;
    return CardanoAccountUtxo._(
        utxo: TransactionUnspentOutput(input: utxo.input, output: utxo.output),
        address: address,
        multiAsset: asset,
        utxoBalance:
            IntegerBalance.token(utxo.output.amount.coin, network.token, immutable: true),
        haveAssets: asset != MultiAsset.empty,
        hasScript: utxo.output.plutusData != null,
        hasReferenceScript: utxo.output.scriptRef != null);
  }

  @override
  List get variables => [utxo, utxoBalance.balance, address];
}

abstract class BaseADATransactionController extends TransactionStateController<
    TokenCore,
    WalletCardanoNetwork,
    ICardanoAddress,
    ADANetworkClient,
    ADAChain,
    IADATransactionData,
    IADATransaction,
    IADASignedTransaction,
    ADAWalletTransaction,
    SubmitTransactionSuccess<IADASignedTransaction>,
    ADATransactionFeeData> {
  BaseADATransactionController(
      {required super.walletProvider, required super.account, required super.address});
}

enum ADAAccountUtxosStatus { failed, success, pending }

class ADAAccountFetchedUtxos with DisposableMixin, Equality, StreamStateController {
  final lock = SafeAtomicLock();
  final ICardanoAddress address;
  ADAAccountFetchedUtxos({required this.address});
  ADAAccountUtxosStatus status = ADAAccountUtxosStatus.pending;
  List<CardanoAccountUtxo>? _utxos;
  List<CardanoAccountUtxo>? get utxos => _utxos;
  List<CardanoAccountUtxo> _selectedUtxos = [];
  List<CardanoAccountUtxo> get selectedUtxos => _selectedUtxos;
  bool get isSuccess => status == ADAAccountUtxosStatus.success;
  bool get isPending => status == ADAAccountUtxosStatus.pending;
  bool get hasUtxos => isSuccess && _utxos!.isNotEmpty;
  bool _allSelected = false;
  // MultiAsset _totalAsset = MultiAsset.empty;
  int _totalSelected = 0;
  bool get allSelected => _allSelected;
  int get totalSelected => _totalSelected;
  BigInt _totalUtxo = BigInt.zero;
  BigInt get totalUtxo => _totalUtxo;
  bool isSelected(CardanoAccountUtxo utxo) {
    return _selectedUtxos.contains(utxo);
  }

  void _update() {
    _totalSelected = _selectedUtxos.length;
    _allSelected = _selectedUtxos.length == _utxos?.length;
    _totalUtxo =
        _selectedUtxos.fold<BigInt>(BigInt.zero, (p, c) => p + c.utxoBalance.balance);

    notify();
  }

  void addUtxo(CardanoAccountUtxo utxo) {
    final utxos = _utxos;
    assert(_utxos?.contains(utxo) ?? false, "utxo does not exists.");
    if (utxos == null) return;
    if (!_selectedUtxos.remove(utxo)) {
      _selectedUtxos.add(utxo);
    }
    _totalSelected = _selectedUtxos.length;
    _allSelected = _selectedUtxos.length == utxos.length;
    _update();
  }

  void selectAll({bool select = false}) {
    final utxos = _utxos;
    assert(utxos != null, "utxo does not exists.");
    if (utxos == null) return;
    if (select) {
      _selectedUtxos = utxos.clone();
    } else {
      _selectedUtxos = [];
    }
    _update();
  }

  void toggleAll() {
    final utxos = _utxos;
    assert(utxos != null, "utxo does not exists.");
    if (utxos == null) return;
    if (allSelected) {
      _selectedUtxos = [];
    } else {
      _selectedUtxos = utxos.clone();
    }
    _update();
  }

  void setUtxo(List<CardanoAccountUtxo> utxos) {
    assert(status == ADAAccountUtxosStatus.pending);
    _utxos = utxos;
    status = ADAAccountUtxosStatus.success;
    notify();
  }

  void setError() {
    assert(status == ADAAccountUtxosStatus.pending);
    status = ADAAccountUtxosStatus.failed;
    notify();
  }

  void setPending() {
    assert(status != ADAAccountUtxosStatus.success);
    if (isPending) return;
    status = ADAAccountUtxosStatus.pending;
    notify();
  }

  @override
  List get variables => [address];
}

class ADATransferAssetDetails {
  final ADAAssetToken token;
  final IntegerBalance amount;
  bool get hasAmount => amount.largerThanZero;
  const ADATransferAssetDetails._({required this.token, required this.amount});
  factory ADATransferAssetDetails(ADAAssetToken token) {
    return ADATransferAssetDetails._(
        token: token, amount: IntegerBalance.zero(token.token));
  }

  void onUpdateAmount(BigInt amount) {
    this.amount.updateBalance(amount);
  }

  MultiAsset toAsset() {
    if (amount.largerThanZero) {
      return MultiAsset({
        token.id: Assets({token.name: amount.balance})
      });
    }
    return MultiAsset({});
  }
}

class ADATransferDetails with DisposableMixin, StreamStateController, Equality {
  final ReceiptAddress<ADAAddress> recipient;
  final IntegerBalance minNative;
  final ADAEpochParametersResponse protocolParams;

  final List<ADATransferAssetDetails> _transfers = [];
  List<ADATransferAssetDetails> get transfers => _transfers;
  bool get isReady => _status.isReady;

  bool get hasAssets => _transfers.isNotEmpty;
  final IntegerBalance amount;
  final bool recipientUpdateble;

  TransactionStateStatus _status = TransactionStateStatus.error();
  TransactionStateStatus get status => _status;
  TransactionStateStatus getStateStatus() {
    if (amount.isZero) return TransactionStateStatus.error();
    for (final i in _transfers) {
      if (!i.hasAmount) return TransactionStateStatus.error();
    }
    if (amount.balance < minNative.balance) {
      return TransactionStateStatus.error(
          error: "amount_must_exceed".tr.replaceOne(
              PriceUtils.priceWithCoinName(minNative.price, minNative.token.symbol)));
    }
    return TransactionStateStatus.ready();
  }

  void onUpdateStatus() {
    _status = getStateStatus();
    notify();
  }

  bool get hasAmount => amount.largerThanZero;
  ADATransferDetails({
    required this.recipient,
    required Token token,
    required this.protocolParams,
    this.recipientUpdateble = false,
    bool allowNegativeAmount = false,
  })  : amount = IntegerBalance.zero(token, allowNegative: allowNegativeAmount),
        minNative = IntegerBalance.zero(token, allowNegative: false) {
    _onUpdateMinAmount();
  }

  BigInt getMinAmount() {
    return minNative.balance;
  }

  void _onUpdateMinAmount() {
    BigInt utxoMin = minValue;
    if (protocolParams.minUtxo > utxoMin) {
      utxoMin = protocolParams.minUtxo;
    }
    minNative.updateBalance(utxoMin);
    onUpdateStatus();
  }

  void onUpdateBalance(BigInt amount) {
    assert(!amount.isNegative, "Invalid transfer amount.");
    if (amount.isNegative) return;
    this.amount.updateBalance(amount);
    _onUpdateMinAmount();
  }

  void onUpdateAsset(ADATransferAssetDetails asset) {
    assert(!_transfers.contains(asset));
    if (_transfers.contains(asset)) return;
    _transfers.add(asset);
    _onUpdateMinAmount();
  }

  void onUpdateAssetAmount(
      {required ADATransferAssetDetails transfer, required BigInt amount}) {
    assert(_transfers.contains(transfer));
    if (!_transfers.contains(transfer)) return;
    transfer.onUpdateAmount(amount);
    _onUpdateMinAmount();
  }

  void onRemoveAssetTransfer(ADATransferAssetDetails transfer) {
    assert(_transfers.contains(transfer));
    if (!_transfers.contains(transfer)) return;
    _transfers.remove(transfer);
    _onUpdateMinAmount();
  }

  void onRemoveAsset(ADAAssetToken token) {
    _transfers.removeWhere((e) => e.token == token);
    _onUpdateMinAmount();
  }

  void onRemoveAssets() {
    _transfers.clear();
    _onUpdateMinAmount();
  }

  TransactionOutput toOutput() {
    final assets =
        transfers.fold<MultiAsset>(MultiAsset.empty, (p, c) => p + c.toAsset());
    return TransactionOutput(
        address: recipient.networkAddress,
        amount: Value(coin: amount.balance, multiAsset: assets.hasAsset ? assets : null));
  }

  BigInt get minValue {
    final out = toOutput();
    return out
        .copyWith(amount: out.amount.copyWith(coin: BinaryOps.maxU64))
        .minAda(protocolParams.coinsPerUtxoSize);
  }

  @override
  List get variables => [recipient];
}

class ADARemainTransferDetails with DisposableMixin, StreamStateController, Equality {
  final IntegerBalance minNative;
  ADAEpochParametersResponse? _protocolParams;
  ReceiptAddress<ADAAddress> _recipient;
  ReceiptAddress<ADAAddress> get recipient => _recipient;
  MultiAsset _asset = MultiAsset.empty;
  List<ADATransferAssetDetails> _tokens = [];
  List<ADATransferAssetDetails> _tokenRemains = [];
  List<ADATransferAssetDetails> get tokenRemains => _tokenRemains;
  bool get haveRemainAssets => _tokenRemains.isNotEmpty;
  final List<ADATransferAssetDetails> _transfers = [];
  List<ADATransferAssetDetails> get transfers => _transfers;
  MultiAsset get asset => _asset;
  final IntegerBalance amount;
  bool get hasAmount => amount.largerThanZero;
  TransactionStateStatus _status = TransactionStateStatus.error();
  TransactionStateStatus get status => _status;
  bool get isReady => _status.isReady;

  ADARemainTransferDetails({
    required ReceiptAddress<ADAAddress> recipient,
    required Token token,
  })  : amount = IntegerBalance.zero(token, allowNegative: true),
        minNative = IntegerBalance.zero(token, allowNegative: false),
        _recipient = recipient;

  TransactionStateStatus getStateStatus() {
    if (amount.isNegative) return TransactionStateStatus.insufficient(amount);
    if (_tokenRemains.isEmpty) {
      return TransactionStateStatus.ready();
    }
    if (amount.balance < minNative.balance) {
      return TransactionStateStatus.error(
          error: "amount_must_exceed".tr.replaceOne(
              PriceUtils.priceWithCoinName(minNative.price, minNative.token.symbol)));
    }
    return TransactionStateStatus.ready();
  }

  void onUpdateStatus() {
    _status = getStateStatus();
    notify();
  }

  void _onUpdateMinAmount() {
    BigInt utxoMin = minValue;
    final params = _protocolParams;
    if (params != null && params.minUtxo > utxoMin) {
      utxoMin = params.minUtxo;
    }
    minNative.updateBalance(utxoMin);
    onUpdateStatus();
  }

  void updateBalance(BigInt amount) {
    this.amount.updateBalance(amount);
    _onUpdateMinAmount();
  }

  void updateRecipientAddress(ReceiptAddress<ADAAddress> recipient) {
    _recipient = recipient;
    _onUpdateMinAmount();
  }

  BigInt getMaxInput(ADATransferAssetDetails asset) {
    final remain = _tokens.firstWhereNullable((e) => e.token == asset.token);
    assert(remain != null);
    if (remain == null) return BigInt.zero;
    return remain.amount.balance + asset.amount.balance;
  }

  void onUpdateAssets(MultiAsset asset) {
    Map<PolicyID, Map<AssetName, ADATransferAssetDetails>> remains = {};
    for (final policy in asset.assets.entries) {
      final pAssets = policy.value.assets;
      remains[policy.key] ??= {};
      for (final pAsset in pAssets.entries) {
        remains[policy.key]![pAsset.key] ??=
            ADATransferAssetDetails(ADAAssetToken(id: policy.key, name: pAsset.key));
        final a = remains[policy.key]![pAsset.key]!;
        a.onUpdateAmount(pAsset.value + a.amount.balance);
      }
    }
    _asset = asset;
    _tokens = remains.values.expand((e) => e.values).toList();
    _tokenRemains = _tokens.clone();
    _transfers.clear();
    _onUpdateMinAmount();
  }

  void _updateRemainAsset(ADAAssetToken token) {
    final remain = _tokens.firstWhereNullable((e) => e.token == token);
    assert(remain != null);
    final totalAmount = _asset.getAssetNameBalance(token.id, token.name);
    assert(totalAmount > BigInt.zero);
    final totalTransfers =
        _transfers.where((e) => e.token == token).map((c) => c.amount.balance).sum;
    remain?.onUpdateAmount(totalAmount - totalTransfers);
    _tokenRemains = _tokens.where((e) => e.hasAmount).toList();
    _onUpdateMinAmount();
  }

  void onUpdateTransferAsset(ADATransferDetails transfer, ADATransferAssetDetails asset) {
    assert(_tokens.contains(asset));
    if (!_tokens.contains(asset)) return;
    final transferAsset = ADATransferAssetDetails(asset.token);
    transfer.onUpdateAsset(transferAsset);
    _transfers.add(transferAsset);
    _onUpdateMinAmount();
  }

  void onUpdateTransferAssetAmount(
      ADATransferDetails recipient, ADATransferAssetDetails asset, BigInt amount) {
    assert(_transfers.contains(asset));
    if (!_transfers.contains(asset)) return;
    asset.onUpdateAmount(amount);
    recipient._onUpdateMinAmount();
    _updateRemainAsset(asset.token);
  }

  void onRemoveTransferAsset(ADATransferAssetDetails asset) {
    assert(_transfers.contains(asset));
    if (!_transfers.contains(asset)) return;
    _transfers.remove(asset);
    _updateRemainAsset(asset.token);
  }

  void onUpdateProtocolParams(ADAEpochParametersResponse params) {
    assert(_protocolParams == null);
    _protocolParams = params;
  }

  TransactionOutput? toOutput() {
    final assets = _tokens.fold<MultiAsset>(MultiAsset.empty, (p, c) => p + c.toAsset());
    if (assets == MultiAsset.empty && amount.isZero) return null;
    return TransactionOutput(
        address: recipient.networkAddress,
        amount: Value(coin: amount.balance, multiAsset: assets.hasAsset ? assets : null));
  }

  BigInt get minValue {
    final out = toOutput();
    return out
            ?.copyWith(amount: out.amount.copyWith(coin: BinaryOps.maxU64))
            .minAda(_protocolParams?.coinsPerUtxoSize ?? 0) ??
        BigInt.zero;
  }

  @override
  List get variables => [recipient];
}

class IADATransactionData extends ITransactionData {
  final ADATransactionFee fee;
  final List<CardanoAccountUtxo> utxos;
  final GeneralTransactionMetadata? metadata;
  final List<ADAMinsBuilder> mints;
  final List<ADACertificateBuilder> certificates;
  final List<ADADepositBuilder> deposits;
  final List<ADADepositBuilder> refundDeposits;
  final List<TransactionOutput> outputs;
  final NativeScripts? nativeScript;

  IADATransactionData({
    required this.fee,
    required List<CardanoAccountUtxo> utxos,
    required List<TransactionOutput> outputs,
    this.nativeScript,
    this.metadata,
    List<ADAMinsBuilder> mints = const [],
    List<ADADepositBuilder> deposits = const [],
    List<ADADepositBuilder> refundDeposits = const [],
    final List<ADACertificateBuilder> certificates = const [],
  })  : outputs = outputs.immutable,
        mints = mints.immutable,
        utxos = utxos.immutable,
        deposits = deposits.immutable,
        certificates = certificates.immutable,
        refundDeposits = refundDeposits.immutable;
}

class IADATransaction extends ITransaction<IADATransactionData, ICardanoAddress> {
  final ADATransactionBuilder transaction;
  const IADATransaction(
      {required super.account,
      required super.transactionData,
      required this.transaction});
}

class IADASignedTransaction extends ISignedTransaction<IADATransaction, ADATransaction> {
  IADASignedTransaction(
      {required super.transaction,
      required super.signatures,
      required super.finalTransactionData});
}

class ADATransactionMemo {
  final BigInt tag;
  final String text;
  const ADATransactionMemo({required this.tag, required this.text});
}
