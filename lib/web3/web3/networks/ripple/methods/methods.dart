import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/constant/constants/constant.dart';

class Web3XRPRequestMethods extends Web3NetworkRequestMethods {
  const Web3XRPRequestMethods._({required super.identifier, required super.name});

  static const Web3XRPRequestMethods requestAccounts = Web3XRPRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag3,
      name: Web3XRPConst.requestAccounts);
  static const Web3XRPRequestMethods signMessage = Web3XRPRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag4, name: Web3XRPConst.signMessage);

  static const Web3XRPRequestMethods signTransaction = Web3XRPRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag5,
      name: Web3XRPConst.signTransaction);

  static const Web3XRPRequestMethods sendTransaction = Web3XRPRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag6,
      name: Web3XRPConst.sendTransaction);

  @override
  NetworkType get network => NetworkType.xrpl;

  static const List<Web3XRPRequestMethods> values = [
    requestAccounts,
    signTransaction,
    sendTransaction,
    signMessage
  ];

  static Web3XRPRequestMethods? fromName(String? name) {
    return values.firstWhereOrNull((e) => e.name == name || e.methodsName.contains(name));
  }
}
