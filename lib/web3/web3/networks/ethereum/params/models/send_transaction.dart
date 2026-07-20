import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/permission/models/account.dart';
import 'package:on_chain/ethereum/ethereum.dart';

class Web3EthreumTransactionAccessList with AppSerialization {
  final ETHAddress address;
  final List<List<int>> storageKeys;
  Web3EthreumTransactionAccessList(
      {required this.address, required List<List<int>> storageKeys})
      : storageKeys = storageKeys.map((e) => e.asImmutableBytes).toImutableList;
  factory Web3EthreumTransactionAccessList.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.web3EthereumTransactionAccessList);
    return Web3EthreumTransactionAccessList(
        address: ETHAddress(values.rawValueAt(0)),
        storageKeys: values.listAt<CborBytesValue>(1).map((e) => e.value).toList());
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3EthereumTransactionAccessList;

  @override
  List<CborObject?> get serializationItems => [
        address.address.toCbor(),
        AppSerialization.listFromObjects(
            storageKeys.map((e) => CborBytesValue(e)).toList())
      ];
}

class Web3EthreumSendTransaction extends Web3EthereumRequestParam<String> {
  final Web3EthereumChainAccount accessAccount;
  final List<Web3EthreumTransactionAccessList>? accessList;
  final ETHAddress? to;
  final int? gas;
  final BigInt? chainId;
  final BigInt? gasPrice;
  final BigInt? maxFeePerGas;
  final BigInt? maxPriorityFeePerGas;
  final BigInt value;
  final List<int> data;
  final ETHTransactionType? transactionType;

  bool get isEip1559Metrics => maxFeePerGas != null;
  bool get isLegacyFeeMetrics => gasPrice != null;
  bool get hasFee => isEip1559Metrics || isLegacyFeeMetrics || gas != null;

  Web3EthreumSendTransaction._(
      {required this.accessAccount,
      required this.to,
      List<Web3EthreumTransactionAccessList>? accessList,
      this.gas,
      this.gasPrice,
      required this.value,
      required List<int> data,
      this.maxFeePerGas,
      this.maxPriorityFeePerGas,
      this.chainId,
      this.transactionType})
      : accessList = accessList?.immutable,
        data = data.asImmutableBytes;

  factory Web3EthreumSendTransaction(
      {required Web3EthereumChainAccount account,
      required ETHAddress? to,
      required BigInt value,
      required int? gas,
      required List<int>? data,
      required BigInt? chainId,
      required BigInt? gasPrice,
      required BigInt? maxPriorityFeePerGas,
      required BigInt? maxFeePerGas,
      List<Web3EthreumTransactionAccessList>? accessList,
      int? transactionType}) {
    if (accessList?.isEmpty ?? false) {
      accessList = null;
    }
    if (gasPrice != null && (maxFeePerGas != null || maxPriorityFeePerGas != null)) {
      throw Web3EthereumExceptionConst.invalidGasArg;
    }

    if ((maxFeePerGas != null && maxPriorityFeePerGas == null) ||
        (maxFeePerGas == null && maxPriorityFeePerGas != null)) {
      throw Web3EthereumExceptionConst.invalidEIP1559GasArg;
    }
    ETHTransactionType? ethTransactionType =
        ETHTransactionType.values.firstWhereOrNull((e) => e.prefix == transactionType);
    if (transactionType != null && ethTransactionType == null) {
      throw Web3EthereumExceptionConst.invalidTransactionType;
    }
    if (ethTransactionType != null) {
      if (maxFeePerGas != null) {
        if (ethTransactionType != ETHTransactionType.eip1559) {
          throw Web3EthereumExceptionConst.invalidTransactionTypeOrGas;
        }
      }
      if (gasPrice != null) {
        if (ethTransactionType == ETHTransactionType.eip1559) {
          throw Web3EthereumExceptionConst.invalidTransactionTypeOrGas;
        }
      }
      if (accessList != null) {
        if (ethTransactionType == ETHTransactionType.legacy) {
          throw Web3EthereumExceptionConst.invalidTransactionAccessList;
        }
      }
    } else {
      if (maxFeePerGas != null) {
        ethTransactionType = ETHTransactionType.eip1559;
      } else if (accessList != null) {
        ethTransactionType = ETHTransactionType.eip2930;
      } else if (gasPrice != null) {
        ethTransactionType = ETHTransactionType.legacy;
      }
    }
    return Web3EthreumSendTransaction._(
        accessAccount: account,
        to: to,
        value: value,
        gas: gas,
        gasPrice: gasPrice,
        maxPriorityFeePerGas: maxPriorityFeePerGas,
        maxFeePerGas: maxFeePerGas,
        data: data ?? const [],
        chainId: chainId,
        transactionType: ethTransactionType);
  }

  factory Web3EthreumSendTransaction.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: Web3MessageTypes.walletRequest.tag,
    );
    final String? to = values.rawValueAt(2);
    final int? trType = values.rawValueAt(10);
    return Web3EthreumSendTransaction._(
        accessAccount: Web3EthereumChainAccount.deserialize(
            object: values.objectAt<CborTagValue>(1)),
        to: to == null ? null : ETHAddress(to),
        gas: values.rawValueAt(3),
        gasPrice: values.rawValueAt(4),
        maxFeePerGas: values.rawValueAt(5),
        maxPriorityFeePerGas: values.rawValueAt(6),
        value: values.rawValueAt(7),
        data: values.rawValueAt(8),
        chainId: values.rawValueAt(9),
        transactionType: trType == null ? null : ETHTransactionType.fromPrefix(trType));
  }

  @override
  Web3EthereumRequestMethods get method => Web3EthereumRequestMethods.sendTransaction;

  @override
  Future<IResult<Web3EthereumRequest<String, Web3EthreumSendTransaction>>> toRequest(
      {required Web3RequestInformation request,
      required Web3RequestAuthentication authenticated,
      required WEB3REQUESTNETWORKCONTROLLER<IEthereumAddress, EthereumChain,
              Web3EthereumChainAccount>
          chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map((chain) => Web3EthereumRequest<String, Web3EthreumSendTransaction>(
          params: this,
          authenticated: authenticated,
          chain: chain.$1,
          info: request,
          accounts: chain.$2,
        ));
  }

  @override
  List<Web3EthereumChainAccount> get requiredAccounts => [accessAccount];

  @override
  List<CborObject?> get serializationItems => [
        method.methodInfos,
        accessAccount.toCbor(),
        to?.address.toCbor(),
        gas?.toCbor(),
        gasPrice?.toCbor(),
        maxFeePerGas?.toCbor(),
        maxPriorityFeePerGas?.toCbor(),
        value.toCbor(),
        CborBytesValue(data),
        chainId?.toCbor(),
        transactionType?.prefix.toCbor()
      ];
}
