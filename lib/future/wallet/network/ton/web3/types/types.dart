import 'package:blockchain_utils/helper/helper.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/web3/operations/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/web3/operations/sign_message.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/client/client.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/networks/ton/models/web3_transaction_info.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/ton.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';
import 'package:ton_dart/ton_dart.dart';

abstract class Web3TonStateController<RESPONSE, CLIENT extends TonNetworkClient?,
        T extends Web3TonRequestParam<RESPONSE>>
    extends Web3StateController<
        RESPONSE,
        TonAddress,
        WalletTonNetwork,
        TonNetworkClient,
        CLIENT,
        ITonAddress,
        TonChain,
        Web3TonChainAccount,
        T,
        Web3TonRequest<RESPONSE, T>,
        Web3RequestResponseData<RESPONSE>,
        TonWalletTransaction> {
  Web3TonStateController({required super.walletProvider, required super.request});

  static BaseWeb3StateController findController(
      {required Web3TonRequest request, required WalletProvider walletProvider}) {
    switch (request.params.method) {
      case Web3TonRequestMethods.signMessage:
        return Web3TonSignMessageStateController(
            walletProvider: walletProvider, request: request.cast());
      case Web3TonRequestMethods.sendTransaction:
      case Web3TonRequestMethods.signTransaction:
        return WebTonSendTransactionStateController(
            walletProvider: walletProvider, request: request.cast());
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
  }
}

abstract class BaseWeb3TonTransactionStateController<RESPONSE,
        T extends Web3TonRequestParam<RESPONSE>, E extends IWeb3TonTransactionData>
    extends Web3TransactionStateController<
        RESPONSE,
        TonAddress,
        WalletTonNetwork,
        ITonAddress,
        TonNetworkClient,
        TonNetworkClient,
        TonChain,
        Web3TonChainAccount,
        T,
        Web3TonRequest<RESPONSE, T>,
        E,
        IWeb3TonTransaction<E>,
        IWeb3TonSignedTransaction<E>,
        TonWalletTransaction,
        SubmitTransactionSuccess<IWeb3TonSignedTransaction<E>>> {
  BaseWeb3TonTransactionStateController(
      {required super.walletProvider, required super.request});
}

abstract class IWeb3TonTransactionData extends ITransactionData {
  const IWeb3TonTransactionData();
}

class IWeb3TonTransactionRawData extends IWeb3TonTransactionData {
  final List<TonWeb3TransactionMessageInfo> messages;
  final int timeout;
  final IntegerBalance totalAmount;
  IWeb3TonTransactionRawData(
      {required List<TonWeb3TransactionMessageInfo> messages,
      required this.timeout,
      required this.totalAmount})
      : messages = messages.immutable;
}

class IWeb3TonTransaction<TXDATA extends IWeb3TonTransactionData>
    extends ITransaction<TXDATA, ITonAddress> {
  final StateInit? stateInit;
  final Cell transaction;
  const IWeb3TonTransaction(
      {required super.account,
      required super.transactionData,
      required this.stateInit,
      required this.transaction});
}

class IWeb3TonSignedTransaction<TXDATA extends IWeb3TonTransactionData>
    extends ISignedTransaction<IWeb3TonTransaction<TXDATA>, Message> {
  Cell get externalMessage => beginCell().store(finalTransactionData).endCell();
  IWeb3TonSignedTransaction(
      {required super.transaction,
      required super.signatures,
      required super.finalTransactionData});
}
