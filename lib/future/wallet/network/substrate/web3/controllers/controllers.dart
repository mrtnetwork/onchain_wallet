import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/controllers/fee.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/web3/types/types.dart';
import 'package:on_chain_wallet/web3/web3/networks/substrate/params/core/request.dart';

abstract class Web3SubstrateTransactionStateController<
        RESPONSE,
        T extends Web3SubstrateRequestParam<RESPONSE>,
        E extends IWeb3SubstrateTransactionData>
    extends BaseWeb3SubstrateTransactionStateController<RESPONSE, T, E>
    with SubstrateTransactionApiController, SubstrateTransactionFeeController {
  Web3SubstrateTransactionStateController(
      {required super.walletProvider, required super.request});
}
