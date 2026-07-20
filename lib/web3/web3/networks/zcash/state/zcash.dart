import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/constant/constants/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/params/models/sign_message.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/state/core/network.dart';
import 'package:on_chain_wallet/web3/web3/state/core/types.dart';
import 'package:on_chain_wallet/web3/web3/utils/web3_validator_utils.dart';
import 'package:zcash_dart/zcash.dart';

mixin ZcashWeb3StateHandler<
        ADDRESS,
        STATEADDRESS extends Web3StateAddress<ZcashAddress, Web3ZcashChainAccount, ADDRESS,
            Web3ZcashChainIdnetifier>,
        STATEACCOUNT extends Web3StateAccount<ZcashAddress, Web3ZcashChainAccount, ADDRESS,
            Web3ZcashChainIdnetifier, STATEADDRESS>,
        RESPONSE,
        REQUEST extends Web3ClientRequest,
        EVENT>
    on Web3StateHandler<ZcashAddress, Web3ZcashChainAccount, ADDRESS,
        Web3ZcashChainIdnetifier, STATEADDRESS, STATEACCOUNT, RESPONSE, REQUEST, EVENT> {
  @override
  ZcashAddress toAddress(String v, {Web3ZcashChainIdnetifier? network}) {
    try {
      final address = ZcashAddress(v);
      if (network != null && network.network != address.network) {
        throw Web3RequestExceptionConst.invalidAddress(
            key: v, network: network.network.name);
      }
      return address;
    } catch (_) {}
    throw Web3RequestExceptionConst.invalidAddress(key: v, network: networkType.name);
  }

  @override
  NetworkType get networkType => NetworkType.zcash;
  @override
  List<Web3ZcashRequestMethods> get methods => Web3ZcashRequestMethods.values;
  Web3ZcashSendTransaction toSignTransactionRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ZcashRequestMethods method,
      Web3ZcashChainIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      final param = params.paramsAsMap(keys: ["recipients"], method: method);
      final accounts = Web3ValidatorUtils.parseParams2(() {
        final accountsJson = param["account"] ?? param["accounts"];
        if (accountsJson == null) return null;
        if (accountsJson is List) {
          final accounts = accountsJson
              .map((e) => tryParseStateAddress(
                  addr: e, params: params, state: state, network: network))
              .toList()
              .cast<ParsedNetworkStateAddress<ZcashAddress, Web3ZcashChainIdnetifier>>();

          if (accounts.isEmpty) return null;
          return accounts
              .map((e) => state.findAddressOrDefault(
                  address: e.address, network: network ?? e.chain))
              .toList();
        }
        final account = tryParseStateAddress(
            addr: accountsJson, params: params, state: state, network: network);
        if (account == null) return null;
        return [
          state.findAddressOrDefault(
              address: account.address, network: network ?? account.chain)
        ];
      },
          error: Web3RequestExceptionConst.invalidAccountOrAccountParamets(
              networkType.name));

      List<Web3ZcashTransactionParams> payments = [];
      network ??=
          state.chains.firstWhere((e) => e.network == accounts.first.address.network);
      final recipients =
          params.objectAsListOfMap(object: param["recipients"], name: "recipients");
      for (final i in recipients) {
        final addr = Web3ValidatorUtils.parseParams2(() {
          return tryParseStateAddress(
              addr: i["address"], params: params, state: state, network: network);
        },
            error: Web3RequestExceptionConst.invalidAddressArgrument(
                key: "address", network: networkType.name));
        final BigInt amount = Web3ValidatorUtils.parseBigInt(
            key: "amount", method: method, json: i, sign: false);
        final addrProtocol = addr.address.supportedProtocols;
        ZcashProtocol protocol = Web3ValidatorUtils.parseParams2(() {
          final String? protocol =
              Web3ValidatorUtils.parseString(key: "protocol", method: method, json: i);
          if (protocol == null) {
            if (addrProtocol.length == 1) return addrProtocol.first;
            throw Web3ZcashExceptionConstant.misingRecipientProtocol;
          }
          try {
            return ZcashProtocol.fromName(protocol);
          } catch (_) {
            throw Web3ZcashExceptionConstant.unsupportedRecipientAddressProtocol(
                protocol);
          }
        }, error: Web3ZcashExceptionConstant.misingRecipientProtocol);
        if (!addr.address.supportedProtocols.contains(protocol)) {
          throw Web3ZcashExceptionConstant.invalidReceiptProtocol(protocol.name);
        }
        final List<int>? memo = Web3ValidatorUtils.parseHex(
            key: "memo", method: method, json: i, required0x: false, strip0x: true);

        payments.add(Web3ZcashTransactionParams(
            address: addr.address, amount: amount, protocol: protocol, memo: memo));
      }
      if (payments.isEmpty) {
        throw Web3ZcashExceptionConstant.noRecipients;
      }
      final addresses = payments.map((e) => e.destination.network).toSet().length;
      if (addresses != 1) {
        throw Web3ZcashExceptionConstant.mismatchPaymentAddresses;
      }
      final List<Script> memos = Web3ValidatorUtils.parseParams2(() {
        final memos = param["memos"];
        if (memos == null) return [];
        if (memos is! List) return null;
        final scriptsBytes = memos
            .map((e) => params.objectAsBytes(
                  object: e,
                  error: Web3ZcashExceptionConstant.invalidMemos,
                  name: "memos",
                  encoding: [StringEncoding.hex],
                ))
            .toList();
        final toScripts = scriptsBytes.map((e) => Script.deserialize(bytes: e)).toList();
        return toScripts;
      }, error: Web3ZcashExceptionConstant.invalidMemos);

      final String? privacyName =
          Web3ValidatorUtils.parseString(key: "privacy", method: method, json: param);
      Web3ZcashTransferPrivacy? privacy = Web3ZcashTransferPrivacy.fromName(privacyName);
      if (privacy == null) {
        throw Web3ZcashExceptionConstant.invalidPrivacy(privacyName ?? '');
      }
      return Web3ZcashSendTransaction(
          destintions: payments,
          accounts: accounts,
          privacy: privacy,
          transparentMemos: memos);
    }, error: Web3ZcashExceptionConstant.invalidTransaction);
  }

  Web3ZcashSignMessage toSignMessageRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ZcashRequestMethods method,
      Web3ZcashChainIdnetifier? network}) {
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
      final toTransparentAddress = account.address.tryToTransparentAddreses();
      if (toTransparentAddress == null || toTransparentAddress.type.isP2sh) {
        throw Web3ZcashExceptionConstant.unsuportedSigningMessageAccount(
            account.addressStr);
      }

      final message = params.objectAsBytes(
          object: data["message"],
          name: "message",
          encoding: [StringEncoding.hex, StringEncoding.utf8]);
      return Web3ZcashSignMessage(
          accessAccount: account,
          challeng: BytesUtils.toHexString(message),
          content: StringUtils.tryDecode(message));
    });
  }

  @override
  Future<Web3MessageCore> request(REQUEST message,
      {Web3ZcashChainIdnetifier? network}) async {
    final method = Web3ZcashRequestMethods.fromName(message.method);
    final state = await getState();
    if (method == null) {
      throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    switch (method) {
      case Web3ZcashRequestMethods.requestAccounts:
        return onConnect_(message);
      case Web3ZcashRequestMethods.signMessage:
        return toSignMessageRequest(
            params: message, state: state, method: method, network: network);
      case Web3ZcashRequestMethods.sendTransaction:
        return toSignTransactionRequest(
            params: message, state: state, method: method, network: network);
      default:
        throw Web3RequestExceptionConst.methodDoesNotSupport;
    }
  }
}
