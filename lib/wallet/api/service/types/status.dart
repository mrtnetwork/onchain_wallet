import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/api/service/exception/bridge.dart';

enum NetworkServiceStatus {
  connected,
  pending,
  pendingTor,
  error;

  bool get isConnected => this == NetworkServiceStatus.connected;
  bool get isPending =>
      this == NetworkServiceStatus.pending || this == NetworkServiceStatus.pendingTor;
  bool get isError => this == error;
}

sealed class INetworkServiceNotify with Equality {
  final NetworkServiceStatus status;
  final ResultErr? error;
  const INetworkServiceNotify({required this.status, this.error});

  @override
  List<dynamic> get variables => [status];
}

class INetworkServiceNotifyStatus extends INetworkServiceNotify {
  INetworkServiceNotifyStatus._({required super.status, super.error});
  factory INetworkServiceNotifyStatus.pending() {
    return INetworkServiceNotifyStatus._(status: NetworkServiceStatus.pending);
  }
  factory INetworkServiceNotifyStatus.pendingTor() {
    return INetworkServiceNotifyStatus._(status: NetworkServiceStatus.pendingTor);
  }
  factory INetworkServiceNotifyStatus.connect() {
    return INetworkServiceNotifyStatus._(status: NetworkServiceStatus.connected);
  }
  factory INetworkServiceNotifyStatus.noProvider() {
    return INetworkServiceNotifyStatus._(
        status: NetworkServiceStatus.error,
        error: ResultErr.fromException(NetworkClientError.noActiveServiceProvider));
  }
  factory INetworkServiceNotifyStatus.error(ResultErr error) {
    return INetworkServiceNotifyStatus._(
        status: NetworkServiceStatus.error, error: error);
  }
  @override
  List<dynamic> get variables => [status, error];
}

enum APIServiceStatus { active, warning, error }
