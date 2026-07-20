import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/api/service/types/tracker/request.dart';
import 'package:on_chain_wallet/wallet/api/service/types/status.dart';

// TODO
// implement for providers.
class APIServiceTracker {
  final StreamValue<APIServiceStatus> status =
      StreamValue<APIServiceStatus>(APIServiceStatus.active, name: "APIServiceTracker");
  final List<ApiRequest> _requests = [];
  List<ApiRequest> get requests =>
      List<ApiRequest>.from(_requests)..sort((a, b) => b.time.compareTo(a.time));
  bool get hasActive => status.value == APIServiceStatus.active;
  int get requestCount => _requests.length;

  int _totalSuccess = 0;
  int _totalError = 0;
  int get totalSuccess => _totalSuccess;

  void addRequest(ApiRequest request) {
    _requests.add(request);
    _updateStatus();
  }

  APIServiceStatus _checkStatus() {
    _totalSuccess = _requests.where((element) => !element.hasError).length;
    _totalError = _requests.length - _totalSuccess;
    if (_requests.isEmpty || _totalSuccess == _requests.length) {
      return APIServiceStatus.active;
    }
    if (_totalError == _requests.length) return APIServiceStatus.error;
    return APIServiceStatus.warning;
  }

  void _updateStatus() {
    final updateStatus = _checkStatus();
    if (status.value != updateStatus) {
      status.value = updateStatus;
    }
  }

  void clean() {
    _requests.clear();
    _totalSuccess = 0;
    _totalError = 0;
    status.value == APIServiceStatus.active;
  }
}
