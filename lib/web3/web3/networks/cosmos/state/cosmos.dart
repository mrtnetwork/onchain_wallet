import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message.dart';
import 'package:on_chain_wallet/web3/web3/state/core/network.dart';
import 'package:on_chain_wallet/web3/web3/networks/cosmos/cosmos.dart';
import 'package:on_chain_wallet/web3/web3/utils/web3_validator_utils.dart';

mixin CosmosWeb3StateHandler<
        ADDRESS,
        STATEADDRESS extends Web3StateAddress<CosmosBaseAddress, Web3CosmosChainAccount,
            ADDRESS, Web3CosmoshainIdnetifier>,
        STATEACCOUNT extends Web3StateAccount<CosmosBaseAddress, Web3CosmosChainAccount,
            ADDRESS, Web3CosmoshainIdnetifier, STATEADDRESS>,
        RESPONSE,
        REQUEST extends Web3ClientRequest,
        EVENT>
    on Web3StateHandler<CosmosBaseAddress, Web3CosmosChainAccount, ADDRESS,
        Web3CosmoshainIdnetifier, STATEADDRESS, STATEACCOUNT, RESPONSE, REQUEST, EVENT> {
  @override
  CosmosBaseAddress toAddress(String v, {Web3CosmoshainIdnetifier? network}) {
    try {
      return CosmosBaseAddress(v, forceHrp: network?.hrp);
    } catch (_) {}
    throw Web3RequestExceptionConst.invalidAddress(key: v, network: networkType.name);
  }

  @override
  NetworkType get networkType => NetworkType.cosmos;

  @override
  List<Web3CosmosRequestMethods> get methods => Web3CosmosRequestMethods.values;

  Web3MessageCore toAddNewChainRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3CosmosRequestMethods method,
      Web3CosmoshainIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      const List<String> keys = ["chainId", "rpc", "name"];
      final data = params.paramsAsMap(keys: keys, method: method);
      final request = Web3CosmosAddNewChain.fromJson(data);
      final network = state.chains.firstWhereOrNull((e) => e.chainId == request.chainId);
      if (network != null) {
        return createResponse(true);
      }
      return request;
    });
  }

  Web3CosmosSignMessage toSignMessageRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3CosmosRequestMethods method,
      Web3CosmoshainIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      const List<String> keys = ["message"];
      final data = params.paramsAsMap(keys: keys, method: method);
      final account = Web3ValidatorUtils.parseParams2(() {
        final address = tryParseStateAddress(
            addr: data["account"] ?? data["address"],
            params: params,
            state: state,
            network: network);
        if (address == null) return null;
        return state.findAddressOrDefault(
            address: address.address, network: network ?? address.chain);
      },
          error: Web3RequestExceptionConst.invalidAddressArgrument(
              key: "account", network: networkType.name));

      final message = StringUtils.toBytes(data["message"]);
      return Web3CosmosSignMessage(
          account: account,
          challeng: BytesUtils.toHexString(message),
          content: StringUtils.tryDecode(message));
    });
  }

  Web3CosmosSignTransaction toSignDirectTransactionRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3CosmosRequestMethods method,
      Web3CosmoshainIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      const List<String> keys = ['signerAddress', 'signDoc'];
      final param = params.paramsAsMap(method: method, keys: keys);
      if (network == null) {
        final String? chainId =
            Web3ValidatorUtils.parseString(key: "chainId", method: method, json: param);
        if (chainId != null) {
          network = state.chains.firstWhere((e) => e.chainId == chainId,
              orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
        }
      }
      final account = Web3ValidatorUtils.parseAddress(
          onParse: (e) =>
              state.findAddressOrDefault(address: CosmosBaseAddress(e), network: network),
          key: "signerAddress",
          method: method,
          json: param,
          network: networkType.name);
      final currentChain = state.getAccountChain(account);

      if (method == Web3CosmosRequestMethods.signTransactionAmino) {
        final aminoJson = Web3ValidatorUtils.tryObjectAsMap(param["signDoc"]);
        if (aminoJson == null) {
          throw Web3CosmosExceptionConstant.invalidAminoSignDoc;
        }
        final AminoTx amino = AminoTx.fromJson(aminoJson);
        if (currentChain.chainId != amino.chainId) {
          throw Web3CosmosExceptionConstant.mismatchChainId;
        }
        return Web3CosmosSignTransaction(
            account: account,
            chainId: amino.chainId,
            transaction: Web3CosmosSignTransactionAminoParams(amino));
      }
      final Map<String, dynamic> signDoc = Web3ValidatorUtils.parseMap(
          key: "signDoc", method: method, json: param, requiredKeys: ["bodyBytes"]);
      final List<int> bodyBytes = params.objectAsBytes(
          object: signDoc["bodyBytes"],
          name: "bodyBytes",
          encoding: [StringEncoding.hex, StringEncoding.base64]);
      final List<int>? authInfoBytes = Web3ValidatorUtils.parseParams2(() {
        final authInfoBytes = signDoc["authInfoBytes"];
        if (authInfoBytes == null) return null;
        return params.objectAsBytes(
            object: signDoc["authInfoBytes"],
            name: "authInfoBytes",
            encoding: [StringEncoding.hex, StringEncoding.base64]);
      }, errorOnNull: false);
      final BigInt? accountNumber = Web3ValidatorUtils.parseBigInt(
          key: "accountNumber", method: method, json: signDoc, sign: false);
      final tx = Web3CosmosSignTransaction(
          account: account,
          chainId: currentChain.chainId,
          transaction: Web3CosmosSignTransactionDirectParams(
              bodyBytes: bodyBytes,
              authInfos: authInfoBytes,
              accountNumber: accountNumber));
      if (tx.chainId != currentChain.chainId) {
        throw Web3CosmosExceptionConstant.mismatchChainId;
      }
      return tx;
    }, error: Web3RequestExceptionConst.invalidTransaction);
  }

  @override
  Future<Web3MessageCore> request(REQUEST message,
      {Web3CosmoshainIdnetifier? network}) async {
    final method = Web3CosmosRequestMethods.fromName(message.method);
    final state = await getState();
    if (method == null) {
      throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    switch (method) {
      case Web3CosmosRequestMethods.requestAccounts:
        return onConnect_(message);
      case Web3CosmosRequestMethods.signTransactionAmino:
      case Web3CosmosRequestMethods.signTransactionDirect:
        return toSignDirectTransactionRequest(
            params: message, state: state, method: method, network: network);
      case Web3CosmosRequestMethods.signMessage:
        return toSignMessageRequest(
            params: message, state: state, network: network, method: method);
      case Web3CosmosRequestMethods.addNewChain:
        return toAddNewChainRequest(
            params: message, state: state, network: network, method: method);
      default:
        throw Web3RequestExceptionConst.methodDoesNotSupport;
    }
  }
}
