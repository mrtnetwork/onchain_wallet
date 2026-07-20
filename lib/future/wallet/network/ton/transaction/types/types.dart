import 'package:blockchain_utils/helper/helper.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:ton_dart/ton_dart.dart';

enum TonTransactionOperations implements TransactionOperations {
  transfer("transfer");

  @override
  final String value;
  const TonTransactionOperations(this.value);
}

class TonTransactionFee extends DefaultTransactionFee {
  final IntegerBalance storageFee;
  final IntegerBalance gasFee;
  final IntegerBalance actionPhase;
  final bool isEstimated;
  final List<TonEmulatedMessage> internalMessages;
  bool get hasInternalFee => internalMessages.isNotEmpty;
  final bool success;
  final String? resultDescription;
  TonTransactionFee(
      {required this.storageFee,
      required this.gasFee,
      required this.actionPhase,
      required super.fee,
      required this.isEstimated,
      this.resultDescription,
      required this.success,
      List<TonEmulatedMessage>? internalMessages,
      super.error})
      : internalMessages = List<TonEmulatedMessage>.unmodifiable(internalMessages ?? []);

  factory TonTransactionFee.build(
      {required BigInt actionPhase,
      required BigInt storageFee,
      required BigInt gasFee,
      required Token feeToken,
      List<TonEmulatedMessage> internalMessages = const [],
      String? resultDescription,
      required bool success,
      bool isEstimated = true,
      String? error}) {
    final IntegerBalance actionPhaseP =
        IntegerBalance.token(actionPhase, feeToken, immutable: true, decimalPlaces: 2);
    final IntegerBalance storageFeeP =
        IntegerBalance.token(storageFee, feeToken, immutable: true, decimalPlaces: 2);
    final IntegerBalance gasFeeP =
        IntegerBalance.token(gasFee, feeToken, immutable: true, decimalPlaces: 2);
    final IntegerBalance fee = IntegerBalance.token(
        actionPhase + storageFee + gasFee, feeToken,
        immutable: true, decimalPlaces: 2);
    final internalFess = internalMessages.fold(
        BigInt.zero, (previousValue, element) => previousValue + element.total.balance);
    final IntegerBalance totalFees = IntegerBalance.token(
        internalFess + fee.balance, feeToken,
        immutable: true, decimalPlaces: 2);

    return TonTransactionFee(
        storageFee: storageFeeP,
        gasFee: gasFeeP,
        fee: totalFees,
        isEstimated: isEstimated,
        actionPhase: actionPhaseP,
        internalMessages: internalMessages,
        success: success,
        resultDescription: resultDescription,
        error: error);
  }

  factory TonTransactionFee.init(Token feeToken, {String? error}) {
    return TonTransactionFee.build(
        actionPhase: BigInt.zero,
        storageFee: BigInt.zero,
        gasFee: BigInt.zero,
        isEstimated: false,
        success: true,
        feeToken: feeToken,
        error: error);
  }
  @override
  List get variables => [
        ...super.variables,
        storageFee,
        gasFee,
        actionPhase,
        isEstimated,
        success,
        resultDescription
      ];
}

class TonTransactionFeeData extends TransactionDefaultFeeData<TonTransactionFee> {
  TonTransactionFeeData({required super.select, required super.feeToken});
}

abstract class BaseTonTransactionController extends TransactionStateController<
    TonJettonToken,
    WalletTonNetwork,
    ITonAddress,
    TonNetworkClient,
    TonChain,
    ITonTransactionData,
    ITonTransaction,
    ITonSignedTransaction,
    TonWalletTransaction,
    SubmitTransactionSuccess<ITonSignedTransaction>,
    TonTransactionFeeData> {
  BaseTonTransactionController(
      {required super.walletProvider, required super.account, required super.address});
}

class ITonTransactionData extends ITransactionData {
  final List<OutActionSendMsg> messages;
  final TonTransactionFee fee;
  final List<ITonTransactionDataTokenTransfer>? payment;
  final int seqno;
  final int timeout;
  ITonTransactionData(
      {required this.fee,
      required List<OutActionSendMsg> messages,
      required this.seqno,
      DateTime? timeout,
      List<ITonTransactionDataTokenTransfer>? payment})
      : messages = messages.immutable,
        payment = payment?.immutable,
        timeout = DateTimeUtils.secondsSinceEpoch(
            timeout ?? DateTime.now().add(const Duration(minutes: 2)));
}

class ITonTransactionDataTokenTransfer {
  final TonAddress recipient;
  final BigInt amount;
  final TonJettonToken? token;
  ITonTransactionDataTokenTransfer(
      {required this.recipient, required this.amount, this.token});
}

class ITonTransaction extends ITransaction<ITonTransactionData, ITonAddress> {
  final Cell transaction;
  final StateInit? stateInit;
  const ITonTransaction(
      {required super.account,
      required super.transactionData,
      required this.transaction,
      required this.stateInit});
}

class ITonSignedTransaction extends ISignedTransaction<ITonTransaction, Message> {
  Cell get externalMessage => beginCell().store(finalTransactionData).endCell();
  ITonSignedTransaction(
      {required super.transaction,
      required super.signatures,
      required super.finalTransactionData});
}

class TonSimulateTransaction {
  final Message message;
  final ITonAddress address;
  final List<OutActionSendMsg> messages;
  const TonSimulateTransaction(
      {required this.message, required this.address, required this.messages});
}

class TonSignedTransaction {
  final Message message;
  final List<List<int>> signatures;
  TonSignedTransaction({required this.message, required List<List<int>> signatures})
      : signatures = signatures.map((e) => e.asImmutableBytes).toImutableList;
}
