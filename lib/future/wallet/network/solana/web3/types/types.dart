import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/web3/operations/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/web3/operations/sign_message.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/client/client.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/solana.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';
import 'transaction.dart';

abstract class Web3SolanaStateController<RESPONSE, CLIENT extends SolanaNetworkClient?,
        T extends Web3SolanaRequestParam<RESPONSE>>
    extends Web3StateController<
        RESPONSE,
        SolAddress,
        WalletSolanaNetwork,
        SolanaNetworkClient,
        CLIENT,
        ISolanaAddress,
        SolanaChain,
        Web3SolanaChainAccount,
        T,
        Web3SolanaRequest<RESPONSE, T>,
        Web3RequestResponseData<RESPONSE>,
        SolanaWalletTransaction> {
  Web3SolanaStateController({required super.walletProvider, required super.request});

  static BaseWeb3StateController findController(
      {required Web3SolanaRequest request, required WalletProvider walletProvider}) {
    switch (request.params.method) {
      case Web3SolanaRequestMethods.signMessage:
      case Web3SolanaRequestMethods.signIn:
        return Web3SolanaSignMessageStateController(
            walletProvider: walletProvider, request: request.cast());
      case Web3SolanaRequestMethods.sendTransaction:
      case Web3SolanaRequestMethods.signTransaction:
      case Web3SolanaRequestMethods.signAllTransactions:
      case Web3SolanaRequestMethods.signAndSendAllTransactions:
        return WebSolanaSignTransactionStateController(
            walletProvider: walletProvider, request: request.cast());
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
  }
}

abstract class BaseWeb3SolanaTransactionStateController<RESPONSE,
        T extends Web3SolanaRequestParam<RESPONSE>, E extends IWeb3SolanaTransactionData>
    extends Web3TransactionStateController<
        RESPONSE,
        SolAddress,
        WalletSolanaNetwork,
        ISolanaAddress,
        SolanaNetworkClient,
        SolanaNetworkClient,
        SolanaChain,
        Web3SolanaChainAccount,
        T,
        Web3SolanaRequest<RESPONSE, T>,
        E,
        IWeb3SolanaTransaction<E>,
        IWeb3SolanaSignedTransaction<E>,
        SolanaWalletTransaction,
        SubmitTransactionSuccess<IWeb3SolanaSignedTransaction<E>>> {
  BaseWeb3SolanaTransactionStateController(
      {required super.walletProvider, required super.request});
}

abstract class IWeb3SolanaTransactionData extends ITransactionData {}

class IWeb3SolanaTransactionRawData extends IWeb3SolanaTransactionData {
  final List<SolanaWeb3TransactionInfo> messagess;
  final bool isMultipleTransaction;
  final bool isSend;
  final bool canReplaceBlockHash;
  final bool isMultipleWithSameOwner;
  final SolanaSignAndSendAllTransactionMode mode;
  IWeb3SolanaTransactionRawData({
    required List<SolanaWeb3TransactionInfo> messagess,
    required this.isMultipleTransaction,
    required this.isSend,
    required this.canReplaceBlockHash,
    required this.isMultipleWithSameOwner,
    required this.mode,
  }) : messagess = messagess.immutable;
}

class IWeb3SolanaTransaction<TXDATA extends IWeb3SolanaTransactionData>
    extends ITransaction<TXDATA, ISolanaAddress> {
  const IWeb3SolanaTransaction({required super.account, required super.transactionData});
}

class IWeb3SolanaSignedTransaction<TXDATA extends IWeb3SolanaTransactionData>
    extends ISignedTransaction<IWeb3SolanaTransaction<TXDATA>,
        List<SolanaWeb3SignedTransactionInfo>> {
  IWeb3SolanaSignedTransaction({
    required super.transaction,
    required super.signatures,
    required super.finalTransactionData,
  });
}

class Web3SolanaSignParamsData {
  final List<int> payload;
  final ISolanaAddress address;
  final Web3SolanaSignParams params;
  Web3SolanaSignParamsData(
      {required this.address,
      required this.params,
      required this.method,
      required List<int> payload})
      : payload = payload.asImmutableBytes;
  final Web3SolanaRequestMethods method;
  bool get isSignIn => method == Web3SolanaRequestMethods.signIn;
}
