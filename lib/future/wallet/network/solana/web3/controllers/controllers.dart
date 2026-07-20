import 'package:on_chain_wallet/future/wallet/network/solana/transaction/controllers/signer.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/web3/types/types.dart';
import 'package:on_chain_wallet/web3/web3/networks/solana/params/core/request.dart';
import 'provider.dart';

abstract class Web3SolanaTransactionStateController<RESPONSE,
        T extends Web3SolanaRequestParam<RESPONSE>, E extends IWeb3SolanaTransactionData>
    extends BaseWeb3SolanaTransactionStateController<RESPONSE, T, E>
    with SolanaWeb3TransactionApiController, SolanaTransactionSignerController {
  @override
  bool get showRequestAccount => false;
  Web3SolanaTransactionStateController(
      {required super.walletProvider, required super.request});
}
