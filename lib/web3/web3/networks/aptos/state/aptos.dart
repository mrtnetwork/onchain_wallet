import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain/aptos/src/address/address/address.dart';
import 'package:on_chain/aptos/src/transaction/types/types.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/models/network/params/aptos.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message.dart';
import 'package:on_chain_wallet/web3/web3/core/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/state/core/network.dart';
import 'package:on_chain_wallet/web3/web3/networks/aptos/aptos.dart';
import 'package:on_chain_wallet/web3/web3/utils/web3_validator_utils.dart';

mixin AptosWeb3StateHandler<
        ADDRESS,
        STATEADDRESS extends Web3StateAddress<AptosAddress, Web3AptosChainAccount, ADDRESS,
            Web3AptosChainIdnetifier>,
        STATEACCOUNT extends Web3StateAccount<AptosAddress, Web3AptosChainAccount, ADDRESS,
            Web3AptosChainIdnetifier, STATEADDRESS>,
        RESPONSE,
        REQUEST extends Web3ClientRequest,
        EVENT>
    on Web3StateHandler<AptosAddress, Web3AptosChainAccount, ADDRESS,
        Web3AptosChainIdnetifier, STATEADDRESS, STATEACCOUNT, RESPONSE, REQUEST, EVENT> {
  @override
  AptosAddress toAddress(String v, {Web3AptosChainIdnetifier? network}) {
    try {
      return AptosAddress(v);
    } catch (e) {
      throw Web3RequestExceptionConst.invalidAddress(key: v, network: networkType.name);
    }
  }

  @override
  NetworkType get networkType => NetworkType.aptos;
  @override
  List<Web3NetworkEvent> get events => [
        Web3NetworkEvent.change,
        Web3NetworkEvent.accountsChanged,
        Web3NetworkEvent.chainChanged
      ];

  @override
  List<Web3AptosRequestMethods> get methods => Web3AptosRequestMethods.values;

  Web3AptosSendTransaction toSignTransactionRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3AptosRequestMethods method,
      Web3AptosChainIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      const List<String> keys = ["rawTransaction"];
      final data = params.paramsAsMap(keys: keys, method: method);
      final AptosAddress? feePayerAddress = Web3ValidatorUtils.parseAddress(
          onParse: (e) => AptosAddress(e),
          key: "feePayerAddress",
          method: method,
          json: data,
          network: networkType.name);

      List<AptosAddress>? secondarySignerAddresses = Web3ValidatorUtils.parseParams2(() {
        final List<String>? secondarySignerAddresses =
            Web3ValidatorUtils.parseList<List<String>?, String>(
                key: "secondarySignerAddresses", method: method, json: data);
        if (secondarySignerAddresses == null || secondarySignerAddresses.isEmpty) {
          return null;
        }
        return secondarySignerAddresses.map((e) => AptosAddress(e)).toList();
      },
          errorOnNull: false,
          error: Web3AptosExceptionConstant.invalidSecondarySignerAddressesParams);
      final rawTx = Web3ValidatorUtils.parseParams2(() {
        return AptosRawTransaction.deserialize(params.objectAsBytes(
            object: data["rawTransaction"],
            name: 'rawTransaction',
            encoding: [StringEncoding.hex]));
      }, error: Web3RequestExceptionConst.invalidBytesOrHexArgrument2("rawTransaction"));
      return Web3AptosSendTransaction(
          transaction: rawTx,
          method: method,
          feePayer: feePayerAddress,
          socondarySignerAddresses: secondarySignerAddresses,
          account: state.defaultNetworkChainAccountOrThrow);
    }, error: Web3RequestExceptionConst.invalidTransaction);
  }

  Web3AptosSignMessage toSignInRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3AptosRequestMethods method,
      Web3AptosChainIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      const List<String> keys = ["message", "nonce"];
      final data = params.paramsAsMap(keys: keys, method: method);
      return Web3AptosSignMessage.aptos(
          account: state.defaultNetworkChainAccountOrThrow,
          message:
              Web3ValidatorUtils.parseString(key: "message", method: method, json: data),
          nonce: Web3ValidatorUtils.parseString(key: "nonce", method: method, json: data),
          address:
              Web3ValidatorUtils.parseBool(key: "address", method: method, json: data),
          application: Web3ValidatorUtils.parseString(
              key: "application", method: method, json: data),
          chainId:
              Web3ValidatorUtils.parseString(key: "chainId", method: method, json: data));
    }, error: Web3RequestExceptionConst.invalidTransaction);
  }

  Web3AptosChainIdnetifier parseSwitchChainRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3AptosRequestMethods method,
      Web3AptosChainIdnetifier? network}) {
    if (!state.hasChainAccount) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    const List<String> keys = ["chainId"];
    final data = params.paramsAsMap(keys: keys, method: method);
    final int chainId =
        Web3ValidatorUtils.parseInt(key: "chainId", method: method, json: data);
    return state.chains.firstWhere(
        (e) => e.aptosChain == AptosChainType.fromValue(chainId),
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
  }

  Future<Web3MessageCore> toSwitchChainRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3AptosRequestMethods method,
      Web3AptosChainIdnetifier? network}) async {
    final chain = parseSwitchChainRequest(
        params: params, state: state, method: method, network: network);
    if (chain.aptosChain == state.defaultChain?.aptosChain) {
      return createResponse();
    }
    return connetInternal(networks: [chain.id]);
  }

  @override
  Future<Web3MessageCore> request(REQUEST message,
      {Web3AptosChainIdnetifier? network}) async {
    final method = Web3AptosRequestMethods.fromName(message.method);
    final state = await getState();
    if (method == null) {
      throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    switch (method) {
      case Web3AptosRequestMethods.switchNetwork:
        return toSwitchChainRequest(
            params: message, state: state, method: method, network: network);
      case Web3AptosRequestMethods.requestAccounts:
        return onConnect_(message);
      case Web3AptosRequestMethods.getNetwork:
        final currentNetwork = state.defaultChain;
        if (currentNetwork != null) {
          return createResponse();
        }
        throw Web3RequestExceptionConst.missingPermission;

      case Web3AptosRequestMethods.signTransaction:
        return toSignTransactionRequest(
            params: message, state: state, method: method, network: network);
      case Web3AptosRequestMethods.signMessage:
        return toSignInRequest(
            params: message, state: state, method: method, network: network);
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
  }
}
