import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/impls/tabs.dart';
import 'package:on_chain_wallet/future/wallet/swap/controller/controller/storage.dart';
import 'package:on_chain_wallet/marketcap/prices/live_currency.dart';
import 'package:on_chain_wallet/repository/repository.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_swap/on_chain_swap.dart';
import 'dest_controller.dart';
import 'source_controller.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

typedef ONREVIEWTX = Future<void> Function(APPSwapRoute);

enum SwapRouteStatus {
  init,
  pending,
  idle;

  bool get isPending => this == pending;
  bool get isIdle => this == idle;
}

enum SwapPage {
  swap,
  review;

  bool get inReview => this == review;
}

typedef ONUPDATEPROVIDERS = Future<APPSwapSettings?> Function(SwapStateController);

class SwapStateController
    with
        DisposableMixin,
        StreamStateController,
        SwapSourceController,
        SwapDestinationController {
  final SwapControllerStorage storage;
  final INetApi netApi;
  APPSwapSettings _settings = APPSwapSettings();
  APPSwapSettings get settings => _settings;

  @override
  final LiveCurrencies liveCurrencies;
  List<Chain> _chains;
  @override
  List<Chain> get chains => _chains;
  SwapStateController(
      {required this.liveCurrencies,
      required List<Chain> chains,
      required IAppDatabaseApi database,
      required this.netApi})
      : _chains = chains.immutable,
        storage = SwapControllerStorage(database);
  late AppSwapServiceApi _api;
  final _lock = SafeAtomicLock();
  final Cancelable _cancelable = Cancelable();
  APPSwapRoutes? _currentRoute;
  APPSwapRoutes? get currentRoute => _currentRoute;
  bool get hasRoute => _currentRoute != null;
  SwapRouteStatus _status = SwapRouteStatus.init;
  SwapRouteStatus get status => _status;
  List<RouteError> _errors = [];
  List<RouteError> get errors => _errors;
  final GlobalKey<FormState> formKey = GlobalKey();
  SwapPage _page = SwapPage.swap;
  SwapPage get page => _page;
  String? _txError;
  String? get txError => _txError;

  StreamSubscription? _timeoutListener;
  final StreamValue<int> _timeout = StreamValue(60, name: "SwapStateController");
  StreamValue<int> get timeout => _timeout;

  void _resetTimeout() {
    _timeoutListener?.cancel();
    _timeoutListener = null;
    _timeout.value = 60;
  }

  void _onRouteTimeout(dynamic _) {
    _timeout.value--;
    if (_timeout.value <= 0) {
      _lock.run(() {
        switch (_walletPage) {
          case WalletPage.swap:
            _resetTimeout();
            _onAmountChanged();
            notify();
            break;
          default:
            _cleanRoute();
            break;
        }
      });
    }
  }

  WalletPage _walletPage = WalletPage.wallet;
  WalletPage get walletPage => _walletPage;
  void onWalletPageChanged(WalletPage page) {
    _walletPage = page;
    if (_walletPage == WalletPage.swap) {
      if (_currentRoute == null) {
        _onAmountChanged();
      }
    }
    notify();
  }

  void _cleanRoute() {
    _cancelable.cancel();
    _currentRoute?.dispose();
    _currentRoute = null;
    _resetTimeout();
    _errors = <RouteError>[].immutable;
    _txError = null;
  }

  @override
  Future<void> onSelectReceiptAddress(ONSELECTDESTACCOUNT onSelectDestAccount) async {
    await super.onSelectReceiptAddress(onSelectDestAccount);
    notify();
    final route = currentRoute;
    if (route?.provider.service != SwapServiceType.swapKit) return;
    final source = sourceAddresses.firstOrNull?.address;
    final destination = destinationAddress?.view;
    if (source == null || destination == null) return;
    if (route?.route.value.route.quote.sourceAddress == source &&
        route?.route.value.route.quote.destinationAddress == destination) {
      return;
    }
    _onAmountChanged(sourceAddress: source, destinationAddress: destination);
  }

  @override
  Future<void> updateSourceAsset(APPSwapAssets asset) async {
    if (sourceAsset == asset) return;
    await super.updateSourceAsset(asset);
    final destAssets = _api.getAppDestAssets(asset.asset);
    setDestAssets(destAssets, sourceAsset: sourceAsset);
    _onAmountChanged();
    notify();
  }

  @override
  void updateDestinationAsset(APPSwapAssets asset) {
    if (destinationAsset == asset) return;
    super.updateDestinationAsset(asset);
    _onAmountChanged();
    notify();
  }

  SwapRouteWithBps? _buildRoute(SwapRoute route) {
    IntegerBalance? totalFee;
    final fees = route.fees
        .map((e) => e.token == null
            ? null
            : getTokenPrice(
                e.amount.amountString, APPSwapUtils.swapAssetToToken(e.token!)))
        .whereType<IntegerBalance>();
    if (fees.isNotEmpty && fees.length == route.fees.length) {
      totalFee = fees.fold<IntegerBalance>(
          IntegerBalance.token(BigInt.zero, fees.first.token), (p, c) => p += c);
    }
    final amoutOut = getTokenPrice(route.quote.amount.amountString,
        APPSwapUtils.swapAssetToToken(route.quote.sourceAsset));
    final destToken = APPSwapUtils.swapAssetToToken(route.quote.destinationAsset);
    final amountIn = getTokenPrice(route.expectedAmount.amountString, destToken);
    RouteBpsPriceDetails? bps;
    if (amountIn != null && amoutOut != null) {
      IntegerBalance change = amountIn - amoutOut;
      final p = (BigRational(change.balance) / BigRational(amountIn.balance)) *
          BigRational.from(100);
      final percentage = p.toDouble();
      final maxTolerance = _settings.tolerance;
      if (percentage.isNegative && maxTolerance != null) {
        if (percentage.abs() > maxTolerance) {
          return null;
        }
      }
      bps = RouteBpsPriceDetails(
          amount: change,
          bpsPercentage: "${percentage.abs().toStringAsFixed(1)}%",
          minus: percentage.isNegative);
    }

    return SwapRouteWithBps(
        route: route,
        bps: bps,
        totalFee: totalFee,
        worstCaseAmount: IntegerBalance.token(route.worstCaseAmount.amount, destToken,
            immutable: true),
        fees: route.fees.map(APPSwapUtils.swapFeeToAppSwapFee).toList(),
        amount: IntegerBalance.token(route.expectedAmount.amount, destToken,
            immutable: true));
  }

  APPSwapRoutes? _buildRoutes(
      {required List<SwapRoute> routes,
      required Chain sourceChain,
      required Chain destChain}) {
    final r = routes.map(_buildRoute).whereType<SwapRouteWithBps>().toList();
    if (r.isEmpty) return null;
    return APPSwapRoutes(routes: r, sourceChain: sourceChain, destChain: destChain);
  }

  Future<void> _createRoute(
      {required APPSwapAssets source,
      required APPSwapAssets destination,
      required Chain sourceChain,
      required Chain destChain,
      required String amount,
      String? sourceAddress,
      String? destinationAddress}) async {
    sourceAddress ??= sourceAddresses.firstOrNull?.address;
    destinationAddress ??= this.destinationAddress?.view;
    await _lock.run(() async {
      _cleanRoute();
      final r = await IResult.call(() async {
        _status = SwapRouteStatus.pending;
        notify();
        return await _api.findAppRoute(
          sourceAsset: source,
          destinationAsset: destination,
          amountIn: amount,
          sourceAddress: sourceAddress,
          destinationAddress: destinationAddress,
        );
      }, cancelable: _cancelable);
      if (r.err()?.canceled() ?? false) return;
      if (r.isErr) {
        _errors = [RouteError(error: r.unwrapErr().localizationError)];
      } else {
        _currentRoute = _buildRoutes(
            routes: r.unwrap().map((e) => e.route).whereType<SwapRoute>().toList(),
            destChain: destChain,
            sourceChain: sourceChain);
        _timeoutListener = _currentRoute?.timeout.listen(_onRouteTimeout);

        _errors = r
            .unwrap()
            .where((e) => !e.hasRoute)
            .map((e) => RouteError(
                error: ResultErr.from(e.error!).localizationError, provider: e.provider))
            .toList();
        if (_currentRoute != null) {
        } else {
          if (_errors.isEmpty) {
            _errors = [RouteError(error: "no_swap_route_found".tr)];
          }
        }
      }
      _status = SwapRouteStatus.idle;
      notify();
    });
  }

  Future<void> _onAmountChanged(
      {String? sourceAddress, String? destinationAddress}) async {
    _cleanRoute();
    notify();
    final source = sourceAsset;
    final out = destinationAsset;
    final sChain = sourceChain;
    final dChain = destinationChain;
    final amount = inputAmount;
    if (_page.inReview ||
        source == null ||
        out == null ||
        amount == null ||
        sChain == null ||
        dChain == null) {
      return;
    }
    _createRoute(
        source: source,
        destination: out,
        amount: amount.amountString,
        sourceAddress: sourceAddress,
        destinationAddress: destinationAddress,
        destChain: dChain,
        sourceChain: sChain);
  }

  Future<void> createSwapTransaction({required ONREVIEWTX onPage}) async {
    if (!formKey.ready()) return;
    Logg.log("start here!");
    final route = currentRoute?.route;
    final sourceAddress = sourceAddresses;
    final destinationAddress = this.destinationAddress;
    final sourceChain = this.sourceChain;
    final destChain = destinationChain;
    final sourceAsset = this.sourceAsset;
    final destAsset = destinationAsset;
    if (route == null ||
        sourceAddress.isEmpty ||
        destinationAddress == null ||
        sourceChain == null ||
        destChain == null ||
        sourceAsset == null ||
        destAsset == null) {
      return;
    }
    _txError = null;
    _page = SwapPage.review;
    notify();
    final r = await _lock.run(() async {
      return IResult.call(() async {
        final transaction = await _api.builSwapTransaction(
            sourceAddress: sourceAddress.first.address,
            destinationAddress: destinationAddress.view,
            swapRoute: route.value.route);
        final s = APPSwapRoute(
            sourceChain: sourceChain,
            destChain: destChain,
            route: route.value,
            transaction: transaction,
            sources: sourceAddress,
            destAddress: destinationAddress,
            sourceAsset: sourceAsset,
            destAsset: destAsset);
        await onPage(s);
      }, delay: APPConst.animationDuraion);
    });
    if (r.isErr) {
      _txError = r.unwrapErr().localizationError;
    }
    _page = SwapPage.swap;
    notify();
  }

  Future<IResult<void>> updateSettings(ONUPDATEPROVIDERS onUpdate) async {
    final setting = await onUpdate(this);
    if (setting == null || _settings == setting) return ResultOk.okVoid;
    _settings = setting;
    final result = await storage.storageSaveSwapSettings(settings);
    return result.mapAsync((_) async {
      _settings = settings;
      _status = SwapRouteStatus.init;
      _cleanRoute();
      cleanDestinationState();
      cleanSourceState();
      notify();
      await initSwap();
    });
  }

  Future<void> initSwap() async {
    amountController.addListener(_listenChangeAmount);
    await _lock.run(() async {
      final settings = await storage.storageGetSwapSettings();
      settings.map((settings) => _settings = settings);
      final networks = _chains.map((e) => e.network).toList();
      switch (_settings.chainType) {
        case ChainType.mainnet:
          _api = await AppSwapServiceApi.loadApi(
              DefaultSwapServiceApiParams(
                  services:
                      _settings.swapProviders.map((e) => e.service).toSet().toList(),
                  swapKitServiceProviders: SwapConstants.supportProviders
                      .whereType<SwapKitSwapServiceProvider>()
                      .toList(),
                  netApi: netApi),
              networks);
          break;
        case ChainType.testnet:
          _api = await AppSwapServiceApi.loadApi(
              DefaultSwapServiceApiParams.testnet(netApi), networks);
          break;
      }

      final assets = await _api.getAppSourceAssets();
      setSourceAssets(assets);
      if (assets.isNotEmpty) {
        updateSourceAsset(assets.values.first.first);
      }
      _status = SwapRouteStatus.idle;
      notify();
    });
  }

  Timer? _timer;
  void _listenChangeAmount() {
    final amount = getInputAmount();
    if (amount == inputAmount) return;
    onAmountChanged();
    _timer?.cancel();
    _timer = Timer(APPConst.oneSecoundDuration, _onAmountChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    _timer = null;
    _chains = [];
    _cleanRoute();
  }
}
