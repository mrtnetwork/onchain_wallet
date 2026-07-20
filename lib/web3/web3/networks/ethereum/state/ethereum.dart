import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain/ethereum/src/address/evm_address.dart';
import 'package:on_chain/ethereum/src/transaction/eth_transaction.dart';
import 'package:on_chain/solidity/abi/abi.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';

import 'package:on_chain_wallet/wallet/api/service/types/protocols.dart';
import 'package:on_chain_wallet/wallet/constant/networks/ethereum.dart';
import 'package:on_chain_wallet/web3/web3/utils/web3_validator_utils.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';

mixin EthereumWeb3StateHandler<
        ADDRESS,
        STATEADDRESS extends Web3StateAddress<ETHAddress, Web3EthereumChainAccount, ADDRESS,
            Web3EthereumChainIdnetifier>,
        STATEACCOUNT extends Web3StateAccount<ETHAddress, Web3EthereumChainAccount, ADDRESS,
            Web3EthereumChainIdnetifier, STATEADDRESS>,
        RESPONSE,
        REQUEST extends Web3ClientRequest,
        EVENT>
    on Web3StateHandler<
        ETHAddress,
        Web3EthereumChainAccount,
        ADDRESS,
        Web3EthereumChainIdnetifier,
        STATEADDRESS,
        STATEACCOUNT,
        RESPONSE,
        REQUEST,
        EVENT> {
  @override
  ETHAddress toAddress(String v, {Web3EthereumChainIdnetifier? network}) {
    try {
      return ETHAddress(v);
    } catch (_) {}
    throw Web3RequestExceptionConst.invalidAddress(key: v, network: networkType.name);
  }

  @override
  NetworkType get networkType => NetworkType.ethereum;
  @override
  List<Web3EthereumRequestMethods> get methods => Web3EthereumRequestMethods.values;
  @override
  List<Web3NetworkEvent> get events => [
        Web3NetworkEvent.change,
        Web3NetworkEvent.accountsChanged,
        Web3NetworkEvent.chainChanged,
        Web3NetworkEvent.message,
        Web3NetworkEvent.connect,
        Web3NetworkEvent.disconnect,
      ];

  Web3EthreumPersonalSign toPersonalSignRequest({
    required REQUEST params,
    required STATEACCOUNT state,
    required Web3EthereumRequestMethods method,
    Web3EthereumChainIdnetifier? network,
  }) {
    final data = params.getParams(length: 2, method: method);
    int addressIndex = 1;
    int messageIndex = 0;
    if (method == Web3EthereumRequestMethods.ethSign) {
      addressIndex = 0;
      messageIndex = 1;
    }
    final String message = BytesUtils.toHexString(params.objectAsBytes(
        object: data[messageIndex],
        name: "message",
        encoding: [StringEncoding.hex, StringEncoding.utf8],
        error: Web3RequestExceptionConst.invalidBytesArgrumentElement(
            index: messageIndex, encoding: [StringEncoding.hex, StringEncoding.utf8])));
    final account = Web3ValidatorUtils.parseParams2(() {
      final address = tryParseStateAddress(
          addr: data.elementAtOrNull(addressIndex),
          params: params,
          state: state,
          network: network);
      if (address == null) return null;
      return state.findAddressOrDefault(
          address: address.address, network: network ?? address.chain);
    },
        error: Web3RequestExceptionConst.invalidAddressArgrument(
            key: 'address', network: networkType.name));
    return Web3EthreumPersonalSign(message: message, account: account, method: method);
  }

  Web3EthreumTypdedData toSignTypedDataRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3EthereumRequestMethods method,
      Web3EthereumChainIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      final versionNumber = int.tryParse(params.method[params.method.length - 1]);
      EIP712Version? version =
          versionNumber == null ? null : EIP712Version.fromVersion(versionNumber);
      final param = params.getParams(length: 2);
      ParsedNetworkStateAddress<ETHAddress, Web3EthereumChainIdnetifier>? address;
      Map<String, dynamic>? typedDataJson;
      for (int i = 0; i < 2; i++) {
        if (address == null) {
          address = tryParseStateAddress(
              addr: param.elementAt(i), params: params, state: state, network: network);
          if (address != null) continue;
        }
        typedDataJson = Web3ValidatorUtils.parseParams2(() {
          if (typedDataJson != null) return null;
          try {
            if (version == null) {
              final typedData = params.objectAsListOfMap(
                  object: param.elementAt(i),
                  name: "typedData",
                  error: Web3EthereumExceptionConst.invalidTypeData);
              return {"typedData": typedData};
            }
          } catch (_) {}
          final typedData = params.objectAsMap(
              object: param.elementAt(i),
              name: "typedData",
              error: Web3EthereumExceptionConst.invalidTypeData);
          return {"typedData": typedData};
        }, error: Web3EthereumExceptionConst.invalidTypeData);
      }
      return Web3EthreumTypdedData.fromJson(
          json: typedDataJson!,
          account: state.findAddressOrDefault(
              address: address!.address, network: network ?? address.chain),
          version: version);
    }, error: Web3EthereumExceptionConst.invalidTypeData);
  }

  Web3EthreumSendTransaction toTransactionRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3EthereumRequestMethods method,
      Web3EthereumChainIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      final txData = params.paramsAsMap();
      final account = Web3ValidatorUtils.parseParams2(() {
        if (txData["from"] == null) {
          return state.findAddressOrDefault(network: network);
        }
        final address = tryParseStateAddress(
            addr: txData["from"], params: params, state: state, network: network);
        if (address == null) return null;
        return state.findAddressOrDefault(
            address: address.address, network: network ?? address.chain);
      },
          error: Web3RequestExceptionConst.invalidAddressArgrument(
              key: "from", network: networkType.name));
      final chainId = BigintUtils.tryParse(txData['chainId']);
      if (chainId != null) {
        final chain = state.chains.firstWhere((e) => e.chainId == chainId,
            orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
        if (chain.id != account.id) {
          throw Web3EthereumExceptionConst.mismatchAccountAndTransactionChainId;
        }
      }
      final maxFeePerGas = BigintUtils.tryParse(txData['maxFeePerGas']);
      final gasPrice = BigintUtils.tryParse(txData['gasPrice']);
      final value = BigintUtils.tryParse(txData['value']);
      final maxPriorityFeePerGas = BigintUtils.tryParse(txData['maxPriorityFeePerGas']);
      final gas = IntUtils.tryParse(txData['gasLimit']);
      if (txData['value'] != null && value == null) {
        throw Web3EthereumExceptionConst.missingValue;
      }
      final type = IntUtils.tryParse(txData['type']);
      final to = MethodUtils.fallbackOnException(() => ETHAddress(txData['to']),
          logOnDebug: false);
      if (txData['to'] != null && to == null) {
        throw Web3RequestExceptionConst.invalidAddressArgrument(
            key: "to", network: networkType.name);
      }
      List<int>? data;
      if (txData['data'] != null) {
        data = BytesUtils.tryFromHexString(txData['data']);
        if (data == null) {
          throw Web3RequestExceptionConst.invalidBytesOrHexArgrument2("data");
        }
      }
      List<Web3EthreumTransactionAccessList> accessList = [];
      if (txData['accessList'] != null) {
        Web3ValidatorUtils.parseParams2(() {
          final accessListData =
              (txData['accessList'] as List).map((e) => Map<String, dynamic>.from(e));
          for (final i in accessListData) {
            final address = ETHAddress(i['address']);
            final dartStorageKeys = List<String>.from(i["storageKeys"]);
            if (dartStorageKeys.isEmpty) {
              return null;
            }
            List<List<int>> storageKeys = [];
            for (final i in dartStorageKeys) {
              final storageKey = BytesUtils.fromHexString(i);
              storageKeys.add(storageKey);
            }
            accessList.add(Web3EthreumTransactionAccessList(
                address: address, storageKeys: storageKeys));
          }
        }, error: Web3EthereumExceptionConst.invalidAccessListParams);
      }

      final transaction = Web3EthreumSendTransaction(
          account: account,
          chainId: chainId,
          gas: gas,
          maxPriorityFeePerGas: maxPriorityFeePerGas,
          maxFeePerGas: maxFeePerGas,
          gasPrice: gasPrice,
          value: value ?? BigInt.zero,
          to: to,
          transactionType: type,
          data: data,
          accessList: accessList.isEmpty ? null : accessList);
      if (transaction.transactionType == ETHTransactionType.eip1559 &&
          !state.defaultChain!.supportEIP1559) {
        throw Web3EthereumExceptionConst.eip1559NotSupported;
      }
      return transaction;
    }, error: Web3RequestExceptionConst.invalidTransaction);
  }

  Future<Web3MessageCore> toAddNewChainRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3EthereumRequestMethods method,
      Web3EthereumChainIdnetifier? network}) async {
    final param =
        params.paramsAsMap(keys: ["chainId", "chainName", "nativeCurrency", "rpcUrls"]);
    final BigInt chainId = Web3ValidatorUtils.parseBigInt(
        key: "chainId", method: method, json: param, sign: false);
    final network = state.chains.firstWhereOrNull((e) => e.chainId == chainId);
    if (network != null) {
      return createResponse(chainId.toRadix16);
    }
    final String chainName =
        Web3ValidatorUtils.parseString(key: "chainName", method: method, json: param);
    return Web3ValidatorUtils.parseParams2(() {
      final nativeCurrency = Web3ValidatorUtils.parseMap(
          key: "nativeCurrency",
          method: method,
          json: param,
          requiredKeys: ["name", "symbol"]);

      final rpcUrls = Web3ValidatorUtils.parseList<List<String>, String>(
          key: "rpcUrls", method: method, json: param);
      final validUrls =
          rpcUrls.where((e) => ServicePorotocolUtils.isHttoOrWebsocket(e)).toList();
      if (validUrls.isEmpty) {
        throw Web3EthereumExceptionConst.missingRpcUrls;
      }
      List<String>? blockExplorerUrls =
          Web3ValidatorUtils.parseList<List<String>?, String>(
              json: param, key: "blockExplorerUrls", method: method, allowEmpty: true);
      List<String>? iconUrls = Web3ValidatorUtils.parseList<List<String>?, String>(
          json: param, key: "iconUrls", method: method, allowEmpty: true);
      return Web3EthereumAddNewChain(
          newChainId: chainId,
          chainName: chainName,
          name: Web3ValidatorUtils.parseString(
              key: "name", method: method, json: nativeCurrency),
          symbol: Web3ValidatorUtils.parseString(
              key: "symbol", method: method, json: nativeCurrency),
          decimals: ETHConst.decimals,
          rpcUrls: rpcUrls,
          blockExplorerUrls: blockExplorerUrls,
          iconUrls: iconUrls);
    });
  }

  Future<Web3MessageCore> toSwitchNetworkRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3EthereumRequestMethods method,
      Web3EthereumChainIdnetifier? network}) async {
    final param = params.paramsAsMap(keys: ["chainId"], method: method);
    final BigInt chainId = Web3ValidatorUtils.parseBigInt(
        key: 'chainId', method: method, json: param, sign: false);
    if (chainId == state.defaultChain?.chainId) {
      return createResponse(chainId.toRadix16);
    }
    final chain = state.chains.firstWhere((e) => e.chainId == chainId,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
    return connetInternal(networks: [chain.id]);
  }

  @override
  Future<Web3MessageCore> request(REQUEST message,
      {Web3EthereumChainIdnetifier? network}) async {
    final method = Web3EthereumRequestMethods.fromName(message.method);
    final state = await getState();
    if (method == null) {
      throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    switch (method) {
      case Web3EthereumRequestMethods.switchEthereumChain:
        return toSwitchNetworkRequest(
            params: message, state: state, method: method, network: network);
      case Web3EthereumRequestMethods.requestAccounts:
        return onConnect_(message);
      case Web3EthereumRequestMethods.addEthereumChain:
        return toAddNewChainRequest(
            params: message, state: state, network: network, method: method);
      case Web3EthereumRequestMethods.sendTransaction:
        return toTransactionRequest(
            params: message, state: state, network: network, method: method);
      case Web3EthereumRequestMethods.persoalSign:
      case Web3EthereumRequestMethods.ethSign:
        return toPersonalSignRequest(
            params: message, state: state, network: network, method: method);
      case Web3EthereumRequestMethods.typedData:
        return toSignTypedDataRequest(
            params: message, state: state, network: network, method: method);
      default:
        throw Web3RequestExceptionConst.methodDoesNotSupport;
    }
  }
}
