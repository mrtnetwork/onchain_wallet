import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain/sui/src/address/address/address.dart';
import 'package:on_chain/sui/src/rpc/models/types/types.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/types/account.dart';
import 'package:on_chain_wallet/web3/web3/state/core/network.dart';
import 'package:on_chain_wallet/web3/web3/networks/sui/sui.dart';
import 'package:on_chain_wallet/web3/web3/utils/web3_validator_utils.dart';

mixin SuiWeb3StateHandler<
        ADDRESS,
        STATEADDRESS extends Web3StateAddress<SuiAddress, Web3SuiChainAccount, ADDRESS,
            Web3ChainDefaultIdnetifier>,
        STATEACCOUNT extends Web3StateAccount<SuiAddress, Web3SuiChainAccount, ADDRESS,
            Web3ChainDefaultIdnetifier, STATEADDRESS>,
        RESPONSE,
        REQUEST extends Web3ClientRequest,
        EVENT>
    on Web3StateHandler<
        SuiAddress,
        Web3SuiChainAccount,
        ADDRESS,
        Web3ChainDefaultIdnetifier,
        STATEADDRESS,
        STATEACCOUNT,
        RESPONSE,
        REQUEST,
        EVENT> {
  @override
  SuiAddress toAddress(String v, {Web3ChainDefaultIdnetifier? network}) {
    try {
      return SuiAddress(v);
    } catch (_) {}
    throw Web3RequestExceptionConst.invalidAddress(key: v, network: networkType.name);
  }

  @override
  NetworkType get networkType => NetworkType.sui;
  @override
  List<Web3SuiRequestMethods> get methods => Web3SuiRequestMethods.values;
  Web3SuiSignOrExecuteTransaction toSignTransactionRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3SuiRequestMethods method,
      Web3ChainDefaultIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      const List<String> keys = ["transaction"];

      final data = params.paramsAsMap(keys: keys, method: method);
      final Web3ChainDefaultIdnetifier? chain = Web3ValidatorUtils.parseParams2(() {
        if (!data.containsKey("chain")) return null;
        return state.getChainFromChainIdentifier(data["chain"]);
      },
          errorOnNull: false,
          error: Web3RequestExceptionConst.invalidStringArgrument('chain'));
      final account = Web3ValidatorUtils.parseParams2(() {
        final account = tryParseStateAddress(
            addr: data["address"] ?? data["account"],
            params: params,
            state: state,
            network: network);
        if (account == null) return null;

        return state.findAddressOrDefault(
            address: account.address, network: network ?? chain ?? account.chain);
      },
          error: Web3RequestExceptionConst.invalidAddressArgrument(
              key: "address", network: networkType.name));
      if (chain != null && account.id != chain.id) {
        throw Web3SuiExceptionConstant.missmatchChainIdAndAccount;
      }
      final List<int> txString = params.objectAsBytes(
          object: data["transaction"],
          name: "transaction",
          encoding: [StringEncoding.hex, StringEncoding.base64]);
      final Map<String, dynamic> txJson = StringUtils.decodeJson(txString);
      final transaction = Web3SuiTransactionDataV2.fromJson(txJson);
      final String? requestType =
          Web3ValidatorUtils.parseString(key: "requestType", method: method, json: data);
      SuiApiExecuteTransactionRequestType? executeType =
          SuiApiExecuteTransactionRequestType.values
              .firstWhereOrNull((e) => e.name == requestType);
      SuiApiTransactionBlockResponseOptions? executeOptions;
      final Map<String, dynamic>? option =
          Web3ValidatorUtils.parseMap(key: "executeOptions", method: method, json: data);
      if (option != null) {
        executeOptions = SuiApiTransactionBlockResponseOptions.fromJson(option);
      }
      return Web3SuiSignOrExecuteTransaction(
          transaction: transaction,
          account: account,
          method: method,
          executeOptions: executeOptions,
          executeType: executeType);
    }, error: Web3RequestExceptionConst.invalidTransaction);
  }

  Web3SuiSignMessage toSignMessageRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3SuiRequestMethods method,
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
      return Web3SuiSignMessage(
          account: account,
          challeng: BytesUtils.toHexString(message),
          content: StringUtils.tryDecode(message),
          method: method);
    });
  }

  @override
  Future<Web3MessageCore> request(REQUEST message,
      {Web3ChainDefaultIdnetifier? network}) async {
    final method = Web3SuiRequestMethods.fromName(message.method);
    final state = await getState();
    if (method == null) {
      throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    switch (method) {
      case Web3SuiRequestMethods.requestAccounts:
        return onConnect_(message);
      case Web3SuiRequestMethods.signPersonalMessage:
      case Web3SuiRequestMethods.signMessage:
        return toSignMessageRequest(
            params: message, state: state, method: method, network: network);
      case Web3SuiRequestMethods.signTransaction:
      case Web3SuiRequestMethods.signAndExecuteTransaction:
        return toSignTransactionRequest(
            params: message, state: state, method: method, network: network);
      default:
        throw Web3RequestExceptionConst.methodDoesNotSupport;
    }
  }
}
