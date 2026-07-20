import 'dart:async';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/app/error/extension/extension.dart';
import 'package:on_chain_wallet/app/models/models/typedef.dart';
import 'package:on_chain_wallet/app/stream/controller.dart';

mixin _LiveListenable {
  final Set<DynamicVoid> _noneIdsListeners = {};

  void addListener(DynamicVoid callBack) {
    _noneIdsListeners.add(callBack);
  }

  void removeListener(DynamicVoid callBack) {
    _noneIdsListeners.remove(callBack);
  }

  void notify() {
    for (final i in [..._noneIdsListeners]) {
      i();
    }
  }
}

class LiveListenable<T> with _LiveListenable {
  LiveListenable(T val) : _value = val;

  void dispose() {
    _noneIdsListeners.clear();
  }

  T _value;

  T get value {
    return _value;
  }

  T get valueSilent => _value;

  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notify();
  }
}

class StreamListenable<T> {
  T _value;
  StreamListenable(T val,
      {this.immutable = false, required String name, bool sync = false})
      : _value = val,
        _controller = SafeStreamController<T>.broadcast(name: name, sync: sync);
  final bool immutable;
  bool get isClosed => _controller.isClosed;

  final SafeStreamController<T> _controller;
  bool get hasListener => _controller.hasListener;
  Stream<T> get stream => _controller.stream();

  void _logImmutable() {
    Logging.error(
      when: () => immutable,
      fn: () => AppLogData(
          runtime: runtimeType,
          function: "add",
          msg: "Cannot add event to stream '${{
            _controller.name ?? 'unnamed'
          }}': the stream controller is immutable."),
    );
  }

  T get value {
    return _value;
  }

  set silent(T newValue) {
    _logImmutable();
    if (_value == newValue || immutable) return;
    _value = newValue;
  }

  set value(T newValue) {
    _logImmutable();
    if (_value == newValue || immutable) return;
    _value = newValue;
    _controller.addIfListener(newValue);
  }

  set updateValue(T newValue) {
    _logImmutable();
    if (immutable) return;
    _value = newValue;
    _controller.addIfListener(newValue);
  }

  void notify({T? value}) {
    _controller.addIfListener(value ?? _value);
  }

  void dispose() {
    _controller.close();
  }
}

class StreamValue<T> extends StreamListenable<T> {
  StreamValue(super.val, {required super.name, super.sync});
  StreamValue.immutable(super.val, {required super.name}) : super(immutable: true);
}

mixin DisposableMixin {
  bool get closed;
  void dispose() {}
}

mixin StreamStateController on DisposableMixin {
  late final StreamValue<void> notifier = StreamValue(null, name: "$runtimeType");
  Stream<void> get stream => notifier.stream;
  @override
  bool get closed => notifier.isClosed;
  void notify() {
    notifier.notify();
  }

  @override
  void dispose() {
    super.dispose();
    notifier.dispose();
  }
}
