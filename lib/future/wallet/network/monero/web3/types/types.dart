import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/web3/operations/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/web3/operations/sign_message.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/client/client.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/monero.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';

abstract class Web3MoneroStateController<RESPONSE, CLIENT extends MoneroNetworkClient?,
        T extends Web3MoneroRequestParam<RESPONSE>>
    extends Web3StateController<
        RESPONSE,
        MoneroAddress,
        WalletMoneroNetwork,
        MoneroNetworkClient,
        CLIENT,
        IMoneroAddress,
        MoneroChain,
        Web3MoneroChainAccount,
        T,
        Web3MoneroRequest<RESPONSE, T>,
        Web3RequestResponseData<RESPONSE>,
        MoneroWalletTransaction> {
  Web3MoneroStateController({required super.walletProvider, required super.request});

  static BaseWeb3StateController findController(
      {required Web3MoneroRequest request, required WalletProvider walletProvider}) {
    switch (request.params.method) {
      case Web3MoneroRequestMethods.signMessage:
        return Web3MoneroSignMessageStateController(
            walletProvider: walletProvider, request: request.cast());
      case Web3MoneroRequestMethods.sendTransaction:
        return WebMoneroSignTransactionStateController(
            walletProvider: walletProvider, request: request.cast());
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
  }
}

abstract class BaseWeb3MoneroTransactionStateController<RESPONSE,
        T extends Web3MoneroRequestParam<RESPONSE>>
    extends Web3TransactionStateController<
        RESPONSE,
        MoneroAddress,
        WalletMoneroNetwork,
        IMoneroAddress,
        MoneroNetworkClient,
        MoneroNetworkClient,
        MoneroChain,
        Web3MoneroChainAccount,
        T,
        Web3MoneroRequest<RESPONSE, T>,
        IMoneroTransactionData,
        IMoneroTransaction,
        IMoneroSignedTransaction,
        MoneroWalletTransaction,
        SubmitTransactionSuccess<IMoneroSignedTransaction>> {
  BaseWeb3MoneroTransactionStateController(
      {required super.walletProvider, required super.request});
}
