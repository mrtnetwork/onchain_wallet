import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/web3/web3/core/exception/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message_types.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';

class Web3ExceptionMessage extends Web3MessageCore {
  final String message;
  final int code;
  final Web3ErrorCode errorType;
  final String? data;
  final String? customError;
  final Web3APPData? authenticated;

  Web3ExceptionMessage(
      {required this.message,
      required this.code,
      required this.errorType,
      this.customError,
      this.data,
      this.authenticated});

  factory Web3ExceptionMessage.deserialize(
      {List<int>? bytes, CborObject? object, String? hex}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.error.tag,
        cborHex: hex);
    return Web3ExceptionMessage(
        message: values.rawValueAt(0),
        code: values.rawValueAt(1),
        errorType: Web3ErrorCode.fromWalletCode(values.rawValueAt(2)),
        data: values.rawValueAt(3),
        authenticated: values.maybeObjectAt<Web3APPData, CborTagValue>(4, (p0) {
          return Web3APPData.deserialize(object: p0);
        }),
        customError: values.rawValueAt(5));
  }

  @override
  Web3MessageTypes get type => Web3MessageTypes.error;

  Web3RequestException toException() {
    return Web3RequestException(
        message: message, errorCode: code, type: errorType, data: data);
  }

  @override
  List<CborObject?> get serializationItems => [
        message.toCbor(),
        code.toCbor(),
        errorType.walletCode.toCbor(),
        data?.toCbor(),
        authenticated?.toCbor(),
        customError?.toCbor()
      ];

  @override
  String toString() {
    return "Web3ExceptionMessage {message:$message, code:$code, type:${errorType.name}}";
  }
}
