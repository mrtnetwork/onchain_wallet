import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/types/account.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/constant/constant.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/params/models/sign_message.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/state/core/network.dart';
import 'package:on_chain_wallet/web3/web3/utils/web3_validator_utils.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

mixin XRPWeb3StateHandler<
        ADDRESS,
        STATEADDRESS extends Web3StateAddress<XRPBaseAddress, Web3XRPChainAccount, ADDRESS,
            Web3ChainDefaultIdnetifier>,
        STATEACCOUNT extends Web3StateAccount<XRPBaseAddress, Web3XRPChainAccount, ADDRESS,
            Web3ChainDefaultIdnetifier, STATEADDRESS>,
        RESPONSE,
        REQUEST extends Web3ClientRequest,
        EVENT>
    on Web3StateHandler<
        XRPBaseAddress,
        Web3XRPChainAccount,
        ADDRESS,
        Web3ChainDefaultIdnetifier,
        STATEADDRESS,
        STATEACCOUNT,
        RESPONSE,
        REQUEST,
        EVENT> {
  @override
  XRPBaseAddress toAddress(String v, {Web3ChainDefaultIdnetifier? network}) {
    try {
      return XRPBaseAddress(v);
    } catch (_) {}
    throw Web3RequestExceptionConst.invalidAddress(key: v, network: networkType.name);
  }

  @override
  NetworkType get networkType => NetworkType.xrpl;
  @override
  List<Web3XRPRequestMethods> get methods => Web3XRPRequestMethods.values;
  Web3XRPSendTransaction toSignTransactionRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3XRPRequestMethods method,
      Web3ChainDefaultIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      final data = params.paramsAsMap(method: method);
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

      final txBlob = Web3ValidatorUtils.parseParams2(() {
        try {
          if (data.containsKey("transactionBlob")) {
            final blob = params.objectAsBytes(
                object: data, name: 'transactionBlob', encoding: [StringEncoding.hex]);
            return SubmittableTransaction.fromBytes(blob);
          } else {
            final blob = params.objectAsMap(object: data, name: 'transaction');
            return SubmittableTransaction.fromXrpl(blob["transaction"]);
          }
        } catch (_) {}
        return null;
      });
      switch (txBlob.transactionType) {
        case SubmittableTransactionType.batch:
        case SubmittableTransactionType.delegateSet:
        case SubmittableTransactionType.credentialAccept:
        case SubmittableTransactionType.credentialCreate:
        case SubmittableTransactionType.credentialDelete:
          throw Web3XRPExceptionConstant.unSuportedTransactionType(
              txBlob.transactionType);
        default:
      }
      if (method == Web3XRPRequestMethods.sendTransaction &&
          txBlob.account != account.address.classicAddress) {
        throw Web3XRPExceptionConstant.mismatchTransactionAccount;
      }
      try {
        return Web3XRPSendTransaction(
            method: method, txBlob: txBlob.toTransactionBlobBytes(), account: account);
      } on XRPLTransactionException catch (e) {
        throw Web3RequestExceptionConst.invalidParameters(e.message);
      }
    }, error: Web3XRPExceptionConstant.invalidTransaction);
  }

  Web3XRPSignMessage toSignMessageRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3XRPRequestMethods method,
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
      if (account.publicKey == null) {
        throw Web3XRPExceptionConstant.accountDoesNotSupportSignMessage;
      }
      final message = params.objectAsBytes(
          object: data["message"],
          name: "message",
          encoding: [StringEncoding.hex, StringEncoding.base64, StringEncoding.utf8]);
      return Web3XRPSignMessage(
          accessAccount: account,
          challeng: BytesUtils.toHexString(message),
          content: StringUtils.tryDecode(message));
    });
  }

  @override
  Future<Web3MessageCore> request(REQUEST message,
      {Web3ChainDefaultIdnetifier? network}) async {
    final method = Web3XRPRequestMethods.fromName(message.method);
    final state = await getState();
    if (method == null) {
      throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    switch (method) {
      case Web3XRPRequestMethods.signMessage:
        return toSignMessageRequest(
            params: message, state: state, method: method, network: network);
      case Web3XRPRequestMethods.signTransaction:
      case Web3XRPRequestMethods.sendTransaction:
        return toSignTransactionRequest(
            params: message, state: state, method: method, network: network);
      default:
        throw Web3RequestExceptionConst.methodDoesNotSupport;
    }
  }
}
