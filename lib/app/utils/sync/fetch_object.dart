import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:on_chain_wallet/app/stream/live.dart';
import 'package:on_chain_wallet/app/utils/method/result.dart';
import 'package:on_chain_wallet/app/utils/sync/cached_object.dart';

enum FetchObjectStatus {
  idle,
  pending,
  success,
  failed;

  bool get isIdle => this == idle;
  bool get isPending => this == pending;
  bool get isSuccess => this == success;
  bool get isFailed => this == failed;
  bool get canRetry => isIdle || isFailed;
}

class FetchObject<T extends Object?> with DisposableMixin, StreamStateController {
  FetchObject(this.onFetch, {FetchObjectStatus status = FetchObjectStatus.idle})
      : _status = status;
  final ONFETCHCACHEDOBJECT<T> onFetch;
  final _lock = SafeAtomicLock();
  T? _value;
  T? get value => _value;
  FetchObjectStatus _status;
  FetchObjectStatus get status => _status;
  Object? _error;
  String? _errorMessage;
  Object? get error => _error;
  String? get errorMessage => _errorMessage;
  Future<void> get() {
    return _lock.run(() async {
      if (_status.isSuccess) return;
      _status = FetchObjectStatus.pending;
      _error = null;
      _errorMessage = null;
      notify();
      try {
        _value = await onFetch();
        _status = FetchObjectStatus.success;
      } catch (e) {
        _error = e;
        _errorMessage = ResultErr.from(e).localizationError;
        _status = FetchObjectStatus.failed;
      } finally {
        notify();
      }
    });
  }
}
