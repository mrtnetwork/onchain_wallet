import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/core/exception/exception.dart';

class Web3RequestExceptionConst {
  static Web3RequestException fromException(IException exception,
      {String? where, String? reason, bool logging = true}) {
    if (exception is Web3RequestException) return exception;
    if (exception is RPCError) {
      return Web3RequestException(
          message: exception.message,
          errorCode: exception.errorCode,
          type: Web3ErrorCode.rpcError,
          data: StringUtils.tryFromJson(exception.jsonRpcErrpr));
    } else if (exception is APIError) {
      return Web3RequestException(
          type: switch (exception.isRpcError) {
            true => Web3ErrorCode.rpcError,
            false => Web3ErrorCode.disconnectedProvider,
          },
          message:
              exception.isRpcError ? exception.message : "The Provider is disconnected.",
          data: exception.isRpcError
              ? StringUtils.tryFromJson(exception.jsonRpcErrpr)
              : exception.isTimeout
                  ? "Request timeout"
                  : null);
    }
    return internalErr(where ?? "Web3RequestException.fromException",
        reason: reason ?? "Unknown exception.",
        details: {"error": exception.toString()},
        logging: logging);
  }

  static Web3RequestException internalErr(String where,
      {String? reason,
      Map<String, dynamic>? details,
      String? trace,
      bool logging = true}) {
    Logging.error(
        when: () => logging,
        fn: () => AppLogData(
            runtime: "Web3RequestException",
            function: "internalErr",
            msg: "Internal error at $where: $reason",
            trace: trace,
            data: details));
    return internalError_;
  }

  static const Web3RequestException internalError_ = Web3RequestException(
    message: "An error occurred during the request",
    type: Web3ErrorCode.internalError,
  );

  static const Web3RequestException rejectedByUser = Web3RequestException(
      message: "The user rejected the request.", type: Web3ErrorCode.rejectedByUser);

  static const Web3RequestException invalidRequest = Web3RequestException(
      message: "The request is not a valid Request object.",
      type: Web3ErrorCode.invalidRequest);

  static const Web3RequestException invalidNetwork = Web3RequestException(
      message: "The specified network is invalid or does not exist.",
      type: Web3ErrorCode.invalidNetwork);

  static const Web3RequestException missingPermission = Web3RequestException(
      message: "The requested method and/or account has not been authorized by the user.",
      data:
          "The Web3 application does not have the required permissions. Please send a permission request first.",
      type: Web3ErrorCode.missingPermission);

  static const Web3RequestException methodDoesNotExist = Web3RequestException(
      message:
          "The requested method does not exist. Please check the method name and try again.",
      type: Web3ErrorCode.unknownRequestMethod);

  static const Web3RequestException methodDoesNotSupport = Web3RequestException(
      message: "The requested method does not supported.",
      type: Web3ErrorCode.unknownRequestMethod);

  static const Web3RequestException invalidHost = Web3RequestException(
    message:
        "Invalid host: Ensure that the request comes from a valid host and try again.",
    type: Web3ErrorCode.invalidOrDisabledClient,
  );
  static const Web3RequestException walletNotInitialized = Web3RequestException(
    message: "Wallet not initialized.",
    type: Web3ErrorCode.walletNotInitialized,
  );

  static const Web3RequestException bannedHost = Web3RequestException(
    message:
        "The requested method and/or account has not been authorized by the user. The client is disable by the owner of the wallet.",
    type: Web3ErrorCode.invalidOrDisabledClient,
  );

  static const Web3RequestException invalidParams = Web3RequestException(
    message: "Invalid method parameters.",
    type: Web3ErrorCode.invalidParams,
  );

  static Web3RequestException invalidStringArgrument(String parameterName) =>
      Web3RequestException(
        message: "Invalid method parameters. $parameterName is not a valid string.",
        type: Web3ErrorCode.invalidParams,
      );

  static Web3RequestException invalidBytesArgrument2(
          {required String arg, required List<StringEncoding> encoding}) =>
      Web3RequestException(
        message:
            "Invalid method parameters. $arg is not a valid bytes. Accepted formats (${encoding.map((e) => e.name).join(", ")}).",
        type: Web3ErrorCode.invalidParams,
      );
  static Web3RequestException invalidBytesArgrumentElement({
    required int index,
    required List<StringEncoding> encoding,
  }) =>
      Web3RequestException(
        message:
            "Invalid method parameters. Parameters at index $index is not a valid bytes. Accepted formats (${encoding.map((e) => e.name).join(", ")}).",
        type: Web3ErrorCode.invalidParams,
      );

  ///

  static Web3RequestException invalidBoolean(String key) => Web3RequestException(
        message: "Invalid method parameters. $key is not a valid boolean.",
        type: Web3ErrorCode.invalidParams,
      );

  static Web3RequestException invalidAddressArgrument(
          {required String key, required String network}) =>
      Web3RequestException(
        message: "Invalid method parameters. $key is not a valid $network address.",
        type: Web3ErrorCode.invalidParams,
      );
  static Web3RequestException invalidAccountOrAccountParamets(String network) =>
      Web3RequestException(
        message:
            'Invalid method parameters. Request must include either "account" or "accounts" '
            'field with a valid address or list of $network addresses.',
        type: Web3ErrorCode.invalidParams,
      );

  static Web3RequestException invalidAddress(
      {required String? key, required String network}) {
    if (key == null) {
      return Web3RequestException(
        message: "Failed to parse $network address.",
        type: Web3ErrorCode.invalidParams,
      );
    }
    return Web3RequestException(
      message: "Failed to parse address. `$key` is not a valid $network address.",
      type: Web3ErrorCode.invalidParams,
    );
  }

  static Web3RequestException invalidBase58(String key) => Web3RequestException(
        message: "Invalid method parameters. $key is not a valid Base58 string.",
        type: Web3ErrorCode.invalidParams,
      );

  static Web3RequestException invalidHexBytes(String parameterName) =>
      Web3RequestException(
        message: "Invalid method parameters. $parameterName is not a valid hex string.",
        type: Web3ErrorCode.invalidParams,
      );

  static Web3RequestException invalidBase64Bytes(String parameterName) =>
      Web3RequestException(
        message:
            "Invalid method parameters. $parameterName is not a valid base64 string.",
        type: Web3ErrorCode.invalidParams,
      );

  static Web3RequestException invalidListArgument(String key) => Web3RequestException(
        message: "Invalid method parameters. $key is not a valid list.",
        type: Web3ErrorCode.invalidParams,
      );

  static Web3RequestException invalidMapParameters({List<String> keys = const []}) =>
      Web3RequestException(
        message: "Invalid method parameters. Parameters must be a valid object.",
        type: Web3ErrorCode.invalidParams,
      );
  static Web3RequestException invalidMapArguments(
      {required String name, List<String> keys = const []}) {
    if (keys.isNotEmpty) {
      return Web3RequestException(
        message:
            "Invalid method parameters. $name must be a valid object contains (${keys.join(', ')})",
        type: Web3ErrorCode.invalidParams,
      );
    }
    return Web3RequestException(
      message: "Invalid method parameters. $name must be a valid object.",
      type: Web3ErrorCode.invalidParams,
    );
  }

  static Web3RequestException invalidListOfObject({List<String> keys = const []}) {
    if (keys.isNotEmpty) {
      return Web3RequestException(
        message:
            "Invalid method parameters. Parameters must be a list of object contains (${keys.join(', ')})",
        type: Web3ErrorCode.invalidParams,
      );
    }
    return Web3RequestException(
      message: "Invalid method parameters. Parameters must be a list of object.",
      type: Web3ErrorCode.invalidParams,
    );
  }

  static Web3RequestException invalidNumbers(String arg) => Web3RequestException(
        message:
            "Invalid method parameters. $arg is not a valid number. Accepted formats (Integer, hexadecimal string)",
        type: Web3ErrorCode.invalidParams,
      );

  static Web3RequestException invalidDecimalsNumbers(String arg) => Web3RequestException(
        message: "Invalid method parameters. $arg is not a valid decimal number.",
        type: Web3ErrorCode.invalidParams,
      );

  static Web3RequestException invalidObjectKeys(
          String parameterName, List<String> keys) =>
      Web3RequestException(
        message:
            "Invalid method parameters. $parameterName must be a object and contain one of the following keys: ${keys.join(", ")}",
        type: Web3ErrorCode.invalidParams,
      );

  // Invalid gas data object. The object must contain one of the following keys: Result, Input, or NestedResult
  static const Web3RequestException invalidMethodArgruments = Web3RequestException(
    message: "Invalid method parameters.",
    type: Web3ErrorCode.invalidParams,
  );

  /// eth

  static Web3RequestException networkIdDoesNotExists(String chainId) =>
      Web3RequestException(
          message: "Unsuported network. $chainId network does not exists.",
          type: Web3ErrorCode.chainNotSupported
          // walletCode: "WEB3-5080",
          // code: -32600,
          );
  static Web3RequestException get invalidCaip2ChainIdStyle => Web3RequestException(
        message:
            "Invalid method parameters. each chainId must be a valid CAIP-2 stryle like (eip1159:1)",
        type: Web3ErrorCode.invalidParams,
      );
  static const Web3RequestException networkDoesNotExists = Web3RequestException(
    message: "Invalid method parameters. The specified Network does not exist.",
    type: Web3ErrorCode.chainNotSupported,
    // walletCode: "WEB3-5080",
    // code: -32600,
  );
  static const Web3RequestException ethereumRpcWrongChainId = Web3RequestException(
    message:
        "The provided RPC link returned a different chain ID. Please ensure the RPC URL matches the expected chain ID.",
    // walletCode: "WEB3-5090",
    // code: -32600,
    type: Web3ErrorCode.chainNotSupported,
  );
  static const Web3RequestException disconnectProvider = Web3RequestException(
    message: "The Provider is disconnected.",
    type: Web3ErrorCode.disconnectedProvider,
  );

  static Web3RequestException invalidParameters(String message) => Web3RequestException(
        message: "Invalid method parameters: $message",
        data: message,
        type: Web3ErrorCode.invalidParams,
      );

  static Web3RequestException unsuportedfeatures(String message,
          {String? data, Map<String, dynamic>? dataJson}) =>
      Web3RequestException(
        message: "Unsuported features: $message",
        type: Web3ErrorCode.unsupportedFeature,
      );
  static Web3RequestException excuteTransactionFailed(String error) =>
      message("Excute transaction failed: $error", errorType: Web3ErrorCode.rpcError);
  static Web3RequestException get invalidRequestStateAccount =>
      Web3RequestExceptionConst.invalidParameters(
          "Invalid account argument. account is not valid wallet account.");
  static Web3RequestException get inactiveAccount => Web3RequestExceptionConst.message(
      "Inactive account. account does not active in network.",
      errorType: Web3ErrorCode.refused);
  static Web3RequestException get invalidTransaction =>
      Web3RequestExceptionConst.invalidParameters(
          "Invalid transaction: Failed to parse or validate the transaction parameters.");

  static Web3RequestException failedToParse(String key) =>
      Web3RequestExceptionConst.invalidParameters("Failed to parse '$key'.");

  static Web3RequestException get multipleBatchRequestNetwork =>
      Web3RequestExceptionConst.message(
          "Invalid request accounts. for batch request all accounts must be related to same netowrk.",
          errorType: Web3ErrorCode.invalidParams);

  static Web3RequestException message(String message,
          {required Web3ErrorCode errorType, String? data}) =>
      Web3RequestException(message: message, data: data, type: errorType);

  static Web3RequestException invalidBytesOrHexArgrument2(String key) =>
      Web3RequestException(
        message:
            "Invalid method parameters. `$key` is not a valid bytes. Accepted formats are hexadecimal strings or Uint8Array. ",
        type: Web3ErrorCode.invalidParams,
      );

  static Web3RequestException get invalidRpcUrl =>
      Web3RequestExceptionConst.invalidParameters(
          "rpcUrl must start with a valid scheme: http, https, ws, or wss.");

  static Web3RequestException unsuportedSigningMessageAccount(String address) =>
      Web3RequestExceptionConst.message(
          "The $address address does not support message signing. Only non-multisig accounts are allowed to sign messages.",
          errorType: Web3ErrorCode.refused);
}
