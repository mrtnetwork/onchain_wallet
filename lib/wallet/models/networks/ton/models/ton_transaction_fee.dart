import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:ton_dart/ton_dart.dart';

class TonTransactionFeeDetails {
  final IntegerBalance storageFee;
  final IntegerBalance gasFee;
  final IntegerBalance actionPhase;
  final IntegerBalance fee;
  final IntegerBalance totalFee;
  final IntegerBalance internalFee;
  final bool isEstimated;
  final List<TonEmulatedMessage> internalMessages;
  bool get hasInternalFee => internalMessages.isNotEmpty;
  final bool success;
  final String? resultDescription;
  TonTransactionFeeDetails._(
      {required this.storageFee,
      required this.gasFee,
      required this.actionPhase,
      required this.fee,
      required this.isEstimated,
      required this.totalFee,
      required this.internalFee,
      this.resultDescription,
      required this.success,
      List<TonEmulatedMessage>? internalMessages})
      : internalMessages =
            List<TonEmulatedMessage>.unmodifiable(internalMessages ?? []);

  factory TonTransactionFeeDetails(
      {required BigInt actionPhase,
      required BigInt storageFee,
      required BigInt gasFee,
      required WalletTonNetwork network,
      List<TonEmulatedMessage> internalMessages = const [],
      String? resultDescription,
      required bool success,
      bool isEstimated = true}) {
    final IntegerBalance actionPhaseP = IntegerBalance.token(
        actionPhase, network.token,
        immutable: true, decimalPlaces: 8);
    final IntegerBalance storageFeeP = IntegerBalance.token(
        storageFee, network.token,
        immutable: true, decimalPlaces: 2);
    final IntegerBalance gasFeeP = IntegerBalance.token(gasFee, network.token,
        immutable: true, decimalPlaces: 2);
    final IntegerBalance fee = IntegerBalance.token(
        actionPhase + storageFee + gasFee, network.token,
        immutable: true, decimalPlaces: 2);
    final internalFess = internalMessages.fold(BigInt.zero,
        (previousValue, element) => previousValue + element.total.balance);
    final feeRate = BigRational.parseDecimal("1.1");

    final finalFee =
        (BigRational(internalFess + fee.balance) * feeRate).toBigInt();
    final IntegerBalance totalFees = IntegerBalance.token(
        finalFee, network.token,
        immutable: true, decimalPlaces: 2);

    return TonTransactionFeeDetails._(
        storageFee: storageFeeP,
        gasFee: gasFeeP,
        fee: totalFees,
        isEstimated: isEstimated,
        actionPhase: actionPhaseP,
        internalMessages: internalMessages,
        success: success,
        resultDescription: resultDescription,
        internalFee: IntegerBalance.token(internalFess, network.token),
        totalFee: totalFees);
  }
  factory TonTransactionFeeDetails.nonEstimate(WalletTonNetwork network) {
    return TonTransactionFeeDetails(
        actionPhase: BigInt.zero,
        storageFee: BigInt.zero,
        gasFee: BigInt.zero,
        isEstimated: false,
        success: true,
        network: network);
  }
}

class TonEmulatedMessage {
  final bool success;
  final IntegerBalance storageFee;
  final IntegerBalance gasFee;
  final IntegerBalance actionPhase;
  final IntegerBalance total;
  final TonAddress? destination;
  final String? resultDescription;

  const TonEmulatedMessage._(
      {required this.storageFee,
      required this.gasFee,
      required this.actionPhase,
      required this.total,
      required this.success,
      this.resultDescription,
      this.destination});

  factory TonEmulatedMessage(
      {required BigInt actionPhase,
      required BigInt storageFee,
      required BigInt gasFee,
      required bool success,
      required WalletTonNetwork network,
      TonAddress? destination,
      String? resultDescription}) {
    final IntegerBalance actionPhaseP = IntegerBalance.token(
        actionPhase, network.token,
        immutable: true, decimalPlaces: 2);
    final IntegerBalance storageFeeP = IntegerBalance.token(
        storageFee, network.token,
        immutable: true, decimalPlaces: 2);
    final IntegerBalance gasFeeP = IntegerBalance.token(gasFee, network.token,
        immutable: true, decimalPlaces: 2);
    final IntegerBalance totalFee = IntegerBalance.token(
        actionPhase + storageFee + gasFee, network.token,
        immutable: true, decimalPlaces: 2);
    return TonEmulatedMessage._(
        storageFee: storageFeeP,
        gasFee: gasFeeP,
        total: totalFee,
        actionPhase: actionPhaseP,
        success: success,
        destination: destination,
        resultDescription: resultDescription);
  }
}
