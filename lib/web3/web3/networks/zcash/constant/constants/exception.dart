import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/exception/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/params/models/transaction.dart';
import 'package:zcash_dart/zcash.dart';

class Web3ZcashExceptionConstant {
  static Web3RequestException get noRecipients =>
      Web3RequestExceptionConst.invalidParameters('at least one recipients required.');
  static Web3RequestException get mismatchPaymentAddresses =>
      Web3RequestExceptionConst.invalidParameters(
          'All recipient addresses must belong to the same zchas network.');
  static Web3RequestException get invalidTransaction =>
      Web3RequestExceptionConst.invalidParameters(
        'Invalid transaction request. Must include a spender account/accounts and a list of recipients '
        'with address, amount, and protocol (sapling, orchard, transparent).',
      );
  static Web3RequestException get misingRecipientProtocol =>
      Web3RequestExceptionConst.invalidParameters(
          'Recipient protocol is required. Supported protocols are orchard, sapling, and transparent. Ensure the recipient address supports the selected protocol.');
  static Web3RequestException get unsupportedRecipientMemo =>
      Web3RequestExceptionConst.invalidParameters(
        'Recipient memos are only supported for shielded addresses. '
        'Use the top-level memo field for transparent recipients.',
      );
  static Web3RequestException get invalidShieldMemo =>
      Web3RequestExceptionConst.invalidParameters(
        'Invalid shield memo length. '
        'The memo length must not exceed ${NoteEncryptionConst.memoLength} bytes. '
        'Shorter memos will be padded with zeros.',
      );

  static Web3RequestException get invalidMemos =>
      Web3RequestExceptionConst.invalidParameters(
        'Invalid memo scripts. The memos field must be a list of OP_RETURN scripts encoded as bytes or hexadecimal bytes.',
      );
  static Web3RequestException unsupportedRecipientAddressProtocol(String protocol,
          {List<ZcashProtocol> protocols = ZcashProtocol.values}) =>
      Web3RequestExceptionConst.message(
          'Unsupported recipient address protocol "$protocol". '
          'Supported protocols: ${protocols.map((e) => e.name).join(", ")}.',
          errorType: Web3ErrorCode.unsupportedFeature);
  static Web3RequestException invalidReceiptProtocol(String protocol) =>
      Web3RequestExceptionConst.invalidParameters(
          'Invalid recipient protocol. The address does not support the selected protocol: $protocol.');

  static Web3RequestException invalidProtocolAddress(String protocol) =>
      Web3RequestExceptionConst.invalidParameters(
          'Invalid recipient protocol address. protocol: $protocol.');

  static Web3RequestException unsuportedSigningMessageAccount(String address) =>
      Web3RequestExceptionConst.message(
          "The $address address does not support message signing. Only transparent P2PKH accounts are allowed to sign messages.",
          errorType: Web3ErrorCode.unsupportedFeature);
  static Web3RequestException invalidPrivacy(String privacy) =>
      Web3RequestExceptionConst.invalidParameters(
        'Invalid privacy option "$privacy". '
        'Supported privacy options: '
        '${Web3ZcashTransferPrivacy.values.map((e) => e.name).join(", ")}.',
      );
}
