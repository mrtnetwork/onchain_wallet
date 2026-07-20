import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/web3/operations/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/web3/operations/sign_message.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/client/client.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/sui/models/types.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/others/others.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/sui.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/sui.dart';
import 'package:on_chain_wallet/wallet/models/transaction/types/types.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';

class SuiWeb3AccountChangeBalance {
  final IntegerBalance? amount;
  final String amountStr;
  final String coinType;
  final SuiToken? token;
  final ReceiptAddress<SuiAddress>? ownerAddres;
  final String owner;
  const SuiWeb3AccountChangeBalance(
      {required this.coinType,
      required this.amountStr,
      required this.owner,
      this.ownerAddres,
      this.amount,
      this.token});
}

class SuiTransferDetails extends TransferOutputDetails<SuiAddress> {
  SuiTransferDetails({
    required super.recipient,
    required Token token,
  }) : super(amount: IntegerBalance.zero(token, allowNegative: false));

  @override
  List get variables => [recipient];
}

abstract class Web3SuiStateController<RESPONSE, CLIENT extends SuiNetworkClient?,
        T extends Web3SuiRequestParam<RESPONSE>>
    extends Web3StateController<
        RESPONSE,
        SuiAddress,
        WalletSuiNetwork,
        SuiNetworkClient,
        CLIENT,
        ISuiAddress,
        SuiChain,
        Web3SuiChainAccount,
        T,
        Web3SuiRequest<RESPONSE, T>,
        Web3RequestResponseData<RESPONSE>,
        SuiWalletTransaction> {
  Web3SuiStateController({required super.walletProvider, required super.request});

  static BaseWeb3StateController findController(
      {required Web3SuiRequest request, required WalletProvider walletProvider}) {
    switch (request.params.method) {
      case Web3SuiRequestMethods.signMessage:
      case Web3SuiRequestMethods.signPersonalMessage:
        return Web3SuiSignMessageStateController(
            walletProvider: walletProvider, request: request.cast());
      case Web3SuiRequestMethods.signAndExecuteTransaction:
      case Web3SuiRequestMethods.signAndExecuteTransactionBlock:
      case Web3SuiRequestMethods.signTransaction:
      case Web3SuiRequestMethods.signTransactionBlock:
        return WebSuiSignTransactionStateController(
            walletProvider: walletProvider, request: request.cast());
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
  }
}

abstract class BaseWeb3SuiTransactionStateController<RESPONSE,
        T extends Web3SuiRequestParam<RESPONSE>, E extends IWeb3SuiTransactionData>
    extends Web3TransactionStateController<
        RESPONSE,
        SuiAddress,
        WalletSuiNetwork,
        ISuiAddress,
        SuiNetworkClient,
        SuiNetworkClient,
        SuiChain,
        Web3SuiChainAccount,
        T,
        Web3SuiRequest<RESPONSE, T>,
        E,
        IWeb3SuiTransaction<E>,
        IWeb3SuiSignedTransaction<E>,
        SuiWalletTransaction,
        SubmitSuiTransactionSuccess<E>> {
  BaseWeb3SuiTransactionStateController(
      {required super.walletProvider, required super.request});
}

abstract class IWeb3SuiTransactionData extends ITransactionData {
  const IWeb3SuiTransactionData();
}

class IWeb3SuiTransactionRawData extends IWeb3SuiTransactionData {
  IWeb3SuiTransactionRawData(
      {required this.transaction,
      required this.hasFee,
      required this.isAccountFeePayer,
      required this.txContent,
      this.owner,
      this.feePayer});
  final SuiTransactionDataV1 transaction;
  final bool hasFee;
  final bool isAccountFeePayer;
  final ReceiptAddress<SuiAddress>? owner;
  final ReceiptAddress<SuiAddress>? feePayer;
  final String txContent;
}

class IWeb3SuiTransaction<TXDATA extends IWeb3SuiTransactionData>
    extends ITransaction<TXDATA, ISuiAddress> {
  final SuiTransactionDataV1 transaction;

  const IWeb3SuiTransaction(
      {required super.account,
      required super.transactionData,
      required this.transaction});
}

class IWeb3SuiSignedTransaction<TXDATA extends IWeb3SuiTransactionData>
    extends ISignedTransaction<IWeb3SuiTransaction<TXDATA>, SuiTransactionDataV1> {
  final SuiBaseSignature suiSignature;
  String get signatureAsBase64 => suiSignature.toVariantBcsBase64();
  String get transactionAsBase64 => finalTransactionData.toVariantBcsBase64();
  IWeb3SuiSignedTransaction({
    required super.transaction,
    required super.signatures,
    required super.finalTransactionData,
    required this.suiSignature,
  });
}

class SubmitSuiTransactionSuccess<E extends IWeb3SuiTransactionData>
    extends SubmitTransactionSuccess<IWeb3SuiSignedTransaction<E>> {
  final SuiExcuteTransactionData excuteTransactionData;
  const SubmitSuiTransactionSuccess(
      {required super.signedTransaction,
      required super.txId,
      required this.excuteTransactionData,
      super.warning});
}
