import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:cosmos_sdk/proto_messages/cosmos/tx/v1beta1/models.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/web3/operations/import_network.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/web3/operations/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/web3/operations/sign_message.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/client/client.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/cosmos.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';

class CosmosWeb3MessagesInfo {
  final String typeUrl;
  final String value;
  const CosmosWeb3MessagesInfo({required this.typeUrl, required this.value});
}

abstract class Web3CosmosStateController<RESPONSE, CLIENT extends CosmosNetworkClient?,
        T extends Web3CosmosRequestParam<RESPONSE>>
    extends Web3StateController<
        RESPONSE,
        CosmosBaseAddress,
        WalletCosmosNetwork,
        CosmosNetworkClient,
        CLIENT,
        ICosmosAddress,
        CosmosChain,
        Web3CosmosChainAccount,
        T,
        Web3CosmosRequest<RESPONSE, T>,
        Web3RequestResponseData<RESPONSE>,
        CosmosWalletTransaction> {
  Web3CosmosStateController({required super.walletProvider, required super.request});

  static BaseWeb3StateController findController(
      {required Web3CosmosRequest request, required WalletProvider walletProvider}) {
    switch (request.params.method) {
      case Web3CosmosRequestMethods.signMessage:
        return Web3CosmosSignMessageStateController(
            walletProvider: walletProvider, request: request.cast());
      case Web3CosmosRequestMethods.signTransactionAmino:
      case Web3CosmosRequestMethods.signTransactionDirect:
        return WebCosmosSignTransactionStateController(
            walletProvider: walletProvider, request: request.cast());
      case Web3CosmosRequestMethods.addNewChain:
        return Web3CosmosImportNetworkStateController(
            walletProvider: walletProvider, request: request.cast());
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
  }
}

abstract class BaseWeb3CosmosTransactionStateController<RESPONSE,
        T extends Web3CosmosRequestParam<RESPONSE>, E extends IWeb3CosmosTransactionData>
    extends Web3TransactionStateController<
        RESPONSE,
        CosmosBaseAddress,
        WalletCosmosNetwork,
        ICosmosAddress,
        CosmosNetworkClient,
        CosmosNetworkClient,
        CosmosChain,
        Web3CosmosChainAccount,
        T,
        Web3CosmosRequest<RESPONSE, T>,
        E,
        IWeb3CosmosTransaction<E>,
        IWeb3CosmosSignedTransaction<E>,
        CosmosWalletTransaction,
        SubmitTransactionSuccess<IWeb3CosmosSignedTransaction<E>>> {
  BaseWeb3CosmosTransactionStateController(
      {required super.walletProvider, required super.request});
}

abstract class IWeb3CosmosTransactionData extends ITransactionData {}

class IWeb3CosmosTransactionRawData extends IWeb3CosmosTransactionData {
  final List<CosmosWeb3MessagesInfo> messages;
  final TxBody? txBody;
  final String? memo;
  final AuthInfo auth;
  final BigInt accountNumber;
  IWeb3CosmosTransactionRawData(
      {required List<CosmosWeb3MessagesInfo> messages,
      required this.memo,
      required this.txBody,
      required this.auth,
      required this.accountNumber})
      : messages = messages.immutable;
}

class IWeb3CosmosTransaction<TXDATA extends IWeb3CosmosTransactionData>
    extends ITransaction<TXDATA, ICosmosAddress> {
  final SignDoc? signDoc;
  final AminoTx? aminoTransaction;
  final AuthInfo auth;
  final List<int> payloadBytes;
  IWeb3CosmosTransaction({
    required super.account,
    required super.transactionData,
    this.signDoc,
    this.aminoTransaction,
    required List<int> payloadBytes,
    required this.auth,
  }) : payloadBytes = payloadBytes.asImmutableBytes;
}

class IWeb3CosmosSignedTransaction<TXDATA extends IWeb3CosmosTransactionData>
    extends ISignedTransaction<IWeb3CosmosTransaction<TXDATA>,
        Web3CosmosSignTransactionResponse> {
  IWeb3CosmosSignedTransaction({
    required super.transaction,
    required super.signatures,
    required super.finalTransactionData,
  });
}
