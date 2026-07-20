import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/sui/constant/constants/constant.dart';

class Web3SuiRequestMethods extends Web3NetworkRequestMethods {
  const Web3SuiRequestMethods._({required super.identifier, required super.name});

  static const Web3SuiRequestMethods requestAccounts = Web3SuiRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag3,
      name: Web3SuiConst.requestAccounts);

  static const Web3SuiRequestMethods signMessage = Web3SuiRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag4, name: Web3SuiConst.signMessage);
  static const Web3SuiRequestMethods signPersonalMessage = Web3SuiRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag5,
      name: Web3SuiConst.signPersonalMessage);

  static const Web3SuiRequestMethods signTransaction = Web3SuiRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag6,
      name: Web3SuiConst.signTransaction);

  static const Web3SuiRequestMethods signRawTransaction = Web3SuiRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag7,
      name: Web3SuiConst.signTransaction);
  static const Web3SuiRequestMethods signAndExecuteTransaction = Web3SuiRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag8,
      name: Web3SuiConst.signAndExecuteTransaction);

  static const Web3SuiRequestMethods signTransactionBlock = Web3SuiRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag9,
      name: Web3SuiConst.signTransactionBlock);
  static const Web3SuiRequestMethods signAndExecuteTransactionBlock =
      Web3SuiRequestMethods._(
          identifier: AppSerializationIdentifier.runtimeTag10,
          name: Web3SuiConst.signAndExecuteTransactionBlock);

  @override
  NetworkType get network => NetworkType.sui;

  static const List<Web3SuiRequestMethods> values = [
    requestAccounts,
    signTransaction,
    signAndExecuteTransaction,
    signMessage,
    signTransactionBlock,
    signAndExecuteTransactionBlock,
    signPersonalMessage
  ];

  static Web3SuiRequestMethods? fromName(String? name) {
    return values.firstWhereOrNull((e) => e.name == name || e.methodsName.contains(name));
  }
}
