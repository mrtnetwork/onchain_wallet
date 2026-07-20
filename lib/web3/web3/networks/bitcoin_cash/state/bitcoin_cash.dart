import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/models/models/wallet_response.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/params/models/send_transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin_cash/constant/constants/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin_cash/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin_cash/params/models/send_transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin_cash/params/models/sign_message.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin_cash/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin_cash/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain_wallet/web3/web3/utils/web3_validator_utils.dart';

mixin BitcoinCashWeb3StateHandler<
        ADDRESS,
        STATEADDRESS extends Web3StateAddress<BitcoinNetworkAddress,
            Web3BitcoinCashChainAccount, ADDRESS, Web3BitcoinCashChainIdnetifier>,
        STATEACCOUNT extends Web3StateAccount<
            BitcoinNetworkAddress,
            Web3BitcoinCashChainAccount,
            ADDRESS,
            Web3BitcoinCashChainIdnetifier,
            STATEADDRESS>,
        RESPONSE,
        REQUEST extends Web3ClientRequest,
        EVENT>
    on Web3StateHandler<
        BitcoinNetworkAddress,
        Web3BitcoinCashChainAccount,
        ADDRESS,
        Web3BitcoinCashChainIdnetifier,
        STATEADDRESS,
        STATEACCOUNT,
        RESPONSE,
        REQUEST,
        EVENT> {
  @override
  BitcoinCashAddress toAddress(String v,
      {Web3BitcoinCashChainIdnetifier? network, STATEACCOUNT? state}) {
    try {
      if (network != null) {
        return BitcoinNetworkAddress.parse(address: v, network: network.network)
            .cast<BitcoinCashAddress>();
      }

      final networks = state?.chains.map((e) => e.network).toSet() ??
          {BitcoinCashNetwork.mainnet, BitcoinCashNetwork.testnet};
      for (final i in networks) {
        try {
          return BitcoinNetworkAddress.parse(address: v, network: i)
              .cast<BitcoinCashAddress>();
        } catch (_) {}
      }
    } catch (_) {}
    throw Web3RequestExceptionConst.invalidAddress(key: v, network: networkType.name);
  }

  @override
  NetworkType get networkType => NetworkType.bitcoinCash;

  @override
  List<Web3BitcoinCashRequestMethods> get methods => Web3BitcoinCashRequestMethods.values;

  Web3BitcoinCashSignTransaction toSignPsbtRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3BitcoinCashRequestMethods method,
      Web3BitcoinCashChainIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      const List<String> keys = ["psbt"];
      final param = params.paramsAsMap(keys: keys, method: method);
      final accounts = Web3ValidatorUtils.parseParams2(() {
        final accountsJson = param["account"] ?? param["accounts"];
        if (accountsJson == null) return null;
        if (accountsJson is List) {
          final accounts = accountsJson
              .map((e) => tryParseStateAddress(
                  addr: e, params: params, state: state, network: network))
              .cast<
                  ParsedNetworkStateAddress<BitcoinCashAddress,
                      Web3BitcoinCashChainIdnetifier>>();
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
      }, error: Web3BitcoinCashExceptionConstant.invalidPSBT);

      final psbt = Web3ValidatorUtils.parseParams2(
          () => Psbt.deserialize(params.objectAsBytes(
              object: param["psbt"], name: "psbt", encoding: [StringEncoding.base64])),
          error: Web3BitcoinCashExceptionConstant.invalidPSBT);
      final inputs = psbt.input.length;
      final output = psbt.output.length;
      if (inputs == 0 || output == 0) {
        throw Web3BitcoinCashExceptionConstant.invalidPSBT;
      }
      final builder = PsbtBuilder.fromPsbt(psbt);
      bool hasAccount = false;
      for (int i = 0; i < inputs; i++) {
        final psbtInput = builder.psbtInput(i);
        hasAccount |=
            accounts.any((e) => e.address.toScriptPubKey() == psbtInput.scriptPubKey);
      }
      if (!hasAccount) {
        throw Web3BitcoinCashExceptionConstant.noRelatedInput;
      }
      return Web3BitcoinCashSignTransaction(accounts: accounts, psbt: psbt);
    });
  }

  Web3BitcoinCashSendTransaction parseTransferObject(
      {required REQUEST params,
      required Map<String, dynamic> param,
      required STATEACCOUNT state,
      required Web3BitcoinCashRequestMethods method,
      Web3BitcoinCashChainIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      final accounts = Web3ValidatorUtils.parseParams2(() {
        final accountsJson = param["account"] ?? param["accounts"];
        if (accountsJson == null) return null;
        if (accountsJson is List) {
          final accounts = accountsJson
              .map((e) => tryParseStateAddress(
                  addr: e, params: params, state: state, network: network))
              .cast<
                  ParsedNetworkStateAddress<BitcoinNetworkAddress,
                      Web3BitcoinCashChainIdnetifier>>();
          if (accounts.isEmpty) return null;
          final wAccounts = accounts
              .map((e) => state.findAddressOrDefault(
                  address: e.address, network: network ?? e.chain))
              .toList();
          return wAccounts;
        }
        final account = tryParseStateAddress(
            addr: accountsJson, params: params, state: state, network: network);
        if (account == null) return null;
        return [
          state.findAddressOrDefault(
              address: account.address, network: network ?? account.chain)
        ];
      }, error: Web3BitcoinCashExceptionConstant.invalidTransferParams);
      final BitcoinNetworkAddress? recipientAddress = Web3ValidatorUtils.parseAddress(
          onParse: (e) {
            return BitcoinNetworkAddress.parse(
                address: e, network: accounts.first.baseNetwork);
          },
          key: "recipientAddress",
          method: method,
          json: param,
          network: network?.network.name ?? networkType.name);
      final Script? script = Web3ValidatorUtils.praseObject<Script?, String?>(
          onParse: (e) {
            final List<int>? scriptBytes = BytesUtils.tryFromHexString(e);
            final script = Script.deserialize(bytes: scriptBytes!);
            if (!BytesUtils.bytesEqual(scriptBytes, script.toBytes())) {
              throw Web3BitcoinCashExceptionConstant.parsingOutputScriptFailed(
                  script.toHex());
            }
            return script;
          },
          key: "script",
          method: method,
          json: param);
      if (script == null && recipientAddress == null) {
        throw Web3BitcoinCashExceptionConstant.invalidTransferOutput;
      }
      if (script != null && recipientAddress != null) {
        throw Web3BitcoinCashExceptionConstant.invalidTransferOutput;
      }
      Web3ValidatorUtils.parseString(key: "amount", method: method, json: param);
      final BigInt amount = Web3ValidatorUtils.parseBigInt(
          key: "amount",
          method: method,
          json: param,
          sign: false,
          error: Web3RequestExceptionConst.failedToParse("amount"));
      return Web3BitcoinCashSendTransaction(accounts: accounts, outputs: [
        Web3BitcoinSendTransactionOutput(
            value: amount,
            scriptPubKey: script ?? recipientAddress!.baseAddress.toScriptPubKey(),
            address: recipientAddress?.address)
      ]);
    });
  }

  Web3WalletResponseMessage toGetAccountAddressesRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3BitcoinCashRequestMethods method,
      Web3BitcoinCashChainIdnetifier? network}) {
    const List<String> keys = [];
    final param = params.paramsAsMap(keys: keys, method: method);
    final account = Web3ValidatorUtils.parseParams2(() {
      final addr = param['account'] ?? param['address'];
      final address = tryParseStateAddress(
          addr: addr, params: params, state: state, network: network);
      if (address == null) return null;
      return state.findAddressOrDefault(
          address: address.address, network: network ?? address.chain);
    },
        error: Web3RequestExceptionConst.invalidAddressArgrument(
            key: 'account', network: networkType.name));
    return createResponse([
      {
        "address": account.addressStr,
        "script": account.address.toScriptPubKey().toHex(),
        "witnessScript": account.witnessScript,
        "redeemScript": account.redeemScript,
        "type": account.type.name,
        "publicKey": BytesUtils.tryToHexString(account.publicKey)
      }
    ]);
  }

  Web3BitcoinCashSignMessage toSignMessageRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3BitcoinCashRequestMethods method,
      Web3BitcoinCashChainIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      const List<String> keys = ["message"];
      final param = params.paramsAsMap(keys: keys, method: method);
      final account = Web3ValidatorUtils.parseParams2(() {
        final addr = param['account'] ?? param['address'];
        final address = tryParseStateAddress(
            addr: addr, params: params, state: state, network: network);
        if (address == null) return null;
        return state.findAddressOrDefault(
            address: address.address, network: network ?? address.chain);
      },
          error: Web3RequestExceptionConst.invalidAddressArgrument(
              key: 'account', network: networkType.name));
      if (account.derivationIndex.isMultiSig ||
          account.type.isP2sh ||
          account.type == SegwitAddressType.p2wsh) {
        throw Web3BitcoinCashExceptionConstant.unsuportedSigningMessageAccount(
            account.addressStr);
      }

      final String message =
          Web3ValidatorUtils.parseString(key: "message", method: method, json: param);
      final String? messagePrefix = Web3ValidatorUtils.parseString(
          key: "messagePrefix", method: method, json: param);
      final messageBytes = StringUtils.toBytes(message);
      final content = StringUtils.tryDecode(messageBytes);
      return Web3BitcoinCashSignMessage(
          account: account,
          message: BytesUtils.toHexString(messageBytes),
          content: content,
          messagePrefix: messagePrefix,
          method: method);
    });
  }

  Web3BitcoinCashSendTransaction toTransferRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3BitcoinCashRequestMethods method,
      Web3BitcoinCashChainIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      final List<Web3BitcoinCashSendTransaction> messages = [];
      const List<String> keys = ["recipientAddress", "amount"];
      final data = params.getParams();
      for (int i = 0; i < data.length; i++) {
        final elem = params.elementAsMap(i, method: method, keys: keys);
        final message = parseTransferObject(
            param: elem, state: state, network: network, method: method, params: params);
        messages.add(message);
      }
      return Web3BitcoinCashSendTransaction(
          accounts: messages.expand((e) => e.accounts).toList(),
          outputs: messages.expand((e) => e.outputs).toList());
    });
  }

  @override
  Future<Web3MessageCore> request(REQUEST message,
      {Web3BitcoinCashChainIdnetifier? network}) async {
    final method = Web3BitcoinCashRequestMethods.fromName(message.method);
    final state = await getState();
    if (method == null) {
      throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    switch (method) {
      case Web3BitcoinCashRequestMethods.requestAccounts:
        return onConnect_(message);
      case Web3BitcoinCashRequestMethods.sendTransaction:
        return toTransferRequest(
            params: message, state: state, method: method, network: network);
      case Web3BitcoinCashRequestMethods.signMessage:
        return toSignMessageRequest(
            params: message, state: state, method: method, network: network);
      case Web3BitcoinCashRequestMethods.signTransaction:
        return toSignPsbtRequest(
            params: message, state: state, method: method, network: network);
      case Web3BitcoinCashRequestMethods.getAccountAddresses:
        return toGetAccountAddressesRequest(
            params: message, state: state, method: method, network: network);
      default:
        throw Web3RequestExceptionConst.methodDoesNotSupport;
    }
  }
}
