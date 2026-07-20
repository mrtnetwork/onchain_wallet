part of 'package:on_chain_wallet/future/state_managment/state_managment.dart';

abstract class Disposable {
  bool _inited = false;
  bool _deleted = false;
  bool get deleted => _deleted;
  final Set<DynamicVoid> _listeners = {};
  void _addListener(DynamicVoid callBack) {
    _listeners.add(callBack);
  }

  void _removeListener(DynamicVoid callBack) {
    _listeners.remove(callBack);
  }

  void notify() {
    for (final DynamicVoid i in [..._listeners]) {
      i();
    }
  }

  void close() {}
  void _close() {
    try {
      if (_deleted) return;
      _deleted = true;
      close();
    } catch (e, s) {
      assert(false, "Disposable: $e $s");
    }
  }

  void _start() {
    if (_inited) return;
    _inited = true;
    init();
  }

  void init() {
    WidgetsFlutterBinding.ensureInitialized()
        .addPostFrameCallback((timeStamp) => ready());
  }

  void ready() {}
}

abstract class StateController extends Disposable {}
