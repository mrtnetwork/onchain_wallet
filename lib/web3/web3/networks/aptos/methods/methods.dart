import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/aptos/constant/constants/constant.dart';

class Web3AptosRequestMethods extends Web3NetworkRequestMethods {
  const Web3AptosRequestMethods._(
      {required super.identifier, required super.name, super.reloadAuthenticated});
// SerializationIdentifier
  static const Web3AptosRequestMethods requestAccounts = Web3AptosRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag3,
      name: Web3AptosConst.requestAccounts);
  static const Web3AptosRequestMethods getNetwork = Web3AptosRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag4,
      name: Web3AptosConst.getNetwork);

  static const Web3AptosRequestMethods signMessage = Web3AptosRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag5,
      name: Web3AptosConst.signMessage);
  static const Web3AptosRequestMethods switchNetwork = Web3AptosRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag6,
      name: Web3AptosConst.switchNetwork,
      reloadAuthenticated: true);
  static const Web3AptosRequestMethods signTransaction = Web3AptosRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag7,
      name: Web3AptosConst.signTransaction);

  @override
  NetworkType get network => NetworkType.aptos;

  static const List<Web3AptosRequestMethods> values = [
    requestAccounts,
    signTransaction,
    signMessage,
    getNetwork,
    switchNetwork
  ];

  static Web3AptosRequestMethods? fromName(String? name) {
    return values.firstWhereOrNull((e) => e.name == name || e.methodsName.contains(name));
  }
}
