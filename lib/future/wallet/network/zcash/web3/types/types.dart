import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/web3/operations/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/web3/operations/sign_message.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/client/client.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/zcash.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';
import 'package:zcash_dart/zcash.dart';

abstract class Web3ZcashStateController<RESPONSE, CLIENT extends ZcashNetworkClient?,
        T extends Web3ZcashRequestParam<RESPONSE>>
    extends Web3StateController<
        RESPONSE,
        ZcashAddress,
        WalletZcashNetwork,
        ZcashNetworkClient,
        CLIENT,
        IZcashAddress,
        ZcashChain,
        Web3ZcashChainAccount,
        T,
        Web3ZcashRequest<RESPONSE, T>,
        Web3RequestResponseData<RESPONSE>,
        ZcashWalletTransaction> {
  Web3ZcashStateController({required super.walletProvider, required super.request});

  static BaseWeb3StateController findController(
      {required Web3ZcashRequest request, required WalletProvider walletProvider}) {
    switch (request.params.method) {
      case Web3ZcashRequestMethods.signMessage:
        return Web3ZcashSignMessageStateController(
            walletProvider: walletProvider, request: request.cast());
      case Web3ZcashRequestMethods.sendTransaction:
        return WebZcashSignTransactionStateController(
            walletProvider: walletProvider, request: request.cast());
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
  }
}

abstract class BaseWeb3ZcashTransactionStateController<RESPONSE,
        T extends Web3ZcashRequestParam<RESPONSE>>
    extends Web3TransactionStateController<
        RESPONSE,
        ZcashAddress,
        WalletZcashNetwork,
        IZcashAddress,
        ZcashNetworkClient,
        ZcashNetworkClient,
        ZcashChain,
        Web3ZcashChainAccount,
        T,
        Web3ZcashRequest<RESPONSE, T>,
        IZcashTransactionData,
        IZcashTransaction,
        IZcashSignedTransaction,
        ZcashWalletTransaction,
        SubmitTransactionSuccess<IZcashSignedTransaction>> {
  BaseWeb3ZcashTransactionStateController(
      {required super.walletProvider, required super.request});
}
