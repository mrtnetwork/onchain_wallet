import 'dart:async';

import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/networks/types/address.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/chain/typedef/types.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/ui_actions.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/exception/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/permission.dart';

import 'params.dart';

enum Web3RequestCompleterEventType {
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

class Web3RequestCompleterEvent {
  final Web3RequestCompleterEventType type;
  final IException? latestError;
  final bool pageClosed;
  const Web3RequestCompleterEvent(
      {required this.type, this.latestError, this.pageClosed = false});
}

abstract class Web3RequestInformation with Equality {
  final Web3ClientInfo? client;
  Web3RequestInformation({this.client});
  bool get isClosed => _controller.isClosed;

  Stream<Web3RequestCompleterEvent?> get stream => _controller.stream;
  bool get hasListener => _controller.hasListener;
  late final StreamValue<Web3RequestCompleterEvent?> _controller =
      StreamValue<Web3RequestCompleterEvent?>(null,
          sync: true, name: "Web3RequestInformation");
  Web3RequestCompleterEvent? get latestEvent => _controller.value;

  final Completer<IResult<Object?>> _completer = Completer();
  bool _responseHasListener = false;

  Completer<IResult<Object?>>? _getResponseCompleter() {
    if (_completer.isCompleted || _responseHasListener) return null;
    try {
      return _completer;
    } finally {
      _responseHasListener = true;
    }
  }

  void _completeResponse(Object? response) {
    assert(!_completer.isCompleted, "request already completed");
    if (_completer.isCompleted) return;
    _completer.complete(ResultOk(response));
    final event = Web3RequestCompleterEvent(type: Web3RequestCompleterEventType.response);
    _controller.value = event;
  }

  void _errorResponse(
      {IException error = Web3RequestExceptionConst.rejectedByUser,
      bool pageClosed = false}) {
    Logging.info(
        when: () => _completer.isCompleted,
        fn: () => AppLogData(
            runtime: runtimeType,
            function: "errorResponse",
            msg: "Request already completed."));
    if (_completer.isCompleted) return;
    _completer.complete(
        ResultErr.fromException(Web3RequestExceptionConst.fromException(error)));
    final event = Web3RequestCompleterEvent(
        type: Web3RequestCompleterEventType.error, pageClosed: pageClosed);
    _controller.value = event;
  }

  void completeError({BaseAppException? err}) {
    final event = Web3RequestCompleterEvent(
        type: Web3RequestCompleterEventType.closed,
        latestError: latestEvent?.latestError ?? (err ?? Web3RequestClosed.instance));
    _controller.value = event;
    _controller.dispose();
    if (!_completer.isCompleted && _responseHasListener) {
      _completer.complete(ResultErr.fromException((err ?? Web3RequestClosed.instance)));
    }
  }

  void completeSuccess() {
    final event = Web3RequestCompleterEvent(
        type: Web3RequestCompleterEventType.success,
        latestError: latestEvent?.latestError);
    _controller.value = event;
    _controller.dispose();
  }

  String get requestId;
}

class Web3RequestLocalInformation extends Web3RequestInformation {
  Web3RequestLocalInformation(this.requestId);

  @override
  final String requestId;

  void completeResponse(Object? response) {
    if (_completer.isCompleted) return;
    super._completeResponse(response);
    completeSuccess();
  }

  void errorResponse({IException error = Web3RequestExceptionConst.rejectedByUser}) {
    if (_completer.isCompleted) return;
    super._errorResponse(error: error);
    completeSuccess();
  }

  @override
  List get variables => [requestId];
}

class Web3RequestApplicationInformation extends Web3RequestInformation {
  final Web3MessageCore message;
  @override
  final String requestId;
  final String applicationId;

  Web3RequestApplicationInformation._(
      {required this.requestId,
      required this.message,
      required this.applicationId,
      super.client});
  factory Web3RequestApplicationInformation(
      {required Web3MessageCore message,
      required String requestId,
      required String applicationId,
      required Web3ClientInfo client}) {
    return Web3RequestApplicationInformation._(
        message: message,
        requestId: requestId,
        applicationId: applicationId,
        client: client);
  }

  @override
  List get variables => [applicationId, requestId];
}

class Web3RequestWalletConnectApplicationInformation extends Web3RequestInformation {
  final Web3ClientInfo info;
  final Web3MessageCore request;
  @override
  final String requestId;
  Web3RequestWalletConnectApplicationInformation._(
      {required this.info,
      required this.request,
      required this.requestId,
      required super.client});
  factory Web3RequestWalletConnectApplicationInformation(
      {required Web3ClientInfo info,
      required Web3MessageCore request,
      required String requestId}) {
    return Web3RequestWalletConnectApplicationInformation._(
        info: info, request: request, requestId: requestId, client: info);
  }

  String get applicationId => info.identifier;

  @override
  List get variables => [info];
}

typedef Web3RequestResponse<RESPONSE>
    = Web3Request<RESPONSE, Web3WalletRequestParams, Web3RequestAuthentication>;

abstract class Web3Request<RESPONSE, PARAMS extends Web3WalletRequestParams,
    AUTH extends Web3RequestAuthentication> implements WalletUiAction<RESPONSE> {
  final AUTH authenticated;
  final Web3RequestInformation info;
  final PARAMS params;
  const Web3Request(
      {required this.authenticated, required this.info, required this.params});
  Web3AccountAcitvity createActivity() {
    return Web3AccountAcitvity(
        method: params.method.name, path: info.client?.url, requestId: info.requestId);
  }

  void completeResponse(RESPONSE response) {
    info._completeResponse(response);
  }

  void error(IException message) {
    info._errorResponse(error: message);
  }

  void onPopRequestPage() {
    if (info._completer.isCompleted || !info._responseHasListener) return;
    info._errorResponse(pageClosed: true);
  }

  @override
  Future<IResult<RESPONSE>> getResponse() async {
    final completer = info._getResponseCompleter();
    if (info.isClosed) {
      return ResultErr.fromException(Web3RequestClosed.instance);
    }
    assert(completer != null, "response has already listener.");
    final result = await completer?.future;
    if (result == null) return ResultErr.fromException(Web3RequestClosed.instance);
    return result.map((e) => e as RESPONSE);
  }
}

enum Web3NetworkRequestMode {
  silent,
}

abstract class Web3NetworkRequest<
    RESPONSE,
    NETWORKADDRESS extends IAddress,
    WALLETACCOUNT extends ACCOUNTADDRESS<NETWORKADDRESS>,
    CHAIN extends APPCHAINACCOUNT<WALLETACCOUNT>,
    CHANACCOUNT extends Web3ChainAccount<NETWORKADDRESS>,
    PARAMS extends Web3RequestParams<RESPONSE, NETWORKADDRESS, WALLETACCOUNT, CHAIN,
        CHANACCOUNT>> extends Web3Request<RESPONSE, PARAMS, Web3RequestAuthentication> {
  Web3NetworkRequest(
      {required super.params,
      required super.authenticated,
      required this.chain,
      required super.info,
      required List<WALLETACCOUNT> accounts})
      : accounts = accounts.immutable;

  final CHAIN chain;
  final List<WALLETACCOUNT> accounts;

  @override
  Web3AccountAcitvity createActivity() {
    final address = params.requiredAccounts.firstOrNull;
    return Web3AccountAcitvity(
        method: params.method.name,
        path: info.client?.url,
        address: address?.addressStr,
        id: chain.network.value,
        requestId: info.requestId);
  }
}
