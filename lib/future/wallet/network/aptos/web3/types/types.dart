import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/web3/operations/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/web3/operations/sign_message.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/client/client.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/others/models/receipt_address.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/aptos.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';

abstract class Web3AptosStateController<RESPONSE, CLIENT extends AptosNetworkClient?,
        T extends Web3AptosRequestParam<RESPONSE>>
    extends Web3StateController<
        RESPONSE,
        AptosAddress,
        WalletAptosNetwork,
        AptosNetworkClient,
        CLIENT,
        IAptosAddress,
        AptosChain,
        Web3AptosChainAccount,
        T,
        Web3AptosRequest<RESPONSE, T>,
        Web3RequestResponseData<RESPONSE>,
        AptosWalletTransaction> {
  Web3AptosStateController({required super.walletProvider, required super.request});

  static BaseWeb3StateController findController(
      {required Web3AptosRequest request, required WalletProvider walletProvider}) {
    switch (request.params.method) {
      case Web3AptosRequestMethods.signMessage:
        return Web3AptosSignInMessageStateController(
            walletProvider: walletProvider, request: request.cast());
      case Web3AptosRequestMethods.signTransaction:
        return Web3AptosSignTransactionStateController(
            walletProvider: walletProvider, request: request.cast());
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
  }
}

abstract class BaseWeb3AptosTransactionStateController<RESPONSE,
        T extends Web3AptosRequestParam<RESPONSE>, E extends IWeb3AptosTransactionData>
    extends Web3TransactionStateController<
        RESPONSE,
        AptosAddress,
        WalletAptosNetwork,
        IAptosAddress,
        AptosNetworkClient,
        AptosNetworkClient,
        AptosChain,
        Web3AptosChainAccount,
        T,
        Web3AptosRequest<RESPONSE, T>,
        E,
        IWeb3AptosTransaction<E>,
        IWeb3AptosSignedTransaction<E>,
        AptosWalletTransaction,
        SubmitTransactionSuccess<IWeb3AptosSignedTransaction<E>>> {
  BaseWeb3AptosTransactionStateController(
      {required super.walletProvider, required super.request});
}

abstract class IWeb3AptosTransactionData extends ITransactionData {
  const IWeb3AptosTransactionData();
}

class IWeb3AptosTransactionRawData extends IWeb3AptosTransactionData {
  final AptosRawTransaction transaction;
  final ReceiptAddress<AptosAddress>? owner;
  final ReceiptAddress<AptosAddress>? feePayer;
  final List<ReceiptAddress<AptosAddress>>? secondarySignerAddresses;
  final String transactionContent;
  final String transactionType;
  final IntegerBalance fee;
  IWeb3AptosTransactionRawData(
      {required this.transaction,
      required this.transactionContent,
      required this.transactionType,
      required this.fee,
      this.owner,
      this.feePayer,
      List<ReceiptAddress<AptosAddress>>? secondarySignerAddresses})
      : secondarySignerAddresses = secondarySignerAddresses?.immutable;
}

class IWeb3AptosTransaction<TXDATA extends IWeb3AptosTransactionData>
    extends ITransaction<TXDATA, IAptosAddress> {
  const IWeb3AptosTransaction({required super.account, required super.transactionData});
}

class IWeb3AptosSignedTransaction<TXDATA extends IWeb3AptosTransactionData>
    extends ISignedTransaction<IWeb3AptosTransaction<TXDATA>, AptosSignedTransaction> {
  final AptosAccountAuthenticator accountAuthenticator;
  IWeb3AptosSignedTransaction(
      {required super.transaction,
      required super.signatures,
      required super.finalTransactionData,
      required this.accountAuthenticator});
}
