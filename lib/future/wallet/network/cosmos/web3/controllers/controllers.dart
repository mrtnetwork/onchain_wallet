import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/controllers/memo.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/controllers/signer.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/web3/types/types.dart';
import 'package:on_chain_wallet/web3/web3/networks/cosmos/params/core/request.dart';

abstract class Web3CosmosTransactionStateController<RESPONSE,
        T extends Web3CosmosRequestParam<RESPONSE>, E extends IWeb3CosmosTransactionData>
    extends BaseWeb3CosmosTransactionStateController<RESPONSE, T, E>
    with
        CosmosTransactionApiController,
        CosmosTransactionMemoController,
        CosmosTransactionSignerController {
  Web3CosmosTransactionStateController(
      {required super.walletProvider, required super.request});
}
