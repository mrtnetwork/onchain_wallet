import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/builder/builder.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

void main() async {
  final logging = kDebugMode ? LoggerMode.debug : LoggerMode.error;
  Logging.init(
      LoggingConfig(
          mode: logging,
          netsdk: LoggerMode.info,
          libs: LoggerMode.debug,
          printDebug: true,
          environment: "Main"),
      writer: LogWriterDefault(logging));
  Logging.debug(
    fn: () => AppLogData(function: "run", msg: "Application start."),
  );
  runZonedGuarded(
    _runApplication,
    (error, stack) {
      Logging.error(
          fn: () => AppLogData(
              runtime: "Main",
              function: "runZonedGuarded",
              trace: stack.toString(),
              err: error,
              loggingTrace: true));
    },
  );
}

Future<IResult<void>> _configDesktop(MainAppContext context) async {
  if (!context.platform.isDesktop) return ResultOk(null);
  return context
      .platformInterface()
      .andThen((e) => e.desktop.toResult())
      .andThenAsync((windows) async {
    await windows.init();
    await windows.waitUntilReadyToShow();
    await windows.setMaximumSize(const WidgetSize(
        width: APPConst.desktopAppWidth, height: APPConst.desktopAppHeight));
    final size = context.setting.setting.size;
    final pixel = size?.devicePixelRatio;
    if (size != null && pixel != null) {
      await windows.setBounds(pixelRatio: pixel, bounds: size);
    }
    return ResultOk(null);
  });
}

Future<IResult<MainAppContext>> _readSetting() async {
  final config = AppConfig(applicationId: APPConst.applicationId);
  final context = await AppContextBuilder.initMainContext(config);
  return context.andThenAsync((context) async {
    final desktop = await _configDesktop(context);
    return desktop.map((_) => context);
  });
}

Future<void> _runApplication() async {
  WidgetsFlutterBinding.ensureInitialized();
  final context = await _readSetting();
  context.map((context) {
    ThemeController.fromAppSetting(context.setting.setting);
  });
  runApp(StateRepository(child: MyBTC(context: context)));
}

class MyBTC extends StatefulWidget {
  const MyBTC({super.key, required this.context});
  final IResult<MainAppContext> context;

  @override
  State<MyBTC> createState() => _MyBTCState();
}

class _MyBTCState extends State<MyBTC> {
  @override
  Widget build(BuildContext context) {
    final observer = StateRepository.walletObserver(context);
    final navigatorKey = StateRepository.navigatorKey(context);
    final messengerKey = StateRepository.messengerKey(context);
    return StateBuilder<WalletProvider>(
      controller: () => WalletProvider(
          contextResult: widget.context,
          observer: observer,
          navigatorKey: navigatorKey,
          messengerKey: messengerKey),
      disposeStrategy: StateBuilderDisposeStrategy.never,
      repositoryId: StateConst.main,
      builder: (m) {
        return MaterialApp(
            scaffoldMessengerKey: messengerKey,
            title: APPConst.name,
            scrollBehavior: AppScrollBehavior(context.appContext.platform),
            builder: (context, child) {
              double? maxWidth;
              if (context.appContext.platform.isDesktop) {
                maxWidth = APPConst.desktopAppWidth;
              }
              ThemeController.updatePrimary(context.theme);
              return MediaQuery(
                  data: context.mediaQuery
                      .copyWith(textScaler: const TextScaler.linear(1.0)),
                  child: Listener(
                    onPointerMove: (e) => m.onAppHover(),
                    onPointerDown: (e) => m.onAppHover(),
                    child: maxWidth == null
                        ? child!
                        : ConstraintsBoxView(maxWidth: maxWidth, child: child!),
                  ));
            },
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate
            ],
            theme: ThemeController.appTheme,
            darkTheme: ThemeController.appTheme,
            locale: ThemeController.materialLocale,
            onGenerateRoute: PageRouter.onGenerateRoute,
            initialRoute: PageRouter.home,
            navigatorObservers: [observer],
            showSemanticsDebugger: false,
            debugShowCheckedModeBanner: false,
            color: ThemeController.appTheme.colorScheme.primary,
            navigatorKey: navigatorKey);
      },
    );
  }
}
