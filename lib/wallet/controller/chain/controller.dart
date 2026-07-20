import 'dart:async';
import 'package:on_chain_bridge/models/device/models/platform.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/onchain/types/types.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/client.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/config.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/hd_wallet.dart';

sealed class InChainWalletController {
  void dispose();
  Stream<ChainEvent> chainStream(int id);
  void add(ChainEvent event);
  Future<IResult<T>> doAction<T>(ChainWalletAction<T> request);
  WalletConfig get config;
  IMainWallet get wallet;
  AppPlatform get walletPlatform;
}

typedef CbWalletAction = Future<IResult<T>> Function<T>(ChainWalletAction<T> request);
typedef CbGetBridgeController = IBridgeClient Function();

abstract mixin class IChainWalletControllerDefault {
  late final SafeStreamController<ChainEvent> _chainEventController =
      SafeStreamController.broadcast(name: "IChainWalletControllerDefault");
  void add(ChainEvent event) {
    _chainEventController.addIfListener(event);
  }

  Stream<ChainEvent> chainStream(int id) {
    return _chainEventController.stream().where((e) => e.chainId == id);
  }

  void dispose() {
    _chainEventController.close();
  }
}

class ChainWalletControllerDefault
    with IChainWalletControllerDefault
    implements InChainWalletController {
  @override
  final WalletConfig config;
  @override
  final MainWallet wallet;
  final CbWalletAction _doAction;
  ChainWalletControllerDefault(
      {required CbWalletAction actionCallBack,
      required this.config,
      required CbGetBridgeController bridgeControllerCallback,
      required this.wallet})
      : _doAction = actionCallBack;

  @override
  void dispose() {
    _chainEventController.close();
  }

  @override
  Future<IResult<T>> doAction<T>(ChainWalletAction<T> request) {
    return _doAction(request);
  }

  @override
  AppPlatform get walletPlatform => config.platform;
}

class ChainWalletControllerExternal
    with IChainWalletControllerDefault
    implements InChainWalletController {
  @override
  final WalletConfig config;
  @override
  final ExternalWallet wallet;
  final WCMSession session;
  ChainWalletControllerExternal(
      {required CbWalletAction actionCallBack,
      required this.config,
      required CbGetBridgeController bridgeControllerCallback,
      required this.wallet,
      required this.session})
      : _doAction = actionCallBack;
  final CbWalletAction _doAction;

  @override
  void dispose() {
    _chainEventController.close();
  }

  @override
  Future<IResult<T>> doAction<T>(ChainWalletAction<T> request) {
    return _doAction(request);
  }

  @override
  AppPlatform get walletPlatform => config.platform;
}
