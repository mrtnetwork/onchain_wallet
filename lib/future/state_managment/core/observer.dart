import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';

typedef CbObserverListenter = void Function(Route route, Route? previousRoute);

class WalletRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  final List<CbObserverListenter> _pushListeners = [];
  final List<CbObserverListenter> _popListeners = [];
  void addPushListener(CbObserverListenter listener) {
    _pushListeners.add(listener);
  }

  void removePushListener(CbObserverListenter listener) {
    _pushListeners.remove(listener);
  }

  void addPopListener(CbObserverListenter listener) {
    _popListeners.add(listener);
  }

  void removePopListener(CbObserverListenter listener) {
    _popListeners.remove(listener);
  }

  void _emitPushListeners(Route route, Route? previousRoute) {
    for (final i in [..._pushListeners]) {
      MethodUtils.fallbackOnException(() => i(route, previousRoute));
    }
  }

  void _emitPopListeners(Route route, Route? previousRoute) {
    for (final i in [..._popListeners]) {
      MethodUtils.fallbackOnException(() => i(route, previousRoute));
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _emitPushListeners(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _emitPopListeners(route, previousRoute);
  }
}
