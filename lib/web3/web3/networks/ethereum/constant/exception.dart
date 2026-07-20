import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/exception/exception.dart';

class Web3EthereumExceptionConst {
  static Web3RequestException get invalidTransactionTypeOrGas =>
      Web3RequestExceptionConst.message(
          "Invalid transaction gas parameters. The provided transaction type does not correspond with the specified gas parameters.",
          errorType: Web3ErrorCode.invalidParams);
  static Web3RequestException get invalidTransactionAccessList =>
      Web3RequestExceptionConst.message(
          "Invalid transaction accesslist parameters. The provided transaction type does not support Ethereum transaction accessList parameters.",
          errorType: Web3ErrorCode.invalidParams);
  static Web3RequestException get eip1559NotSupported => Web3RequestExceptionConst.message(
      "Invalid transaction gas parameters. The current network does not support EIP-1559 transactions.",
      errorType: Web3ErrorCode.invalidParams);

  static Web3RequestException get mismatchAccountAndTransactionChainId =>
      Web3RequestExceptionConst.message(
          "Invalid transaction chain id. Mismatch between account and transaction chain ID.",
          errorType: Web3ErrorCode.invalidParams);
  static Web3RequestException get invalidTransactionType =>
      Web3RequestExceptionConst.unsuportedfeatures("Unknown ethereum transaction type.");
  static Web3RequestException get invalidGasArg =>
      Web3RequestExceptionConst.invalidParameters(
          'Cannot use both legacy and EIP-1559 gas parameters simultaneously.');
  static Web3RequestException get invalidEIP1559GasArg =>
      Web3RequestExceptionConst.invalidParameters(
          "To use EIP-1559 gas metrics, you must fill both maxFeePerGas and maxPriorityFeePerGas fields.");
  static Web3RequestException get missingRpcUrls =>
      Web3RequestExceptionConst.invalidParameters(
          "At least one valid rpcUrl is required. Each URL must start with a valid scheme: http, https, ws, or wss.");

  static Web3RequestException get invalidAccessListParams =>
      Web3RequestExceptionConst.failedToParse("accessList");
  static Web3RequestException get missingValue =>
      Web3RequestExceptionConst.failedToParse("value");
  static Web3RequestException get invalidTypeData =>
      Web3RequestExceptionConst.failedToParse("typeData");

  static const Web3RequestException disconnectedChain = Web3RequestException(
      message: "The Provider is not connected to the requested chain.",
      type: Web3ErrorCode.disconnectedChain);
}
