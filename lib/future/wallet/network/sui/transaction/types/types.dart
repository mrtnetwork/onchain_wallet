import 'package:blockchain_utils/helper/helper.dart';
import 'package:on_chain/sui/sui.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

enum SuiTransactionOperations implements TransactionOperations {
  transfer("transfer"),
  tokenTransfer("transfer_token");

  @override
  final String value;
  const SuiTransactionOperations(this.value);
}

class SuiTransactionFee extends DefaultTransactionFee {
  final bool isSimulate;
  final BigInt gasPrice;
  final BigInt budget;
  final BigInt requiredFee;
  final SuiApiDryRunTransactionBlockResponse? simulateData;
  final String? simulateContent;

  SuiTransactionFee._(
      {required this.isSimulate,
      required this.gasPrice,
      required this.budget,
      required this.requiredFee,
      required super.fee,
      this.simulateContent,
      this.simulateData,
      super.error});

  factory SuiTransactionFee.fromBudget(
      {required BigInt gasPrice,
      required Token feeToken,
      required BigInt budget}) {
    return SuiTransactionFee._(
        budget: budget,
        gasPrice: gasPrice,
        fee: IntegerBalance.token(budget, feeToken),
        isSimulate: true,
        requiredFee: budget);
  }

  factory SuiTransactionFee(
      {SuiApiGasCostSummary? gasUsed,
      required BigInt gasPrice,
      required Token feeToken,
      SuiApiDryRunTransactionBlockResponse? simulateData,
      String? error,
      String? simulateContent}) {
    final safeOverHead = SuiTransactionConst.gasSafeOverHead;
    if (gasUsed != null) {
      final baseComputationGasOverHead = gasUsed.computationCost + safeOverHead;
      BigInt gasBudget = baseComputationGasOverHead +
          gasUsed.storageCost -
          gasUsed.storageRebate;
      if (gasBudget < baseComputationGasOverHead) {
        gasBudget = baseComputationGasOverHead;
      }
      return SuiTransactionFee._(
          budget: gasBudget,
          gasPrice: gasPrice,
          fee: IntegerBalance.token(gasBudget, feeToken),
          isSimulate: true,
          requiredFee: gasBudget,
          simulateData: simulateData,
          simulateContent: simulateContent);
    }
    return SuiTransactionFee._(
        budget: SuiTransactionConst.minGas,
        gasPrice: gasPrice,
        fee: IntegerBalance.token(SuiTransactionConst.minGas, feeToken),
        isSimulate: false,
        requiredFee: SuiTransactionConst.minGas,
        error: error,
        simulateData: simulateData);
  }

  @override
  List get variables =>
      [...super.variables, isSimulate, gasPrice, budget, requiredFee];
}

class SuiTransactionFeeData
    extends TransactionDefaultFeeData<SuiTransactionFee> {
  SuiTransactionFeeData({required super.select, required super.feeToken});
}

abstract class BaseSuiTransactionController<T extends ISuiTransactionData>
    extends TransactionStateController<
        SuiToken,
        WalletSuiNetwork,
        ISuiAddress,
        SuiNetworkClient,
        SuiChain,
        T,
        ISuiTransaction<T>,
        ISuiSignedTransaction<T>,
        SuiWalletTransaction,
        SubmitTransactionSuccess<ISuiSignedTransaction<T>>,
        SuiTransactionFeeData> {
  BaseSuiTransactionController(
      {required super.walletProvider,
      required super.account,
      required super.address});
}

abstract class ISuiTransactionData extends ITransactionData {
  final SuiTransactionFee fee;
  const ISuiTransactionData({required this.fee});
}

class ISuiTransactionDataTransfer extends ISuiTransactionData {
  final List<ITransactionDataTransferRecipient<SuiAddress>> recipients;
  ISuiTransactionDataTransfer({
    required List<ITransactionDataTransferRecipient<SuiAddress>> recipients,
    required super.fee,
  }) : recipients = recipients.immutable;
}

class ISuiTransactionDataTokenTransfer extends ISuiTransactionData {
  final List<ITransactionDataTransferTokenRecipient<SuiAddress, SuiToken>>
      recipients;
  final List<SuiApiCoinResponse> coins;
  final SuiToken token;
  ISuiTransactionDataTokenTransfer({
    required List<SuiApiCoinResponse> coins,
    required this.token,
    required List<ITransactionDataTransferTokenRecipient<SuiAddress, SuiToken>>
        recipients,
    required super.fee,
  })  : coins = coins.immutable,
        recipients = recipients.immutable;
}

class ISuiTransaction<TXDATA extends ISuiTransactionData>
    extends ITransaction<TXDATA, ISuiAddress> {
  const ISuiTransaction(
      {required super.account,
      required super.transactionData,
      required this.transaction});
  final SuiTransactionDataV1 transaction;

  ISuiTransaction<TXDATA> replaceTx(SuiTransactionDataV1 transaction) {
    return ISuiTransaction(
        account: account,
        transactionData: transactionData,
        transaction: transaction);
  }
}

class ISuiSignedTransaction<TXDATA extends ISuiTransactionData>
    extends ISignedTransaction<ISuiTransaction<TXDATA>, SuiTransactionDataV1> {
  final SuiBaseSignature suiSignature;
  ISuiSignedTransaction(
      {required super.transaction,
      required super.signatures,
      required super.finalTransactionData,
      required this.suiSignature});
}

class SuiSignedTransaction {
  final SuiBaseSignature suiSignature;
  final List<List<int>> signatures;
  final SuiTransactionDataV1 transaction;
  SuiSignedTransaction(
      {required this.suiSignature,
      required List<List<int>> signatures,
      required this.transaction})
      : signatures = signatures.map((e) => e.asImmutableBytes).toImutableList;
}
