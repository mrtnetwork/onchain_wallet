import 'dart:async';

import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/models/models.dart';
import 'package:on_chain_wallet/wallet/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/wallet/web3/core/exception/exception.dart';
import 'package:on_chain_wallet/wallet/web3/core/permission/permission.dart';
import 'package:on_chain_wallet/wallet/web3/models/models.dart';
import 'params.dart';

enum Web3RequestCompleterErrorType {
  response,
  error,

  closed,
  success;

  bool get canUpdate {
    switch (this) {
      case response:
      case error:
        return true;
      default:
        return false;
    }
  }

  bool get isDone => !canUpdate;
  bool get isSuccess => this == success;
}

abstract class Web3RequestInformation with Equatable {
  String? get origin;
  bool get isClosed => _controller.isClosed;
  Stream<Web3RequestCompleterErrorType> get stream => _controller.stream;
  bool get hasListener => _controller.hasListener;
  late final StreamController<Web3RequestCompleterErrorType> _controller =
      StreamController<Web3RequestCompleterErrorType>.broadcast(sync: true);

  final Completer<WalletEvent> _requestComoleter = Completer<WalletEvent>();
  final Completer<Object?> _responseCompleter = Completer();

  void completeResponse(Object? response) {
    if (_responseCompleter.isCompleted) return;
    _responseCompleter.complete(response);
    _controller.add(Web3RequestCompleterErrorType.response);
  }

  void errorResponse(
      {Object error = Web3RequestExceptionConst.rejectedByUser}) {
    if (_responseCompleter.isCompleted) return;
    _responseCompleter.completeError(error is Web3RequestException
        ? error
        : Web3RequestExceptionConst.fromException(error));
    _controller.add(Web3RequestCompleterErrorType.error);
  }

  void completeError() {
    _controller.add(Web3RequestCompleterErrorType.closed);
    _controller.close();
    if (!_responseCompleter.isCompleted) {
      _responseCompleter.completeError(Web3RejectException.instance);
    }
  }

  void completeSuccess() {
    _controller.add(Web3RequestCompleterErrorType.success);
    _controller.close();
    assert(_requestComoleter.isCompleted, "must be completed.");
  }

  // String get applicationId => info.applicationId;

  void completeRequest(WalletEvent event) {
    _requestComoleter.complete(event);
  }

  void errorRequest() {
    _requestComoleter.completeError(Web3RejectException.instance);
  }

  Future<WalletEvent> get onCompleteRequest {
    return _requestComoleter.future;
  }

  String get requestId;
}

class Web3RequestLocalInformation extends Web3RequestInformation {
  Web3RequestLocalInformation(this.requestId);
  @override
  final String requestId;

  @override
  void completeResponse(Object? response) {
    if (_responseCompleter.isCompleted) return;
    super.completeResponse(response);
    completeSuccess();
  }

  @override
  void errorResponse(
      {Object error = Web3RequestExceptionConst.rejectedByUser}) {
    if (_responseCompleter.isCompleted) return;
    super.errorResponse(error: error);
    completeSuccess();
  }

  @override
  List get variabels => [requestId];

  @override
  String? get origin => null;
}

class Web3RequestApplicationInformation extends Web3RequestInformation {
  final Web3ClientInfo info;
  final WalletEvent request;
  Web3RequestApplicationInformation._(
      {required this.info, required this.request});
  factory Web3RequestApplicationInformation(
      {required Web3ClientInfo info, required WalletEvent request}) {
    return Web3RequestApplicationInformation._(info: info, request: request);
  }

  String get applicationId => info.applicationId;

  @override
  List get variabels => [info, request.requestId];

  @override
  String get requestId => request.requestId;

  @override
  String? get origin => info.url;
}

abstract class Web3Request<RESPONSE, PARAMS extends Web3WalletRequestParams,
    AUTH extends Web3RequestAuthentication> {
  final AUTH authenticated;
  final Web3RequestInformation info;
  final PARAMS params;
  const Web3Request(
      {required this.authenticated, required this.info, required this.params});

  void updateActivity() {
    authenticated.addActivity(this);
  }

  void completeResponse(Object? response) {
    if (response is! RESPONSE) {
      throw WalletExceptionConst.invalidArgruments(
          "$RESPONSE", response.runtimeType.toString());
    }
    info.completeResponse(response);
  }

  void error(Object message) {
    info.errorResponse(error: message);
  }

  void reject() {
    info.errorResponse();
  }

  Future<RESPONSE> getResponse() async {
    if (info.isClosed) {
      if (!info._responseCompleter.isCompleted) {
        MethodUtils.nullOnException(() => info._responseCompleter
            .completeError(Web3RejectException.instance));
      }

      throw Web3RejectException.instance;
    }
    final result = await info._responseCompleter.future;
    return result as RESPONSE;
  }
}

abstract class Web3NetworkRequest<
        RESPONSE,
        NETWORKADDRESS,
        CHAIN extends Chain,
        CHANACCOUNT extends Web3ChainAccount,
        WALLETACCOUNT extends NETWORKCHAINACCOUNT,
        WEB3CHAIN extends Web3Chain<NETWORKADDRESS, CHAIN, WALLETACCOUNT,
            CHANACCOUNT, WalletNetwork>,
        PARAMS extends Web3RequestParams<RESPONSE, NETWORKADDRESS, CHAIN,
            WALLETACCOUNT, CHANACCOUNT, WEB3CHAIN>>
    extends Web3Request<RESPONSE, PARAMS, Web3RequestAuthentication> {
  Web3NetworkRequest(
      {required super.params,
      required super.authenticated,
      required this.chain,
      required super.info,
      required List<WALLETACCOUNT> accounts})
      : accounts = accounts.imutable;

  final CHAIN chain;
  final List<WALLETACCOUNT> accounts;
}
