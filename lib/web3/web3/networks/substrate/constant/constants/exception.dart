import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/exception/exception.dart';

class Web3SubstrateExceptionConstant {
  static Web3RequestException get metadataParsingFailed =>
      Web3RequestExceptionConst.invalidParameters(
          "Failed to parse or validate the metadata.");
  static Web3RequestException get unsuportedMetadataVersion =>
      Web3RequestExceptionConst.unsuportedfeatures("Unsuported metadata version.");
  static Web3RequestException get differentRuntimeMetadata =>
      Web3RequestExceptionConst.message(
          "Invalid runtime information: The node returned a different genesis hash or a spec version that does not match your request.",
          errorType: Web3ErrorCode.invalidParams);
}
