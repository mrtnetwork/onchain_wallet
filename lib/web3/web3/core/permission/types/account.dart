import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/networks/types/address.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/networks/aptos/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/bitcoin.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin_cash/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/networks/cosmos/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/networks/monero/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/networks/solana/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/networks/stellar/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/networks/substrate/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/networks/sui/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/networks/ton/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/networks/tron/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/permission/models/account.dart';

abstract class Web3ChainAccount<NETWORKADDRESS extends IAddress>
    with AppSerialization, Equality {
  int get id;
  final DerivationIndex derivationIndex;
  final NETWORKADDRESS address;
  final String identifier;
  final bool defaultAddress;
  String get addressStr;

  Web3ChainAccount({
    required this.derivationIndex,
    required this.address,
    required this.identifier,
    required this.defaultAddress,
  });

  Web3ChainAccount<NETWORKADDRESS> clone();

  @override
  List get variables => [derivationIndex, addressStr, id, defaultAddress];
}

abstract class Web3ChainIdnetifier with AppSerialization, Equality {
  final int id;
  final String wsIdentifier;
  final String caip2;
  final String caipChainId;
  final String wsChainId;

  bool isChain(String chainId) {
    if (chainId.indexOf(":") > 0) {
      return wsIdentifier == chainId || caip2 == chainId;
    }
    return caipChainId == chainId || wsChainId == chainId;
  }

  Web3ChainIdnetifier({required this.id, required this.wsIdentifier, required this.caip2})
      : caipChainId = caip2.split(":").last,
        wsChainId = wsIdentifier.split(":").last;
  @override
  List get variables => [id];

  // static Web3ChainIdnetifier from(WalletNetwork network){}
}

class Web3ChainDefaultIdnetifier extends Web3ChainIdnetifier {
  Web3ChainDefaultIdnetifier(
      {required super.id, required super.wsIdentifier, required super.caip2});
  factory Web3ChainDefaultIdnetifier.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.web3ChainIdentifier);
    return Web3ChainDefaultIdnetifier(
        id: values.rawValueAt(0),
        wsIdentifier: values.rawValueAt(1),
        caip2: values.rawValueAt(2));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3ChainIdentifier;

  @override
  List<CborObject?> get serializationItems =>
      [id.toCbor(), wsIdentifier.toCbor(), caip2.toCbor()];
}

abstract class Web3ChainAuthenticated<CHAINACCOUNT extends Web3ChainAccount>
    with AppSerialization {
  final NetworkType networkType;
  final List<CHAINACCOUNT> accounts;
  abstract final List<Web3ChainIdnetifier> networks;
  abstract final Web3ChainIdnetifier currentNetwork;

  Web3ChainAuthenticated({
    required this.networkType,
    required List<CHAINACCOUNT> accounts,
  }) : accounts = accounts.immutable;
  factory Web3ChainAuthenticated.deserialize({List<int>? bytes, CborObject? object}) {
    final CborTagValue tag = AppSerialization.decode(
      cborObject: object,
      cborBytes: bytes,
    );
    final type = NetworkType.fromTags(tag.tags);
    return switch (type) {
      NetworkType.solana => Web3SolanaChainAuthenticated.deserialize(object: tag),
      NetworkType.xrpl => Web3XRPChainAuthenticated.deserialize(object: tag),
      NetworkType.monero => Web3MoneroChainAuthenticated.deserialize(object: tag),
      NetworkType.cardano => Web3ADAChainAuthenticated.deserialize(object: tag),
      NetworkType.ethereum => Web3EthereumChainAuthenticated.deserialize(object: tag),
      NetworkType.ton => Web3TonChainAuthenticated.deserialize(object: tag),
      NetworkType.tron => Web3TronChainAuthenticated.deserialize(object: tag),
      NetworkType.stellar => Web3StellarChainAuthenticated.deserialize(object: tag),
      NetworkType.substrate => Web3SubstrateChainAuthenticated.deserialize(object: tag),
      NetworkType.aptos => Web3AptosChainAuthenticated.deserialize(object: tag),
      NetworkType.sui => Web3SuiChainAuthenticated.deserialize(object: tag),
      NetworkType.cosmos => Web3CosmosChainAuthenticated.deserialize(object: tag),
      NetworkType.bitcoinAndForked =>
        Web3BitcoinChainAuthenticated.deserialize(object: tag),
      NetworkType.bitcoinCash =>
        Web3BitcoinCashChainAuthenticated.deserialize(object: tag),
      NetworkType.zcash => Web3ZcashChainAuthenticated.deserialize(object: tag),
    } as Web3ChainAuthenticated<CHAINACCOUNT>;
  }

  T cast<T extends Web3ChainAuthenticated>() {
    if (this is! T) {
      throw AppInternalError.internalError("Web3ChainAuthenticated");
    }
    return this as T;
  }

  @override
  SerializationIdentifier get serializationIdentifier => networkType.identifier;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(accounts.map((e) => e.toCbor()).toList()),
        AppSerialization.listFromObjects(networks.map((e) => e.toCbor()).toList()),
        currentNetwork.toCbor(),
      ];
}
