import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:on_chain/ada/src/address/era/core/address.dart';
import 'package:on_chain/ada/src/models/transaction/input/models/transaction_unspent_output.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/bridge.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/params/models/sign_data.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/params/models/sign_message.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/state/cardano.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/state/types/types.dart';
import 'package:on_chain_wallet/web3/walletconnect/core/state.dart';
import 'package:on_chain_wallet/web3/walletconnect/types/types.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';

class ADAWalletConnectAddress extends WalletConnectAddress {
  ADAWalletConnectAddress(
      {required super.address, required super.chain, required super.publicKey});
}

class WalletConnectADAEIPChainChanged extends WalletConnectEvent {
  final String chainId;
  final String netVersion;
  const WalletConnectADAEIPChainChanged(
      {required this.chainId, required this.netVersion, required super.chainIds});

  @override
  List<WCActionSessionEvent> buildEvent() {
    final param = WCSessionEvent(name: Web3NetworkEvent.chainChanged.name, data: chainId);
    return chainIds
        .map((e) => WCActionSessionEvent(chainId: e.caip2, event: param))
        .toList();
  }
}

class WalletConnectADAEIPAccountChanged extends WalletConnectEvent {
  final List<String> addresses;

  const WalletConnectADAEIPAccountChanged(
      {required this.addresses, required super.chainIds});
  @override
  List<WCActionSessionEvent> buildEvent() {
    final param =
        WCSessionEvent(name: Web3NetworkEvent.accountsChanged.name, data: addresses);
    return chainIds
        .map((e) => WCActionSessionEvent(chainId: e.caip2, event: param))
        .toList();
  }
}

class WalletConnectADAEIPProviderRpcError extends WalletConnectEvent {
  final String message;
  final int? code;
  final dynamic data;
  const WalletConnectADAEIPProviderRpcError(
      {required this.message, required this.code, this.data, required super.chainIds});
  @override
  List<WCActionSessionEvent> buildEvent() {
    final param = WCSessionEvent(name: Web3NetworkEvent.disconnect.name, data: {
      "message": message,
      if (code != null) "code": code,
      if (data != null) "data": data
    });
    return chainIds
        .map((e) => WCActionSessionEvent(chainId: e.caip2, event: param))
        .toList();
  }
}

class ADAWeb3WalletConnectStateAddress extends Web3WalletConnectStateAddress<ADAAddress,
    Web3ADAChainAccount, ADAWalletConnectAddress, Web3ADAChainIdnetifier> {
  const ADAWeb3WalletConnectStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class ADAWeb3WalletConnectStateAccount extends Web3WalletConnectStateAccount<
    ADAAddress,
    Web3ADAChainAccount,
    ADAWalletConnectAddress,
    Web3ADAChainIdnetifier,
    ADAWeb3WalletConnectStateAddress> {
  ADAWeb3WalletConnectStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });
  factory ADAWeb3WalletConnectStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return ADAWeb3WalletConnectStateAccount._(
        accounts: const [], state: state, chains: []);
  }
  factory ADAWeb3WalletConnectStateAccount(Web3ADAChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return ADAWeb3WalletConnectStateAccount.init(state: Web3NetworkState.block);
    }
    Map<int, Web3ADAChainIdnetifier> networks = {
      for (final i in authenticated.networks) i.id: i
    };
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return ADAWeb3WalletConnectStateAddress(
          chainaccount: e,
          jsAccount: ADAWalletConnectAddress(
              address: e.addressStr, publicKey: e.publicKey, chain: network.caip2),
          networkIdentifier: network);
    }).toList();
    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return ADAWeb3WalletConnectStateAccount._(
        accounts: accounts.whereType<ADAWeb3WalletConnectStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : ADAWeb3WalletConnectStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: ADAWalletConnectAddress(
                    publicKey: defaultAddress.publicKey,
                    address: defaultAddress.addressStr,
                    chain: networks[defaultAddress.id]!.caip2)));
  }
}

class ADAWeb3WalletConnectStateHandler extends Web3WalletConnectStateHandler<
        ADAAddress,
        Web3ADAChainAccount,
        ADAWalletConnectAddress,
        Web3ADAChainIdnetifier,
        ADAWeb3WalletConnectStateAddress,
        ADAWeb3WalletConnectStateAccount>
    with
        ADAWeb3StateHandler<
            ADAWalletConnectAddress,
            ADAWeb3WalletConnectStateAddress,
            ADAWeb3WalletConnectStateAccount,
            WalletConnectWalletMessageResponse,
            WalletConnectNetworkRequest,
            WalletConnectClientEvent> {
  ADAWeb3WalletConnectStateHandler({required super.sendInternalMessage});

  @override
  ADAWeb3WalletConnectStateAccount createState(
      Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) {
      return ADAWeb3WalletConnectStateAccount.init();
    }
    return ADAWeb3WalletConnectStateAccount(authenticated.getAuth(networkType));
  }

  @override
  Future<Web3MessageCore> request(WalletConnectNetworkRequest message,
      {Web3ADAChainIdnetifier? network}) async {
    final state = await getState();
    final network = state.chains.firstWhere((e) => e.caip2 == message.request?.chainId,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
    return super.request(message, network: network);
  }

  @override
  Future<WalletConnectWalletMessageResponse> finalizeWalletResponse(
      {required WalletConnectNetworkRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    final state = await getState();
    final method = Web3ADARequestMethods.fromName(message.method);
    switch (method) {
      case Web3ADARequestMethods.requestAccounts:
        if (state.hasAccount && message.request != null) {
          final addresses = state.getChainStateAddresses(message.request!.chainId);
          if (addresses.isNotEmpty) {
            return WalletConnectWalletMessageResponse.success(
                data: addresses.map((e) => e.toJson()).toList());
          }
        }
        return WalletConnectWalletMessageResponse.fail(
            Web3RequestExceptionConst.rejectedByUser.toResponseMessage());
      case Web3ADARequestMethods.signMessage:
        final result = response.resultAs<Web3ADASignMessageResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: result.toWalletConnectJson());
      case Web3ADARequestMethods.signTransaction:
        final result = response.resultAs<Web3ADASignTransactionsResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: result.witnesses.map((e) => e.witness.serializeHex()).toList());
      case Web3ADARequestMethods.signAndSendTransaction:
        final result = response.resultAs<Web3ADASignTransactionsResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: result.witnesses.map((e) {
          if (e.error != null) {
            return {
              "info": e.error,
              "code": findErrorCode(error: Web3ErrorCode.rpcError, method: method)
            };
          }
          return e.txId;
        }).toList());

      case Web3ADARequestMethods.signData:
        final signature = response.resultAs<Web3ADASignDataResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: signature.toWalletConnectJson());
      case Web3ADARequestMethods.getCollateral:
        final utxos = response.resultAsList<TransactionUnspentOutput>();
        return WalletConnectWalletMessageResponse.success(
            data: utxos.map((e) => e.serializeHex()).toList());

      case Web3ADARequestMethods.signTx:
        final result = response.resultAs<Web3ADASignTransactionsResponse>();
        if (result.witnesses.length != 1) {
          throw Web3RequestExceptionConst.internalErr("ada.finalizeWalletResponse",
              reason: "unexpected response.");
        }
        return WalletConnectWalletMessageResponse.success(
            data: result.witnesses[0].witness.serializeHex());
      case Web3ADARequestMethods.signTxs:
        final result = response.resultAs<Web3ADASignTransactionsResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: result.witnesses.map((e) => e.witness.serializeHex()).toList());
      case Web3ADARequestMethods.submitTxs:
        final result = response.resultAs<Web3ADASignTransactionsResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: result.witnesses.map((e) {
          if (e.error != null) {
            return {
              "info": e.error,
              "code": findErrorCode(error: Web3ErrorCode.rpcError, method: method)
            };
          }
          return e.txId;
        }).toList());
      case Web3ADARequestMethods.submitTx:
      case Web3ADARequestMethods.submitUnsignedTx:
        final result = response.resultAs<Web3ADASignTransactionsResponse>();
        if (result.witnesses.length != 1) {
          throw Web3RequestExceptionConst.internalErr("ada.finalizeWalletResponse",
              reason: "unexpected response.");
        }
        return WalletConnectWalletMessageResponse.success(data: result.witnesses[0].txId);

      case Web3ADARequestMethods.getScriptRequirements:
        final resposne = response.resultAsList<Web3ADAScriptRequirement>();

        return WalletConnectWalletMessageResponse.success(
            data: resposne.map((e) => e.toWalletConnectJson()).toList());
      case Web3ADARequestMethods.getScript:
        final result = response.resultAs<String>();
        return WalletConnectWalletMessageResponse.success(data: result);

      case Web3ADARequestMethods.getAccountPub:
        final result = response.resultAsList<int>();
        return WalletConnectWalletMessageResponse.success(
            data: BytesUtils.toHexString(result));
      case Web3ADARequestMethods.getExtensions:
        final resposne = response.resultAsList<Web3ADAExtension>();
        return WalletConnectWalletMessageResponse.success(
            data: resposne.map((e) => e.toWalletConnectJson()).toList());

      default:
    }
    return super
        .finalizeWalletResponse(message: message, params: params, response: response);
  }
}
