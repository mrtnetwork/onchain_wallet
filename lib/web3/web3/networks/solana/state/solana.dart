import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain/ethereum/src/eip_4361/exception/exception.dart';
import 'package:on_chain/solana/src/address/sol_address.dart';
import 'package:on_chain/solana/src/transaction/transaction.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/types/account.dart';
import 'package:on_chain_wallet/web3/web3/state/core/network.dart';
import 'package:on_chain_wallet/web3/web3/networks/solana/solana.dart';
import 'package:on_chain_wallet/web3/web3/utils/web3_validator_utils.dart';

mixin SolanaWeb3StateHandler<
        ADDRESS,
        STATEADDRESS extends Web3StateAddress<SolAddress, Web3SolanaChainAccount, ADDRESS,
            Web3ChainDefaultIdnetifier>,
        STATEACCOUNT extends Web3StateAccount<SolAddress, Web3SolanaChainAccount, ADDRESS,
            Web3ChainDefaultIdnetifier, STATEADDRESS>,
        RESPONSE,
        REQUEST extends Web3ClientRequest,
        EVENT>
    on Web3StateHandler<
        SolAddress,
        Web3SolanaChainAccount,
        ADDRESS,
        Web3ChainDefaultIdnetifier,
        STATEADDRESS,
        STATEACCOUNT,
        RESPONSE,
        REQUEST,
        EVENT> {
  @override
  SolAddress toAddress(String v, {Web3ChainDefaultIdnetifier? network}) {
    try {
      return SolAddress(v);
    } catch (_) {}
    throw Web3RequestExceptionConst.invalidAddress(key: v, network: networkType.name);
  }

  @override
  NetworkType get networkType => NetworkType.solana;
  @override
  List<Web3SolanaRequestMethods> get methods => Web3SolanaRequestMethods.values;
  Web3SolanaSendTransactionData _parseTransactionObject(
      {required Map<String, dynamic> data,
      required STATEACCOUNT state,
      required REQUEST params,
      required Web3SolanaRequestMethods method,
      Web3ChainDefaultIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      final transaction = Web3ValidatorUtils.parseParams2(() {
        final transaction = params.objectAsBytes(
            object: data["transaction"],
            name: "transaction",
            encoding: [StringEncoding.hex, StringEncoding.base64]);
        return SolanaTransaction.deserialize(transaction);
      }, error: Web3RequestExceptionConst.invalidTransaction);
      Web3SolanaChainAccount? account;
      final hasAccount = data["account"] ?? data["address"];

      if (hasAccount != null) {
        account = Web3ValidatorUtils.parseParams2(() {
          final account = tryParseStateAddress(
              addr: hasAccount, params: params, state: state, network: network);
          if (account == null) return null;
          return state.findAddressOrDefault(
              address: account.address, network: network ?? account.chain);
        },
            error: Web3RequestExceptionConst.invalidAddressArgrument(
                key: "address", network: networkType.name));
      } else {
        for (final i in transaction.signers) {
          account = state.findAddressOrNull(address: i, network: network);
          if (account != null) {
            break;
          }
        }
      }
      if (account == null) throw Web3RequestExceptionConst.missingPermission;
      Web3SolanaSendTransactionOptions? options;
      if (data["options"] != null) {
        options = Web3SolanaSendTransactionOptions.fromJson(
            json: data["options"], method: method);
      }
      return Web3SolanaSendTransactionData(
          account: account, messageByte: transaction.serialize(), sendConfig: options);
    }, error: Web3RequestExceptionConst.invalidTransaction);
  }

  Web3SolanaSendTransaction toSignTransactionsRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3SolanaRequestMethods method,
      Web3ChainDefaultIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      const List<String> keys = [];
      final data = params.getParams(method: method);
      final List<Web3SolanaSendTransactionData> transactions = [];
      SolanaSignAndSendAllTransactionMode? mode;
      for (int i = 0; i < data.length; i++) {
        Map<String, dynamic> elem = params.elementAsMap(i, keys: keys, method: method);
        bool isModeOption =
            method == Web3SolanaRequestMethods.signAndSendAllTransactions &&
                i == data.length - 1 &&
                elem["mode"] != null &&
                elem["transaction"] == null;
        if (isModeOption) {
          mode = SolanaSignAndSendAllTransactionMode.fromName(
              Web3ValidatorUtils.parseString(key: "mode", method: method, json: elem));
          break;
        }
        elem = params.elementAsMap(i, keys: ["transaction"], method: method);
        final transaction = _parseTransactionObject(
            data: elem, state: state, network: network, params: params, method: method);
        transactions.add(transaction);
        //
      }
      return Web3SolanaSendTransaction(
          messages: transactions, method: method, mode: mode);
    });
  }

  Web3SolanaSignMessageParams parseSignMessageObject(
      {required Map<String, dynamic> data,
      required STATEACCOUNT state,
      required REQUEST params,
      Web3ChainDefaultIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      final account = Web3ValidatorUtils.parseParams2(() {
        final addr = data['pubkey'] ?? data['account'] ?? data['address'];
        final address = tryParseStateAddress(
            addr: addr, params: params, state: state, network: network);
        if (address == null) return null;
        return state.findAddressOrDefault(
            address: address.address, network: network ?? address.chain);
      },
          error: Web3RequestExceptionConst.invalidAddressArgrument(
              key: 'pubkey', network: networkType.name));
      final message =
          params.objectAsBytes(object: data['message'], name: "message", encoding: [
        StringEncoding.hex,
        StringEncoding.base58,
        StringEncoding.utf8,
      ]);
      return Web3SolanaSignMessageParams(
          data: BytesUtils.toHexString(message),
          account: account,
          content: StringUtils.tryDecode(message));
    });
  }

  Web3SolanaSignMessage toSignMessageRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3SolanaRequestMethods method,
      Web3ChainDefaultIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      final List<Web3SolanaSignMessageParams> messages = [];
      final data = params.getParams();
      for (int i = 0; i < data.length; i++) {
        final elem = params.elementAsMap(i, method: method);
        final message = parseSignMessageObject(
            data: elem, state: state, network: network, params: params);
        messages.add(message);
      }
      return Web3SolanaSignMessage(messages: messages, method: method);
    });
  }

  Web3SolanaSignInParams parseSignInRequest(
      {required Map<String, dynamic> data,
      required REQUEST params,
      required STATEACCOUNT state,
      required Web3SolanaRequestMethods method,
      Web3ChainDefaultIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      Web3SolanaChainAccount account;
      if (data["address"] != null) {
        account = Web3ValidatorUtils.parseParams2(() {
          final address = tryParseStateAddress(
              addr: data["address"], params: params, state: state, network: network);
          if (address == null) return null;
          return state.findAddressOrDefault(
              address: address.address, network: network ?? address.chain);
        }, error: Web3RequestExceptionConst.missingPermission);
      } else {
        account = state.findAddressOrDefault(network: network);
      }
      try {
        return Web3SolanaSignInParams.fromJson(json: data, account: account);
      } on EIP4631Exception catch (e) {
        throw Web3RequestExceptionConst.invalidParameters(e.message);
      }
    }, error: Web3SolanaExceptionConstant.invalidSignInParams);
  }

  Future<Web3SolanaSignMessage> toSignInRequest(
      {required REQUEST params,
      STATEACCOUNT? state,
      required Web3SolanaRequestMethods method,
      Web3ChainDefaultIdnetifier? network}) async {
    state ??= await getState();
    return Web3ValidatorUtils.parseParams2(() {
      final List<Web3SolanaSignInParams> messages = [];
      final data = params.getParams();
      for (int i = 0; i < data.length; i++) {
        final elem = params.elementAsMap(i, method: method);
        final message = parseSignInRequest(
            data: elem, state: state!, network: network, method: method, params: params);
        messages.add(message);
      }
      return Web3SolanaSignMessage(messages: messages, method: method);
    }, error: Web3SolanaExceptionConstant.invalidSignInParams);
  }

  @override
  Future<Web3MessageCore> request(REQUEST message,
      {Web3ChainDefaultIdnetifier? network}) async {
    final method = Web3SolanaRequestMethods.fromName(message.method);
    final state = await getState();
    if (method == null) {
      throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    switch (method) {
      case Web3SolanaRequestMethods.requestAccounts:
        return onConnect_(message);
      case Web3SolanaRequestMethods.signMessage:
        return toSignMessageRequest(
            params: message, state: state, network: network, method: method);
      case Web3SolanaRequestMethods.signIn:
        return toSignInRequest(
            params: message, state: state, network: network, method: method);
      case Web3SolanaRequestMethods.signTransaction:
      case Web3SolanaRequestMethods.sendTransaction:
      case Web3SolanaRequestMethods.signAndSendAllTransactions:
      case Web3SolanaRequestMethods.signAllTransactions:
        return toSignTransactionsRequest(
            params: message, state: state, network: network, method: method);
      default:
        throw Web3RequestExceptionConst.methodDoesNotSupport;
    }
  }
}
