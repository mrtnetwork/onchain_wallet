import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/solana/constant/constants/constant.dart';

class Web3SolanaRequestMethods extends Web3NetworkRequestMethods {
  const Web3SolanaRequestMethods._({required super.identifier, required super.name});

  static const Web3SolanaRequestMethods requestAccounts = Web3SolanaRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag3,
      name: Web3SolanaConst.requestAccounts);
  static const Web3SolanaRequestMethods signMessage = Web3SolanaRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag4,
      name: Web3SolanaConst.signMessage);

  static const Web3SolanaRequestMethods signTransaction = Web3SolanaRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag5,
      name: Web3SolanaConst.signTransaction);
  static const Web3SolanaRequestMethods signAllTransactions = Web3SolanaRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag6,
      name: Web3SolanaConst.signAllTransactions);
  static const Web3SolanaRequestMethods signAndSendAllTransactions =
      Web3SolanaRequestMethods._(
          identifier: AppSerializationIdentifier.runtimeTag7,
          name: Web3SolanaConst.signAndSendAllTransactions);

  static const Web3SolanaRequestMethods sendTransaction = Web3SolanaRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag8,
      name: Web3SolanaConst.sendTransaction);
  static const Web3SolanaRequestMethods signIn = Web3SolanaRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag9, name: Web3SolanaConst.signIn);

  @override
  NetworkType get network => NetworkType.solana;

  static const List<Web3SolanaRequestMethods> values = [
    requestAccounts,
    signTransaction,
    signAndSendAllTransactions,
    signAllTransactions,
    sendTransaction,
    signIn,
    signMessage
  ];

  static Web3SolanaRequestMethods? fromName(String? name) {
    return values.firstWhereOrNull((e) => e.name == name || e.methodsName.contains(name));
  }
}
