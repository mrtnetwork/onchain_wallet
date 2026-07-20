import 'package:on_chain_bridge/models/config/config.dart';
import 'package:on_chain_bridge/models/device/models/platform.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';

Future<IResult<MainAppContext>> mainContext(AppConfig config) =>
    throw UnsupportedError('Cannot create a instance without dart:js or dart:io.');
IResult<AppPlatform> getPlatform() =>
    throw UnsupportedError('Cannot create a instance without dart:js or dart:io.');
