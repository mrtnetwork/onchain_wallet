import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/web3/operations/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/web3/operations/sign_message.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/web3/operations/sign_psbt_transaction.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/client/client.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/bitcoin.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';

abstract class Web3BitcoinStateController<RESPONSE, CLIENT extends BitcoinNetworkClient?,
        T extends BaseWeb3BitcoinRequestParam<RESPONSE, Web3BitcoinChainAccount>>
    extends Web3StateController<
        RESPONSE,
        BitcoinNetworkAddress,
        WalletBitcoinNetwork,
        BitcoinNetworkClient,
        CLIENT,
        IBitcoinAddress,
        BitcoinChain,
        Web3BitcoinChainAccount,
        T,
        BaseWeb3BitcoinRequest<RESPONSE, Web3BitcoinChainAccount, T>,
        Web3RequestResponseData<RESPONSE>,
        BitcoinWalletTransaction> {
  Web3BitcoinStateController({required super.walletProvider, required super.request});

  static BaseWeb3StateController findController(
      {required BaseWeb3BitcoinRequest request, required WalletProvider walletProvider}) {
    switch (request.params.method) {
      case Web3BitcoinRequestMethods.signMessage:
      case Web3BitcoinRequestMethods.signPersonalMessage:
      case Web3BitcoinCashRequestMethods.signMessage:
      case Web3BitcoinCashRequestMethods.signPersonalMessage:
        return Web3BitcoinSignMessageStateController(
            walletProvider: walletProvider, request: request.cast());
      case Web3BitcoinRequestMethods.sendTransaction:
      case Web3BitcoinCashRequestMethods.sendTransaction:
        return Web3BitcoinSendTransactionStateController(
            walletProvider: walletProvider, request: request.cast());
      case Web3BitcoinRequestMethods.signTransaction:
      case Web3BitcoinCashRequestMethods.signTransaction:
        return Web3BitcoinSignTransactionStateController(
            walletProvider: walletProvider, request: request.cast());
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
  }
}

abstract class BaseWeb3BitcoinTransactionStateController<
        RESPONSE,
        T extends BaseWeb3BitcoinRequestParam<RESPONSE, Web3BitcoinChainAccount>,
        E extends IWeb3BitcoinTransactionData,
        TRANSACTION extends IWeb3BitcoinTransaction<E>,
        SIGNEDTX extends IWeb3BitcoinSignedTransaction<TRANSACTION, Object>>
    extends Web3TransactionStateController<
        RESPONSE,
        BitcoinNetworkAddress,
        WalletBitcoinNetwork,
        IBitcoinAddress,
        BitcoinNetworkClient,
        BitcoinNetworkClient,
        BitcoinChain,
        Web3BitcoinChainAccount,
        T,
        BaseWeb3BitcoinRequest<RESPONSE, Web3BitcoinChainAccount, T>,
        E,
        TRANSACTION,
        SIGNEDTX,
        BitcoinWalletTransaction,
        SubmitTransactionSuccess<SIGNEDTX>> {
  BaseWeb3BitcoinTransactionStateController(
      {required super.walletProvider, required super.request});
}

abstract class IWeb3BitcoinTransactionData extends ITransactionData {}

class IWeb3BitcoinSignPsbtTransactionData extends IWeb3BitcoinTransactionData {
  IWeb3BitcoinSignPsbtTransactionData({
    required List<BitcoinPsbtInputWithAccount> inputs,
    required List<BitcoinPsbtInputWithAccount> accountInputs,
    required List<PsbtBitcoinOutputWithBalance> outputs,
    required this.psbt,
    required this.totalOutput,
    required this.fee,
    required this.builder,
    required this.totalInput,
    required this.totalAccountInput,
  })  : inputs = inputs.immutable,
        accountInputs = accountInputs.immutable,
        outputs = outputs.immutable;
  final List<PsbtBitcoinOutputWithBalance> outputs;
  final List<BitcoinPsbtInputWithAccount> inputs;
  final List<BitcoinPsbtInputWithAccount> accountInputs;
  final Psbt psbt;
  final IntegerBalance totalOutput;
  final IntegerBalance totalInput;
  final IntegerBalance totalAccountInput;
  final IntegerBalance fee;
  final PsbtBuilder builder;
}

class IWeb3BitcoinSendTransactionData extends IWeb3BitcoinTransactionData {
  final List<PsbtBitcoinOutputWithBalance> requestOutputs;
  final IBitcoinAddress? requireAccount;
  final List<UtxoWithAddress> utxos;
  final bool enableRBF;
  final BitcoinOrdering ordering;
  final BitcoinTransactionFee fee;
  final List<BitcoinBaseOutput> outputs;
  IWeb3BitcoinSendTransactionData({
    required List<PsbtBitcoinOutputWithBalance> requestOutputs,
    required List<UtxoWithAddress> utxos,
    required List<BitcoinBaseOutput> outputs,
    required this.enableRBF,
    required this.ordering,
    required this.fee,
    this.requireAccount,
  })  : requestOutputs = requestOutputs.immutable,
        utxos = utxos.immutable,
        outputs = outputs.immutable;
}

abstract class IWeb3BitcoinTransaction<TXDATA extends IWeb3BitcoinTransactionData>
    extends ITransaction<TXDATA, IBitcoinAddress> {
  final List<IBitcoinAddress> accounts;
  IWeb3BitcoinTransaction(
      {required super.account,
      required super.transactionData,
      required List<IBitcoinAddress> accounts})
      : accounts = accounts.immutable;
}

class IWeb3BitcoinPsbtTransaction
    extends IWeb3BitcoinTransaction<IWeb3BitcoinSignPsbtTransactionData> {
  IWeb3BitcoinPsbtTransaction(
      {required super.account, required super.transactionData, required super.accounts});
}

class IWeb3BitcoinPaymentTransaction
    extends IWeb3BitcoinTransaction<IWeb3BitcoinSendTransactionData> {
  final BasedBitcoinTransacationBuilder transnaction;
  IWeb3BitcoinPaymentTransaction(
      {required super.account,
      required super.transactionData,
      required super.accounts,
      required this.transnaction});
}

abstract class IWeb3BitcoinSignedTransaction<
    TX extends IWeb3BitcoinTransaction<IWeb3BitcoinTransactionData>,
    FINALTX extends Object> extends ISignedTransaction<TX, FINALTX> {
  IWeb3BitcoinSignedTransaction(
      {required super.transaction,
      required super.signatures,
      required super.finalTransactionData});
}

class IWeb3BitcoinSignedPSBTTransaction
    extends IWeb3BitcoinSignedTransaction<IWeb3BitcoinPsbtTransaction, String> {
  IWeb3BitcoinSignedPSBTTransaction(
      {required super.transaction,
      required super.signatures,
      required super.finalTransactionData});
}

class IWeb3BitcoinSignedPaymentTransaction extends IWeb3BitcoinSignedTransaction<
    IWeb3BitcoinPaymentTransaction, BtcTransaction> {
  IWeb3BitcoinSignedPaymentTransaction(
      {required super.transaction,
      required super.signatures,
      required super.finalTransactionData});
}
