import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/constant/constant.dart';
import 'package:on_chain_wallet/web3/web3/networks/tron/constant/constants/constant.dart';

class Web3TronRequestMethods extends Web3NetworkRequestMethods {
  const Web3TronRequestMethods._({
    required super.identifier,
    required super.name,
    super.methodsName,
    super.reloadAuthenticated,
  });

  static const Web3TronRequestMethods requestAccounts = Web3TronRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag3,
      name: Web3TronConst.requestAccounts,
      methodsName: [Web3EthereumConst.requestAccounts]);
  static const Web3TronRequestMethods signMessageV2 = Web3TronRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag4,
      name: Web3TronConst.signMessageV2,
      methodsName: [Web3TronConst.signMessage]);

  static const Web3TronRequestMethods switchTronChain = Web3TronRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag5,
      name: Web3TronConst.switchChain,
      reloadAuthenticated: true,
      methodsName: [Web3EthereumConst.switchEthereumChain]);

  static const Web3TronRequestMethods signTransaction = Web3TronRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag6,
      name: Web3TronConst.signTransaction);

  @override
  NetworkType get network => NetworkType.tron;

  static const List<Web3TronRequestMethods> values = [
    requestAccounts,
    signTransaction,
    signMessageV2,
    switchTronChain
  ];

  static Web3TronRequestMethods? fromName(String? name) {
    return values.firstWhereOrNull((e) => e.name == name || e.methodsName.contains(name));
  }
}
