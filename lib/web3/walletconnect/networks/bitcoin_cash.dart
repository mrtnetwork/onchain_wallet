import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/params/models/sign_message.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin_cash/bitcoin_cash.dart';
import 'package:on_chain_wallet/web3/walletconnect/core/state.dart';
import 'package:on_chain_wallet/web3/walletconnect/types/types.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';

class BitcoinCashWalletConnectAddress extends WalletConnectAddress {
  final String type;
  final String? witnessScript;
  final String? redeemScript;
  BitcoinCashWalletConnectAddress(
      {required super.address,
      required super.chain,
      required super.publicKey,
      required this.type,
      required this.witnessScript,
      required this.redeemScript});

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      "type": type,
      "witnessScript": witnessScript,
      "redeemScript": redeemScript
    }.withoutNullValue;
  }
}

class BitcoinCashWeb3WalletConnectStateAddress extends Web3WalletConnectStateAddress<
    BitcoinNetworkAddress,
    Web3BitcoinCashChainAccount,
    BitcoinCashWalletConnectAddress,
    Web3BitcoinCashChainIdnetifier> {
  const BitcoinCashWeb3WalletConnectStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class BitcoinCashWeb3WalletConnectStateAccount extends Web3WalletConnectStateAccount<
    BitcoinNetworkAddress,
    Web3BitcoinCashChainAccount,
    BitcoinCashWalletConnectAddress,
    Web3BitcoinCashChainIdnetifier,
    BitcoinCashWeb3WalletConnectStateAddress> {
  BitcoinCashWeb3WalletConnectStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });
  factory BitcoinCashWeb3WalletConnectStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return BitcoinCashWeb3WalletConnectStateAccount._(
        accounts: const [], state: state, chains: []);
  }
  factory BitcoinCashWeb3WalletConnectStateAccount(
      Web3BitcoinCashChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return BitcoinCashWeb3WalletConnectStateAccount.init(state: Web3NetworkState.block);
    }
    final networks = {for (final i in authenticated.networks) i.id: i};
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return BitcoinCashWeb3WalletConnectStateAddress(
          chainaccount: e,
          jsAccount: BitcoinCashWalletConnectAddress(
              address: e.wcStyle,
              publicKey: e.publicKey,
              redeemScript: e.redeemScript,
              type: e.type.name,
              witnessScript: e.witnessScript,
              chain: network.caip2),
          networkIdentifier: network);
    }).toList();
    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return BitcoinCashWeb3WalletConnectStateAccount._(
        accounts: accounts.whereType<BitcoinCashWeb3WalletConnectStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : BitcoinCashWeb3WalletConnectStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: BitcoinCashWalletConnectAddress(
                    address: defaultAddress.wcStyle,
                    redeemScript: defaultAddress.redeemScript,
                    type: defaultAddress.type.name,
                    witnessScript: defaultAddress.witnessScript,
                    publicKey: defaultAddress.publicKey,
                    chain: networks[defaultAddress.id]!.caip2),
              ));
  }
}

class BitcoinCashWeb3WalletConnectStateHandler extends Web3WalletConnectStateHandler<
        BitcoinNetworkAddress,
        Web3BitcoinCashChainAccount,
        BitcoinCashWalletConnectAddress,
        Web3BitcoinCashChainIdnetifier,
        BitcoinCashWeb3WalletConnectStateAddress,
        BitcoinCashWeb3WalletConnectStateAccount>
    with
        BitcoinCashWeb3StateHandler<
            BitcoinCashWalletConnectAddress,
            BitcoinCashWeb3WalletConnectStateAddress,
            BitcoinCashWeb3WalletConnectStateAccount,
            WalletConnectWalletMessageResponse,
            WalletConnectNetworkRequest,
            WalletConnectClientEvent> {
  BitcoinCashWeb3WalletConnectStateHandler({required super.sendInternalMessage});
  @override
  BitcoinCashAddress toAddress(String v,
      {Web3BitcoinCashChainIdnetifier? network,
      BitcoinCashWeb3WalletConnectStateAccount? state}) {
    if (network == null) {
      return super.toAddress(v, network: network, state: state);
    }
    final hasCaip = v.indexOf(":") > 0;
    if (hasCaip) {
      return super.toAddress(v, network: network, state: state);
    }
    final correctAddress = "${network.caipChainId}:$v";
    return super.toAddress(correctAddress, network: network, state: state);
  }

  @override
  Future<Web3MessageCore> request(WalletConnectNetworkRequest message,
      {Web3BitcoinCashChainIdnetifier? network}) async {
    final state = await getState();
    final network = state.chains.firstWhere((e) => e.caip2 == message.request?.chainId,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
    return super.request(message, network: network);
  }

  @override
  BitcoinCashWeb3WalletConnectStateAccount createState(
      Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) {
      return BitcoinCashWeb3WalletConnectStateAccount.init();
    }
    return BitcoinCashWeb3WalletConnectStateAccount(authenticated.getAuth(networkType));
  }

  @override
  Future<WalletConnectWalletMessageResponse> finalizeWalletResponse(
      {required WalletConnectNetworkRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    final state = await getState();
    final method = Web3BitcoinCashRequestMethods.fromName(message.method);
    switch (method) {
      case Web3BitcoinCashRequestMethods.requestAccounts:
        if (state.hasAccount && message.request != null) {
          final addresses = state.getChainStateAddresses(message.request!.chainId);
          if (addresses.isNotEmpty) {
            return WalletConnectWalletMessageResponse.success(
                data: addresses.map((e) => e.toJson()).toList());
          }
        }
        return WalletConnectWalletMessageResponse.fail(
            Web3RequestExceptionConst.rejectedByUser.toResponseMessage());
      case Web3BitcoinCashRequestMethods.sendTransaction:
        return WalletConnectWalletMessageResponse.success(
            data: {"txid": response.resultAsString()});
      case Web3BitcoinCashRequestMethods.signMessage:
        final signedMessage = response.resultAs<Web3BitcoinSignMessageResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: signedMessage.toWalletConnectJson());
      case Web3BitcoinCashRequestMethods.signTransaction:
        final psbt = response.resultAsString();
        return WalletConnectWalletMessageResponse.success(data: {"psbt": psbt});
      default:
        break;
    }
    return super
        .finalizeWalletResponse(message: message, params: params, response: response);
  }
}
