import 'package:on_chain_wallet/web3/web3/web3.dart';

class Web3CosmosExceptionConstant {
  static Web3RequestException get mismatchChainId =>
      Web3RequestExceptionConst.invalidParameters(
          "Chain ID mismatch. account chain ID does not match 'signDoc' chain ID.");
  static Web3RequestException get feeCoinNotFound =>
      Web3RequestExceptionConst.message("Transaction fee unavailable. Token not found",
          errorType: Web3ErrorCode.invalidParams);
  static Web3RequestException get invalidAminoSignDoc =>
      Web3RequestExceptionConst.invalidParameters(
          "signDoc parameter must be a valid amino transaction as json.");
}
