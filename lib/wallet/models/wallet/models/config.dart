import 'package:on_chain_bridge/models/device/models/platform.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/api/core.dart';
import 'package:on_chain_wallet/repository/repository.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/ui_actions.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

abstract class WalletConfig {
  const WalletConfig();
  CbUiActionRequest get uiAction;
  AppContext get context;
  AppBasicCryptoApi get cryptoLib => context.cryptoLib;
  IAppDatabaseApi get database => context.database;
  INetApi get netApi => context.netApi;
  AppPlatform get platform => context.platform;
}

class WalletConfigDefault extends WalletConfig {
  @override
  final CbUiActionRequest uiAction;
  @override
  final AppContext context;
  const WalletConfigDefault({
    required this.uiAction,
    required this.context,
  });
}

class WalletConfigBackground extends WalletConfig {
  @override
  final AppContext context;
  const WalletConfigBackground(this.context);

  Future<IResult<T>> onUtiAction<T>(WalletUiAction<T> _) async {
    return ResultErr.fromException(AppExceptionConst.walletContextNotAvailable);
  }

  @override
  CbUiActionRequest get uiAction => onUtiAction;
}

class InitWalletParams {
  final bool isBackup;
  final String id;
  const InitWalletParams({
    required this.id,
    this.isBackup = false,
  });
}
