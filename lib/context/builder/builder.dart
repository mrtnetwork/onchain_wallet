import 'package:on_chain_bridge/models/config/config.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'platform.dart'
    if (dart.library.js_interop) '../web/web.dart'
    if (dart.library.io) '../native/native.dart';

class AppContextBuilder {
  static Future<IResult<MainAppContext>> initMainContext(AppConfig config) =>
      mainContext(config);
}
