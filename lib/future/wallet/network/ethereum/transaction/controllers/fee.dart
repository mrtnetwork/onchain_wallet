import 'dart:async';

import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/ethereum/utils.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/ethereum/client/ethereum.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';

mixin EthereumTransactionFeeController on DisposableMixin {
  WalletEthereumNetwork get network;
  EthereumNetworkClient get client;
  StreamSubscription<EthereumTransactionGasInfo>? _listener;
  final _lock = SafeAtomicLock();

  late final EthereumTransactionFeeData txFee = EthereumTransactionFeeData(
      select: EthereumTransactionFee.init(
          feeToken: network.token,
          mode: network.coinParam.supportEIP1559
              ? EthereumFeeMode.eip1559
              : EthereumFeeMode.legacy),
      feeToken: network.token,
      mode: network.coinParam.supportEIP1559
          ? EthereumFeeMode.eip1559
          : EthereumFeeMode.legacy);

  void _onUpdateFee(EthereumTransactionGasInfo fee) {
    final eip = fee.eip1559;
    final gasPrice = fee.gasPrice;
    final feeToken = network.token;
    if (gasPrice != null) {
      txFee.setDefaultFees([
        EthereumTransactionFee.legacy(
            feeToken: feeToken,
            gasLimit: fee.gasLimit,
            gasPrice: gasPrice,
            type: TxFeeTypes.normal),
      ]);
    } else if (eip != null) {
      txFee.setDefaultFees([
        EthereumTransactionFee.eip1559(
            feeToken: feeToken,
            gasLimit: fee.gasLimit,
            maxPriorityFeePerGas: eip.slow,
            baseFee: eip.baseFee,
            type: TxFeeTypes.slow),
        EthereumTransactionFee.eip1559(
            feeToken: feeToken,
            gasLimit: fee.gasLimit,
            maxPriorityFeePerGas: eip.normal,
            baseFee: eip.baseFee,
            type: TxFeeTypes.normal),
        EthereumTransactionFee.eip1559(
            feeToken: feeToken,
            gasLimit: fee.gasLimit,
            maxPriorityFeePerGas: eip.high,
            baseFee: eip.baseFee,
            type: TxFeeTypes.high),
      ]);
    }
  }

  void _setDefaultFee({String? error}) {
    txFee.setDefaultFees([
      EthereumTransactionFee.init(feeToken: network.token, error: error, mode: txFee.mode)
    ]);
  }

  Map<String, dynamic>? buildEstimateTx();
  BigInt getMaxFeeInput();
  int? get fixedGasLimit => null;

  Future<void> estimateFee() async {
    _lock.run(() {
      _listener?.cancel();
      _listener = null;
      final txJson = buildEstimateTx();
      _listener = _fetchGasFee(txJson: txJson).listen(_onUpdateFee);
    });
  }

  Stream<EthereumTransactionGasInfo> _fetchGasFee(
      {int defaultGasLimit = EthereumUtils.baseGasLimit, Map<String, dynamic>? txJson}) {
    final controller = SafeStreamController<EthereumTransactionGasInfo>(
        name: "EthereumTransactionFeeController");
    final Duration blockInterval = Duration(seconds: network.coinParam.averageBlockTime);
    bool isClosed = false;
    EthereumTransactionGasInfo? latestFee;
    int? gasLimit = fixedGasLimit;
    _setDefaultFee();

    Future<void> poll() async {
      if (isClosed) return;
      txFee.setPending();
      final gas = await IResult.call(() async {
        if (gasLimit == null) {
          if (txJson == null) {
            gasLimit = defaultGasLimit;
          } else {
            gasLimit = (await client.estimateGasLimit(txJson)).toInt();
          }
        }
        if (txFee.mode == EthereumFeeMode.eip1559) {
          final fee = await client.getHistoricalFee();
          return EthereumTransactionGasInfo(eip1559: fee, gasLimit: gasLimit!);
        } else {
          final gasPrice = await client.gasPrice();
          return EthereumTransactionGasInfo(gasPrice: gasPrice, gasLimit: gasLimit!);
        }
      });
      if (isClosed) return;
      gas.fold(
        onOk: (gas) {
          latestFee = gas;
          controller.add(gas);
        },
        onErr: (error) {
          if (latestFee == null) {
            _setDefaultFee(error: error.localizationError);
            isClosed = true;
            controller.close();
          } else {
            controller.add(latestFee!);
          }
        },
      );
      if (!isClosed) {
        await MethodUtils.delayed(duration: blockInterval);
        poll();
      }
    }

    controller.onListenListener(poll);
    controller.onCancelListener(() {
      isClosed = true;
    });

    return controller.stream();
  }

  Future<void> initFee({EthereumFeeMode? mode}) async {
    if (mode != null) {
      txFee.onUpdateMode(mode);
      _setDefaultFee();
    }

    _listener = _fetchGasFee().listen(_onUpdateFee);
  }

  @override
  void dispose() {
    super.dispose();
    _listener?.cancel();
    _listener = null;
    txFee.dispose();
  }
}
