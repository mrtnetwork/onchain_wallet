import 'package:blockchain_utils/layout/constant/constant.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/utils/web3_validator_utils.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

mixin SubstrateWeb3StateHandler<
        ADDRESS,
        STATEADDRESS extends Web3StateAddress<BaseSubstrateAddress, Web3SubstrateChainAccount,
            ADDRESS, Web3SubstrateChainIdnetifier>,
        STATEACCOUNT extends Web3StateAccount<BaseSubstrateAddress, Web3SubstrateChainAccount,
            ADDRESS, Web3SubstrateChainIdnetifier, STATEADDRESS>,
        RESPONSE,
        REQUEST extends Web3ClientRequest,
        EVENT>
    on Web3StateHandler<
        BaseSubstrateAddress,
        Web3SubstrateChainAccount,
        ADDRESS,
        Web3SubstrateChainIdnetifier,
        STATEADDRESS,
        STATEACCOUNT,
        RESPONSE,
        REQUEST,
        EVENT> {
  @override
  BaseSubstrateAddress toAddress(String v, {Web3SubstrateChainIdnetifier? network}) {
    try {
      if (network == null) return BaseSubstrateAddress(v);
      if (network.type.isEthereum) {
        return SubstrateEthereumAddress(v);
      }
      return SubstrateAddress(v, ss58Format: network.ss58Fromat);
    } catch (_) {}
    throw Web3RequestExceptionConst.invalidAddress(key: v, network: networkType.name);
  }

  @override
  NetworkType get networkType => NetworkType.substrate;
  @override
  List<Web3SubstrateRequestMethods> get methods => Web3SubstrateRequestMethods.values;
  Web3SubstrateSignMessage toSignMessageRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3SubstrateRequestMethods method,
      Web3SubstrateChainIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      // const List<String> keys = ["address", "message"];
      final data = params.paramsAsMap(method: method, keys: ["message"]);
      final account = Web3ValidatorUtils.parseParams2(() {
        final address = tryParseStateAddress(
            addr: data["address"] ?? data["account"],
            params: params,
            state: state,
            network: network);
        if (address == null) return null;
        return state.findAddressOrDefault(
            address: address.address, network: network ?? address.chain);
      });
      final message = params.objectAsBytes(
          object: data["message"] ?? data["data"],
          name: "message",
          encoding: [StringEncoding.hex, StringEncoding.utf8]);
      return Web3SubstrateSignMessage(
          accessAccount: account,
          challeng: BytesUtils.toHexString(message),
          content: StringUtils.tryDecode(message));
    });
  }

  Web3MessageCore toAddNewChainRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3SubstrateRequestMethods method,
      Web3SubstrateChainIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      const List<String> keys = [
        "chain",
        "genesisHash",
        "ss58Format",
        "specVersion",
        "tokenDecimals",
        "tokenSymbol"
      ];
      Map<String, dynamic> param = params.paramsAsMap(keys: keys, method: method);

      Web3ValidatorUtils.parseParams2<int?>(() {
        final metadataHex = param["rawMetadata"];
        if (metadataHex == null) return null;
        final toBytes = BytesUtils.fromHexString(metadataHex);
        final decode = LayoutConst.bytes().deserialize(toBytes).value;
        try {
          final metadata = VersionedMetadata.fromBytes(decode);
          if (metadata.supportedByApi) return metadata.version;
        } catch (_) {}
        throw Web3SubstrateExceptionConstant.unsuportedMetadataVersion;
      }, error: Web3SubstrateExceptionConstant.metadataParsingFailed, errorOnNull: false);
      final request = Web3SubstrateAddNewChain.fromJson(param);
      final chain = state.chains.firstWhereOrNull(
          (e) => StringUtils.hexEqual(e.genesisHash, request.genesisHash));
      if (chain != null && chain.specVersion == request.specVersion) {
        return createResponse();
      }

      return request;
    }, error: Web3SubstrateExceptionConstant.metadataParsingFailed);
  }

  Web3SubstrateSendTransaction toSignTransactionRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3SubstrateRequestMethods method,
      Web3SubstrateChainIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      const List<String> keys = ["address"];
      Map<String, dynamic> param = params.paramsAsMap(keys: keys, method: method);
      Map<String, dynamic> transactionPayload;
      if (param.containsKey("transactionPayload")) {
        transactionPayload = params.objectAsMap(
            object: param["transactionPayload"], name: "transactionPayload");
      } else {
        transactionPayload = param;
      }
      final String genesis = Web3ValidatorUtils.parseHex<String>(
          key: "genesisHash", method: method, json: transactionPayload);
      final txChain = state.chains.firstWhere(
        (e) => StringUtils.hexEqual(e.genesisHash, genesis),
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists,
      );

      final account = Web3ValidatorUtils.parseParams2(() {
        final addr =
            param["address"] ?? param["account"] ?? transactionPayload["address"];
        final address = tryParseStateAddress(
            addr: addr, params: params, state: state, network: txChain);
        if (address == null) return null;
        return state.findAddressOrDefault(address: address.address, network: txChain);
      },
          error: Web3RequestExceptionConst.invalidAddressArgrument(
              key: 'address', network: networkType.name));

      return Web3SubstrateSendTransaction(json: transactionPayload, address: account);
    }, error: Web3RequestExceptionConst.invalidTransaction);
  }

  @override
  Future<Web3MessageCore> request(REQUEST message,
      {Web3SubstrateChainIdnetifier? network}) async {
    final method = Web3SubstrateRequestMethods.fromName(message.method);
    final state = await getState();
    if (method == null) {
      throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    switch (method) {
      case Web3SubstrateRequestMethods.requestAccounts:
        return onConnect_(message);
      case Web3SubstrateRequestMethods.knownMetadata:
        return createResponse();
      case Web3SubstrateRequestMethods.addSubstrateChain:
        return toAddNewChainRequest(
            params: message, state: state, method: method, network: network);
      case Web3SubstrateRequestMethods.signTransaction:
        return toSignTransactionRequest(
            params: message, state: state, method: method, network: network);
      case Web3SubstrateRequestMethods.signMessage:
        return toSignMessageRequest(
            params: message, state: state, method: method, network: network);
      default:
        throw Web3RequestExceptionConst.methodDoesNotSupport;
    }
  }
}
