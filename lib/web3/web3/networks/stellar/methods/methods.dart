import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/stellar/constant/constant.dart';

class Web3StellarRequestMethods extends Web3NetworkRequestMethods {
  const Web3StellarRequestMethods._({required super.identifier, required super.name});

  static const Web3StellarRequestMethods requestAccounts = Web3StellarRequestMethods._(
    identifier: AppSerializationIdentifier.runtimeTag3,
    name: Web3StellarConst.requestAccounts,
  );
  static const Web3StellarRequestMethods signMessage = Web3StellarRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag4,
      name: Web3StellarConst.signMessage);

  static const Web3StellarRequestMethods sendTransaction = Web3StellarRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag5,
      name: Web3StellarConst.sendTransaction);

  static const Web3StellarRequestMethods signTransaction = Web3StellarRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag6,
      name: Web3StellarConst.signTransaction);

  @override
  NetworkType get network => NetworkType.stellar;

  static const List<Web3StellarRequestMethods> values = [
    requestAccounts,
    signMessage,
    sendTransaction,
    signTransaction
  ];

  static Web3StellarRequestMethods? fromName(String? name) {
    return values.firstWhereOrNull((e) => e.name == name || e.methodsName.contains(name));
  }
}
