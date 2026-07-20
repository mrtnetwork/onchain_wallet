import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/constant/constants/constant.dart';

class Web3ZcashRequestMethods extends Web3NetworkRequestMethods {
  const Web3ZcashRequestMethods._({required super.identifier, required super.name});

  @override
  NetworkType get network => NetworkType.zcash;
  static const Web3ZcashRequestMethods requestAccounts = Web3ZcashRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag3,
      name: Web3ZcashConst.requestAccounts);
  static const Web3ZcashRequestMethods signMessage = Web3ZcashRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag4,
      name: Web3ZcashConst.signMessage);

  static const Web3ZcashRequestMethods sendTransaction = Web3ZcashRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag5,
      name: Web3ZcashConst.sendTransaction);

  static const List<Web3ZcashRequestMethods> values = [
    requestAccounts,
    signMessage,
    sendTransaction
  ];

  static Web3ZcashRequestMethods? fromName(String? name) {
    return values.firstWhereOrNull((e) => e.name == name || e.methodsName.contains(name));
  }
}
