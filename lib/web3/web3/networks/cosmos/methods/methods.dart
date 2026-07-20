import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/cosmos/constant/constants/constant.dart';

class Web3CosmosRequestMethods extends Web3NetworkRequestMethods {
  const Web3CosmosRequestMethods._(
      {required super.identifier, required super.name, super.reloadAuthenticated});

  static const Web3CosmosRequestMethods requestAccounts = Web3CosmosRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag3,
      name: Web3CosmosConst.requestAccounts);
  static const Web3CosmosRequestMethods addNewChain = Web3CosmosRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag4,
      name: Web3CosmosConst.addNewChain,
      reloadAuthenticated: true);

  static const Web3CosmosRequestMethods signMessage = Web3CosmosRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag5,
      name: Web3CosmosConst.signMessage);

  static const Web3CosmosRequestMethods sendTransaction = Web3CosmosRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag6,
      name: Web3CosmosConst.sendTransaction);

  static const Web3CosmosRequestMethods signTransactionAmino = Web3CosmosRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag7,
      name: Web3CosmosConst.signTransactionAmino);
  static const Web3CosmosRequestMethods signTransactionDirect =
      Web3CosmosRequestMethods._(
          identifier: AppSerializationIdentifier.runtimeTag8,
          name: Web3CosmosConst.signTransactionDirect);

  @override
  NetworkType get network => NetworkType.cosmos;

  static const List<Web3CosmosRequestMethods> values = [
    requestAccounts,
    signTransactionAmino,
    signTransactionDirect,
    signMessage,
    addNewChain,
    sendTransaction
  ];

  static Web3CosmosRequestMethods fromTags(List<int>? tags) {
    return values.firstWhere((e) => e.identifier.isValidTags(tags),
        orElse: () => throw Web3RequestExceptionConst.methodDoesNotExist);
  }

  static Web3CosmosRequestMethods? fromName(String? name) {
    return values.firstWhereOrNull((e) => e.name == name || e.methodsName.contains(name));
  }
}
