import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/types/account.dart';
import 'package:on_chain_wallet/web3/web3/networks/ton/ton.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain_wallet/web3/web3/utils/web3_validator_utils.dart';
import 'package:ton_dart/ton_dart.dart';

mixin TonWeb3StateHandler<
        ADDRESS,
        STATEADDRESS extends Web3StateAddress<TonAddress, Web3TonChainAccount, ADDRESS,
            Web3ChainDefaultIdnetifier>,
        STATEACCOUNT extends Web3StateAccount<TonAddress, Web3TonChainAccount, ADDRESS,
            Web3ChainDefaultIdnetifier, STATEADDRESS>,
        RESPONSE,
        REQUEST extends Web3ClientRequest,
        EVENT>
    on Web3StateHandler<
        TonAddress,
        Web3TonChainAccount,
        ADDRESS,
        Web3ChainDefaultIdnetifier,
        STATEADDRESS,
        STATEACCOUNT,
        RESPONSE,
        REQUEST,
        EVENT> {
  @override
  TonAddress toAddress(String v, {Web3ChainDefaultIdnetifier? network}) {
    try {
      return TonAddress(v);
    } catch (_) {}
    throw Web3RequestExceptionConst.invalidAddress(key: v, network: networkType.name);
  }

  @override
  NetworkType get networkType => NetworkType.ton;
  @override
  List<Web3TonRequestMethods> get methods => Web3TonRequestMethods.values;
  Web3TonSignMessage toSignMessageRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3TonRequestMethods method,
      Web3ChainDefaultIdnetifier? network}) {
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
      final message = params.objectAsBytes(
          object: data["message"],
          name: "message",
          encoding: [StringEncoding.hex, StringEncoding.base64, StringEncoding.utf8]);
      return Web3TonSignMessage(
          accessAccount: account,
          challeng: BytesUtils.toHexString(message),
          content: StringUtils.tryDecode(message));
    });
  }

  Web3TonSendTransaction toSignTransactionRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3TonRequestMethods method,
      Web3ChainDefaultIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      const List<String> keys = ["messages", "validUntil"];
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
      final int validUntil =
          Web3ValidatorUtils.parseInt(key: "validUntil", method: method, json: data);
      final List<Map<String, dynamic>> messagesJson =
          Web3ValidatorUtils.parseList<List<Map<String, dynamic>>, Map<String, dynamic>>(
              key: "messages", method: method, json: data);
      List<Web3TonTransactionMessage> messages =
          messagesJson.map(Web3TonTransactionMessage.fromJson).toList();
      final maxMessageLength = account.maxMessageLength;
      if (messages.isEmpty || messages.length > maxMessageLength) {
        throw Web3TonExceptionConstant.invalidTransactionMessageLength(maxMessageLength);
      }
      return Web3TonSendTransaction(
          account: account, validUntil: validUntil, method: method, messages: messages);
    });
  }

  @override
  Future<Web3MessageCore> request(REQUEST message,
      {Web3ChainDefaultIdnetifier? network}) async {
    final method = Web3TonRequestMethods.fromName(message.method);
    final state = await getState();
    if (method == null) {
      throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    switch (method) {
      case Web3TonRequestMethods.requestAccounts:
        return onConnect_(message);
      case Web3TonRequestMethods.sendTransaction:
      case Web3TonRequestMethods.signTransaction:
        return toSignTransactionRequest(
            params: message, state: state, method: method, network: network);
      case Web3TonRequestMethods.signMessage:
        return toSignMessageRequest(params: message, state: state, method: method);
      default:
        throw Web3RequestExceptionConst.methodDoesNotSupport;
    }
  }
}
