import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/networks/types/network.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/app/error/exception/app_exception.dart';
import 'package:on_chain_wallet/app/error/exception/exception.dart';
import 'package:on_chain_wallet/app/error/utils/utils.dart';

class NormalizedIExceptionMessage {
  final bool localizedMessage;
  final bool isAppException;
  final bool isInternalError;
  final IException exception;
  const NormalizedIExceptionMessage(
      {required this.localizedMessage,
      required this.isAppException,
      required this.isInternalError,
      required this.exception});
}

extension ExtNormalizeException on IException {
  bool get isInternalError => this is AppInternalError;
  bool isA<ERROR extends IException>() {
    return this is ERROR;
  }

  NormalizedIExceptionMessage normalize() {
    return NormalizedIExceptionMessage(
        localizedMessage: switch (this) {
          BaseAppException exp => exp.localizedMessage,
          _ => true
        },
        isAppException: this is BaseAppException,
        isInternalError: this is AppInternalError,
        exception: this);
  }

  String toDebugMessage() {
    return StringUtils.fromJson({
      "message": message,
      "details": details,
      "type": runtimeType.toString(),
      if (relatedNetwork case BlockchainNetwork(:final name)) "plugin": name,
      if (this case AppInternalError(:final where) when where != null) "in": where,
      if (this case AppInternalError(:final interalError) when interalError != null)
        "internalError": interalError.toDebugMessage(),
      if (this case APIError(:final statusCode, :final errorCode)) ...{
        "statusCode": statusCode,
        "errorCode": errorCode
      }
    }, toStringEncodable: true);
  }
}

class AppLogData implements ILogData {
  @override
  final String? runtime;
  @override
  final String? function;
  @override
  final String? message;
  @override
  final String? trace;
  @override
  final Object? data;
  @override
  final String? prefix;
  const AppLogData._(
      {this.runtime, this.function, this.message, this.trace, this.data, this.prefix});
  factory AppLogData(
      {Object? runtime,
      String? function,

      /// when is error
      Object? err,

      /// debuging message or etc.
      String? msg,
      Object? data,
      String? prefix,
      String? trace,
      bool? loggingTrace}) {
    Map<String, String> e = {};
    if (msg != null) {
      e["message"] = msg;
    }
    if (err != null) {
      e['error'] = switch (err) {
        String err => err,
        _ => IExceptionUtils.findError(err).toDebugMessage()
      };
    }
    return AppLogData._(
        data: data,
        function: function,
        message: e.toString(),
        runtime: runtime?.toString(),
        trace: switch (err) {
          APIError() when loggingTrace != true => null,
          _ when loggingTrace == false => null,
          _ => trace
        },
        prefix: prefix);
  }
}
