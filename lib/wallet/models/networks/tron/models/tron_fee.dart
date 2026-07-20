import 'package:on_chain_wallet/crypto/networks/tron/tron.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain/on_chain.dart';

import 'tron_account_info.dart';

enum TronFeeLimitType {
  def("default"),
  custom("custom");

  final String value;
  const TronFeeLimitType(this.value);
}

class TronFee {
  TronFee._(
      {required this.burnBandwidth,
      required this.burnEnergy,
      required this.consumedBandwidth,
      required this.connsumedEnergy,
      required this.totalBurn,
      required this.burnedForResource,
      required IntegerBalance feeLimit,
      IntegerBalance? custommFee})
      : _feeLimit = feeLimit,
        _customFeeLimit = custommFee;
  final int burnBandwidth;
  final int burnEnergy;

  final int consumedBandwidth;
  final int connsumedEnergy;

  late final int stackedBandWidth = consumedBandwidth - burnBandwidth;
  late final int stackedEnergy = connsumedEnergy - burnEnergy;
  final IntegerBalance burnedForResource;
  final IntegerBalance totalBurn;
  final IntegerBalance _feeLimit;
  final IntegerBalance? _customFeeLimit;
  IntegerBalance get feeLimit => _customFeeLimit ?? _feeLimit;
  late final TronFeeLimitType feeLimitType =
      _customFeeLimit == null ? TronFeeLimitType.def : TronFeeLimitType.custom;
  TronFee setCustomFeeLimit({
    IntegerBalance? customFeeLimit,
  }) {
    return TronFee._(
      burnBandwidth: burnBandwidth,
      burnedForResource: burnedForResource,
      burnEnergy: burnEnergy,
      consumedBandwidth: consumedBandwidth,
      connsumedEnergy: connsumedEnergy,
      totalBurn: totalBurn,
      feeLimit: _feeLimit,
      custommFee: customFeeLimit,
    );
  }

  factory TronFee.calculate(
      {required TransactionRaw raw,
      required TronChainParameters chainParameters,
      required TronAccountResourceInfo resource,
      required WalletTronNetwork network,
      int signature = 1,
      bool isNewAccount = false,
      int consumedEnergy = 0,
      bool hasMemo = false}) {
    final tr = Transaction(
        rawData: raw,
        signature: List.generate(
            signature, (index) => List<int>.filled(TronUtils.signatureLength, 1)));
    final BigInt transactionFee = BigInt.from(chainParameters.getTransactionFee!);
    final size = tr.length + TronUtils.tronFeeRequiredSize;
    BigInt totalBurn = BigInt.zero;
    BigInt energy = BigInt.from(consumedEnergy);
    BigInt bandWidth = BigInt.from(size);
    BigInt burnedForResource = BigInt.zero;
    if (isNewAccount) {
      burnedForResource += BigInt.from(chainParameters.getCreateAccountFee!);
      totalBurn += BigInt.from(chainParameters.getCreateNewAccountFeeInSystemContract!);
    }
    if (hasMemo) {
      totalBurn += BigInt.from(chainParameters.getMemoFee!);
    }
    if (signature > 1) {
      totalBurn += BigInt.from(chainParameters.getMultiSignFee!);
    }
    switch (raw.contract.first.type) {
      case TransactionContractType.assetIssueContract:
        totalBurn += chainParameters.getAssetIssueFee!;
        break;
      case TransactionContractType.accountPermissionUpdateContract:
        totalBurn += chainParameters.getUpdateAccountPermissionFee!;
        break;
      case TransactionContractType.witnessCreateContract:
        totalBurn += chainParameters.getAccountUpgradeCost!;
        break;
      default:
    }
    energy = energy - resource.howManyEnergy;
    if (energy.isNegative) {
      energy = BigInt.zero;
    }

    final BigInt consumedBandwidth = bandWidth;
    if (resource.howManyBandwIth > bandWidth && signature == 1) {
      bandWidth = BigInt.zero;
    }
    final totalBandWidth = bandWidth;
    totalBurn += totalBandWidth * transactionFee;
    totalBurn += burnedForResource;
    totalBurn += energy * BigInt.from(chainParameters.getEnergyFee!);
    BigInt feeLimit = TronHelper.toSun("10");
    if (totalBurn > feeLimit) {
      feeLimit = totalBurn;
    }

    return TronFee._(
      burnBandwidth: totalBandWidth.toInt(),
      burnEnergy: energy.toInt(),
      consumedBandwidth: consumedBandwidth.toInt(),
      connsumedEnergy: consumedEnergy,
      totalBurn: IntegerBalance.token(totalBurn, network.token),
      feeLimit: IntegerBalance.token(feeLimit, network.token),
      burnedForResource: IntegerBalance.token(burnedForResource, network.token),
    );
  }

  late final bool feeLimitError = feeLimit.balance < totalBurn.balance;
}
