import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/utils/web3_validator_utils.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';

abstract class Web3StateAddress<
    NETWORKADDRESS extends IAddress,
    CHAINACCOUNT extends Web3ChainAccount<NETWORKADDRESS>,
    STATEADDRESS,
    NETWORK extends Web3ChainIdnetifier> with Equality {
  final CHAINACCOUNT chainaccount;
  final STATEADDRESS jsAccount;
  final NETWORK networkIdentifier;
  bool get isDefault => chainaccount.defaultAddress;
  NETWORKADDRESS get address => chainaccount.address;
  String get addressStr;

  const Web3StateAddress(
      {required this.chainaccount,
      required this.jsAccount,
      required this.networkIdentifier});

  @override
  List get variables =>
      [chainaccount.derivationIndex, chainaccount.addressStr, chainaccount.id];
}

abstract class Web3StateAccount<
    NETWORKADDRESS extends IAddress,
    CHAINACCOUNT extends Web3ChainAccount<NETWORKADDRESS>,
    JSACCOUNT,
    CHAIN extends Web3ChainIdnetifier,
    STATEADDRESS extends Web3StateAddress<NETWORKADDRESS, CHAINACCOUNT, JSACCOUNT,
        CHAIN>> {
  Web3StateProtocol get protocol;

  Web3StateAccount.init()
      : state = Web3NetworkState.disconnect,
        chains = const [],
        accounts = const [],
        networkAccounts = const [],
        defaultAccount = null,
        defaultChain = null;
  static int compareAddress(String a, String b, String? defaultAddress) {
    if (a == defaultAddress) {
      return -1;
    } else if (b == defaultAddress) {
      return 1;
    }
    return a.compareTo(b);
  }

  static List<STATEADDRESS> _sortAccounts<
      NETWORKADDRESS extends IAddress,
      CHAINACCOUNT extends Web3ChainAccount<NETWORKADDRESS>,
      JSACCOUNT,
      CHAIN extends Web3ChainIdnetifier,
      STATEADDRESS extends Web3StateAddress<NETWORKADDRESS, CHAINACCOUNT, JSACCOUNT,
          CHAIN>>(List<STATEADDRESS> accounts, {STATEADDRESS? defaultAccount}) {
    final clone = accounts.clone();

    if (defaultAccount == null) {
      clone
          .sort((a, b) => a.chainaccount.addressStr.compareTo(b.chainaccount.addressStr));
      return clone.immutable;
    }

    clone.sort((a, b) => compareAddress(a.chainaccount.addressStr,
        b.chainaccount.addressStr, defaultAccount.chainaccount.addressStr));
    return clone.immutable;
  }

  static List<CHAIN> _sortChains<CHAIN extends Web3ChainIdnetifier>(List<CHAIN> chains) {
    final clone = chains.clone();
    clone.sort((a, b) => a.id.compareTo(b.id));
    return clone.immutable;
  }

  Web3StateAccount(
      {required this.state,
      required List<STATEADDRESS> accounts,
      required List<CHAIN> chains,
      required this.defaultAccount,
      required this.defaultChain})
      : networkAccounts =
            _sortAccounts<NETWORKADDRESS, CHAINACCOUNT, JSACCOUNT, CHAIN, STATEADDRESS>(
                accounts.where((e) => e.chainaccount.id == defaultChain?.id).toList(),
                defaultAccount: defaultAccount),
        chains = _sortChains<CHAIN>(chains),
        accounts =
            _sortAccounts<NETWORKADDRESS, CHAINACCOUNT, JSACCOUNT, CHAIN, STATEADDRESS>(
                accounts);
  final Web3NetworkState state;
  final STATEADDRESS? defaultAccount;
  final List<STATEADDRESS> accounts;
  final List<STATEADDRESS> networkAccounts;
  final List<CHAIN> chains;
  final CHAIN? defaultChain;

  CHAIN get defaultChainOrThrow {
    if (defaultChain == null) throw Web3RequestExceptionConst.bannedHost;
    return defaultChain!;
  }

  List<JSACCOUNT> get stateAccounts =>
      accounts.map((e) => e.jsAccount).cast<JSACCOUNT>().toList();
  List<JSACCOUNT> get defaultStateAccounts =>
      networkAccounts.map((e) => e.jsAccount).cast<JSACCOUNT>().toList();

  bool networkChanged(
      Web3StateAccount<NETWORKADDRESS, CHAINACCOUNT, JSACCOUNT, CHAIN, STATEADDRESS>
          other) {
    return defaultChain != other.defaultChain;
  }

  bool networksChanged(
      Web3StateAccount<NETWORKADDRESS, CHAINACCOUNT, JSACCOUNT, CHAIN, STATEADDRESS>
          other) {
    return !CompareUtils.iterableIsEqual(other.chains, chains);
  }

  bool networkAccountChanged(
      Web3StateAccount<NETWORKADDRESS, CHAINACCOUNT, JSACCOUNT, CHAIN, STATEADDRESS>
          other) {
    return defaultAccount?.chainaccount != other.defaultAccount?.chainaccount ||
        !CompareUtils.iterableIsEqual(networkAccounts.map((e) => e.chainaccount),
            other.networkAccounts.map((e) => e.chainaccount));
  }

  bool accountsChanged(
      Web3StateAccount<NETWORKADDRESS, CHAINACCOUNT, JSACCOUNT, CHAIN, STATEADDRESS>
          other) {
    return !CompareUtils.iterableIsEqual(accounts, other.accounts);
  }

  bool stateChanged(
      Web3StateAccount<NETWORKADDRESS, CHAINACCOUNT, JSACCOUNT, CHAIN, STATEADDRESS>
          other) {
    return state != other.state;
  }

  bool chainHasActiveAccount(CHAIN chain) {
    return accounts.any((e) => e.networkIdentifier == chain);
  }

  CHAINACCOUNT findAddressOrDefault(
      {NETWORKADDRESS? address, CHAIN? network, String? networkStr}) {
    if (network == null && networkStr != null) {
      network = chains.firstWhere(
          (e) => e.caip2 == networkStr || e.wsIdentifier == networkStr,
          orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
    }
    if (address == null) {
      return _findDefaultAddress(network: network);
    }

    if (network != null) {
      if (defaultAccount?.networkIdentifier == network &&
          defaultAccount?.address == address) {
        return defaultAccount!.chainaccount;
      }
      return accounts
          .firstWhere(
              (e) => e.networkIdentifier.id == network!.id && e.address == address,
              orElse: () => throw Web3RequestExceptionConst.missingPermission)
          .chainaccount;
    }
    final addresses = accounts.where((e) => e.address == address);
    if (addresses.length != 1) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    return addresses.first.chainaccount;
  }

  CHAINACCOUNT _findDefaultAddress({CHAIN? network}) {
    if (network == null) return defaultNetworkChainAccountOrThrow;
    if (defaultAccount?.networkIdentifier == network) {
      return defaultAccount!.chainaccount;
    }
    return accounts
        .firstWhere((e) => e.networkIdentifier.id == network.id,
            orElse: () => throw Web3RequestExceptionConst.missingPermission)
        .chainaccount;
  }

  CHAINACCOUNT? findAddressOrNull({NETWORKADDRESS? address, CHAIN? network}) {
    try {
      return findAddressOrDefault(address: address, network: network);
    } catch (_) {
      return null;
    }
  }

  CHAINACCOUNT get defaultNetworkChainAccountOrThrow {
    if (defaultAccount == null) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    return defaultAccount!.chainaccount;
  }

  CHAIN getAccountChain(CHAINACCOUNT account) {
    final chain = chains.firstWhere((e) => e.id == account.id,
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);

    return chain;
  }

  JSACCOUNT get defaultAccountOrError {
    if (defaultAccount == null) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    return defaultAccount!.jsAccount;
  }

  bool get hasAccount => accounts.isNotEmpty;
  bool get hasChainAccount => defaultAccount != null;

  List<String> get defaultAccountsAddresses =>
      networkAccounts.map((e) => e.chainaccount.addressStr).toList();

  JSACCOUNT getStateAddress(NETWORKADDRESS address, {int? id}) {
    if (id != null) {
      return accounts
          .firstWhere((e) => e.address == address && e.networkIdentifier.id == id,
              orElse: () => throw Web3RequestExceptionConst.missingPermission)
          .jsAccount;
    }
    return accounts
        .firstWhere((e) => e.address == address,
            orElse: () => throw Web3RequestExceptionConst.missingPermission)
        .jsAccount;
  }

  CHAIN getChainFromChainIdentifier(String chainId) {
    return chains.firstWhere((e) => e.isChain(chainId),
        orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
  }

  List<JSACCOUNT> getChainStateAddresses(String chainId) {
    final chain = getChainFromChainIdentifier(chainId);
    return accounts
        .where((e) => e.networkIdentifier == chain)
        .map((e) => e.jsAccount)
        .toList()
        .cast<JSACCOUNT>();
  }
}

typedef WEB3PLATFORMSTATEHANDLER<JSACCOUNT, RESPONSE, CLIENT extends Web3ClientRequest,
        EVENT>
    = Web3StateHandler<
        IAddress,
        Web3ChainAccount<IAddress>,
        JSACCOUNT,
        Web3ChainIdnetifier,
        Web3StateAddress<IAddress, Web3ChainAccount<IAddress>, JSACCOUNT,
            Web3ChainIdnetifier>,
        Web3StateAccount<
            IAddress,
            Web3ChainAccount<IAddress>,
            JSACCOUNT,
            Web3ChainIdnetifier,
            Web3StateAddress<IAddress, Web3ChainAccount<IAddress>, JSACCOUNT,
                Web3ChainIdnetifier>>,
        RESPONSE,
        CLIENT,
        EVENT>;

abstract class Web3StateHandler<
    NETWORKADDRESS extends IAddress,
    CHAINACCOUNT extends Web3ChainAccount<NETWORKADDRESS>,
    JSACCOUNT,
    CHAIN extends Web3ChainIdnetifier,
    STATEADDRESS extends Web3StateAddress<NETWORKADDRESS, CHAINACCOUNT, JSACCOUNT, CHAIN>,
    STATE extends Web3StateAccount<NETWORKADDRESS, CHAINACCOUNT, JSACCOUNT, CHAIN,
        STATEADDRESS>,
    RESPONSE,
    REQUEST extends Web3ClientRequest,
    EVENT> {
  NETWORKADDRESS toAddress(String v, {CHAIN? network});
  NETWORKADDRESS? tryToAddress(String v, {CHAIN? network}) {
    try {
      final address = toAddress(v, network: network);
      return address;
    } catch (_) {}
    return null;
  }

  ParsedNetworkStateAddress<NETWORKADDRESS, CHAIN> parseStateAddress(
      {required dynamic addr,
      required REQUEST params,
      required STATE state,
      CHAIN? network,
      Web3RequestException? error}) {
    try {
      if (addr == null) {
        throw Web3RequestExceptionConst.invalidAddress(
            key: addr, network: networkType.name);
      }
      if (addr is String) {
        final address = toAddress(addr, network: network);
        return ParsedNetworkStateAddress<NETWORKADDRESS, CHAIN>(
            address: address, chain: network);
      }

      final obj = params.tryObjectAsMap(addr, keys: ["address", "chains"]);
      if (obj == null) {
        throw Web3RequestExceptionConst.invalidAddress(
            key: addr, network: networkType.name);
      }
      if (network != null) {
        return ParsedNetworkStateAddress(
            address: toAddress(obj["address"], network: network), chain: network);
      }
      final String chainName = (obj["chains"] as List).firstOrNull;
      final chain = state.chains.firstWhere((e) => e.isChain(chainName),
          orElse: () => throw Web3RequestExceptionConst.networkDoesNotExists);
      final address = toAddress(obj["address"], network: chain);
      return ParsedNetworkStateAddress(address: address, chain: chain);
    } on Web3RequestException {
      if (error != null) throw error;
      rethrow;
    } catch (_) {
      throw error ??
          Web3RequestExceptionConst.invalidAddress(key: addr, network: networkType.name);
    }
  }

  ParsedNetworkStateAddress<NETWORKADDRESS, CHAIN>? tryParseStateAddress(
      {required dynamic addr,
      required REQUEST params,
      required STATE state,
      Web3RequestException? error,
      CHAIN? network,
      bool throwOnFailed = false}) {
    if (addr == null) return null;
    try {
      return parseStateAddress(
          addr: addr, params: params, network: network, error: error, state: state);
    } catch (_) {
      if (throwOnFailed) rethrow;
    }
    return null;
  }

  Web3StateHandler({required this.sendInternalMessage});
  EVENT createStateEvent(
      {required STATE previousState,
      required STATE currentState,
      required bool networkAccountsChanged,
      required bool networkChanged,
      required bool accountsChanged,
      required bool networksChanged});
  List<Web3NetworkRequestMethods> get methods;
  NetworkType get networkType;
  List<Web3NetworkEvent> get events =>
      [Web3NetworkEvent.change, Web3NetworkEvent.accountsChanged];
  final SafeAtomicLock lock = SafeAtomicLock();
  final SENDINTERNALWALLETMESSAGE sendInternalMessage;
  Web3WalletResponseMessage createResponse([Object? result]) {
    return Web3WalletResponseMessage(result: result, network: networkType);
  }

  Future<Web3MessageCore> onConnect_(REQUEST? message) async {
    Web3ChainIdnetifier? chain;
    final state = await getState();

    if (message != null) {
      String? chainId = message.requestParams.elementAtOrNull(0)?.toString();
      if (chainId != null) {
        chain = state.chains.firstWhereOrNull((e) => e.isChain(chainId));
        if (chain == null) {
          throw Web3RequestExceptionConst.networkIdDoesNotExists(chainId);
        }
      }
    }

    switch (message?.source) {
      case null:
      case Web3RequestSource.walletStandard:
      case Web3RequestSource.walletConnect:
        if (chain == null) {
          if (state.hasAccount) return createResponse();

          return connetInternal();
        }
        final chainAccounts = state.accounts.where((e) => e.networkIdentifier == chain);
        if (chainAccounts.isEmpty) {
          return connetInternal(networks: [chain.id]);
        }
        switch (networkType) {
          case NetworkType.aptos:
            if (chain != state.defaultChain) {
              return connetInternal(networks: [chain.id]);
            }
            break;
          default:
        }
        return createResponse();
      case Web3RequestSource.injected:
        if (chain == null) {
          if (state.hasChainAccount) return createResponse();
          return connetInternal();
        }
        if (state.defaultChain == chain && state.hasChainAccount) {
          return createResponse();
        }
        return connetInternal(networks: [chain.id]);
    }
  }

  Future<Web3MessageCore> connetInternal({List<int>? networks}) async {
    await sendInternalMessage(
        network: networkType,
        request: networks == null
            ? Web3ConnectApplication.network(networkType)
            : Web3ConnectApplication.networks(networks));
    return createResponse();
  }

  Future<STATE> silentConnetInternal() async {
    await sendInternalMessage(
        network: networkType, request: Web3SilentConnectApplication.network(networkType));
    return getState();
  }

  Future<Web3MessageCore> request(REQUEST message);
  STATE createState(Web3APPData? authenticated, AppContext? context);
  void onRequestDone(REQUEST message) {}
  Future<STATE> getState();
  Future<RESPONSE> finalizeError(
      {required REQUEST message,
      required Web3RequestParams? params,
      required Web3ExceptionMessage error});
  Future<RESPONSE> finalizeWalletResponse(
      {required REQUEST message,
      required Web3RequestParams? params,
      required Web3WalletResponseMessage response});

  Future<RESPONSE> onConnectResponse(REQUEST? message);

  Web3DisconnectApplication discoonect() {
    return Web3DisconnectApplication(chain: networkType);
  }

  Future<EVENT> initChain(Web3APPData authenticated, AppContext? context);
  Future<EVENT?> createEvent(Web3NetworkEvent event);
  Future<void> event(Web3NetworkEvent event);
}

abstract class Web3ClientRequest {
  const Web3ClientRequest();
  Web3RequestSource get source;
  List<Object?> get requestParams;
  String get method;

  Object? tryElementAs(int index) {
    return requestParams.elementAtOrNull(index);
  }

  bool? tryElementAsBolean(int index) {
    final elem = requestParams.elementAtOrNull(index);
    if (elem is bool) return elem;
    return null;
  }

  String? tryElementAsString(int index) {
    final elem = requestParams.elementAtOrNull(index);
    if (elem is String) return elem;
    return null;
  }

  List<dynamic> getParams({Web3RequestMethods? method, int? length}) {
    return Web3ValidatorUtils.parseParams2(() {
      if (length != null && requestParams.length < length) return null;
      return requestParams;
    }, error: Web3RequestExceptionConst.invalidParams);
  }

  Map<String, dynamic> paramsAsMap(
      {Web3RequestMethods? method, List<String> keys = const []}) {
    return Web3ValidatorUtils.parseParams2(() {
      final param = tryObjectAsMap(requestParams[0]);
      if (param == null) return null;
      for (final i in keys) {
        if (!param.containsKey(i)) return null;
      }
      return param;
    }, error: Web3RequestExceptionConst.invalidMapParameters(keys: keys));
  }

  Map<String, dynamic> elementAsMap(int index,
      {Web3RequestException? error,
      Web3RequestMethods? method,
      List<String> keys = const []}) {
    final params = getParams(length: index + 1);
    return Web3ValidatorUtils.parseParams2(() {
      final object = params[index];
      final elem = tryObjectAsMap(object);
      if (elem == null) return null;
      for (final i in keys) {
        if (!elem.containsKey(i)) return null;
      }
      return elem;
    }, error: error ?? Web3RequestExceptionConst.invalidListOfObject(keys: keys));
  }

  Map<String, dynamic> objectAsMap(
      {required Object? object,
      required String name,
      Web3RequestException? error,
      List<String> keys = const []}) {
    final result = Web3ValidatorUtils.tryObjectAsMap(object);

    if (result == null || !keys.every((e) => result[e] != null)) {
      throw error ??
          Web3RequestExceptionConst.invalidMapArguments(name: name, keys: keys);
    }
    return result;
  }

  Map<String, dynamic>? tryObjectAsMap(Object? object, {List<String> keys = const []}) {
    try {
      return objectAsMap(object: object, name: '', keys: keys);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> objectAsListOfMap(
      {required Object? object, required String name, Web3RequestException? error}) {
    final result = Web3ValidatorUtils.tryObjectAsListOfMap(object);
    if (result == null) {
      throw error ?? Web3RequestExceptionConst.invalidListArgument(name);
    }
    return result;
  }

  List<int> objectAsBytes({
    required Object? object,
    required String name,
    Web3RequestException? error,
    required List<StringEncoding> encoding,
  }) {
    return Web3ValidatorUtils.parseParams2(() {
      if (object == null) return null;
      if (object is String) {
        for (final i in encoding) {
          final bytes = StringUtils.tryEncode(object, encoding: i);
          if (bytes != null) return bytes;
        }
      } else if (object is List) {
        return object.cast<int>().asBytes;
      }
      return null;
    },
        error: error ??
            Web3RequestExceptionConst.invalidBytesArgrument2(
                arg: name, encoding: encoding));
  }
}
