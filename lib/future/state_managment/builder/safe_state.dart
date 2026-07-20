part of 'package:on_chain_wallet/future/state_managment/state_managment.dart';

mixin SafeState<T extends StatefulWidget> on State<T> {
  AppContext? _appContext;
  AppContext? get appContext => _appContext;
  bool _closed = false;
  bool _builded = false;
  bool get closed => _closed;
  @override
  bool get mounted => !_closed && _builded && super.mounted;

  void onInitOnce() {}

  void safeDispose() {}

  @override
  void setState(VoidCallback fn) {
    if (!mounted) return;
    super.setState(fn);
  }

  @override
  void dispose() {
    _closed = true;
    try {
      safeDispose();
    } catch (e, s) {
      Logging.error(
        fn: () => AppLogData(
            function: "safeDispose", trace: s.toString(), runtime: runtimeType, err: e),
      );
    }
    super.dispose();
    _appContext = null;
  }

  GlobalKey<NavigatorState>? navigatorKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appContext = context.appContextOrNull;
    navigatorKey ??= context.navigatorKey;
    if (!_builded) {
      onInitOnce();
    }
    _builded = true;
  }

  void updateState([VoidCallback? fn]) {
    setState(fn ?? () {});
  }
}

mixin ProgressMixin<T extends StatefulWidget> on SafeState<T> {
  final StreamPageProgressController progressKey = StreamPageProgressController();
  @override
  void safeDispose() {
    super.safeDispose();
    progressKey.dispose();
  }
}
