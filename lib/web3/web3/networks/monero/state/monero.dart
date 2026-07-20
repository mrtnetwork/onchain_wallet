import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message.dart';
import 'package:on_chain_wallet/web3/web3/networks/monero/constant/constants/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/monero/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/monero/params/models/sign_message.dart';
import 'package:on_chain_wallet/web3/web3/networks/monero/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/monero/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/state/core/network.dart';
import 'package:on_chain_wallet/web3/web3/utils/web3_validator_utils.dart';

mixin MoneroWeb3StateHandler<
        ADDRESS,
        STATEADDRESS extends Web3StateAddress<MoneroAddress, Web3MoneroChainAccount, ADDRESS,
            Web3MoneroChainIdnetifier>,
        STATEACCOUNT extends Web3StateAccount<MoneroAddress, Web3MoneroChainAccount, ADDRESS,
            Web3MoneroChainIdnetifier, STATEADDRESS>,
        RESPONSE,
        REQUEST extends Web3ClientRequest,
        EVENT>
    on Web3StateHandler<MoneroAddress, Web3MoneroChainAccount, ADDRESS,
        Web3MoneroChainIdnetifier, STATEADDRESS, STATEACCOUNT, RESPONSE, REQUEST, EVENT> {
  @override
  MoneroAddress toAddress(String v, {Web3MoneroChainIdnetifier? network}) {
    try {
      final address = MoneroAddress(v);
      if (network != null && network.network != address.network) {
        throw Web3RequestExceptionConst.invalidAddress(
            key: v, network: network.network.name);
      }
      return address;
    } catch (_) {}
    throw Web3RequestExceptionConst.invalidAddress(key: v, network: networkType.name);
  }

  @override
  NetworkType get networkType => NetworkType.monero;
  @override
  List<Web3MoneroRequestMethods> get methods => Web3MoneroRequestMethods.values;
  Web3MoneroSendTransaction toSignTransactionRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3MoneroRequestMethods method,
      Web3MoneroChainIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      final data = params.paramsAsMap(keys: ['recipients'], method: method);
      final account = Web3ValidatorUtils.parseParams2(() {
        final account = tryParseStateAddress(
            addr: data["address"] ?? data["account"],
            params: params,
            state: state,
            network: network);
        if (account == null) return null;

        return state.findAddressOrDefault(
            address: account.address, network: network ?? account.chain);
      },
          error: Web3RequestExceptionConst.invalidAddressArgrument(
              key: "address", network: networkType.name));

      List<Web3MoneroTransactionParams> payments = [];
      network ??= state.chains.firstWhere((e) => e.network == account.address.network);
      final recipients =
          params.objectAsListOfMap(object: data["recipients"], name: "recipients");
      for (final i in recipients) {
        final recipientsData = Web3ValidatorUtils.parseParams2(() {
          return tryParseStateAddress(
              addr: i["address"], params: params, state: state, network: network);
        },
            error: Web3RequestExceptionConst.invalidAddressArgrument(
                key: "address", network: networkType.name));
        final BigInt amount = Web3ValidatorUtils.parseBigInt(
            key: "amount", method: method, json: i, sign: false);
        payments.add(Web3MoneroTransactionParams(
            destination: recipientsData.address, amount: amount));
      }
      if (payments.isEmpty) {
        throw Web3MoneroExceptionConstant.noRecipients;
      }
      final addresses = payments.map((e) => e.destination.network).toSet().length;
      if (addresses != 1) {
        throw Web3MoneroExceptionConstant.mismatchPaymentAddresses;
      }
      if (payments.map((e) => e.destination).toSet().length != payments.length) {
        throw Web3MoneroExceptionConstant.duplicateOutputAddressesNotAllowed;
      }
      if (payments.length > 1) {
        final integratedAddresses =
            payments.map((e) => e.destination.isIntegratedAddress).length;
        if (integratedAddresses > 1) {
          throw Web3MoneroExceptionConstant.multipleIntegratedAddressNotAllowed;
        }
      }

      return Web3MoneroSendTransaction(destintions: payments, account: account);
    }, error: Web3MoneroExceptionConstant.invalidTransaction);
  }

  Web3MoneroSignMessage toSignMessageRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3MoneroRequestMethods method,
      Web3MoneroChainIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      const List<String> keys = ["message"];
      final data = params.paramsAsMap(keys: keys, method: method);
      final account = Web3ValidatorUtils.parseParams2(() {
        final account = tryParseStateAddress(
            addr: data["address"] ?? data["account"],
            params: params,
            state: state,
            network: network);
        if (account == null) return null;
        return state.findAddressOrDefault(
            address: account.address, network: network ?? account.chain);
      },
          error: Web3RequestExceptionConst.invalidAddressArgrument(
              key: "address", network: networkType.name));

      if (account.publicKey == null) {
        throw Web3MoneroExceptionConstant.accountDoesNotSupportSignMessage;
      }

      final message = params.objectAsBytes(
          object: data["message"],
          name: "message",
          encoding: [StringEncoding.hex, StringEncoding.utf8]);
      return Web3MoneroSignMessage(
          accessAccount: account,
          challeng: BytesUtils.toHexString(message),
          content: StringUtils.tryDecode(message));
    });
  }

  @override
  Future<Web3MessageCore> request(REQUEST message,
      {Web3MoneroChainIdnetifier? network}) async {
    final method = Web3MoneroRequestMethods.fromName(message.method);
    final state = await getState();
    if (method == null) {
      throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    switch (method) {
      case Web3MoneroRequestMethods.requestAccounts:
        return onConnect_(message);
      case Web3MoneroRequestMethods.signMessage:
        return toSignMessageRequest(
            params: message, state: state, method: method, network: network);
      case Web3MoneroRequestMethods.sendTransaction:
        return toSignTransactionRequest(
            params: message, state: state, method: method, network: network);
      default:
        throw Web3RequestExceptionConst.methodDoesNotSupport;
    }
  }
}
