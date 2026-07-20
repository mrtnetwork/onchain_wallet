import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:on_chain/tron/src/address/tron_address.dart';
import 'package:on_chain/tron/src/models/contract/transaction/transaction.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/walletconnect/core/state.dart';
import 'package:on_chain_wallet/web3/walletconnect/types/types.dart';
import 'package:on_chain_wallet/web3/web3/networks/tron/tron.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';

class TronWalletConnectAddress extends WalletConnectAddress {
  final String hexAddress;
  TronWalletConnectAddress(
      {required super.address,
      required super.chain,
      required super.publicKey,
      required this.hexAddress});

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      "hex": hexAddress,
    }.withoutNullValue;
  }
}

class TronWeb3WalletConnectStateAddress extends Web3WalletConnectStateAddress<TronAddress,
    Web3TronChainAccount, TronWalletConnectAddress, Web3TronChainIdnetifier> {
  const TronWeb3WalletConnectStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class TronWeb3WalletConnectStateAccount extends Web3WalletConnectStateAccount<
    TronAddress,
    Web3TronChainAccount,
    TronWalletConnectAddress,
    Web3TronChainIdnetifier,
    TronWeb3WalletConnectStateAddress> {
  bool chainExist(int chainId) {
    return chains.any((e) => e.chainId == chainId);
  }

  Web3TronChainIdnetifier getChainFromChainId(int chainId) {
    return chains.firstWhere((e) => e.chainId == chainId,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
  }

  TronWeb3WalletConnectStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });
  factory TronWeb3WalletConnectStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return TronWeb3WalletConnectStateAccount._(
        accounts: const [], state: state, chains: []);
  }
  factory TronWeb3WalletConnectStateAccount(Web3TronChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return TronWeb3WalletConnectStateAccount.init(state: Web3NetworkState.block);
    }
    Map<int, Web3TronChainIdnetifier> networks = {
      for (final i in authenticated.networks) i.id: i
    };
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return TronWeb3WalletConnectStateAddress(
          chainaccount: e,
          jsAccount: TronWalletConnectAddress(
              address: e.addressStr,
              publicKey: e.publicKey,
              hexAddress: e.address.toAddress(false),
              chain: network.caip2),
          networkIdentifier: network);
    }).toList();
    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return TronWeb3WalletConnectStateAccount._(
        accounts: accounts.whereType<TronWeb3WalletConnectStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : TronWeb3WalletConnectStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: TronWalletConnectAddress(
                    address: defaultAddress.addressStr,
                    publicKey: defaultAddress.publicKey,
                    hexAddress: defaultAddress.address.toAddress(false),
                    chain: networks[defaultAddress.id]!.caip2),
              ));
  }
}

class TronWeb3WalletConnectStateHandler extends Web3WalletConnectStateHandler<
        TronAddress,
        Web3TronChainAccount,
        TronWalletConnectAddress,
        Web3TronChainIdnetifier,
        TronWeb3WalletConnectStateAddress,
        TronWeb3WalletConnectStateAccount>
    with
        TronWeb3StateHandler<
            TronWalletConnectAddress,
            TronWeb3WalletConnectStateAddress,
            TronWeb3WalletConnectStateAccount,
            WalletConnectWalletMessageResponse,
            WalletConnectNetworkRequest,
            WalletConnectClientEvent> {
  TronWeb3WalletConnectStateHandler({required super.sendInternalMessage});

  @override
  Future<Web3MessageCore> request(WalletConnectNetworkRequest message,
      {Web3TronChainIdnetifier? network}) async {
    final state = await getState();
    final network = state.chains.firstWhere((e) => e.caip2 == message.request?.chainId,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
    return super.request(message, network: network);
  }

  @override
  TronWeb3WalletConnectStateAccount createState(
      Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) {
      return TronWeb3WalletConnectStateAccount.init();
    }
    return TronWeb3WalletConnectStateAccount(authenticated.getAuth(networkType));
  }

  @override
  Future<WalletConnectWalletMessageResponse> finalizeWalletResponse(
      {required WalletConnectNetworkRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    final method = Web3TronRequestMethods.fromName(message.method);
    final state = await getState();
    switch (method) {
      case Web3TronRequestMethods.requestAccounts:
        if (state.hasAccount && message.request != null) {
          final addresses = state.getChainStateAddresses(message.request!.chainId);
          if (addresses.isNotEmpty) {
            return WalletConnectWalletMessageResponse.success(
                data: addresses.map((e) => e.address).toList());
          }
        }
        return WalletConnectWalletMessageResponse.fail(
            Web3RequestExceptionConst.rejectedByUser.toResponseMessage());
      case Web3TronRequestMethods.signMessageV2:
        final signature = response.resultAsString();
        return WalletConnectWalletMessageResponse.success(data: {"signature": signature});
      case Web3TronRequestMethods.signTransaction:
        final transaction = response.resultAs<Transaction>();
        return WalletConnectWalletMessageResponse.success(data: {
          "transaction": transaction.toJson(
              rawDataHex: true, signatures: true, txID: true, visible: false),
          "result": {
            "result": true,
            'signature': BytesUtils.tryToHexString(transaction.signature.firstOrNull)
          },
        });
      default:
    }
    return super
        .finalizeWalletResponse(message: message, params: params, response: response);
  }
}
