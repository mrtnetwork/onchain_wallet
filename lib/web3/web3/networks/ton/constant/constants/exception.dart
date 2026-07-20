import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/exception/exception.dart';

class Web3TonExceptionConstant {
  static Web3RequestException invalidTransactionMessageLength(int maxMessageLength) =>
      Web3RequestExceptionConst.invalidParameters(
          "Invalid transaction messages. Expected 1 to $maxMessageLength messages.");
}
