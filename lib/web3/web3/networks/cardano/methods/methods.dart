import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/constant/constants/constant.dart';

class Web3ADARequestMethods extends Web3NetworkRequestMethods {
  const Web3ADARequestMethods._({required super.identifier, required super.name});

  static const Web3ADARequestMethods requestAccounts = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag3,
      name: Web3ADAConst.requestAccounts);
  static const Web3ADARequestMethods signMessage = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag4, name: Web3ADAConst.signMessage);
  static const Web3ADARequestMethods signTransaction = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag5,
      name: Web3ADAConst.signTransaction);

  ///
  static const Web3ADARequestMethods isEnabled = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag6, name: Web3ADAConst.isEnabled);
  static const Web3ADARequestMethods getNetworkId = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag7,
      name: Web3ADAConst.getNetworkId);
  static const Web3ADARequestMethods getBalance = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag8, name: Web3ADAConst.getBalance);
  static const Web3ADARequestMethods getUtxos = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag9, name: Web3ADAConst.getUtxos);

  static const Web3ADARequestMethods getAddressUtxos = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag10,
      name: Web3ADAConst.getAddressUtxos);
  static const Web3ADARequestMethods getUnusedAddresses = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag11,
      name: Web3ADAConst.getUnusedAddresses);
  static const Web3ADARequestMethods getUsedAddresses = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag12,
      name: Web3ADAConst.getUsedAddresses);
  static const Web3ADARequestMethods getRewardAddresses = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag13,
      name: Web3ADAConst.getRewardAddresses);
  static const Web3ADARequestMethods getCollateral = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag14,
      name: Web3ADAConst.getCollateral);
  static const Web3ADARequestMethods getChangeAddress = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag15,
      name: Web3ADAConst.getChangeAddress);

  static const Web3ADARequestMethods signData = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag16, name: Web3ADAConst.signData);
  static const Web3ADARequestMethods getExtensions = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag17,
      name: Web3ADAConst.getExtensions);
  static const Web3ADARequestMethods submitTx = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag18, name: Web3ADAConst.submitTx);
  static const Web3ADARequestMethods signTx = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag19, name: Web3ADAConst.signTx);
  static const Web3ADARequestMethods signAndSendTransaction = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag20,
      name: Web3ADAConst.sendTransaction);

  static const Web3ADARequestMethods submitTxs = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag21, name: Web3ADAConst.submitTxs);
  static const Web3ADARequestMethods signTxs = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag22, name: Web3ADAConst.signTxs);

  static const Web3ADARequestMethods getAccountPub = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag23,
      name: Web3ADAConst.getAccountPub);
  //
  static const Web3ADARequestMethods getScriptRequirements = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag24,
      name: Web3ADAConst.getScriptRequirements);
  static const Web3ADARequestMethods getScript = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag25, name: Web3ADAConst.getScript);
  static const Web3ADARequestMethods submitUnsignedTx = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag26,
      name: Web3ADAConst.submitUnsignedTx);
  static const Web3ADARequestMethods getCompletedTx = Web3ADARequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag27,
      name: Web3ADAConst.getCompletedTx);
  @override
  NetworkType get network => NetworkType.cardano;

  static const List<Web3ADARequestMethods> values = [
    signMessage,
    signTransaction,
    requestAccounts,
    signAndSendTransaction,
    getAddressUtxos,

    //
    getScriptRequirements,
    getScript,
    submitUnsignedTx,
    getCompletedTx,
    submitTxs,
    signTxs,
    getUnusedAddresses,
    getChangeAddress,
    getCollateral,
    getUsedAddresses,
    isEnabled,
    getNetworkId,
    getBalance,
    getUtxos,
    signTx,
    signData,
    getExtensions,
    submitTx,
    getRewardAddresses,
    getAccountPub
  ];

  static Web3ADARequestMethods? fromName(String? name) {
    return values.firstWhereOrNull((e) => e.name == name || e.methodsName.contains(name));
  }
}
