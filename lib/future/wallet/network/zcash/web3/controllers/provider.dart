import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

mixin ZcashWeb3TransactionApiController on DisposableMixin {
  ZcashNetworkClient get client;
  WalletZcashNetwork get network;
}
