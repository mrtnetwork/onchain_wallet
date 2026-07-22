import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/address/utils.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/others/models/receipt_address.dart';
import 'package:on_chain_wallet/wallet/models/token/coingecko/coin.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_swap/on_chain_swap.dart';

class APPSwapUtils {
  static Set<APPSwapAssets> sortAssets(Set<APPSwapAssets> assets) {
    final clone = assets.toList();
    clone.sort((a, b) {
      if (a.asset.isNative && !b.asset.isNative) return -1;
      if (!a.asset.isNative && b.asset.isNative) return 1;
      return a.asset.providerIdentifier
          .toLowerCase()
          .compareTo(b.asset.providerIdentifier.toLowerCase());
    });
    return clone.toImutableSet;
  }

  static Token swapAssetToToken(BaseSwapAsset asset) {
    return Token(
        name: asset.fullName ?? asset.providerIdentifier,
        symbol: asset.symbol,
        decimal: asset.decimal,
        assetLogo: APPImage.network(asset.logoUrl),
        market:
            asset.coingeckoId == null ? null : CoingeckoCoin(apiId: asset.coingeckoId!));
  }

  static APPSwapFee swapFeeToAppSwapFee(SwapFee fee) {
    final asset = fee.token;
    final token = asset == null
        ? Token(name: fee.asset, symbol: fee.asset, decimal: 0)
        : swapAssetToToken(asset);
    IntegerBalance? feeAmount;
    if (fee.amount case SwapAmount(:final amount)) {
      feeAmount = IntegerBalance.token(amount, token);
    }
    return APPSwapFee(
      token: asset == null ? null : token,
      fee: fee,
      amount: feeAmount,
    );
  }
}

class APPSwapAssets with Equality {
  final BaseSwapAsset asset;
  final WalletNetwork network;
  final Token token;
  const APPSwapAssets._(
      {required this.asset, required this.network, required this.token});
  factory APPSwapAssets.fromAsset(
      {required BaseSwapAsset asset, required WalletNetwork network}) {
    return APPSwapAssets._(
        asset: asset, network: network, token: APPSwapUtils.swapAssetToToken(asset));
  }

  @override
  List get variables => [asset];
}

class RouteBpsPriceDetails {
  final IntegerBalance amount;
  final String bpsPercentage;
  final bool minus;
  const RouteBpsPriceDetails(
      {required this.amount, required this.bpsPercentage, required this.minus});
}

class SwapRouteWithBps {
  final SwapRoute route;
  final RouteBpsPriceDetails? bps;
  final IntegerBalance? totalFee;
  final IntegerBalance amount;
  final List<APPSwapFee> fees;
  final IntegerBalance worstCaseAmount;
  // final Token source;
  SwapServiceProvider get provider => route.provider;
  SwapRouteWithBps(
      {required this.route,
      required this.bps,
      required this.totalFee,
      required this.amount,
      required List<APPSwapFee> fees,
      required this.worstCaseAmount})
      : fees = fees.immutable;
}

class APPSwapFee {
  final SwapFee fee;
  final IntegerBalance? amount;
  final Token? token;
  const APPSwapFee({required this.fee, required this.amount, this.token});
  String get feeAmount => amount?.viewPrice ?? fee.amount.amountString;
}

class APPSwapRoutes {
  final Chain sourceChain;
  final Chain destChain;
  List<SwapRouteWithBps> _routes;
  StreamValue<SwapRouteWithBps> _route;
  List<SwapRouteWithBps> get routes => _routes;
  StreamValue<SwapRouteWithBps> get route => _route;
  Stream get timeout => Stream.periodic(const Duration(seconds: 1));
  SwapServiceProvider get provider => route.value.provider;
  SwapAmount get expectAmout => route.value.route.expectedAmount;
  double _tolerance;
  double get tolerance => _tolerance;
  bool get hasMultipleRoute => _routes.length > 1;

  bool get supportTolerance => route.value.route.supportTolerance;
  double _maxTolerance;
  double get maxTolerance => _maxTolerance;

  void toggleSorting() {
    final routes = _routes.clone();
    routes.sort(
        (a, b) => a.route.expectedAmount.amount.compareTo(b.route.expectedAmount.amount));
    _routes = routes.immutable;
    _route.notify();
  }

  APPSwapRoutes._({
    required List<SwapRouteWithBps> routes,
    required SwapRouteWithBps route,
    required this.sourceChain,
    required this.destChain,
  })  : _routes = routes.immutable,
        _route = StreamValue(route, name: "APPSwapRoutes"),
        _tolerance = route.route.tolerance,
        _maxTolerance = IntUtils.max(50, route.route.tolerance.ceil()).toDouble();
  factory APPSwapRoutes(
      {required List<SwapRouteWithBps> routes,
      required Chain sourceChain,
      required Chain destChain}) {
    routes.sort(
        (a, b) => a.route.expectedAmount.amount.compareTo(b.route.expectedAmount.amount));
    return APPSwapRoutes._(
        routes: routes,
        route: routes.last,
        destChain: destChain,
        sourceChain: sourceChain);
  }
  int get index => _routes.indexOf(route.value);

  void updateTolerance(double tolerance) {
    final route = this.route;
    final routes = _routes.clone();
    final index = routes.indexOf(route.value);
    if (index.isNegative) return;
    final updateRoute = route.value.route.updateTolerance(tolerance);
    final newRoute = SwapRouteWithBps(
      route: updateRoute,
      bps: route.value.bps,
      totalFee: route.value.totalFee,
      amount: route.value.amount,
      fees: route.value.fees,
      // worstCaseAmount: route.value.worstCaseAmount,
      worstCaseAmount: IntegerBalance.token(
          updateRoute.worstCaseAmount.amount, route.value.worstCaseAmount.token),
    );
    routes[index] = newRoute;
    _routes = routes.immutable;
    _tolerance = newRoute.route.tolerance;
    _maxTolerance = IntUtils.max(50, newRoute.route.tolerance.ceil()).toDouble();
    _route.value = newRoute;
  }

  void onChangeRoute(int index) {
    assert(index < _routes.length, "Invalid route index.");
    if (index >= _routes.length) return;
    final route = routes.elementAt(index);
    _tolerance = route.route.tolerance;
    _maxTolerance = IntUtils.max(50, route.route.tolerance.ceil()).toDouble();
    _route.value = route;
  }

  void dispose() {
    _route.dispose();
  }
}

class RouteError {
  final SwapServiceProvider? provider;
  final String error;
  const RouteError({this.provider, required this.error});
}

class APPSwapRoute {
  final Chain sourceChain;
  final Chain destChain;
  final SwapRouteWithBps route;
  final SwapRouteTransactionBuilder transaction;
  final List<ChainAccount> sources;
  final ReceiptAddress destAddress;
  final APPSwapAssets sourceAsset;
  final APPSwapAssets destAsset;
  final IntegerBalance sourceAmount;
  final IntegerBalance destAmount;
  factory APPSwapRoute({
    required Chain sourceChain,
    required Chain destChain,
    required SwapRouteWithBps route,
    required SwapRouteTransactionBuilder transaction,
    required List<ChainAccount> sources,
    required ReceiptAddress destAddress,
    required APPSwapAssets sourceAsset,
    required APPSwapAssets destAsset,
  }) {
    // final err = WalletException("invalid_swap_information");
    if (sourceAsset.asset != route.route.quote.sourceAsset) {
      throw WalletExceptionConst.invalidSwapInformation;
    }
    if (destAsset.asset != route.route.quote.destinationAsset) {
      throw WalletExceptionConst.invalidSwapInformation;
    }
    if (sourceChain.network != sourceAsset.network) {
      throw WalletExceptionConst.invalidSwapInformation;
    }
    if (destChain.network != destAsset.network) {
      throw WalletExceptionConst.invalidSwapInformation;
    }
    if (sources.isEmpty || sources.any((e) => e.network != sourceChain.network)) {
      throw WalletExceptionConst.invalidSwapInformation;
    }
    if (!BlockchainAddressUtils.isValidNetworkAddress(
        destAddress.view, destChain.network)) {
      throw WalletExceptionConst.invalidSwapInformation;
    }
    if (transaction.operations.isEmpty ||
        transaction.route != route.route ||
        transaction.params.destinationAddress != destAddress.view ||
        !sources.any((e) => e.address == transaction.params.sourceAddress) ||
        transaction.operations.any((e) => e.network != sourceAsset.asset.network)) {
      throw WalletExceptionConst.invalidSwapInformation;
    }
    return APPSwapRoute._(
        sourceChain: sourceChain,
        destChain: destChain,
        route: route,
        transaction: transaction,
        sources: sources,
        destAddress: destAddress,
        sourceAsset: sourceAsset,
        destAsset: destAsset,
        sourceAmount: IntegerBalance.token(
            transaction.route.quote.amount.amount, sourceAsset.token),
        destAmount: IntegerBalance.token(
            transaction.route.expectedAmount.amount, destAsset.token));
  }
  APPSwapRoute._(
      {required this.sourceChain,
      required this.destChain,
      required this.route,
      required this.transaction,
      required List<ChainAccount> sources,
      required this.destAddress,
      required this.sourceAsset,
      required this.destAsset,
      required this.sourceAmount,
      required this.destAmount})
      : sources = sources.immutable;
}
