import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/substrate/constant/constant.dart';

class Web3SubstrateRequestMethods extends Web3NetworkRequestMethods {
  const Web3SubstrateRequestMethods._(
      {required super.identifier, required super.name, super.reloadAuthenticated});

  static const Web3SubstrateRequestMethods requestAccounts =
      Web3SubstrateRequestMethods._(
          identifier: AppSerializationIdentifier.runtimeTag3,
          name: Web3SubstrateConst.polkadotRequestAccounts);
  static const Web3SubstrateRequestMethods addSubstrateChain =
      Web3SubstrateRequestMethods._(
          identifier: AppSerializationIdentifier.runtimeTag4,
          name: Web3SubstrateConst.addChain,
          reloadAuthenticated: true);
  static const Web3SubstrateRequestMethods signMessage = Web3SubstrateRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag5,
      name: Web3SubstrateConst.signMessage);
  static const Web3SubstrateRequestMethods knownMetadata = Web3SubstrateRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag6,
      name: Web3SubstrateConst.knownMetadata);

  static const Web3SubstrateRequestMethods signTransaction =
      Web3SubstrateRequestMethods._(
          identifier: AppSerializationIdentifier.runtimeTag7,
          name: Web3SubstrateConst.polkadotSignTransaction);

  @override
  NetworkType get network => NetworkType.substrate;

  static const List<Web3SubstrateRequestMethods> values = [
    requestAccounts,
    signMessage,
    signTransaction,
    addSubstrateChain,
    knownMetadata
  ];

  static Web3SubstrateRequestMethods? fromName(String? name) {
    return values.firstWhereOrNull((e) => e.name == name || e.methodsName.contains(name));
  }
}
