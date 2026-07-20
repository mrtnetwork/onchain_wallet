import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain/tron/src/address/tron_address.dart';
import 'package:on_chain/tron/src/models/contract/transaction/transaction.dart';
import 'package:on_chain/tron/src/models/contract/transaction/transaction_raw.dart';
// import 'package:on_chain/tron/src/models/contract/transaction/transaction.dart';
// import 'package:on_chain/tron/src/models/contract/transaction/transaction_raw.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message.dart';
import 'package:on_chain_wallet/web3/web3/networks/tron/tron.dart';
import 'package:on_chain_wallet/web3/web3/state/core/network.dart';
import 'package:on_chain_wallet/web3/web3/utils/web3_validator_utils.dart';

mixin TronWeb3StateHandler<
        ADDRESS,
        STATEADDRESS extends Web3StateAddress<TronAddress, Web3TronChainAccount, ADDRESS,
            Web3TronChainIdnetifier>,
        STATEACCOUNT extends Web3StateAccount<TronAddress, Web3TronChainAccount, ADDRESS,
            Web3TronChainIdnetifier, STATEADDRESS>,
        RESPONSE,
        REQUEST extends Web3ClientRequest,
        EVENT>
    on Web3StateHandler<TronAddress, Web3TronChainAccount, ADDRESS,
        Web3TronChainIdnetifier, STATEADDRESS, STATEACCOUNT, RESPONSE, REQUEST, EVENT> {
  @override
  TronAddress toAddress(String v, {Web3TronChainIdnetifier? network}) {
    try {
      return TronAddress(v);
    } catch (_) {}
    throw Web3RequestExceptionConst.invalidAddress(key: v, network: networkType.name);
  }

  @override
  NetworkType get networkType => NetworkType.tron;
  @override
  List<Web3TronRequestMethods> get methods => Web3TronRequestMethods.values;
  Web3TronSignMessageV2 toSignMessageRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3TronRequestMethods method,
      Web3TronChainIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      if (params.source.isInjected) {
        final msg = params.tryElementAsString(0);
        if (msg != null) {
          final message = params.objectAsBytes(
              object: msg,
              name: 'message',
              encoding: [StringEncoding.hex, StringEncoding.utf8]);
          return Web3TronSignMessageV2(
              accessAccount: state.defaultNetworkChainAccountOrThrow,
              challeng: BytesUtils.toHexString(message),
              content: StringUtils.tryDecode(message));
        }
      }
      // params.tr(0);
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
      if (account.derivationIndex.isMultiSig) {
        throw Web3RequestExceptionConst.unsuportedSigningMessageAccount(
            account.addressStr);
      }
      final message = StringUtils.toBytes(data["message"]);
      return Web3TronSignMessageV2(
          accessAccount: account,
          challeng: BytesUtils.toHexString(message),
          content: StringUtils.tryDecode(message));
    });
  }

  Web3TronSignTransaction toSignTransactionRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3TronRequestMethods method,
      Web3TronChainIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      final data = params.paramsAsMap(method: method);
      final account = Web3ValidatorUtils.parseParams2(() {
        if (params.source.isInjected &&
            !data.containsKey("address") &&
            !data.containsKey("account")) {
          return state.defaultNetworkChainAccountOrThrow;
        }
        final account = tryParseStateAddress(
            addr: data["address"] ?? data["account"],
            params: params,
            state: state,
            network: network);
        if (account == null) return null;
        return state.findAddressOrDefault(
          address: account.address,
          network: network ?? account.chain,
        );
      },
          error: Web3RequestExceptionConst.invalidAddressArgrument(
              key: "address", network: networkType.name));
      Map<String, dynamic> txObject;
      if (data.containsKey("raw_data_hex")) {
        txObject = data;
      } else {
        txObject = Web3ValidatorUtils.parseMap(
            key: "transaction",
            method: method,
            json: data,
            requiredKeys: ["txID", "raw_data_hex"]);
      }
      final List<int> txBytes = Web3ValidatorUtils.parseHex(
          key: "raw_data_hex", method: method, json: txObject, required0x: false);
      final String txId = Web3ValidatorUtils.parseHex(
          key: "txID", method: method, json: txObject, required0x: false);

      final transaction =
          Transaction(rawData: TransactionRaw.deserialize(txBytes), signature: []);
      if (transaction.rawData.txID != txId) {
        return null;
      }

      return Web3TronSignTransaction(
          transaction: transaction.toBuffer(), accessAccount: account);
    }, error: Web3RequestExceptionConst.invalidTransaction);
  }

  Future<Web3MessageCore> toSwitchTronChainRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3TronRequestMethods method,
      Web3TronChainIdnetifier? network}) async {
    return Web3ValidatorUtils.parseParams2(() {
      final data = params.paramsAsMap(keys: ["chainId"], method: method);
      final chainId =
          Web3ValidatorUtils.parseInt<int>(key: "chainId", method: method, json: data);
      final chain = state.chains.firstWhere((e) => e.chainId == chainId,
          orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
      if (chain == state.defaultChain) return createResponse();
      return connetInternal(networks: [chain.id]);
    });
  }

  @override
  Future<Web3MessageCore> request(REQUEST message,
      {Web3TronChainIdnetifier? network}) async {
    final method = Web3TronRequestMethods.fromName(message.method);
    final state = await getState();
    if (method == null) {
      throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    switch (method) {
      case Web3TronRequestMethods.requestAccounts:
        return onConnect_(message);
      case Web3TronRequestMethods.signMessageV2:
        return toSignMessageRequest(params: message, state: state, method: method);
      case Web3TronRequestMethods.signTransaction:
        return toSignTransactionRequest(params: message, state: state, method: method);
      default:
        throw Web3RequestExceptionConst.methodDoesNotSupport;
    }
  }
}
