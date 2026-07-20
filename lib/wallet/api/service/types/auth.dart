import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/api/types/types.dart';
import 'package:on_chain_wallet/wallet/api/utils/utils.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class RPCURL {
  final String url;
  final ProviderAuthenticated? auth;

  const RPCURL._({required this.url, required this.auth});
  factory RPCURL({required String url, ProviderAuthenticated? auth}) {
    final details = APIUtils.getUrlDetails(url);
    if (details == null) {
      throw APIErrorConst.invalidRequestUrl;
    }
    return RPCURL._(url: details.url, auth: auth);
  }

  DefaultAPIProvider toProvider(APIProviderServices service) {
    return DefaultAPIProvider.create(service: service, url: url, auth: auth);
  }

  DefaultAPIProvider? tryToProvider(APIProviderServices service) {
    try {
      return toProvider(service);
    } catch (e) {
      return null;
    }
  }
}
