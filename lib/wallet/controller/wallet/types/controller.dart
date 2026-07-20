import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/chain/chain/typedef/types.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/models/others/models/wallet.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/config.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/hd_wallet.dart';
import 'package:on_chain_wallet/web3/walletconnect/types/controller.dart';

abstract class BaseAppWalletController {
  bool get isOpen;
  bool get isLock;
  bool get isUnlock;
  bool get isReadOnly;
  bool get isReady;
  bool get isSetup;
  Future<IResult<T>> doAction<T extends Object?>(
    WalletAction<T> request, {
    Duration? delay = APPConst.animationDuraion,
  });
  StreamValue<WalletEvent> get status;
  Future<void> lock();
  WalletEvent get latestEvent;
  WStatus get homePageStatus;
  List<HdWalletKey> get wallets;
  IMainWallet get wallet;
  IWeb3WalletConnectController get walletConnect;

  List<T> getChains<T extends APPCHAIN>();
  T? chainController<T extends APPNETWORKCONTROLLER>(NetworkType type);
  WalletConfig get config;
}
