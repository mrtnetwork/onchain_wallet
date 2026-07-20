import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

mixin SubstrateWeb3TransactionApiController on DisposableMixin {
  SubstrateNetworkClient get client;
}
