import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/walletconnect/core/state.dart';
import 'package:on_chain_wallet/web3/walletconnect/types/types.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/bitcoin.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';

class BitcoinWalletConnectAddress extends WalletConnectAddress {
  final String type;
  final String? witnessScript;
  final String? redeemScript;
  BitcoinWalletConnectAddress(
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

class BitcoinWeb3WalletConnectStateAddress extends Web3WalletConnectStateAddress<
    BitcoinNetworkAddress,
    Web3BitcoinChainAccount,
    BitcoinWalletConnectAddress,
    Web3BitcoinChainIdnetifier> {
  const BitcoinWeb3WalletConnectStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class BitcoinWeb3WalletConnectStateAccount extends Web3WalletConnectStateAccount<
    BitcoinNetworkAddress,
    Web3BitcoinChainAccount,
    BitcoinWalletConnectAddress,
    Web3BitcoinChainIdnetifier,
    BitcoinWeb3WalletConnectStateAddress> {
  BitcoinWeb3WalletConnectStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });
  factory BitcoinWeb3WalletConnectStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return BitcoinWeb3WalletConnectStateAccount._(
        accounts: const [], state: state, chains: []);
  }
  factory BitcoinWeb3WalletConnectStateAccount(
      Web3BitcoinChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return BitcoinWeb3WalletConnectStateAccount.init(state: Web3NetworkState.block);
    }
    final networks = {for (final i in authenticated.networks) i.id: i};
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return BitcoinWeb3WalletConnectStateAddress(
          chainaccount: e,
          jsAccount: BitcoinWalletConnectAddress(
              address: e.addressStr,
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
    return BitcoinWeb3WalletConnectStateAccount._(
        accounts: accounts.whereType<BitcoinWeb3WalletConnectStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : BitcoinWeb3WalletConnectStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: BitcoinWalletConnectAddress(
                    address: defaultAddress.addressStr,
                    redeemScript: defaultAddress.redeemScript,
                    type: defaultAddress.type.name,
                    witnessScript: defaultAddress.witnessScript,
                    publicKey: defaultAddress.publicKey,
                    chain: networks[defaultAddress.id]!.caip2),
              ));
  }
}

class BitcoinWeb3WalletConnectStateHandler extends Web3WalletConnectStateHandler<
        BitcoinNetworkAddress,
        Web3BitcoinChainAccount,
        BitcoinWalletConnectAddress,
        Web3BitcoinChainIdnetifier,
        BitcoinWeb3WalletConnectStateAddress,
        BitcoinWeb3WalletConnectStateAccount>
    with
        BitcoinWeb3StateHandler<
            BitcoinWalletConnectAddress,
            BitcoinWeb3WalletConnectStateAddress,
            BitcoinWeb3WalletConnectStateAccount,
            WalletConnectWalletMessageResponse,
            WalletConnectNetworkRequest,
            WalletConnectClientEvent> {
  BitcoinWeb3WalletConnectStateHandler({required super.sendInternalMessage});

  @override
  Future<Web3MessageCore> request(WalletConnectNetworkRequest message,
      {Web3BitcoinChainIdnetifier? network}) async {
    final state = await getState();
    final network = state.chains.firstWhere((e) => e.caip2 == message.request?.chainId,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
    return super.request(message, network: network);
  }

  @override
  BitcoinWeb3WalletConnectStateAccount createState(
      Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) {
      return BitcoinWeb3WalletConnectStateAccount.init();
    }
    return BitcoinWeb3WalletConnectStateAccount(authenticated.getAuth(networkType));
  }

  @override
  Future<WalletConnectWalletMessageResponse> finalizeWalletResponse(
      {required WalletConnectNetworkRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    final state = await getState();
    final method = Web3BitcoinRequestMethods.fromName(message.method);
    switch (method) {
      case Web3BitcoinRequestMethods.requestAccounts:
        if (state.hasAccount && message.request != null) {
          final addresses = state.getChainStateAddresses(message.request!.chainId);
          if (addresses.isNotEmpty) {
            return WalletConnectWalletMessageResponse.success(
                data: addresses.map((e) => e.toJson()).toList());
          }
        }
        return WalletConnectWalletMessageResponse.fail(
            Web3RequestExceptionConst.rejectedByUser.toResponseMessage());
      case Web3BitcoinRequestMethods.sendTransaction:
        return WalletConnectWalletMessageResponse.success(
            data: {"txid": response.resultAsString()});
      case Web3BitcoinRequestMethods.signMessage:
        final signedMessage = response.resultAs<Web3BitcoinSignMessageResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: signedMessage.toWalletConnectJson());
      case Web3BitcoinRequestMethods.signTransaction:
        final psbt = response.resultAsString();
        return WalletConnectWalletMessageResponse.success(data: {"psbt": psbt});
      default:
        break;
    }
    return super
        .finalizeWalletResponse(message: message, params: params, response: response);
  }
}
