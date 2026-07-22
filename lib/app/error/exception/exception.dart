import 'dart:async';

import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exception/rpc_error.dart';
import 'package:blockchain_utils/utils/json/extension/json.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_bridge/net_sdk/exception/exception.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/error/exception/app_exception.dart';
import 'package:on_chain_wallet/app/serialization/serialization/tags.dart';
import 'package:on_chain_wallet/app/utils/map/extension.dart';
import 'package:on_chain_wallet/app/utils/string/utils.dart';

class APIErrorConst {
  static const List<int> validStatusCode = [404, 400, 401, 403, 405, 408, 500, 503];
  static const int timeoutStatucCode = 10001;
  static const int notFoundStatusCode = 404;
  static const APIError noNetworkConnection =
      APIError._(message: 'no_network_connection');
  static const APIError connectionClosed = APIError._(message: 'http_connection_closed');
  static const APIError clientDisposed = APIError._(message: 'client_disposed');
  static const APIError socketConnectingFailed =
      APIError._(message: 'socket_connection_failed');
  static const APIError initializeClientFailed =
      APIError._(message: 'network_client_initialize_failed');
  static const APIError invalidRequestType = APIError._(message: 'invalid_request_type');
  static const APIError invalidOrUnsuportedDigestAuth =
      APIError._(message: 'invalid_or_unsuported_dgiest_auth');
  static const APIError timeoutException =
      APIError._(message: 'api_http_timeout_error', statusCode: timeoutStatucCode);
  static const APIError serverUnexpectedResponse =
      APIError._(message: 'server_unexpected_response');
  static const APIError unexpectedRequestData =
      APIError._(message: 'unexpected_request_data');
  static const APIError invalidRequestUrl = APIError._(message: 'invalid_request_url');
  static const APIError clientIsNotInitialized =
      APIError._(message: 'client_is_not_initialized');
  static const APIError serviceInternalError =
      APIError._(message: 'service_internal_error');
  static APIError get failedToFetchSaplingParameters =>
      APIError._(message: 'failed_to_fetch_sapling_parameters');
  static APIError get invalidServiceConfiguration =>
      APIError._(message: 'invalid_service_configuration');
  static const APIError socketIsNotInitialized =
      APIError._(message: 'socket_is_not_initialized');

  static const APIError failedToParseResponseContent =
      APIError._(message: 'failed_to_parse_response_content');
  static const APIError badClientState = APIError._(message: 'bad_client_state');
  static const APIError apiConnectionFailed =
      APIError._(message: 'api_connection_failed');
  static const APIError serviceOutOfSync = APIError._(message: 'service_out_of_sync');
}

class APIError extends RPCError implements BaseAppException {
  // @override
  // final int? statusCode;
  final String? url;
  @override
  final bool localizedMessage;
  final bool isRpcError;
  bool get isTimeout => statusCode == APIErrorConst.timeoutStatucCode;
  const APIError._(
      {required super.message,
      this.isRpcError = false,
      super.details,
      super.request,
      super.errorCode,
      super.statusCode,
      this.url,
      super.jsonRpcErrpr,
      this.localizedMessage = false});

  factory APIError.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.apiError,
    );
    return APIError._(
        message: values.rawValueAt(0),
        statusCode: values.rawValueAt(1),
        url: values.rawValueAt(2),
        localizedMessage: values.rawValueAt(3),
        request: values.maybeRawMapAt<String, dynamic>(4),
        details: values.maybeRawMapAt<String, String?>(5),
        jsonRpcErrpr: values.maybeObjectAt<Map<String, dynamic>, CborStringValue>(
            6, (v) => StringUtils.toJson(v.value)),
        errorCode: values.rawValueAt(7),
        isRpcError: values.rawValueAt(8));
  }

  @override
  AppSerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.apiError;

  @override
  List<dynamic> get variables => [message, errorCode, statusCode];

  factory APIError.fromNetSdk(NetSdkException error, {required String? url}) {
    final status = error.error;
    String? message = error.details?.valueAs("message");
    if (message != null && StrUtils.isHtml(message)) {
      message = null;
    }
    return APIError._(
        message: switch (status) {
          NetResultStatus.requestTimeout => APIErrorConst.timeoutException.message,
          NetResultStatus status when status.isDevError() =>
            APIErrorConst.serviceInternalError.message,
          _ => status.dsecription
        },
        url: url,
        errorCode: error.details?.valueAsInt("code"),
        details:
            {"status": status.name, "message": message}.withoutNullValue.nullOnEmpty);
  }
  factory APIError.fromNetResponseHttp(NetResponseHttp response, {required String? url}) {
    final statusCode = response.statusCode;
    final defaultError = APIErrorConst.validStatusCode.contains(statusCode)
        ? "http_error_$statusCode"
        : "request_error";
    assert(!response.isSuccess);
    String? message = StringUtils.tryDecode(response.body);
    if (message != null && StrUtils.isHtml(message)) {
      message = null;
    }
    return APIError._(message: message ?? defaultError, url: url, statusCode: statusCode);
  }
  factory APIError.fromException(
      {String? url, Object? message, int? statusCode, bool isRpcError = false}) {
    final defaultError = APIErrorConst.validStatusCode.contains(statusCode)
        ? "http_error_$statusCode"
        : "request_error";
    if (message == null && statusCode == null) {
      return APIError._(message: defaultError, statusCode: statusCode);
    }
    switch (message) {
      case APIError msg:
        return msg;
      case RPCError error:
        return APIError._(
            message: error.message,
            statusCode: statusCode ?? error.statusCode,
            localizedMessage: true,
            details: error.details?.withoutNullValue.nullOnEmpty,
            request: error.request?.withoutNullValue.nullOnEmpty,
            errorCode: error.errorCode,
            jsonRpcErrpr: error.jsonRpcErrpr,
            isRpcError: true,
            url: url);
      case NetSdkException msg:
        return APIError.fromNetSdk(msg, url: url);
      case TimeoutException _:
        return APIError._(
            message: "api_http_timeout_error",
            statusCode: APIErrorConst.timeoutStatucCode,
            url: url);

      case null:
      case String message when StrUtils.isHtml(message):
        return APIError._(message: defaultError, statusCode: statusCode, url: url);
      default:
        final Map<String, dynamic>? decode = StringUtils.tryToJson(message);
        String? msg =
            (decode?["message"] ?? decode?["error"] ?? decode?["Error"])?.toString();
        if (msg == null && message is String && message.trim().isNotEmpty) {
          msg = message;
        }
        if (msg == null && !APIErrorConst.validStatusCode.contains(statusCode)) {
          return APIError._(
              message: 'api_unknown_error', statusCode: statusCode, url: url);
        }
        return APIError._(
            message: msg ?? defaultError,
            statusCode: statusCode,
            isRpcError: isRpcError,
            url: url,
            localizedMessage: msg != null);
    }
  }

  @override
  List<CborObject?> get serializationItems => [
        message.toCbor(),
        statusCode?.toCbor(),
        url?.toCbor(),
        localizedMessage.toCbor(),
        request?.toCbor(
          (obj) => CborStringValue(obj.toString()),
        ),
        details?.toCbor(),
        switch (jsonRpcErrpr) {
          null => CborNullValue(),
          Map<String, dynamic> v =>
            CborStringValue(StringUtils.fromJson(v, toStringEncodable: true)),
        },
        errorCode?.toCbor()
      ];

  @override
  String toString() {
    return message;
  }
}
