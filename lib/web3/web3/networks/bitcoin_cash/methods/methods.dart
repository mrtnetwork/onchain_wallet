import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin_cash/constant/constants/constant.dart';

class Web3BitcoinCashRequestMethods extends Web3BitcoinRequestMethods {
  const Web3BitcoinCashRequestMethods._(
      {required super.identifier, required super.name, super.methodsName});

  static const Web3BitcoinCashRequestMethods requestAccounts =
      Web3BitcoinCashRequestMethods._(
          identifier: AppSerializationIdentifier.runtimeTag3,
          name: Web3BitcoinCashConst.requestAccounts);

  static const Web3BitcoinCashRequestMethods signPersonalMessage =
      Web3BitcoinCashRequestMethods._(
          identifier: AppSerializationIdentifier.runtimeTag4,
          name: Web3BitcoinCashConst.signPersonalMessage);

  static const Web3BitcoinCashRequestMethods signMessage =
      Web3BitcoinCashRequestMethods._(
          identifier: AppSerializationIdentifier.runtimeTag5,
          name: Web3BitcoinCashConst.signMessage);

  static const Web3BitcoinCashRequestMethods signTransaction =
      Web3BitcoinCashRequestMethods._(
          identifier: AppSerializationIdentifier.runtimeTag6,
          name: Web3BitcoinCashConst.signTransaction,
          methodsName: [Web3BitcoinCashConst.signPsbt]);

  static const Web3BitcoinCashRequestMethods getAccountAddresses =
      Web3BitcoinCashRequestMethods._(
          identifier: AppSerializationIdentifier.runtimeTag7,
          name: Web3BitcoinCashConst.getAccountAddresses,
          methodsName: [Web3BitcoinCashConst.bitcoinGetAccountAddresses]);

  static const Web3BitcoinCashRequestMethods sendTransaction =
      Web3BitcoinCashRequestMethods._(
          identifier: AppSerializationIdentifier.runtimeTag8,
          name: Web3BitcoinCashConst.sendTransaction,
          methodsName: [Web3BitcoinCashConst.sendTransfer]);

  @override
  NetworkType get network => NetworkType.bitcoinCash;

  static const List<Web3BitcoinCashRequestMethods> values = [
    requestAccounts,
    signTransaction,
    signPersonalMessage,
    sendTransaction,
    signMessage,
    getAccountAddresses
  ];

  static Web3BitcoinCashRequestMethods? fromName(String? name) {
    return values.firstWhereOrNull((e) => e.name == name || e.methodsName.contains(name));
  }
}
