import 'dart:async';
import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:on_chain_swap/on_chain_swap.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/text_field/input_formaters.dart';
import 'package:on_chain_wallet/marketcap/prices/live_currency.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

typedef ONSELECTSOURCEACCOUNTS = Future<ChainAccount?> Function(Chain);

mixin SwapSourceController on StreamStateController {
  final _lock = SafeAtomicLock();
  StreamValue<IntegerBalance?> inputPrice =
      StreamValue(null, name: "SwapSourceController");
  List<Chain> get chains;
  LiveCurrencies get liveCurrencies;
  Map<WalletNetwork, Set<APPSwapAssets>> _sourceAssets = {};
  Map<WalletNetwork, Set<APPSwapAssets>> get sourceAssets => _sourceAssets;
  SwapAssetsWithBalance? _sourceAsset;
  APPSwapAssets? get sourceAsset => _sourceAsset?.asset;
  Chain? get sourceChain => _sourceAsset?.sourceChain;
  List<ChainAccount> get sourceAddresses => _sourceAsset?.accounts ?? [];
  bool _sourceSupported = false;
  bool get sourceSupported => _sourceSupported;
  bool _hasBalance = false;
  bool get hasBalance => _hasBalance;

  bool get allowMultipleAccountSpent => _sourceAsset?.allowMultipleAccountSpent ?? false;
  bool get allowAddSource => _sourceAsset?.allowAddSource ?? false;
  SwapAmount? _inputAmount;
  SwapAmount? get inputAmount => _inputAmount;

  final CurrencyTextEdittingController amountController =
      CurrencyTextEdittingController(text: '');

  void _checkBalance() {
    bool hasBalance = this.hasBalance;
    final balance = _sourceAsset?.totalAccountsBalance;
    final amount = _inputAmount;
    if (balance == null || amount == null) {
      hasBalance = true;
    } else {
      hasBalance = balance >= amount.amount;
    }
    if (hasBalance != _hasBalance) {
      _hasBalance = hasBalance;
      notify();
    }
  }

  SwapAmount? getInputAmount() {
    final decimals = _sourceAsset?.asset.asset.decimal;
    if (decimals == null) return null;
    final amount = amountController.getText();
    if (amount.trim().isEmpty) return null;
    return MethodUtils.fallbackOnException(
        () => SwapAmount.fromString(amountController.getText(), decimals),
        logOnDebug: false);
  }

  void setSourceAssets(Map<WalletNetwork, Set<APPSwapAssets>> assets) {
    _sourceAssets = assets;
    final coingeckoId = _sourceAssets.values
        .expand((e) => e)
        .map((e) => e.asset.coingeckoId)
        .whereType<String>()
        .toList();
    liveCurrencies.streamPrices(coingeckoId);
  }

  Future<void> _selectAddress(
      ONSELECTSOURCEACCOUNTS onSelectAddress,
      void Function(SwapAssetsWithBalance asset, ChainAccount account)
          onSelectedAddress) async {
    final sChain = _sourceAsset;
    if (sChain == null) return;
    final account = await onSelectAddress(sChain.sourceChain);
    if (account == null || account.network.value != sChain.sourceChain.networkId) {
      return;
    }
    onSelectedAddress(sChain, account);
    notify();
  }

  Future<void> addNewSourceAddress(ONSELECTSOURCEACCOUNTS onSelectAddress,
      {ChainAccount? account}) async {
    await _selectAddress(
      onSelectAddress,
      (asset, acc) {
        asset.updateAccount(acc, exitAccount: account);
      },
    );
  }

  Future<void> removeSourceAddress(ChainAccount account) async {
    _sourceAsset?.removeAccount(account);
    notify();
  }

  IntegerBalance? getTokenPrice(String amount, Token token) {
    return liveCurrencies.getTokenPrice(amount: amount, token: token);
  }

  IntegerBalance? _inputPrice() {
    final asset = sourceAsset;
    final amount = _inputAmount;
    if (asset == null || amount == null) return null;
    final price = getTokenPrice(amount.amountString, asset.token);
    return price;
  }

  // Future<void> onSelectUpdateAddress(
  //     ONSELECTSOURCEACCOUNTS onSelectAddress, ChainAccount account) async {
  //   if (allowMultipleAccountSpent) {
  //     _sourceAsset?.removeAccount(account);
  //     notify();
  //     return;
  //   }
  //   onSelectSourceAddress(onSelectAddress);
  // }

  void onAmountChanged() {
    _inputAmount = getInputAmount();
    inputPrice.value = _inputPrice();
    inputPrice.notify();
    _checkBalance();
  }

  Future<void> updateSourceAsset(APPSwapAssets asset) async {
    await _lock.run(() async {
      final cAsset = _sourceAsset;
      _sourceAsset = null;
      final sChain = chains.firstWhereOrNull((e) => e.network == asset.network);
      await sChain?.initAsMainNetwork();
      amountController.setSymbol(asset.token.symbolView);
      List<ChainAccount> addresses = this.sourceAddresses;
      final sourceAddresses = addresses.firstOrNull;
      if (sourceAddresses?.network != sChain?.network) {
        addresses = [];
        if (sChain != null && sChain.haveAddress) {
          addresses = [sChain.addressSync];
        }
      } else {
        addresses =
            addresses.where((e) => sChain?.addresses.contains(e) ?? false).toList();
      }
      _sourceAsset = switch (sChain) {
        null => null,
        Chain chain =>
          SwapAssetsWithBalance.from(asset: asset, accounts: addresses, account: chain)
      };
      _sourceSupported = sChain != null;
      onAmountChanged();
      cAsset?.dispose();
      _checkBalance();
      _sourceAsset?.updateBalance();
      _sourceAsset?.balanceStream.stream.listen((_) {
        _checkBalance();
      });
    });
  }

  void cleanSourceState() {
    _inputAmount = null;
    _sourceAssets = {};
    _sourceAsset?.dispose();
    _sourceAsset = null;
    amountController.clear();
  }

  @override
  void dispose() {
    super.dispose();
    amountController.dispose();
    inputPrice.dispose();

    _sourceAssets = {};
  }
}
