import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain/ethereum/ethereum.dart';

import 'ethereum_fee.dart';

class EthereumInitFee {
  final BigInt? gasPrice;
  final BigInt? maxPriorityFeePerGas;
  final BigInt? maxFeePerGas;
  final int? gasLimit;
  const EthereumInitFee(
      {this.gasPrice,
      this.maxFeePerGas,
      this.maxPriorityFeePerGas,
      this.gasLimit});

  bool get isEip1559Metrics =>
      maxFeePerGas != null && maxPriorityFeePerGas != null;
  bool get isLegacyFeeMetrics => gasPrice != null;
  bool get hasGasMetrics => isEip1559Metrics || isLegacyFeeMetrics;
  bool get hasFee => hasGasMetrics || gasLimit != null;

  EthereumFee? toFee(
      {required FeeHistorical? feeHistorical,
      required BigInt? gasPrice,
      required int gasLimit,
      required WalletEthereumNetwork network}) {
    if (!hasFee || (feeHistorical == null && gasPrice == null)) return null;
    if (feeHistorical != null) {
      return EthereumFee.eip1559(network, this.gasLimit ?? gasLimit,
          maxPriorityFeePerGas ?? feeHistorical.normal, feeHistorical.baseFee,
          maxFeePerGas: maxFeePerGas);
    } else {
      return EthereumFee.legacy(
          network, this.gasLimit ?? gasLimit, this.gasPrice ?? gasPrice!);
    }
  }
}
