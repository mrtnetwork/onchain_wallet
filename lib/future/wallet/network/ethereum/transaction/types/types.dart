import 'dart:async';

import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:on_chain/ethereum/ethereum.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/crypto/networks/ethereum/utils.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

enum EthereumFeeMode {
  eip1559,
  legacy;

  bool get isEIP1559 => this == EthereumFeeMode.eip1559;
}

class EthereumTransactionFee extends TransactionFee {
  final EthereumFeeMode ethereumFeeMode;
  final int gasLimit;
  final BigInt? gasPrice;
  final BigInt? maxFeePerGas;
  final BigInt? maxPriorityFeePerGas;

  EthereumTransactionFee._(
      {required this.gasLimit,
      this.gasPrice,
      this.maxFeePerGas,
      this.maxPriorityFeePerGas,
      required super.type,
      required super.fee,
      super.error,
      required this.ethereumFeeMode});
  factory EthereumTransactionFee.init({
    required EthereumFeeMode mode,
    required Token feeToken,
    String? error,
  }) {
    return EthereumTransactionFee._(
      gasLimit: EthereumUtils.baseGasLimit,
      gasPrice: mode.isEIP1559 ? null : BigInt.zero,
      fee: IntegerBalance.zero(feeToken, immutable: true, allowNegative: false),
      type: TxFeeTypes.normal,
      ethereumFeeMode: mode,
      error: error,
      maxFeePerGas: mode.isEIP1559 ? BigInt.zero : null,
      maxPriorityFeePerGas: mode.isEIP1559 ? BigInt.zero : null,
    );
  }
  factory EthereumTransactionFee.legacy(
      {required Token feeToken,
      required int gasLimit,
      required BigInt gasPrice,
      required TxFeeTypes type}) {
    final fee = gasPrice * BigInt.from(gasLimit);
    return EthereumTransactionFee._(
        gasLimit: gasLimit,
        gasPrice: gasPrice,
        fee: IntegerBalance.token(fee, feeToken, immutable: true, allowNegative: false),
        type: type,
        ethereumFeeMode: EthereumFeeMode.legacy);
  }
  factory EthereumTransactionFee.eip1559(
      {required Token feeToken,
      required int gasLimit,
      required BigInt maxPriorityFeePerGas,
      required BigInt baseFee,
      BigInt? maxFeePerGas,
      required TxFeeTypes type}) {
    final mFeePerGas = maxFeePerGas ?? maxPriorityFeePerGas + baseFee;
    final fee = mFeePerGas * BigInt.from(gasLimit);
    return EthereumTransactionFee._(
        gasLimit: gasLimit,
        maxFeePerGas: mFeePerGas,
        maxPriorityFeePerGas: maxPriorityFeePerGas,
        fee: IntegerBalance.token(fee, feeToken, immutable: true, allowNegative: false),
        type: type,
        ethereumFeeMode: EthereumFeeMode.eip1559);
  }
}

class EthereumTransactionGasInfo {
  final FeeHistorical? eip1559;
  final BigInt? gasPrice;
  final int gasLimit;
  const EthereumTransactionGasInfo({this.eip1559, this.gasPrice, required this.gasLimit});
}

class EthereumTransactionFeeData
    extends TransactionDynamicFeeData<EthereumTransactionFee> {
  EthereumFeeMode _mode;
  EthereumFeeMode get mode => _mode;
  EthereumTransactionFeeData(
      {required super.select, required super.feeToken, required EthereumFeeMode mode})
      : _mode = mode;

  void onUpdateMode(EthereumFeeMode mode) {
    _mode = mode;
  }

  @override
  EthereumTransactionFee createManualFee(BigInt amount) {
    throw UnimplementedError();
  }
}

enum EthereumTransactionOperations implements TransactionOperations {
  transfer("transfer"),
  tokenTransfer("transfer_erc20");

  @override
  final String value;
  const EthereumTransactionOperations(this.value);
}

typedef ONUPDATEETHEREUMTXMEMO = Future<String?> Function(String?);

abstract class BaseEthereumTransactionController<TXDATA extends IEthereumTransactionData>
    extends TransactionStateController<
        ETHERC20Token,
        WalletEthereumNetwork,
        IEthereumAddress,
        EthereumNetworkClient,
        EthereumChain,
        TXDATA,
        IEthereumTransaction<TXDATA>,
        IEthereumSignedTransaction<TXDATA>,
        EthWalletTransaction,
        SubmitTransactionSuccess<IEthereumSignedTransaction<TXDATA>>,
        EthereumTransactionFeeData> {
  BaseEthereumTransactionController(
      {required super.walletProvider, required super.account, required super.address});
}

class IEthereumTransactionData extends ITransactionData {
  final ETHAddress recipient;
  final BigInt amount;
  final EthereumTransactionFee fee;
  final List<int> data;
  final int nonce;
  IEthereumTransactionData(
      {required this.recipient,
      required this.amount,
      required this.fee,
      required this.nonce,
      List<int>? data})
      : data = (data ?? <int>[]).asImmutableBytes;

  IEthereumTransactionData copyWith({
    ETHAddress? recipient,
    BigInt? amount,
    EthereumTransactionFee? fee,
    List<int>? data,
    int? nonce,
  }) {
    return IEthereumTransactionData(
      recipient: recipient ?? this.recipient,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      nonce: nonce ?? this.nonce,
      data: data ?? this.data,
    );
  }
}

class IEthereumTransactionTokenTransferData extends IEthereumTransactionData {
  final ETHERC20Token token;
  final BigInt tokenAmount;
  IEthereumTransactionTokenTransferData(
      {required super.recipient,
      required super.amount,
      required super.fee,
      required super.nonce,
      required List<int> super.data,
      required this.token,
      required this.tokenAmount});
}

class IEthereumTransaction<TXDATA extends IEthereumTransactionData>
    extends ITransaction<TXDATA, IEthereumAddress> {
  IEthereumTransaction(
      {required super.account,
      required super.transactionData,
      required this.transaction});

  final ETHTransaction transaction;
}

class IEthereumSignedTransaction<TXDATA extends IEthereumTransactionData>
    extends ISignedTransaction<IEthereumTransaction<TXDATA>, String> {
  IEthereumSignedTransaction(
      {required super.transaction,
      required super.signatures,
      required super.finalTransactionData});
}
