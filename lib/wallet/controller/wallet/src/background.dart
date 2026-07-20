import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/client.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/api/core.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/storage/wallet_storage.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/walletconnect/types/controller.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';
import 'package:on_chain_wallet/crypto/crypto.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/storage/web3_storage.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/models/access/wallet_access.dart';
import 'package:on_chain_wallet/wallet/models/others/models/wallet.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/ui_actions.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/config.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/hd_wallet.dart';
import 'package:on_chain_wallet/wallet/controller/chain/controller.dart';

class BackgroundWalletControllerContext
    extends BaseWalletControllerContext<ViewMasterKey, MainWallet> {
  @override
  final Web3StorageManager web3Storage;
  @override
  final WalletStorageManager storage;
  @override
  final String id;
  @override
  final InChainWalletController inChainWalletController;

  @override
  IWeb3WalletConnectController get web3Controller => throw UnimplementedError();
  @override
  IBridgeClient get bridgeController => throw UnimplementedError();

  BackgroundWalletControllerContext(
      {required this.storage,
      required this.web3Storage,
      required List<Chain> chains,
      required this.networks,
      required this.inChainWalletController,
      required this.chain,
      required this.id,
      required this.wallet})
      : chains = chains.immutable,
        _status = switch (wallet.requiredPassword) {
          true => WStatus.lock,
          _ => WStatus.readOnly
        };

  @override
  final Chain chain;
  @override
  final List<Chain> chains;
  @override
  WalletConfig get config => inChainWalletController.config;
  @override
  bool get hasWalletKey => false;

  @override
  Map<NetworkType, NetworkController> networks;
  @override
  final MainWallet wallet;
  WStatus _status;
  @override
  WStatus get status => _status;
  @override
  bool get isUnlock => status.isUnlock;

  @override
  void setNetwork(NetworkController controller) {}

  @override
  void removeCredential(WalletCredentialResponseVerify credential) {}

  @override
  IResult<void> validateCredential(WalletCredentialResponseVerify credential,
      {bool remove = true}) {
    return ResultErr.fromException(WalletExceptionConst.authFailed);
  }

  @override
  T networkController<T extends APPNETWORKCONTROLLER>(NetworkType network) {
    final controller = networks[network];
    if (controller == null) {
      throw WalletExceptionConst.walletIsNotavailable;
    }
    return controller.cast<T>();
  }

  @override
  void updateWalletStatus() {}

  @override
  Future<IResult<void>> setChain(Chain chain) async {
    return ResultErr.fromException(WalletExceptionConst.walletIsNotavailable);
  }

  Future<IResult<List<int>>> getMemoryKey({bool newKey = false}) async {
    return ResultErr.fromException(WalletExceptionConst.walletIsNotavailable);
  }

  @override
  Future<IResult<void>> login({String? password, bool? platformCredential}) async {
    return ResultErr.fromException(WalletExceptionConst.walletIsNotavailable);
  }

  @override
  Future<IResult<void>> updateMasterKey(ViewMasterKey masterKey) async {
    return ResultErr.fromException(WalletExceptionConst.walletIsNotavailable);
  }

  @override
  Future<IResult<void>> updateWallet(MainWallet wallet) async {
    return ResultErr.fromException(WalletExceptionConst.walletIsNotavailable);
  }

  @override
  Future<IResult<T>> uiActionRequest<T>(WalletUiAction<T> request) async {
    return ResultErr.fromException(WalletExceptionConst.walletIsNotavailable);
  }

  @override
  Future<IResult<bool>> switchNetwork(Chain switchChain) async {
    return ResultErr.fromException(WalletExceptionConst.walletIsNotavailable);
  }

  @override
  Future<IResult<T>> doActionInChainRequest<T>(ChainWalletAction<T> request) async {
    return ResultErr.fromException(WalletExceptionConst.walletIsNotavailable);
  }

  @override
  Future<IResult<T>> doRequest<T>(WalletActionWallet<T> request) async {
    return ResultErr.fromException(WalletExceptionConst.walletIsNotavailable);
  }

  @override
  Future<IResult<T>> onAccessWallet<T extends Object?>(
      Future<IResult<WalletInternalCallResponse<T>>> Function(
              TransfableMemoryWallet memoryWallet, AppBasicCryptoApi crypto)
          fn) async {
    return ResultErr.fromException(WalletExceptionConst.walletIsNotavailable);
  }

  @override
  Future<IResult<RESPONSE>> createAccess<RESPONSE extends WalletCredentialResponse>(
      WalletActionAccess<RESPONSE> action) async {
    return ResultErr.fromException(WalletExceptionConst.walletIsNotavailable);
  }

  @override
  Future<IResult<void>> dispose() async {
    storage.dispose();
    web3Storage.dispose();
    inChainWalletController.dispose();
    networks.clear();
    _status = WStatus.init;
    return ResultOk.okVoid;
  }

  @override
  Future<void> lock() async {}

  @override
  Future<IResult<void>> init() async {
    return ResultOk.okVoid;
  }
}

class WalletBackgroundController extends BaseWalletController {
  final WalletConfig config;
  WalletBackgroundController(this.config);

  final _lock = SafeAtomicLock();
  BaseWalletControllerContext? _contextNullable;
  BaseWalletControllerContext get _context {
    final context = _contextNullable;
    if (context == null) {
      throw WalletExceptionConst.walletIsNotavailable;
    }
    return context;
  }

  IResult<BaseWalletControllerContext> getContext() {
    final context = _contextNullable;
    if (context == null) {
      return ResultErr.fromException(WalletExceptionConst.walletIsNotavailable);
    }
    return ResultOk(context);
  }

  IWeb3WalletConnectController get walletConnect => _context.web3Controller;
  WStatus get status => _contextNullable?.status ?? WStatus.init;
  bool get hasWalletKey => _contextNullable?.hasWalletKey ?? false;
  @override
  List<Chain> chains() {
    return _contextNullable?.chains ?? [];
  }

  Chain get chain => _context.chain;

  @override
  Future<IResult<void>> dispose() async {
    return await _lock.run(() async {
      final controller = _contextNullable;
      _contextNullable = null;
      controller?.dispose();
      return ResultOk(null);
    });
  }

  @override
  Future<IResult<T>> doRequest<T>(WalletActionWallet<T> request) async {
    return ResultErr.fromException(WalletExceptionConst.walletIsNotavailable);
  }

  IWalletStorageManager get storage => _context.storage;
  IWeb3StorageManager get web3Storage => _context.web3Storage;
  @override
  Future<IResult<void>> init(InitWalletParams params) {
    return _lock.run(() async {
      if (_contextNullable != null) {
        return ResultErr.fromException(WalletExceptionConst.walletAlreadyInitialized);
      }
      final id = params.id;
      final storage = WalletStorageManager(id, config.database);
      final web3Storage = Web3StorageManager(id, config.database);
      final mainWallet = await storage.mainWallet();
      return mainWallet.andThenAsync((mainWallet) async {
        if (mainWallet == null) {
          return ResultErr.fromException(WalletExceptionConst.walletDoesNotExists);
        }
        final InChainWalletController controller = switch (mainWallet) {
          MainWallet() => ChainWalletControllerDefault(
              actionCallBack: <T>(request) async {
                return ResultErr.fromException(WalletExceptionConst.walletIsNotavailable);
              },
              bridgeControllerCallback: () => _context.bridgeController,
              config: config,
              wallet: mainWallet),
          _ => throw UnimplementedError()
          // ExternalWallet(:final connection) => ChainWalletControllerExternal(
          //     actionCallBack: <T>(request) async {
          //       return ResultErr.fromException(WalletExceptionConst.walletIsNotavailable);
          //     },
          //     bridgeControllerCallback: () => _context.bridgeController,
          //     config: config,
          //     wallet: mainWallet,
          //     session: WCMSession(connection)),
        };
        final accounts = await storage.readAccounts(controller);
        return accounts.andThenAsync((accounts) async {
          final allAccounts =
              WalletController.getAllNetworksAccounts(accounts, controller, id);
          final result = await IResult.anyError(
              allAccounts.newAccounts.map((e) => e.setupAccount()).toList());
          return result.andThenAsync(
            (_) async {
              final result = await IResult.anyError(
                  allAccounts.allAccounts.map((e) => e.init()).toList());
              return result.andThenAsync((value) async {
                final networks = allAccounts.accounts.map(
                  (key, value) => MapEntry(
                      key,
                      NetworkController.fromChains(
                          type: key, chains: value, id: id, database: config.database)),
                );
                final chains = allAccounts.allAccounts;
                final chain = allAccounts.allAccounts.firstWhereNullable(
                      (e) => e.network.value == mainWallet.network,
                    ) ??
                    chains.first;
                final BaseWalletControllerContext context = switch (mainWallet) {
                  MainWallet wallet => BackgroundWalletControllerContext(
                      storage: storage,
                      web3Storage: web3Storage,
                      chains: chains,
                      networks: networks,
                      inChainWalletController: controller,
                      chain: chain,
                      id: id,
                      wallet: wallet),
                };
                final init = await context.init();
                return init.map((_) {
                  _contextNullable = context;
                });
              });
            },
          );
        });
      });
    });
  }

  @override
  Future<void> lock() async {}

  @override
  Future<IResult<void>> login({String? password, bool? platformCredential}) async {
    return ResultErr.fromException(WalletExceptionConst.walletIsNotavailable);
  }

  @override
  IMainWallet get mainWallet => _context.wallet;

  @override
  T networkController<T extends APPNETWORKCONTROLLER>(NetworkType network) {
    return _context.networkController<T>(network);
  }

  Future<IResult<Web3APPData>> createWeb3Auth(Web3ApplicationAuthentication app,
      {List<NetworkType>? networks}) async {
    final context = getContext();
    return context
        .andThenAsync((context) => context.createWeb3Auth(app, networks: networks));
  }

  Future<IResult<void>> disconnectWeb3Chain(Web3ApplicationAuthentication app,
      {List<NetworkType>? networks}) async {
    final context = getContext();
    return context
        .andThenAsync((context) => context.disconnectWeb3Chain(app, networks: networks));
  }
}
