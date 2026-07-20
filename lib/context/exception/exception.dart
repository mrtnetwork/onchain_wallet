import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

// enum WorkerError {
//   unexpectedError(1),
//   connectionClosed(2),
//   connectionTimeout(3),
//   webResources(4),
//   ;

//   final int value;
//   const WorkerError(this.value);
//   static WorkerError fromValue(int? value) => WorkerError.values
//       .firstWhere((e) => e.value == value, orElse: () => WorkerError.unexpectedError);
// }

class AppContextError extends BaseAppException {
  const AppContextError._(super.message, {super.details});
  factory AppContextError.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.appContextError,
    );
    return AppContextError._(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  static AppContextError wokerInitializationError(String? reason) =>
      AppContextError._("message", details: {"reason": reason});

  static const AppContextError invalidConfig = AppContextError._("Invalid ocnfig");
  static const AppContextError requestTimeout = AppContextError._("Request timeout");
  static const AppContextError createConnectionTimeount =
      AppContextError._("Request timeout");
  static const AppContextError connectionNotFound = AppContextError._("Request timeout");
  @override
  AppSerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.appContextError;

  @override
  bool get localizedMessage => false;
}
