import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:cosmos_sdk/proto_messages/cosmos/base/v1beta1/models.dart';
import 'package:cosmos_sdk/proto_messages/cosmos/tx/v1beta1/models.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/wallet/constant/networks/cosmos.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/networks/cosmos/extension/extension.dart';
import 'package:on_chain_wallet/wallet/models/networks/cosmos/models/network_types.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/cw20.dart';

class CosmosWeb3SimulateMessageResponse {
  final String typeUrl;
  final String response;
  // final String? content;
  const CosmosWeb3SimulateMessageResponse(
      {required this.typeUrl, required this.response});
}

class CosmosWeb3SimulateEvent {
  final String type;
  final String key;
  final String value;
  const CosmosWeb3SimulateEvent(
      {required this.key, required this.value, required this.type});
}

class CosmosWeb3SimulateInfos {
  final BigInt gasUsed;
  final BigInt? gasWanted;
  final String? log;
  final String? content;
  final List<CosmosWeb3SimulateMessageResponse> messageResponse;
  final List<CosmosWeb3SimulateEvent> events;
  CosmosWeb3SimulateInfos._({
    required this.gasUsed,
    required this.gasWanted,
    required this.content,
    required List<CosmosWeb3SimulateMessageResponse> messageResponse,
    required List<CosmosWeb3SimulateEvent> events,
    required this.log,
  })  : messageResponse = messageResponse.immutable,
        events = events.immutable;
  factory CosmosWeb3SimulateInfos(SimulateResponse simulate) {
    final List<CosmosWeb3SimulateEvent> events = [];
    final simulateEvent = simulate.result?.events ?? [];
    for (final i in simulateEvent) {
      final type = i.type;
      if (type == null) continue;
      for (final e in i.attributes) {
        final key = e.key;
        final value = e.value;
        if (key == null || value == null) continue;
        events.add(CosmosWeb3SimulateEvent(key: key, value: value, type: type));
      }
    }
    final List<CosmosWeb3SimulateMessageResponse> msgResult = [];
    final msgResponses = simulate.result?.msgResponses ?? [];
    for (int i = 0; i < msgResponses.length; i++) {
      final response = msgResponses[i];
      final String? type = response.typeUrl;
      if (type == null) continue;
      String value;
      switch (response) {
        case AnyBinary():
          value = response.toBase64();
          break;
        case AnyJson():
          value =
              StringUtils.fromJson(response.value, indent: '', toStringEncodable: true);
          break;
      }
      msgResult.add(CosmosWeb3SimulateMessageResponse(typeUrl: type, response: value));
    }
    String log = simulate.result?.log ?? '';
    return CosmosWeb3SimulateInfos._(
        gasUsed: simulate.gasInfo?.gasUsed ?? BigInt.zero,
        gasWanted: simulate.gasInfo?.gasWanted,
        messageResponse: msgResult,
        events: events,
        log: log.isEmpty ? null : log,
        content: MethodUtils.fallbackOnException(() => StringUtils.fromJson(
            simulate.toJson(),
            indent: '',
            toStringEncodable: true)));
  }
}

class CosmosWeb3TransactionSimulate {
  final CosmosWeb3SimulateInfos? simulate;
  final String? simulateError;
  const CosmosWeb3TransactionSimulate._(this.simulate, this.simulateError);
  factory CosmosWeb3TransactionSimulate.simulate(CosmosWeb3SimulateInfos simulate) {
    return CosmosWeb3TransactionSimulate._(simulate, null);
  }
  factory CosmosWeb3TransactionSimulate.fail(String error) {
    return CosmosWeb3TransactionSimulate._(null, error);
  }
}

enum CosmosWeb3TransactionFeeStatus {
  pending,
  failed,
  success,
  idle;

  bool get isProgress => this == pending;
  bool get isSuccess => this == success;
  bool get isFailed => this == failed;
  bool get isIdle => this == idle;
}

class CosmosWeb3TransactionFeeToken {
  final CW20Token token;
  final IntegerBalance feeAmount;
  bool get hasAmount => feeAmount.largerThanZero;
  CosmosWeb3TransactionFeeToken({required this.token, required BigInt feeAmount})
      : feeAmount = IntegerBalance.token(feeAmount, token.token);
  Coin toCosmosCoin() {
    return Coin(denom: token.denom, amount: "${feeAmount.balance}");
  }
}

class CosmosWeb3TransactionFeeInfo with DisposableMixin, StreamStateController {
  final int totalMessage;
  final CosmosTransactionRequirment transactionRequirment;
  List<CosmosWeb3TransactionFeeToken> _fees;
  List<CosmosWeb3TransactionFeeToken> get fees => _fees;
  bool get isThorChain =>
      network.coinParam.networkType == CosmosNetworkTypes.thorAndForked;
  final List<CW20Token> feeTokens;

  List<CW20Token> _avalableFeeTokens = [];
  List<CW20Token> get avalableFeeTokens => _avalableFeeTokens;
  bool _allowAddFee = false;

  bool get allowAddFee => _allowAddFee;
  bool _isDefaultFee;
  bool get isDefaultFee => _isDefaultFee;
  BigInt _gasLimit = BigInt.zero;

  final String? payer;
  final WalletCosmosNetwork network;
  final String? granter;
  final bool allowSimulate;
  CosmosWeb3TransactionSimulate? _simulate;
  CosmosWeb3TransactionSimulate? get simulate => _simulate;

  CosmosWeb3TransactionFeeStatus _simulateStatus = CosmosWeb3TransactionFeeStatus.idle;
  CosmosWeb3TransactionFeeStatus get simulateStatus => _simulateStatus;

  TransactionStateStatus _status = TransactionStateStatus.error();
  TransactionStateStatus get status => _status;

  factory CosmosWeb3TransactionFeeInfo(
      {required List<CW20Token> feeTokens,
      required bool allowSimulate,
      required WalletCosmosNetwork network,
      required CosmosTransactionRequirment transactionRequirment,
      required int totalMessage,
      required Fee fee}) {
    final fees = fee.amount.map((e) {
      final feeToken =
          transactionRequirment.feeTokens.firstWhere((i) => i.denom == e.getDenom());
      return CosmosWeb3TransactionFeeToken(token: feeToken, feeAmount: e.getAmount());
    }).toList();
    if (fees.isEmpty && fee.gasLimit != null && fee.gasLimit != BigInt.zero) {
      final feeDenom = network.coinParam.getFeeToken();
      final feeToken =
          transactionRequirment.feeTokens.firstWhere((e) => e.denom == feeDenom.denom);
      final feeData = _buildDefaultFee(
          feeToken: feeToken,
          gasLimit: fee.gasLimit!,
          feeTokens: feeTokens,
          network: network,
          transactionRequirment: transactionRequirment,
          totalMessage: totalMessage);
      fees.add(feeData);
    }
    return CosmosWeb3TransactionFeeInfo._(
        fees: fees,
        gasLimit: fee.gasLimit ?? BigInt.zero,
        payer: fee.payer,
        feeTokens: feeTokens,
        allowSimulate: allowSimulate,
        network: network,
        transactionRequirment: transactionRequirment,
        totalMessage: totalMessage,
        granter: fee.granter,
        isDefaultFee: fee.amount.isEmpty);
  }

  CosmosWeb3TransactionFeeInfo._(
      {required List<CosmosWeb3TransactionFeeToken> fees,
      required BigInt gasLimit,
      required this.totalMessage,
      required this.transactionRequirment,
      this.payer,
      this.granter,
      required this.feeTokens,
      required this.allowSimulate,
      required this.network,
      bool isDefaultFee = false})
      : _gasLimit = gasLimit,
        _isDefaultFee = isDefaultFee,
        _fees = fees;

  static CosmosWeb3TransactionFeeToken _buildDefaultFee({
    required CW20Token feeToken,
    required BigInt gasLimit,
    required List<CW20Token> feeTokens,
    required WalletCosmosNetwork network,
    required CosmosTransactionRequirment transactionRequirment,
    required int totalMessage,
  }) {
    if (network.coinParam.networkType == CosmosNetworkTypes.thorAndForked) {
      BigInt fee = transactionRequirment.fixedNativeGas!;
      if (totalMessage > 1) {
        fee = fee * BigInt.from(totalMessage);
      }
      return CosmosWeb3TransactionFeeToken(token: feeToken, feeAmount: fee);
    }
    BigRational gasPrice = CosmosConst.avarageGasPrice;
    if (network.coinParam.networkType.isEthreum) {
      gasPrice = transactionRequirment.ethermintTxFee!;
    } else {
      final avarageFee = network.coinParam.getFeeToken(denom: feeToken.denom).getFee();
      gasPrice = BigRational.parseDecimal(avarageFee.price);
    }

    final fee = BigRational(gasLimit) * gasPrice;
    return CosmosWeb3TransactionFeeToken(token: feeToken, feeAmount: fee.toBigInt());
  }

  void setSimulate(CosmosWeb3TransactionSimulate simulate) {
    assert(simulateStatus.isProgress);
    final simulateData = simulate.simulate;
    if (simulateData == null) return;
    _simulate = simulate;
    if (_gasLimit == BigInt.zero) {
      _gasLimit = (BigRational(simulate.simulate!.gasUsed) * CosmosConst.feeMultiplier)
          .toBigInt();
    }
    if (fees.isEmpty) {
      final feeDenom = network.coinParam.getFeeToken();
      final feeToken =
          transactionRequirment.feeTokens.firstWhere((e) => e.denom == feeDenom.denom);
      final fee = _buildDefaultFee(
          feeToken: feeToken,
          gasLimit: gasLimit,
          feeTokens: feeTokens,
          network: network,
          transactionRequirment: transactionRequirment,
          totalMessage: totalMessage);
      fees.add(fee);
    }
    _simulateStatus = CosmosWeb3TransactionFeeStatus.success;
    onStateUpdated();
  }

  void setFail(CosmosWeb3TransactionSimulate simulate) {
    assert(simulateStatus.isProgress);
    _simulate = simulate;
    _simulateStatus = CosmosWeb3TransactionFeeStatus.failed;
    onStateUpdated();
  }

  void setPending() {
    if (!allowSimulate) return;
    assert(!simulateStatus.isSuccess);
    _simulateStatus = CosmosWeb3TransactionFeeStatus.pending;
    _simulate = null;
    onStateUpdated();
  }

  void onAddFeeToken(CW20Token? token) {
    if (token == null) return;
    if (_fees.any((e) => e.token == token)) return;
    final fee = CosmosWeb3TransactionFeeToken(token: token, feeAmount: BigInt.zero);
    _fees.add(fee);
    onStateUpdated();
  }

  void onRemoveFee(CosmosWeb3TransactionFeeToken fee) {
    _fees.remove(fee);
    onStateUpdated();
  }

  void onUpdateGasLimit(BigRational? gasLimit) {
    if (gasLimit == null || gasLimit.isNegative || gasLimit.isDecimal) return;
    _gasLimit = gasLimit.toBigInt();
    onStateUpdated();
  }

  void onUpdateFeeAmount(CosmosWeb3TransactionFeeToken token, BigInt? amount) {
    if (amount == null) return;
    token.feeAmount.updateBalance(amount);
    onStateUpdated();
  }

  TransactionStateStatus getStateStatus() {
    if (gasLimit == BigInt.zero) {
      return TransactionStateStatus.error(error: "gas_limit_validator".tr);
    }
    if (!isThorChain && fees.isEmpty) {
      return TransactionStateStatus.error(error: "at_least_one_fee_token_required".tr);
    }
    return TransactionStateStatus.ready();
  }

  void onStateUpdated() {
    _avalableFeeTokens =
        feeTokens.where((e) => !fees.any((e) => e.token == e.token)).toList();
    _allowAddFee = _avalableFeeTokens.isNotEmpty;
    final status = getStateStatus();
    _status = status;
    notify();
  }

  BigInt get gasLimit => _gasLimit;
  BigRational get gasLimitAsBigRational => BigRational(_gasLimit);

  Fee toTransactionFee() {
    return Fee(
        amount: fees.map((e) => e.toCosmosCoin()).toList(),
        gasLimit: _gasLimit,
        granter: granter,
        payer: payer);
  }

  AminoFee toAminoFee() {
    return AminoFee(
        amount: fees.map((e) => e.toCosmosCoin()).toList(),
        gas: _gasLimit,
        granter: granter,
        payer: payer);
  }
}
