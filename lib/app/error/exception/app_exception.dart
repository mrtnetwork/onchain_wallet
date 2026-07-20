import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/networks/types/network.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/error/utils/utils.dart';
import 'package:on_chain_wallet/app/serialization/serialization/tags.dart';

abstract class BaseAppException extends IException {
  const BaseAppException(super.message, {super.details});
  bool get localizedMessage;
  @override
  AppSerializationIdentifier get serializationIdentifier;

  @override
  String toString() {
    return message;
  }

  @override
  List<dynamic> get variables => [message];

  @override
  BlockchainNetwork? get relatedNetwork => null;
}

class AppException extends BaseAppException {
  @override
  final bool localizedMessage;
  const AppException(super.message, {this.localizedMessage = false});
  factory AppException.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.appError,
    );
    return AppException(values.rawValueAt(0));
  }

  @override
  AppSerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.appError;
}

class AppCryptoException extends BaseAppException {
  const AppCryptoException(super.message);
  factory AppCryptoException.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.appCryptoError,
    );
    return AppCryptoException(values.rawValueAt(0));
  }

  @override
  AppSerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.appCryptoError;

  @override
  bool get localizedMessage => false;
}

class AppInternalError extends BaseAppException {
  final String? where;
  final IException? interalError;
  AppInternalError({this.interalError, this.where, super.details, String? message})
      : super(message ?? "unexpected_error");
  AppInternalError.internalError(this.where,
      {String? reason, Map<String, String?>? details, String? message, this.interalError})
      : super(message ?? "unexpected_error",
            details: {"reason": reason, ...details ?? {}}.notNullValue);
  factory AppInternalError.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.appInternalError,
    );
    return AppInternalError(
        message: values.rawValueAt(0),
        where: values.rawValueAt(1),
        details: values.maybeRawMapAt<String, String?>(2),
        interalError: values.maybeObjectAt<IException, CborObject>(
            3, (e) => IExceptionUtils.deserialize(object: e)));
  }

  @override
  AppSerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.appInternalError;

  @override
  List<CborObject?> get serializationItems => [
        CborStringValue(message),
        where?.toCbor(),
        details?.toCbor(),
        interalError?.toCbor()
      ];

  @override
  bool get localizedMessage => false;

  @override
  List<dynamic> get variables => [message, where];
}
