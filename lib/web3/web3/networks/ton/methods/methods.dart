import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/ton/constant/constants/constant.dart';

class Web3TonRequestMethods extends Web3NetworkRequestMethods {
  const Web3TonRequestMethods._({required super.identifier, required super.name});

  static const Web3TonRequestMethods requestAccounts = Web3TonRequestMethods._(
    identifier: AppSerializationIdentifier.runtimeTag3,
    name: Web3TonConst.requestAccounts,
  );
  static const Web3TonRequestMethods signMessage = Web3TonRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag4, name: Web3TonConst.signMessage);

  static const Web3TonRequestMethods sendTransaction = Web3TonRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag5,
      name: Web3TonConst.sendTransaction);

  static const Web3TonRequestMethods signTransaction = Web3TonRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag6,
      name: Web3TonConst.signTransaction);

  @override
  NetworkType get network => NetworkType.ton;

  static const List<Web3TonRequestMethods> values = [
    requestAccounts,
    signMessage,
    sendTransaction,
    signTransaction
  ];

  static Web3TonRequestMethods? fromName(String? name) {
    return values.firstWhereOrNull((e) => e.name == name || e.methodsName.contains(name));
  }
}
