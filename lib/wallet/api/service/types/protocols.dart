import 'package:blockchain_utils/service/models/params.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_wallet/app/core.dart';

extension ExtServiceProtocol on ServiceProtocol {
  List<AppPlatform> get platforms {
    switch (this) {
      case ServiceProtocol.http:
      case ServiceProtocol.websocket:
      case ServiceProtocol.grpc:
        return AppPlatform.values;
      default:
        return [
          AppPlatform.android,
          AppPlatform.windows,
          AppPlatform.ios,
          AppPlatform.macos,
          AppPlatform.linux
        ];
    }
  }

  bool supportOnThisPlatform(AppPlatform platform) {
    return platforms.contains(platform);
  }
}

class ServicePorotocolUtils {
  static ServiceProtocol httpOrWebsocketFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.startsWith("http")) {
      return ServiceProtocol.http;
    } else if (lower.startsWith("ws")) {
      return ServiceProtocol.websocket;
    } else {
      throw APIErrorConst.invalidRequestUrl;
    }
  }

  static bool isHttoOrWebsocket(String url) {
    final parse = Uri.tryParse(url);
    if (parse == null) return false;
    return parse.scheme.startsWith('http') || parse.scheme.startsWith('ws');
  }
}
