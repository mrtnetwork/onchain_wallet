import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/constant/constants/constant.dart';

class Web3BitcoinRequestMethods extends Web3NetworkRequestMethods {
  const Web3BitcoinRequestMethods(
      {required super.identifier, required super.name, super.methodsName});

  static const Web3BitcoinRequestMethods requestAccounts = Web3BitcoinRequestMethods(
      identifier: AppSerializationIdentifier.runtimeTag3,
      name: Web3BitcoinConst.requestAccounts);

  static const Web3BitcoinRequestMethods signPersonalMessage = Web3BitcoinRequestMethods(
      identifier: AppSerializationIdentifier.runtimeTag4,
      name: Web3BitcoinConst.signPersonalMessage);

  static const Web3BitcoinRequestMethods signMessage = Web3BitcoinRequestMethods(
      identifier: AppSerializationIdentifier.runtimeTag5,
      name: Web3BitcoinConst.signMessage);

  static const Web3BitcoinRequestMethods signTransaction = Web3BitcoinRequestMethods(
      identifier: AppSerializationIdentifier.runtimeTag6,
      name: Web3BitcoinConst.signTransaction,
      methodsName: [Web3BitcoinConst.signPsbt]);

  static const Web3BitcoinRequestMethods getAccountAddresses = Web3BitcoinRequestMethods(
      identifier: AppSerializationIdentifier.runtimeTag7,
      name: Web3BitcoinConst.getAccountAddresses,
      methodsName: [Web3BitcoinConst.bitcoinGetAccountAddresses]);

  static const Web3BitcoinRequestMethods sendTransaction = Web3BitcoinRequestMethods(
      identifier: AppSerializationIdentifier.runtimeTag8,
      name: Web3BitcoinConst.sendTransaction,
      methodsName: [Web3BitcoinConst.sendTransfer]);

  @override
  NetworkType get network => NetworkType.bitcoinAndForked;

  static const List<Web3BitcoinRequestMethods> values = [
    requestAccounts,
    signTransaction,
    signPersonalMessage,
    sendTransaction,
    signMessage,
    getAccountAddresses
  ];

  static Web3BitcoinRequestMethods? fromName(String? name) {
    return values.firstWhereOrNull((e) => e.name == name || e.methodsName.contains(name));
  }
}
