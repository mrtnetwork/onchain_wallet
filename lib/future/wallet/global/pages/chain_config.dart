import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';

typedef ONCREATECHAINCONFIG<CONFIG extends ChainConfig> = CONFIG Function();

abstract mixin class ChainConfigStateController<
    T extends APPCHAIN,
    CONFIG extends ChainConfig,
    CONTROLLER extends APPNETWORKCONTROLLERCHAINCONFIG<T, CONFIG>> {
  Future<CONFIG> getChainConfig(
      {required WalletProvider walletProvider,
      required NetworkType type,
      required ONCREATECHAINCONFIG<CONFIG> onCreate}) async {
    final controller = walletProvider.wallet.chainController<CONTROLLER>(type);
    final config = await controller?.getConfig();
    return config?.fold(
          onOk: (value) => value,
          onErr: (error) => onCreate(),
        ) ??
        onCreate();
  }

  Future<void> updateChainConfig({
    required WalletProvider walletProvider,
    required CONFIG config,
    required NetworkType type,
  }) async {
    final controller = walletProvider.wallet.chainController<CONTROLLER>(type);
    assert(controller != null);
    await controller?.updateConfig(config);
  }
}
