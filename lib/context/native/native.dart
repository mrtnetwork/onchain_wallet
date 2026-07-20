import 'package:on_chain_bridge/native/utils/utils.dart';
import 'package:on_chain_bridge/models/config/config.dart';
import 'package:on_chain_bridge/models/device/models/platform.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/context/native/context/main.dart';

Future<IResult<MainAppContext>> mainContext(AppConfig config) =>
    DefaultAppContextNative.init(config);
IResult<AppPlatform> getPlatform() => OnChainBridgeIoUtils.platform().toResult();
