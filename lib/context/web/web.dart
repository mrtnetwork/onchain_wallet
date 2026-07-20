import 'package:on_chain_bridge/models/config/config.dart';
import 'package:on_chain_bridge/models/device/models/platform.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/context/web/context/main.dart';

Future<IResult<MainAppContext>> mainContext(AppConfig config) =>
    DefaultAppContextWeb.init(config);
IResult<AppPlatform> getPlatform() => ResultOk(AppPlatform.web);
