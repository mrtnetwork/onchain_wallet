import 'package:blockchain_utils/cbor/serialization/cbor/cbor.dart';
import 'package:blockchain_utils/cbor/types/int.dart';
import 'package:blockchain_utils/cbor/types/list.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/aptos/aptos.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin_cash/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/cardano.dart';
import 'package:on_chain_wallet/web3/web3/networks/cosmos/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/monero/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/solana/solana.dart';
import 'package:on_chain_wallet/web3/web3/networks/stellar/stellar.dart';
import 'package:on_chain_wallet/web3/web3/networks/substrate/substrate.dart';
import 'package:on_chain_wallet/web3/web3/networks/sui/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/ton/ton.dart';
import 'package:on_chain_wallet/web3/web3/networks/tron/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/methods/methods.dart';

enum Web3RequestMode { silent, user }

abstract class Web3RequestMethods {
  final AppSerializationIdentifier identifier;
  final String name;
  final List<String> methodsName;
  final bool reloadAuthenticated;
  final Web3RequestMode mode;
  bool get isGlobalMethod => false;
  List<String> get walletConnectMethodNames => [name, ...methodsName];

  const Web3RequestMethods(
      {required this.identifier,
      required this.name,
      required this.methodsName,
      required this.reloadAuthenticated,
      this.mode = Web3RequestMode.user});
  T cast<T extends Web3RequestMethods>() {
    if (this is! T) {
      throw Web3RequestExceptionConst.internalErr("Web3RequestMethods.cast",
          details: {"type": runtimeType.toString(), "expected": "$T"});
    }
    return this as T;
  }

  @override
  String toString() {
    return name;
  }
}

enum Web3NetworkEvent {
  accountsChanged,
  chainChanged,
  message,
  connect,
  disconnect,
  change;

  bool get needEmit =>
      this == accountsChanged ||
      this == chainChanged ||
      this == connect ||
      this == change;

  static Web3NetworkEvent name(String? name) {
    return values.firstWhere((e) => e.name == name,
        orElse: () => throw Web3RequestExceptionConst.internalErr("Web3NetworkEvent",
            details: {"name": name}));
  }

  static List<Web3NetworkEvent> getEvents(NetworkType network) {
    switch (network) {
      case NetworkType.ethereum:
        return values;
      case NetworkType.tron:
      case NetworkType.aptos:
        return [accountsChanged, chainChanged, change];
      default:
        return [change];
    }
  }

  static Web3NetworkEvent? fromName(String? name) {
    return values.firstWhereOrNull((e) => e.name == name);
  }
}

abstract class Web3NetworkRequestMethods extends Web3RequestMethods {
  const Web3NetworkRequestMethods(
      {required super.identifier,
      required super.name,
      super.methodsName = const [],
      super.reloadAuthenticated = false});
  abstract final NetworkType network;
  CborListValue get methodInfos => CborListValue.definite([
        CborIntValue(network.identifier.id),
        CborIntValue(identifier.id),
      ]);

  static List<Web3NetworkRequestMethods> getMethods(NetworkType network) {
    return switch (network) {
      NetworkType.ethereum => Web3EthereumRequestMethods.values,
      NetworkType.tron => Web3TronRequestMethods.values,
      NetworkType.solana => Web3SolanaRequestMethods.values,
      NetworkType.xrpl => Web3XRPRequestMethods.values,
      NetworkType.monero => Web3MoneroRequestMethods.values,
      NetworkType.cardano => Web3ADARequestMethods.values,
      NetworkType.ton => Web3TonRequestMethods.values,
      NetworkType.stellar => Web3StellarRequestMethods.values,
      NetworkType.aptos => Web3AptosRequestMethods.values,
      NetworkType.sui => Web3SuiRequestMethods.values,
      NetworkType.cosmos => Web3CosmosRequestMethods.values,
      NetworkType.bitcoinAndForked => Web3BitcoinRequestMethods.values,
      NetworkType.bitcoinCash => Web3BitcoinCashRequestMethods.values,
      NetworkType.substrate => Web3SubstrateRequestMethods.values,
      NetworkType.zcash => Web3ZcashRequestMethods.values,
    };
  }

  static ({T method, NetworkType network})
      findMethod<T extends Web3NetworkRequestMethods>(CborListValue id) {
    if (id.value.length != 2) {
      throw Web3RequestExceptionConst.internalErr("findMethod");
    }
    final network = NetworkType.fromIdentifier(id.rawValueAt<int>(0));
    final mId = id.rawValueAt<int>(1);
    final method = getMethods(network)
        .firstWhere((e) => e.identifier.isValidIdentifier(mId),
            orElse: () => throw Web3RequestExceptionConst.methodDoesNotExist)
        .cast<T>();
    return (method: method, network: network);
  }
}
