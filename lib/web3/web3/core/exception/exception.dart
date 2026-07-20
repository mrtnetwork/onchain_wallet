import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/models/models/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';

enum Web3ErrorCode {
  // General / internal errors
  internalError(-32603, "WALLET-000"),
  walletNotInitialized(-1, "WALLET-001"),

  // User & authentication
  rejectedByUser(4001, "WALLET-002"),
  missingPermission(4100, "WALLET-003"),
  invalidOrDisabledClient(-32001, "WALLET-004"), // subcode to distinguish

  // Request & method errors
  invalidRequest(-32600, "WALLET-005"),
  invalidParams(-32602, "WALLET-006"),
  unknownRequestMethod(4200, "WALLET-007"),
  unsupportedFeature(4903, "WALLET-008"),
  refused(4904, "WALLET-018"),

  // Network / chain
  invalidNetwork(-32000, "WALLET-009"),
  disconnectedProvider(4900, "WALLET-010"),
  disconnectedChain(4901, "WALLET-011"),
  chainNotSupported(-32002, "WALLET-012"),
  invalidHost(-32004, "WALLET-013"),

  // RPC errors
  rpcError(-32005, "WALLET-014");

  // Auth helper
  bool get isAuthError =>
      this == rejectedByUser ||
      this == missingPermission ||
      this == invalidOrDisabledClient;
  bool get isRefused => this == refused;

  const Web3ErrorCode(this.code, this.walletCode);

  final int code;
  final String walletCode;

  static Web3ErrorCode fromWalletCode(String? walletCode) {
    return values.firstWhere(
      (e) => e.walletCode == walletCode,
      orElse: () => Web3ErrorCode.internalError,
    );
  }

  static Web3ErrorCode fromCode(int? code) {
    return values.firstWhere(
      (e) => e.code == code,
      orElse: () => Web3ErrorCode.internalError,
    );
  }
}

class Web3RequestException extends BaseAppException {
  final int? errorCode;
  final String? data;
  final Web3ErrorCode type;
  int get code => errorCode ?? type.code;
  const Web3RequestException(
      {required String message, this.errorCode, required this.type, this.data})
      : super(message);
  factory Web3RequestException.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.web3RequestError,
        cborBytes: bytes,
        cborObject: object);
    return Web3RequestException(
      message: values.rawValueAt(0),
      errorCode: values.rawValueAt(1),
      data: values.rawValueAt(2),
      type: Web3ErrorCode.fromCode(values.rawValueAt(3)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "message": message,
      "code": errorCode ?? type.code,
      "walletCode": type.walletCode,
      "data": data
    };
  }

  Web3ExceptionMessage toResponseMessage(
      {Map<String, dynamic>? request, String? requestId, Web3APPData? authenticated}) {
    return Web3ExceptionMessage(
        message: message,
        code: errorCode ?? type.code,
        errorType: type,
        data: data,
        authenticated: authenticated);
  }

  @override
  List get variables => [type, errorCode, message];

  @override
  bool get localizedMessage => true;

  @override
  AppSerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3RequestError;

  @override
  List<CborObject?> get serializationItems =>
      [message.toCbor(), errorCode?.toCbor(), data?.toCbor(), type.code.toCbor()];

  @override
  String toString() {
    return message;
  }
}

class Web3RequestClosed extends BaseAppException {
  const Web3RequestClosed._() : super("web3_request_rejected_desc");
  static const Web3RequestClosed instance = Web3RequestClosed._();
  factory Web3RequestClosed.deserialize({List<int>? bytes, CborObject? object}) {
    AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.web3RequestClosed,
    );
    return instance;
  }

  @override
  AppSerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3RequestClosed;

  @override
  bool get localizedMessage => false;
}
