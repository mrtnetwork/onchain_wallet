import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/types/server/types.dart';

typedef TypeCbBridgeSocketStatus = void Function(SocketConnectionStatus status);

typedef TypeCbGenerateBridgeUrl = Future<IResult<BridgeServerUrl>> Function(
    BridgeProtocol protocol);

sealed class SocketConnectionStatus with Equality {
  const SocketConnectionStatus();
  @override
  List<dynamic> get variables => [];

  bool get allowRetry => false;

  bool get closed => false;
  bool get disposed => false;
  bool get isError => false;
  bool get connected => false;
  bool get isPending => false;

  // bool get connectiong => closed || disposed;
}

class SocketConnectionClosed extends SocketConnectionStatus {
  @override
  bool get closed => true;
  @override
  String toString() {
    return "SocketConnectionClosed()";
  }
}

class SocketConnectionDisposed extends SocketConnectionStatus {
  @override
  bool get disposed => true;

  @override
  String toString() {
    return "SocketConnectionDisposed()";
  }
}

class SocketConnectionPending extends SocketConnectionStatus {
  final IException? latestError;
  SocketConnectionPending({this.latestError});
  @override
  String toString() {
    return "SocketConnectionPending()";
  }

  @override
  bool get allowRetry => true;

  @override
  bool get isPending => true;
  @override
  List<dynamic> get variables => [latestError];
}

class SocketConnectionDisconnected extends SocketConnectionStatus {
  final IException? error;
  const SocketConnectionDisconnected({this.error});
  @override
  bool get allowRetry {
    final error = this.error;
    return error == null ||
        (!error.isInternalError && error != APIErrorConst.noNetworkConnection);
  }

  @override
  bool get isError => true;

  @override
  List<dynamic> get variables => [error];

  @override
  String toString() {
    return "SocketConnectionDisconnected($error)";
  }
}

class SocketConnectionConnected extends SocketConnectionStatus {
  @override
  bool get connected => true;
}

class BridgeServerUrl {
  final String url;
  final DateTime expire;
  const BridgeServerUrl({required this.url, required this.expire});

  bool get isExpired => expire.isBefore(DateTime.now());
}
