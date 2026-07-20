import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

mixin MoneroWeb3TransactionApiController on DisposableMixin {
  MoneroNetworkClient get client;
  WalletMoneroNetwork get network;
}
