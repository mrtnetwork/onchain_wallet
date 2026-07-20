import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/exception/exception.dart';

class Web3AptosExceptionConstant {
  static Web3RequestException get invalidTransaction =>
      Web3RequestExceptionConst.invalidParameters(
          "Invalid Aptos transaction. The transaction must be a valid Aptos transaction and include a method like bcsToBytes.");
  static Web3RequestException get invalidTransactionChainId =>
      Web3RequestExceptionConst.message(
          "Invalid transaction Chain id. Wallet connected to the different aptos network.",
          errorType: Web3ErrorCode.refused);
  static Web3RequestException get invalidSecondarySignerAddressesParams =>
      Web3RequestExceptionConst.invalidParameters(
          "`secondarySignerAddresses` must be a valid list of aptos address as string.");
}
