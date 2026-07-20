import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/constant/constant.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';

class Web3EthereumRequestMethods extends Web3NetworkRequestMethods {
  const Web3EthereumRequestMethods._(
      {required super.identifier,
      required super.name,
      super.methodsName,
      super.reloadAuthenticated});

  static const Web3EthereumRequestMethods sendTransaction = Web3EthereumRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag3,
      name: Web3EthereumConst.sendTransaction);
  static const Web3EthereumRequestMethods persoalSign = Web3EthereumRequestMethods._(
    identifier: AppSerializationIdentifier.runtimeTag4,
    name: Web3EthereumConst.personalSign,
  );
  static const Web3EthereumRequestMethods ethSign = Web3EthereumRequestMethods._(
    identifier: AppSerializationIdentifier.runtimeTag5,
    name: Web3EthereumConst.ethSign_,
  );
  static const Web3EthereumRequestMethods typedData = Web3EthereumRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag6,
      name: Web3EthereumConst.typedData,
      methodsName: [Web3EthereumConst.typedDataV3, Web3EthereumConst.typedDataV4]);
  static const Web3EthereumRequestMethods addEthereumChain = Web3EthereumRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag7,
      name: Web3EthereumConst.addChain,
      reloadAuthenticated: true);
  static const Web3EthereumRequestMethods switchEthereumChain =
      Web3EthereumRequestMethods._(
          identifier: AppSerializationIdentifier.runtimeTag8,
          name: Web3EthereumConst.switchEthereumChain,
          reloadAuthenticated: true);

  static const Web3EthereumRequestMethods requestAccounts = Web3EthereumRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag9,
      name: Web3EthereumConst.requestAccounts);
  static const Web3EthereumRequestMethods ethAccounts = Web3EthereumRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag10,
      name: Web3EthereumConst.ethAccounts);
  static const Web3EthereumRequestMethods ethChainId = Web3EthereumRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag11,
      name: Web3EthereumConst.ethChinId);
  static const List<Web3EthereumRequestMethods> values = [
    sendTransaction,
    persoalSign,
    typedData,
    addEthereumChain,
    switchEthereumChain,
    requestAccounts,
    ethAccounts,
    ethChainId,
    ethSign
  ];

  static Web3EthereumRequestMethods? fromName(String? name) {
    return values.firstWhereOrNull((e) => e.name == name || e.methodsName.contains(name));
  }

  @override
  NetworkType get network => NetworkType.ethereum;

  @override
  String toString() {
    return name;
  }
}
