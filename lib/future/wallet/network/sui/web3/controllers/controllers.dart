import 'package:on_chain_wallet/future/wallet/network/sui/web3/types/types.dart';
import 'package:on_chain_wallet/web3/web3/networks/sui/params/core/request.dart';

abstract class Web3SuiTransactionStateController<RESPONSE,
        T extends Web3SuiRequestParam<RESPONSE>, E extends IWeb3SuiTransactionData>
    extends BaseWeb3SuiTransactionStateController<RESPONSE, T, E> {
  Web3SuiTransactionStateController(
      {required super.walletProvider, required super.request});
}
