import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/network/net_api/constants/constants.dart';
import 'package:on_chain_wallet/wallet/models/networks/tron/models/chain_type.dart';

class TronClientUtils {
  static const tronScanMaxTokenLimit = 50;
  static const String tronProHeaderKey = "TRON-PRO-API-KEY";
  static const String tronProAuthKey = "403776f1-6571-42a5-a6e5-0d855332f149";
  static const String tronScanAccountTokenListUrl =
      "https://#api.tronscan.org/api/account/tokens?address=#address&start=#start&limit=#limit&hidden=0&show=0&sortType=0&sortBy=0&token=";
  static String getTronScanNetworkSubdomain(TronChainType chain) {
    switch (chain) {
      case TronChainType.mainnet:
        return "apilist";
      case TronChainType.shasta:
        return "shastapi";
      case TronChainType.nile:
        return "nileapi";
    }
  }

  static Map<String, String> getHeaders(TronChainType chain) {
    switch (chain) {
      case TronChainType.mainnet:
        return {
          ...HttpConst.applicationJsonContentType,
          tronProHeaderKey: tronProAuthKey
        };
      case TronChainType.shasta:
      case TronChainType.nile:
        return HttpConst.applicationJsonContentType;
    }
  }

  static String buildTronScanUrl(
      {required TronAddress address,
      required TronChainType chain,
      int limit = tronScanMaxTokenLimit,
      int start = 0}) {
    return tronScanAccountTokenListUrl
        .replaceAll("#api", getTronScanNetworkSubdomain(chain))
        .replaceFirst("#address", address.toAddress())
        .replaceFirst("#limit", limit.toString())
        .replaceFirst("#start", start.toString());
  }
}
