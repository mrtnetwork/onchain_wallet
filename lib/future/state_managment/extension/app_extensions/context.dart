import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/future/state_managment/core/observer.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/theme/theme.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/controller/impls/action_controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';

extension ExtCustomColorsSchame on ColorScheme {
  Color get disable => onSurface.wOpacity(0.38);
  Color get orange => Colors.orange;
  Color get green => Colors.green;
  Color get onGreen => Colors.white;
  Color get transparent => Colors.transparent;
  Color get blue => Colors.blue;
}

extension ExtQuickColor on Color {
  Color wOpacity(double opacity) {
    assert(opacity >= 0.0 && opacity <= 1.0);
    return withAlpha((255.0 * opacity).round());
  }

  Color get disabled => wOpacity(0.38);
}

extension ExtQuickContextAccsess on BuildContext {
  WalletProvider get wallet {
    return StateRepository.stateOf(this, StateConst.main)!;
  }

  MainAppContext get appContext => wallet.context;
  MainAppContext? get appContextOrNull => mounted ? wallet.context : null;
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colors => theme.colorScheme;
  Color get onPrimaryContainer => colors.onPrimaryContainer;
  Color get primaryContainer => colors.primaryContainer;
  TextTheme get onPrimaryTextTheme => ThemeController.onPrimary;
  TextTheme get primaryTextTheme => ThemeController.primary;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  bool get hasFocus => FocusScope.of(this).hasFocus;
  bool get hasParentFocus => FocusScope.of(this).parent?.hasFocus ?? false;
  void mybePop() {
    if (mounted) Navigator.maybeOf(this);
  }

  void clearFocus() {
    if (mounted) {
      FocusScope.of(this).unfocus();
    }
  }

  Future<T?> to<T>(String? path, {dynamic argruments}) async {
    if (path == null) {
      showAlert('page_not_found'.tr);
      return null;
    }
    if (mounted) {
      final push = await Navigator.pushNamed(this, path, arguments: argruments);
      return (push as T?);
    }
    return null;
  }

  Future<IResult<T?>> toNamed<T>(String? path, {dynamic argruments}) async {
    if (path == null) {
      showAlert('page_not_found'.tr);
      return ResultErr.fromException(AppExceptionConst.walletContextNotAvailable);
    }
    if (mounted) {
      final push = await Navigator.pushNamed<T>(this, path, arguments: argruments);
      return ResultOk(push);
    }
    return ResultErr.fromException(AppExceptionConst.walletContextNotAvailable);
  }

  Future<T?> mybeTo<T>(String? path, {dynamic argruments}) async {
    if (path != null && mounted) {
      final push = await Navigator.pushNamed(this, path, arguments: argruments);
      return (push as T?);
    }
    return null;
  }

  Future<T?> toPage<T>(Widget page, {dynamic argruments}) async {
    if (mounted) {
      final push = await Navigator.push(
          this,
          MaterialPageRoute(
              builder: (context) => page,
              settings: RouteSettings(arguments: argruments)));
      return (push as T?);
    }
    return null;
  }

  bool toSync(String path, {dynamic argruments}) {
    if (!mounted) return false;
    Navigator.pushNamed(this, path, arguments: argruments);
    return true;
  }

  Future<T?> offTo<T>(String path, {dynamic argruments}) async {
    if (mounted) {
      final push = Navigator.popAndPushNamed<T, T>(this, path, arguments: argruments);
      return push;
    }
    return null;
  }

  BuildContext? get muntedOrNull => mounted ? this : null;
  void showAlert(String message) {
    wallet.showAlert(message);
  }

  void showSnackbar(SnackBar snackbar, {CbOnScaffoldFeatureController? onShow}) {
    wallet.showSnackbar(snackbar, onShow ?? (_) {});
  }

  Future<T?> openSliverBottomSheet<T>(String label,
      {Widget? child,
      BodyBuilder? bodyBuilder,
      List<Widget> Function(BuildContext context)? appbarActions,
      List<Widget> slivers = const [],
      double initiaalExtend = 0.9,
      bool centerContent = true,
      bool useNavigatorContext = false}) async {
    assert(mounted, "context is not ready");

    if (!mounted) return null;
    return await showModalBottomSheet<T>(
      context: this,
      constraints: const BoxConstraints(maxWidth: 900),
      builder: (context) => AppBottomSheet(
        label: label,
        body: bodyBuilder,
        actions: appbarActions?.call(context) ?? [],
        minExtent: 0.8,
        maxExtend: 1.0,
        centerContent: centerContent,
        slivers: slivers,
        initiaalExtend: initiaalExtend >= 0.8 ? initiaalExtend : 0.8,
        child: child,
      ),
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  Future<T?> openMaxExtendSliverBottomSheet<T>(String label,
      {Widget? child,
      BodyBuilder? bodyBuilder,
      List<Widget> Function(BuildContext context)? appbarActions,
      List<Widget> slivers = const [],
      bool centerContent = true}) async {
    if (!mounted) return null;
    return await openSliverBottomSheet(label,
        centerContent: centerContent,
        appbarActions: appbarActions,
        bodyBuilder: bodyBuilder,
        child: child,
        initiaalExtend: 1,
        slivers: slivers);
  }

  Future<T?> openSliverDialog<T>(
      {List<Widget> Function(BuildContext)? content,
      WidgetContext? widget,
      WidgetContext? sliver,
      String? label,
      double? maxWidth,
      bool dismissible = true,
      String? routeName}) async {
    return await showAdaptiveDialog(
      context: this,
      useRootNavigator: true,
      barrierDismissible: dismissible,
      routeSettings: routeName == null ? null : RouteSettings(name: routeName),
      builder: (context) {
        return DialogView(
            title: label,
            dismissible: dismissible,
            content: content?.call(context) ?? const [],
            widget: widget == null ? null : widget(context),
            sliver: sliver == null ? null : sliver(context),
            maxWidth: maxWidth);
      },
    );
  }

  Future<T?> openDialogPage<T>(
    String label, {
    /// instead custom scroll widget
    WidgetContext? child,
    List<Widget> Function(BuildContext)? content,
    WidgetContext? fullWidget,

    /// under Custom scroll widget
    WidgetContext? sliver,

    /// under sliver widget
    WidgetContext? widget,
    String? routeName,
    double? maxWidth,
  }) async {
    return await showAdaptiveDialog(
      context: this,
      useRootNavigator: false,
      barrierDismissible: true,
      useSafeArea: false,
      routeSettings: routeName == null ? null : RouteSettings(name: routeName),
      builder: (context) {
        return fullWidget?.call(context) ??
            DialogView(
              title: label,
              sliver: sliver?.call(context),
              widget: widget?.call(context),
              content: content?.call(context) ?? const [],
              maxWidth: maxWidth,
              child: child?.call(context),
            );
      },
    );
  }

  void pop<T>([T? result]) {
    if (mounted) {
      Navigator.of(this).pop(result);
    }
  }

  T? getNullArgruments<T>() {
    final args = ModalRoute.of(this)?.settings.arguments;
    if (args == null) return null;
    if (args.runtimeType != T) {
      return null;
    }
    return args as T?;
  }

  T getArgruments<T>() {
    final args = ModalRoute.of(this)?.settings.arguments;
    if (args == null) {
      throw StateError("argruments not found");
    }

    return args as T;
  }

  dynamic getDynamicArgs() {
    final args = ModalRoute.of(this)?.settings.arguments;
    if (args == null) {
      throw StateError("argruments not found");
    }

    return args;
  }

  void popToHome() {
    Navigator.of(this).popUntil((route) {
      return route.isFirst;
    });
  }

  void backToCurrent() {
    final name = route()?.settings.name;
    if (name == null) return;
    Navigator.of(this).popUntil((route) {
      return route.settings.name == name || route.isFirst;
    });
  }

  BuildContext? get scaffoldContext => StateRepository.scaffoldKey(this).currentContext;

  GlobalKey<NavigatorState> get navigatorKey => StateRepository.navigatorKey(this);
  ModalRoute? route() {
    return ModalRoute.of(this);
  }

  WalletRouteObserver get observer => StateRepository.walletObserver(this);

  ///
  Future<IResult<T?>> openDialog<T>(
      {List<Widget> Function(BuildContext)? content,
      WidgetContext? widget,
      WidgetContext? sliver,
      String? label,
      double? maxWidth,
      bool dismissible = true,
      String? routeName}) async {
    if (!mounted) {
      return ResultErr.fromException(AppExceptionConst.walletContextNotAvailable);
    }
    final result = await showAdaptiveDialog<T>(
      context: this,
      useRootNavigator: true,
      barrierDismissible: dismissible,
      routeSettings: routeName == null ? null : RouteSettings(name: routeName),
      builder: (context) {
        return DialogView(
            title: label,
            dismissible: dismissible,
            content: content?.call(context) ?? const [],
            widget: widget == null ? null : widget(context),
            sliver: sliver == null ? null : sliver(context),
            maxWidth: maxWidth);
      },
    );
    return ResultOk(result);
  }
}
