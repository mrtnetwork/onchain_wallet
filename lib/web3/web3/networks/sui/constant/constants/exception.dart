import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/exception/exception.dart';

class Web3SuiExceptionConstant {
  static Web3RequestException retrieveObjectFailed(
          {required String objectId, String? error}) =>
      Web3RequestExceptionConst.message(
          "Failed retrieve tranaction object $objectId.${error == null ? '' : ' Error: $error'}",
          errorType: Web3ErrorCode.rpcError);
  static Web3RequestException get mismatchMoveCallArguments =>
      Web3RequestExceptionConst.message(
          "Invalid tranaction Move call arguments. Mismatch between move call required parameters and arguments.",
          errorType: Web3ErrorCode.invalidParams);
  static Web3RequestException fialedToParseTransactionObject(String objectId) =>
      Web3RequestExceptionConst.message(
          "Invalid tranaction: Failed to parse transaction object $objectId",
          errorType: Web3ErrorCode.invalidParams);
  static Web3RequestException get unsuportedTransactionVersion =>
      Web3RequestExceptionConst.unsuportedfeatures("Unknow Sui transaction version.");
  static Web3RequestException get missmatchChainIdAndAccount =>
      Web3RequestExceptionConst.invalidParameters(
          "Mismatch between request chainId and account.");
}
