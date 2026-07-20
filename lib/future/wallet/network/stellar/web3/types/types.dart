import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/types/operations.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/web3/operations/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/web3/operations/sign_message.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/client/client.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/others/models/receipt_address.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/stellar.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';
import 'package:stellar_dart/stellar_dart.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/types/types.dart';

enum StellarWeb3TransactionType {
  v1("version_1"),
  feeBump("fee_bump_transaction");

  const StellarWeb3TransactionType(this.translate);
  final String translate;
}

class StellarWeb3TransactionDetails {
  final StellarSorobanTransactionDetais? soroban;
  final StellarMemoDetils memo;
  final IntegerBalance fee;
  final ReceiptAddress<StellarAddress> source;
  final StellarWeb3TransactionType type;
  final List<StellarTransactionOperationDetails> operations;
  final String contentStr;
  final Envelope envelope;
  StellarWeb3TransactionDetails(
      {required this.memo,
      required this.fee,
      required this.source,
      required this.envelope,
      required this.type,
      required this.soroban,
      required this.contentStr,
      required List<StellarTransactionOperationDetails> operations})
      : operations = operations.immutable;
}

class StellarSorobanTransactionDetais {
  final Map<String, dynamic> content;
  final String contentStr;
  final IntegerBalance feeSource;
  const StellarSorobanTransactionDetais._(
      {required this.content, required this.contentStr, required this.feeSource});
  factory StellarSorobanTransactionDetais(
      {required SorobanTransactionData sorobanData,
      required WalletStellarNetwork network}) {
    final content = sorobanData.resources.toJson();
    return StellarSorobanTransactionDetais._(
        content: content,
        contentStr: StringUtils.fromJson(content, indent: '  ', toStringEncodable: true),
        feeSource: IntegerBalance.token(sorobanData.resourceFee, network.token));
  }
}

abstract class Web3StellarStateController<RESPONSE, CLIENT extends StellarClient?,
        T extends Web3StellarRequestParam<RESPONSE>>
    extends Web3StateController<
        RESPONSE,
        StellarAddress,
        WalletStellarNetwork,
        StellarClient,
        CLIENT,
        IStellarAddress,
        StellarChain,
        Web3StellarChainAccount,
        T,
        Web3StellarRequest<RESPONSE, T>,
        Web3RequestResponseData<RESPONSE>,
        StellarWalletTransaction> {
  Web3StellarStateController({required super.walletProvider, required super.request});

  static BaseWeb3StateController findController(
      {required Web3StellarRequest request, required WalletProvider walletProvider}) {
    switch (request.params.method) {
      case Web3StellarRequestMethods.signMessage:
        return Web3StellarSignMessageStateController(
            walletProvider: walletProvider, request: request.cast());
      case Web3StellarRequestMethods.signTransaction:
      case Web3StellarRequestMethods.sendTransaction:
        return WebStellarSignTransactionStateController(
            walletProvider: walletProvider, request: request.cast());
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
  }
}

abstract class BaseWeb3StellarTransactionStateController<
        RESPONSE,
        T extends Web3StellarRequestParam<RESPONSE>,
        E extends IWeb3StellarTransactionData>
    extends Web3TransactionStateController<
        RESPONSE,
        StellarAddress,
        WalletStellarNetwork,
        IStellarAddress,
        StellarClient,
        StellarClient,
        StellarChain,
        Web3StellarChainAccount,
        T,
        Web3StellarRequest<RESPONSE, T>,
        E,
        IWeb3StellarTransaction<E>,
        IWeb3StellarSignedTransaction<E>,
        StellarWalletTransaction,
        SubmitTransactionSuccess<IWeb3StellarSignedTransaction<E>>> {
  BaseWeb3StellarTransactionStateController(
      {required super.walletProvider, required super.request});
}

abstract class IWeb3StellarTransactionData extends ITransactionData {}

class IWeb3StellarTransactionRawData extends IWeb3StellarTransactionData {
  final StellarWeb3TransactionDetails transactionInfo;
  final StellarAccountResponse accountInfo;
  final Envelope transaction;
  IWeb3StellarTransactionRawData(
      {required this.transaction,
      required this.accountInfo,
      required this.transactionInfo});
}

class IWeb3StellarTransaction<TXDATA extends IWeb3StellarTransactionData>
    extends ITransaction<TXDATA, IStellarAddress> {
  const IWeb3StellarTransaction({required super.account, required super.transactionData});
}

class IWeb3StellarSignedTransaction<TXDATA extends IWeb3StellarTransactionData>
    extends ISignedTransaction<IWeb3StellarTransaction<TXDATA>, TransactionV1Envelope> {
  IWeb3StellarSignedTransaction(
      {required super.transaction,
      required super.signatures,
      required super.finalTransactionData});
}
