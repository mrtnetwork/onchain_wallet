import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/exception/exception.dart';

class Web3SolanaExceptionConstant {
  static Web3RequestException get invalidModeOptions =>
      Web3RequestExceptionConst.invalidParameters(
          "Invalid mode argument. only 'parallel' or 'serial' are allowed.");
  static Web3RequestException get invalidCommitmentOptions =>
      Web3RequestExceptionConst.invalidParameters(
          "Invalid Commitment argument. only 'processed', 'confirmed' or 'finalized' are allowed.");
  static Web3RequestException get invalidSignInParams =>
      Web3RequestExceptionConst.invalidParameters(
          "Failed to parse or validate the Sign-In parameters.");
}
