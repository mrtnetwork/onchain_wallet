import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:on_chain/aptos/src/address/address/address.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/aptos/aptos.dart';
import 'package:on_chain_wallet/web3/web3/state/state.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/walletconnect/core/state.dart';
import 'package:on_chain_wallet/web3/walletconnect/types/types.dart';
import 'package:on_chain_wallet/context/core/context.dart';

enum AptosWalletConnectUserResponseType {
  approved("Approved"),
  rejected("Rejected");

  final String name;
  const AptosWalletConnectUserResponseType(this.name);
}

class AptosWalletConnectUserResponse {
  final Object? args;
  final AptosWalletConnectUserResponseType status;
  const AptosWalletConnectUserResponse._({required this.status, this.args});
  factory AptosWalletConnectUserResponse.rejected() {
    return AptosWalletConnectUserResponse._(
        status: AptosWalletConnectUserResponseType.rejected);
  }
  factory AptosWalletConnectUserResponse.approved({Object? args}) {
    return AptosWalletConnectUserResponse._(
        status: AptosWalletConnectUserResponseType.approved, args: args);
  }
  Map<String, dynamic> toWalletConnectResponse() {
    return {"args": args, "status": status.name}.withoutNullValue;
  }
}

class AptosWalletConnectSwitchChainResponse {
  final String? reason;
  final bool success;
  const AptosWalletConnectSwitchChainResponse._({required this.success, this.reason});
  factory AptosWalletConnectSwitchChainResponse.success() {
    return AptosWalletConnectSwitchChainResponse._(success: true);
  }
  factory AptosWalletConnectSwitchChainResponse.fail({String? reason}) {
    return AptosWalletConnectSwitchChainResponse._(success: false, reason: reason);
  }
  Map<String, dynamic> toWalletConnectResponse() {
    return {"success": success, "reason": reason}.withoutNullValue;
  }
}

class AptosNetworkInfo {
  final String name;
  final int? chainId;
  final String? url;
  const AptosNetworkInfo({required this.name, required this.chainId, this.url});
  Map<String, dynamic> toWalletConnectJson() {
    return {"name": name, "chainId": chainId, "url": url}.withoutNullValue;
  }
}

class AptosWalletConnectAddress extends WalletConnectAddress {
  final int signingScheme;
  AptosWalletConnectAddress(
      {required super.address,
      required super.chain,
      required super.publicKey,
      required this.signingScheme});

  @override
  Map<String, dynamic> toJson() {
    return {
      "address": address,
      "chains": [chain],
      "publicKey": BytesUtils.tryToHexString(publicKey, prefix: "0x"),
      "signingScheme": signingScheme
    }.withoutNullValue;
  }
}

class AptosWeb3WalletConnectStateAddress extends Web3WalletConnectStateAddress<
    AptosAddress,
    Web3AptosChainAccount,
    AptosWalletConnectAddress,
    Web3AptosChainIdnetifier> {
  const AptosWeb3WalletConnectStateAddress(
      {required super.chainaccount,
      required super.jsAccount,
      required super.networkIdentifier});
}

class AptosWeb3WalletConnectStateAccount extends Web3WalletConnectStateAccount<
    AptosAddress,
    Web3AptosChainAccount,
    AptosWalletConnectAddress,
    Web3AptosChainIdnetifier,
    AptosWeb3WalletConnectStateAddress> {
  AptosNetworkInfo get currentChainInfo {
    final chain = defaultChain;
    if (chain == null) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    return AptosNetworkInfo(chainId: chain.chainId, name: chain.aptosChain.name);
  }

  AptosWeb3WalletConnectStateAccount._({
    required super.state,
    required super.chains,
    required super.accounts,
    super.defaultAccount,
    super.defaultChain,
  });
  factory AptosWeb3WalletConnectStateAccount.init(
      {Web3NetworkState state = Web3NetworkState.disconnect}) {
    return AptosWeb3WalletConnectStateAccount._(
        accounts: const [], state: state, chains: []);
  }
  factory AptosWeb3WalletConnectStateAccount(Web3AptosChainAuthenticated? authenticated) {
    if (authenticated == null) {
      return AptosWeb3WalletConnectStateAccount.init(state: Web3NetworkState.block);
    }
    final networks = {for (final i in authenticated.networks) i.id: i};
    final accounts = authenticated.accounts.map((e) {
      final network = networks[e.id];
      if (network == null) return null;
      return AptosWeb3WalletConnectStateAddress(
          chainaccount: e,
          jsAccount: AptosWalletConnectAddress(
              address: e.addressStr,
              signingScheme: e.signingScheme,
              publicKey: e.publicKey,
              chain: network.caip2),
          networkIdentifier: network);
    }).toList();
    final defaultAddress = authenticated.accounts.firstWhereOrNull((e) =>
        e.defaultAddress &&
        networks.containsKey(e.id) &&
        e.id == authenticated.currentNetwork.id);
    return AptosWeb3WalletConnectStateAccount._(
        accounts: accounts.whereType<AptosWeb3WalletConnectStateAddress>().toList(),
        state: Web3NetworkState.ready,
        chains: authenticated.networks,
        defaultChain: authenticated.currentNetwork,
        defaultAccount: defaultAddress == null
            ? null
            : AptosWeb3WalletConnectStateAddress(
                chainaccount: defaultAddress,
                networkIdentifier: networks[defaultAddress.id]!,
                jsAccount: AptosWalletConnectAddress(
                    signingScheme: defaultAddress.signingScheme,
                    publicKey: defaultAddress.publicKey,
                    address: defaultAddress.addressStr,
                    chain: networks[defaultAddress.id]!.caip2),
              ));
  }
}

class AptosWeb3WalletConnectStateHandler extends Web3WalletConnectStateHandler<
        AptosAddress,
        Web3AptosChainAccount,
        AptosWalletConnectAddress,
        Web3AptosChainIdnetifier,
        AptosWeb3WalletConnectStateAddress,
        AptosWeb3WalletConnectStateAccount>
    with
        AptosWeb3StateHandler<
            AptosWalletConnectAddress,
            AptosWeb3WalletConnectStateAddress,
            AptosWeb3WalletConnectStateAccount,
            WalletConnectWalletMessageResponse,
            WalletConnectNetworkRequest,
            WalletConnectClientEvent> {
  AptosWeb3WalletConnectStateHandler({required super.sendInternalMessage});

  @override
  Future<Web3MessageCore> request(WalletConnectNetworkRequest message,
      {Web3AptosChainIdnetifier? network}) async {
    final state = await getState();
    final network = state.chains.firstWhere((e) => e.caip2 == message.request?.chainId,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
    return super.request(message, network: network);
  }

  @override
  AptosWeb3WalletConnectStateAccount createState(
      Web3APPData? authenticated, AppContext? context) {
    if (authenticated == null) return AptosWeb3WalletConnectStateAccount.init();
    return AptosWeb3WalletConnectStateAccount(authenticated.getAuth(networkType));
  }

  @override
  Future<WalletConnectWalletMessageResponse> finalizeError(
      {required WalletConnectNetworkRequest message,
      required Web3RequestParams? params,
      required Web3ExceptionMessage error}) async {
    final method = Web3AptosRequestMethods.fromName(message.method);
    bool isAuthenticatedError = error.errorType.isAuthError;
    if (isAuthenticatedError) {
      switch (method) {
        case Web3AptosRequestMethods.requestAccounts:
        case Web3AptosRequestMethods.signTransaction:
        case Web3AptosRequestMethods.signMessage:
          return WalletConnectWalletMessageResponse.success(
              data: AptosWalletConnectUserResponse.rejected().toWalletConnectResponse());
        default:
      }
    } else {
      switch (method) {
        case Web3AptosRequestMethods.switchNetwork:
          return WalletConnectWalletMessageResponse.success(
              data: AptosWalletConnectSwitchChainResponse.fail(reason: error.message)
                  .toWalletConnectResponse());
        default:
      }
    }

    return super.finalizeError(message: message, params: params, error: error);
  }

  ///AptosWalletConnectUserResponse
  @override
  Future<WalletConnectWalletMessageResponse> finalizeWalletResponse(
      {required WalletConnectNetworkRequest message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response}) async {
    final method = Web3AptosRequestMethods.fromName(message.method);
    final state = await getState();
    if (method == null) {
      throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    switch (method) {
      case Web3AptosRequestMethods.getNetwork:
        return WalletConnectWalletMessageResponse.success(
            data: state.currentChainInfo.toWalletConnectJson());
      case Web3AptosRequestMethods.requestAccounts:
        if (state.hasAccount && message.request != null) {
          final addresses = state.getChainStateAddresses(message.request!.chainId);
          if (addresses.isNotEmpty) {
            final message =
                AptosWalletConnectUserResponse.approved(args: addresses.first.toJson());
            return WalletConnectWalletMessageResponse.success(
                data: message.toWalletConnectResponse());
          }
        }
        return WalletConnectWalletMessageResponse.success(
            data: AptosWalletConnectUserResponse.rejected().toWalletConnectResponse());
      case Web3AptosRequestMethods.signTransaction:
        final transactionResponse = response.resultAsList<int>();
        final message = AptosWalletConnectUserResponse.approved(
            args: BytesUtils.toHexString(transactionResponse, prefix: "0x"));
        return WalletConnectWalletMessageResponse.success(
            data: message.toWalletConnectResponse());
      case Web3AptosRequestMethods.signMessage:
        final signature = response.resultAs<Web3AptosSignMessageResponse>();
        return WalletConnectWalletMessageResponse.success(
            data: AptosWalletConnectUserResponse.approved(
                    args: signature.toWalletConnectJson())
                .toWalletConnectResponse());
      case Web3AptosRequestMethods.switchNetwork:
        return WalletConnectWalletMessageResponse.success(
            data: AptosWalletConnectSwitchChainResponse.success()
                .toWalletConnectResponse());

      default:
    }
    return super
        .finalizeWalletResponse(message: message, params: params, response: response);
  }
}
