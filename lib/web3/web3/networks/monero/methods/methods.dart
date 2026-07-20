import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/monero/constant/constants/constant.dart';

class Web3MoneroRequestMethods extends Web3NetworkRequestMethods {
  const Web3MoneroRequestMethods._({required super.identifier, required super.name});

  static const Web3MoneroRequestMethods requestAccounts = Web3MoneroRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag3,
      name: Web3MoneroConst.requestAccounts);
  static const Web3MoneroRequestMethods signMessage = Web3MoneroRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag4,
      name: Web3MoneroConst.signMessage);

  static const Web3MoneroRequestMethods sendTransaction = Web3MoneroRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag5,
      name: Web3MoneroConst.sendTransaction);

  @override
  NetworkType get network => NetworkType.monero;

  static const List<Web3MoneroRequestMethods> values = [
    requestAccounts,
    sendTransaction,
    signMessage
  ];

  static Web3MoneroRequestMethods? fromName(String? name) {
    return values.firstWhereOrNull((e) => e.name == name || e.methodsName.contains(name));
  }
}
