import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/types/account.dart';
import 'package:on_chain_wallet/web3/web3/state/core/network.dart';
import 'package:on_chain_wallet/web3/web3/networks/stellar/stellar.dart';
import 'package:on_chain_wallet/web3/web3/utils/web3_validator_utils.dart';
import 'package:stellar_dart/stellar_dart.dart';

mixin StellarWeb3StateHandler<
        ADDRESS,
        STATEADDRESS extends Web3StateAddress<StellarAddress, Web3StellarChainAccount,
            ADDRESS, Web3ChainDefaultIdnetifier>,
        STATEACCOUNT extends Web3StateAccount<StellarAddress, Web3StellarChainAccount,
            ADDRESS, Web3ChainDefaultIdnetifier, STATEADDRESS>,
        RESPONSE,
        REQUEST extends Web3ClientRequest,
        EVENT>
    on Web3StateHandler<
        StellarAddress,
        Web3StellarChainAccount,
        ADDRESS,
        Web3ChainDefaultIdnetifier,
        STATEADDRESS,
        STATEACCOUNT,
        RESPONSE,
        REQUEST,
        EVENT> {
  @override
  StellarAddress toAddress(String v, {Web3ChainDefaultIdnetifier? network}) {
    try {
      return StellarAddress.fromBase32Addr(v);
    } catch (_) {}
    throw Web3RequestExceptionConst.invalidAddress(key: v, network: networkType.name);
  }

  @override
  NetworkType get networkType => NetworkType.stellar;
  @override
  List<Web3StellarRequestMethods> get methods => Web3StellarRequestMethods.values;

  Web3StellarSendTransaction toSignTransactionRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3StellarRequestMethods method,
      Web3ChainDefaultIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      const List<String> keys = ["transaction"];
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
      final List<int> txBytes = params.objectAsBytes(
          object: data["transaction"],
          name: "transaction",
          encoding: [StringEncoding.hex, StringEncoding.base64]);
      return Web3StellarSendTransaction(
          account: account, transaction: txBytes, method: method);
    }, error: Web3RequestExceptionConst.invalidTransaction);
  }

  Web3StellarSignMessage toSignMessageRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3StellarRequestMethods method,
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
      return Web3StellarSignMessage(
          accessAccount: account,
          challeng: BytesUtils.toHexString(message),
          content: StringUtils.tryDecode(message));
    });
  }

  @override
  Future<Web3MessageCore> request(REQUEST message,
      {Web3ChainDefaultIdnetifier? network}) async {
    final method = Web3StellarRequestMethods.fromName(message.method);
    final state = await getState();
    if (method == null) {
      throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    switch (method) {
      case Web3StellarRequestMethods.requestAccounts:
        return onConnect_(message);
      case Web3StellarRequestMethods.signMessage:
        return toSignMessageRequest(
            params: message, state: state, method: method, network: network);
      case Web3StellarRequestMethods.signTransaction:
      case Web3StellarRequestMethods.sendTransaction:
        return toSignTransactionRequest(
            params: message, state: state, method: method, network: network);
      default:
        throw Web3RequestExceptionConst.methodDoesNotSupport;
    }
  }
}
