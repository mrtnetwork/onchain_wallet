import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/exception/exception.dart';

class Web3MoneroExceptionConstant {
  static Web3RequestException get accountDoesNotSupportSignMessage =>
      Web3RequestExceptionConst.message(
          'The provided address does not support message signing.',
          errorType: Web3ErrorCode.refused);
  static Web3RequestException get noRecipients =>
      Web3RequestExceptionConst.invalidParameters('at least one recipients required.');

  static Web3RequestException get mismatchPaymentAddresses =>
      Web3RequestExceptionConst.invalidParameters(
          'All recipient addresses must belong to the same monero network.');

  static Web3RequestException get multipleIntegratedAddressNotAllowed =>
      Web3RequestExceptionConst.invalidParameters(
          'Multiple integrated addresses are not allowed.');

  static Web3RequestException get invalidTransaction =>
      Web3RequestExceptionConst.invalidParameters(
          'The request must include a spender account and a list of recipients with address and amount.');
  static Web3RequestException get duplicateOutputAddressesNotAllowed =>
      Web3RequestExceptionConst.message('Duplicate output addresses are not allowed',
          errorType: Web3ErrorCode.refused);
}
