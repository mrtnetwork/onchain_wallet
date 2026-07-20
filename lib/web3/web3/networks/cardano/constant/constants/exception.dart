import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/exception/exception.dart';

class Web3ADAExceptionConstant {
  static Web3RequestException get invalidWsTransactionParams =>
      Web3RequestExceptionConst.invalidParameters(
          "Required: 'account' or 'accounts' (for multi-address transfers), and 'transaction' CBOR-encoded transaction represented as a hex string or a Uint8Array");
  static Web3RequestException get invalidRequestAccounts =>
      Web3RequestExceptionConst.invalidParameters(
          "Invalid request accounts: All accounts must belong to the same network.");
  static Web3RequestException get invalidTransaction =>
      Web3RequestExceptionConst.invalidParameters(
          'Invalid transaction: must be a CBOR-encoded transaction represented as a hex string or a Uint8Array.');
  static Web3RequestException get invalidBatchTransaction =>
      Web3RequestExceptionConst.invalidParameters(
          'Invalid batch transaction: each object must be contains "cbor" a CBOR-encoded transaction represented as a hex string or a Uint8Array.');

  static Web3RequestException get invalidPaginated =>
      Web3RequestExceptionConst.invalidParameters(
          'Invalid pagination. Must include both "page" (>= 0) and "limit" (> 0).');

  static Web3RequestException invalidCborParameters(String name) =>
      Web3RequestExceptionConst.invalidParameters(
          'Invalid CBOR: unable to parse "$name" as CBOR.');
  static Web3RequestException paginateReached(int maxSize) =>
      Web3RequestExceptionConst.message(
          'Pagination limit reached. Maximum available items: $maxSize.',
          data: maxSize.toString(),
          errorType: Web3ErrorCode.invalidParams);

  static Web3RequestException get unsuportedSigningMessageAccount =>
      Web3RequestExceptionConst.message("The address does not support message signing.",
          errorType: Web3ErrorCode.refused);

  static Web3RequestException get unableToAccessBip32PublicKey =>
      Web3RequestExceptionConst.message(
          "Cannot access BIP32 public key: account is script or wallet-controlled.",
          errorType: Web3ErrorCode.refused);

  static Web3RequestException get walletNotConnectedToScript =>
      Web3RequestExceptionConst.message("No script account connected to the wallet.",
          errorType: Web3ErrorCode.refused);

  static Web3RequestException get unableToSignTransactionAsNonPartial =>
      Web3RequestExceptionConst.message(
          "Unable to fully sign transaction: required account keys are not available in this wallet.",
          errorType: Web3ErrorCode.refused);

  static Web3RequestException get transactionNotFound =>
      Web3RequestExceptionConst.message("Transaction not found.",
          errorType: Web3ErrorCode.refused);
}
