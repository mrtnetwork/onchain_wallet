import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain/solidity/address/core.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/operations/eth_sign.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/operations/import_network.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/operations/personal_sign.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/operations/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/operations/typed_data.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/client/client.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/others/models/receipt_address.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/core/core.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/ethereum.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';

class EthereumInitFee {
  final BigInt? gasPrice;
  final BigInt? maxPriorityFeePerGas;
  final BigInt? maxFeePerGas;
  final int? gasLimit;
  const EthereumInitFee(
      {this.gasPrice, this.maxFeePerGas, this.maxPriorityFeePerGas, this.gasLimit});

  bool get isEip1559Metrics => maxFeePerGas != null && maxPriorityFeePerGas != null;
  bool get isLegacyFeeMetrics => gasPrice != null;
  bool get hasGasMetrics => isEip1559Metrics || isLegacyFeeMetrics;
  bool get hasFee => hasGasMetrics || gasLimit != null;
}

class Web3EthereumTransactionRequestInfos {
  bool get isContract => dataInfo != null;
  final String? data;
  final EthereumTransactionDataInfo? dataInfo;
  final ReceiptAddress<ETHAddress>? destination;
  final ETHTransactionType type;

  final IntegerBalance value;
  final EthereumInitFee? initFee;

  const Web3EthereumTransactionRequestInfos._(
      {this.destination,
      this.data,
      this.dataInfo,
      required this.value,
      required this.type,
      this.initFee});
  factory Web3EthereumTransactionRequestInfos(
      {required Web3EthreumSendTransaction transaction,
      required ReceiptAddress<ETHAddress>? destination,
      required EthereumTransactionDataInfo? contractInfo,
      required WalletEthereumNetwork network,
      required ETHTransactionType type}) {
    EthereumInitFee? initFee;
    if (transaction.hasFee) {
      initFee = EthereumInitFee(
          gasLimit: transaction.gas,
          gasPrice: transaction.gasPrice,
          maxFeePerGas: transaction.maxFeePerGas,
          maxPriorityFeePerGas: transaction.maxPriorityFeePerGas);
    }
    return Web3EthereumTransactionRequestInfos._(
        value: IntegerBalance.token(transaction.value, network.token),
        data: BytesUtils.toHexString(transaction.data, prefix: "0x"),
        initFee: initFee,
        destination: destination,
        dataInfo: contractInfo,
        type: type);
  }
}

enum SolidityMethodInfoTypes {
  unknown("unknown"),
  unknownData("unknown"),
  creationContract("creation_contract"),
  nameAndInputs(""),
  erc20("erc20"),
  erc20Transfer("token_transfer");

  final String localizationName;
  const SolidityMethodInfoTypes(this.localizationName);
}

abstract class EthereumTransactionDataInfo {
  final String? selector;
  EthereumTransactionDataInfo({List<int>? selector})
      : selector = BytesUtils.tryToHexString(selector, prefix: "0x");
  SolidityMethodInfoTypes get type;

  String get localizationName => "smart_contract";

  T? safeCast<T extends EthereumTransactionDataInfo>() {
    if (this is T) return this as T;
    return null;
  }

  T cast<T extends EthereumTransactionDataInfo>() {
    return this as T;
  }
}

class UnknownTransactionData extends EthereumTransactionDataInfo {
  final String dataHex;
  final String? content;
  UnknownTransactionData(this.dataHex, this.content);
  factory UnknownTransactionData.fromBytes(List<int> data) {
    final dataHex = BytesUtils.toHexString(data, prefix: "0x");
    final content = StringUtils.tryDecode(data);
    return UnknownTransactionData(dataHex, content);
  }

  @override
  SolidityMethodInfoTypes get type => SolidityMethodInfoTypes.unknownData;
  @override
  String get localizationName => type.localizationName;
}

class SolidityCreationContract extends EthereumTransactionDataInfo {
  @override
  SolidityMethodInfoTypes get type => SolidityMethodInfoTypes.creationContract;
  @override
  String get localizationName => type.localizationName;
}

class SolidityUnknownMethodInfo extends EthereumTransactionDataInfo {
  SolidityUnknownMethodInfo({required this.dataHex, required super.selector});
  final String dataHex;

  @override
  SolidityMethodInfoTypes get type => SolidityMethodInfoTypes.unknown;
}

class SolidityNameAndInputValues extends EthereumTransactionDataInfo {
  SolidityNameAndInputValues(
      {required super.selector, required this.inputs, required this.name});
  final List<dynamic> inputs;
  final String? name;
  @override
  SolidityMethodInfoTypes get type => SolidityMethodInfoTypes.nameAndInputs;

  @override
  String get localizationName => name ?? super.localizationName;
}

class SolidityERC20MethodInfo extends EthereumTransactionDataInfo {
  SolidityERC20MethodInfo({
    required super.selector,
    required this.token,
    required this.dataHex,
  });
  final SolidityToken token;
  final String dataHex;
  @override
  SolidityMethodInfoTypes get type => SolidityMethodInfoTypes.erc20;
}

class SolidityERC20TransferMethodInfo<T extends SolidityAddress>
    extends SolidityERC20MethodInfo {
  SolidityERC20TransferMethodInfo({
    required super.selector,
    required super.token,
    required this.to,
    required this.value,
    required super.dataHex,
  });
  final ReceiptAddress<T> to;
  final IntegerBalance value;
  @override
  SolidityMethodInfoTypes get type => SolidityMethodInfoTypes.erc20Transfer;

  @override
  String get localizationName => type.localizationName;
}

abstract class Web3EthereumStateController<
        RESPONSE,
        CLIENT extends EthereumNetworkClient?,
        T extends Web3EthereumRequestParam<RESPONSE>>
    extends Web3StateController<
        RESPONSE,
        ETHAddress,
        WalletEthereumNetwork,
        EthereumNetworkClient,
        CLIENT,
        IEthereumAddress,
        EthereumChain,
        Web3EthereumChainAccount,
        T,
        Web3EthereumRequest<RESPONSE, T>,
        Web3RequestResponseData<RESPONSE>,
        EthWalletTransaction> {
  Web3EthereumStateController({required super.walletProvider, required super.request});

  static BaseWeb3StateController findController(
      {required Web3EthereumRequest request, required WalletProvider walletProvider}) {
    switch (request.params.method) {
      case Web3EthereumRequestMethods.persoalSign:
        return Web3EthereumPersonalSignStateController(
            walletProvider: walletProvider, request: request.cast());
      case Web3EthereumRequestMethods.ethSign:
        return Web3EthereumEthSignStateController(
            walletProvider: walletProvider, request: request.cast());
      case Web3EthereumRequestMethods.sendTransaction:
        return Web3EthereumSendTransactionStateController(
            walletProvider: walletProvider, request: request.cast());
      case Web3EthereumRequestMethods.typedData:
        return Web3EthereumSignTypedDataStateController(
            walletProvider: walletProvider, request: request.cast());
      case Web3EthereumRequestMethods.addEthereumChain:
        return Web3EthereumImportNetworkStateController(
            walletProvider: walletProvider, request: request.cast());
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
  }
}

abstract class BaseWeb3EthereumTransactionStateController<
        RESPONSE,
        T extends Web3EthereumRequestParam<RESPONSE>,
        E extends IWeb3EthereumTransactionData>
    extends Web3TransactionStateController<
        RESPONSE,
        ETHAddress,
        WalletEthereumNetwork,
        IEthereumAddress,
        EthereumNetworkClient,
        EthereumNetworkClient,
        EthereumChain,
        Web3EthereumChainAccount,
        T,
        Web3EthereumRequest<RESPONSE, T>,
        E,
        IWeb3EthereumTransaction<E>,
        IWeb3EthereumSignedTransaction<E>,
        EthWalletTransaction,
        SubmitTransactionSuccess<IWeb3EthereumSignedTransaction<E>>> {
  BaseWeb3EthereumTransactionStateController(
      {required super.walletProvider, required super.request});
}

class IWeb3EthereumTransactionData extends ITransactionData {
  final Web3EthereumTransactionRequestInfos transactionInfos;
  const IWeb3EthereumTransactionData({required this.transactionInfos});
}

class IWeb3EthereumTransaction<TXDATA extends IWeb3EthereumTransactionData>
    extends ITransaction<TXDATA, IEthereumAddress> {
  final ETHTransaction transaction;
  const IWeb3EthereumTransaction(
      {required super.account,
      required super.transactionData,
      required this.transaction});
}

class IWeb3EthereumSignedTransaction<TXDATA extends IWeb3EthereumTransactionData>
    extends ISignedTransaction<IWeb3EthereumTransaction<TXDATA>, String> {
  IWeb3EthereumSignedTransaction(
      {required super.transaction,
      required super.signatures,
      required super.finalTransactionData});
}
