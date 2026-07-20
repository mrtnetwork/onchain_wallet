import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/constant/chain/const.dart';
import 'package:on_chain_wallet/wallet/models/network/network.dart';
import 'package:on_chain_wallet/wallet/models/networks/tron/models/chain_type.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

sealed class WalletNetwork<PARAMS extends NetworkCoinParams>
    with Equality, AppSerialization {
  const WalletNetwork();
  abstract final int value;
  abstract final PARAMS coinParam;
  abstract final NetworkType type;
  bool get isWalletNetwork => value >= 0;
  bool get isImportedNetwork => value >= ChainConst.importedNetworkStartId;
  bool get supportCustomNode;
  Token get token => coinParam.token;
  int get coinDecimal => token.decimal;
  WalletNetwork copyWith({int? value, PARAMS? coinParam});
  String get networkName => token.name;
  String get networkSymbol => token.symbol;
  List<CryptoCoins> get coins;
  bool get supportImportNetwork => false;
  bool get supportWeb3;
  bool get allowSwap => false;
  String? get accountExplorer => ChainConst.getAddressExplorer(value);
  String? get txExplorer => ChainConst.getTxExplorer(value);
  Object get identifier;

  String get caip;
  String get wsIdentifier;
  String? getAccountExplorer(String? address) {
    if (address == null) return null;
    return accountExplorer?.replaceAll(NetworkCoinParamsConst.addrArgs, address);
  }

  String? getTransactionExplorer(String txId) {
    return txExplorer?.replaceAll(NetworkCoinParamsConst.txIdArgs, txId);
  }

  T cast<T extends WalletNetwork>() {
    if (this is! T) throw WalletExceptionConst.incorrectNetwork;
    return this as T;
  }

  static WalletNetwork deserialize({List<int>? bytes, CborObject? object}) {
    final CborTagValue toCborTag =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    final network = NetworkType.fromTags(toCborTag.tags);
    switch (network) {
      case NetworkType.bitcoinAndForked:
        return WalletBitcoinNetwork.deserialize(object: toCborTag);
      case NetworkType.bitcoinCash:
        return WalletBitcoinCashNetwork.deserialize(object: toCborTag);
      case NetworkType.xrpl:
        return WalletXRPNetwork.deserialize(object: toCborTag);
      case NetworkType.ethereum:
        return WalletEthereumNetwork.deserialize(object: toCborTag);
      case NetworkType.zcash:
        return WalletZcashNetwork.deserialize(object: toCborTag);
      case NetworkType.solana:
        return WalletSolanaNetwork.deserialize(object: toCborTag);
      case NetworkType.cardano:
        return WalletCardanoNetwork.deserialize(object: toCborTag);
      case NetworkType.cosmos:
        return WalletCosmosNetwork.deserialize(object: toCborTag);
      case NetworkType.ton:
        return WalletTonNetwork.deserialize(object: toCborTag);
      case NetworkType.tron:
        return WalletTronNetwork.deserialize(object: toCborTag);
      case NetworkType.substrate:
        return WalletSubstrateNetwork.deserialize(object: toCborTag);
      case NetworkType.stellar:
        return WalletStellarNetwork.deserialize(object: toCborTag);
      case NetworkType.monero:
        return WalletMoneroNetwork.deserialize(object: toCborTag);
      case NetworkType.aptos:
        return WalletAptosNetwork.deserialize(object: toCborTag);
      case NetworkType.sui:
        return WalletSuiNetwork.deserialize(object: toCborTag);
    }
  }

  @override
  List<CborObject?> get serializationItems => [value.toCbor(), coinParam.toCbor()];

  @override
  SerializationIdentifier get serializationIdentifier => type.identifier;
}

class WalletBitcoinNetwork extends WalletNetwork<BitcoinParams> {
  @override
  final int value;
  @override
  final BitcoinParams coinParam;
  @override
  bool get supportWeb3 => true;
  @override
  bool get allowSwap => true;
  @override
  String get caip => ChainConst.buildCaip2(type, identifier);
  @override
  String get wsIdentifier => coinParam.transacationNetwork.identifier;
  factory WalletBitcoinNetwork.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.bitconNetwork);
    return WalletBitcoinNetwork(cbor.rawValueAt(0),
        BitcoinParams.deserialize(object: cbor.objectAt<CborTagValue>(1)));
  }

  const WalletBitcoinNetwork(this.value, this.coinParam);

  bool get isBitcoin => true;

  @override
  NetworkType get type => NetworkType.bitcoinAndForked;

  @override
  List<BipCoins> get coins => coinParam.transacationNetwork.coins;

  CryptoCoins findCoinFromBitcoinAddressType(BitcoinAddressType type) {
    if (type.isP2sh) {
      return coins.firstWhere((element) => element.proposal == CoinProposal.bip49);
    }
    switch (type) {
      case P2pkhAddressType.p2pkh:
      case P2pkhAddressType.p2pkhwt:
      case PubKeyAddressType.p2pk:
        return coins.firstWhere((element) => element.proposal == CoinProposal.bip44);
      case SegwitAddressType.p2wsh:
      case SegwitAddressType.p2wpkh:
        return coins.firstWhere((element) => element.proposal == CoinProposal.bip84);
      default:
        return coins.firstWhere((element) => element.proposal == CoinProposal.bip86);
    }
  }

  @override
  List get variables => [value];

  @override
  bool get supportCustomNode => true;

  @override
  WalletBitcoinNetwork copyWith({int? value, BitcoinParams? coinParam}) {
    return WalletBitcoinNetwork(value ?? this.value, coinParam ?? this.coinParam);
  }

  @override
  String get identifier => switch (coinParam.transacationNetwork) {
        BitcoinSVNetwork.testnet => ChainConst.zeroBlockHash,
        _ => ChainConst.getDefaultGenesisBlock(value),
      };
}

class WalletBitcoinCashNetwork extends WalletBitcoinNetwork {
  @override
  String get caip => ChainConst.buildCaip2(
      type, coinParam.chainType.isMainnet ? "bitcoincash" : "bchtest");
  @override
  String get wsIdentifier => caip;
  @override
  WalletBitcoinCashNetwork copyWith({int? value, BitcoinParams? coinParam}) {
    return WalletBitcoinCashNetwork(value ?? this.value, coinParam ?? this.coinParam);
  }

  const WalletBitcoinCashNetwork(super.value, super.coinParam);
  @override
  bool get isBitcoin => false;

  @override
  NetworkType get type => NetworkType.bitcoinCash;

  factory WalletBitcoinCashNetwork.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.bitcoinCashNetwork);
    return WalletBitcoinCashNetwork(
      cbor.rawValueAt(0),
      BitcoinParams.deserialize(object: cbor.objectAt<CborTagValue>(1)),
    );
  }
}

class WalletXRPNetwork extends WalletNetwork<RippleNetworkParams> {
  @override
  final int value;
  @override
  final RippleNetworkParams coinParam;
  @override
  bool get supportWeb3 => true;
  @override
  String get caip => ChainConst.buildCaip2(type, coinParam.networkId.toString());

  @override
  String get wsIdentifier => caip;
  const WalletXRPNetwork(this.value, this.coinParam);

  factory WalletXRPNetwork.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.xrpNetwork);
    return WalletXRPNetwork(
      cbor.rawValueAt(0),
      RippleNetworkParams.deserialize(object: cbor.objectAt<CborTagValue>(1)),
    );
  }

  @override
  List<BipCoins> get coins {
    if (coinParam.mainnet) {
      return [Bip44Coins.ripple, Bip44Coins.rippleEd25519];
    }
    return [Bip44Coins.rippleTestnet, Bip44Coins.rippleTestnetED25519];
  }

  @override
  List get variables => [value];

  @override
  bool get supportCustomNode => true;

  @override
  NetworkType get type => NetworkType.xrpl;

  @override
  WalletXRPNetwork copyWith({int? value, RippleNetworkParams? coinParam}) {
    return WalletXRPNetwork(value ?? this.value, coinParam ?? this.coinParam);
  }

  @override
  Object get identifier => coinParam.identifier;
}
//

class WalletEthereumNetwork extends WalletNetwork<EthereumNetworkParams> {
  @override
  final int value;
  @override
  final EthereumNetworkParams coinParam;

  @override
  bool get supportWeb3 => true;

  @override
  String get caip => ChainConst.buildCaip2(type, coinParam.chainId.toString());

  @override
  String get wsIdentifier => "ethereum:${coinParam.chainId}";

  const WalletEthereumNetwork(this.value, this.coinParam);
  factory WalletEthereumNetwork.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.evmNetwork);
    return WalletEthereumNetwork(
      cbor.rawValueAt(0),
      EthereumNetworkParams.deserialize(object: cbor.objectAt<CborTagValue>(1)),
    );
  }
  @override
  WalletEthereumNetwork copyWith(
      {int? value, EthereumNetworkParams? coinParam, int? slip44}) {
    return WalletEthereumNetwork(value ?? this.value, coinParam ?? this.coinParam);
  }

  @override
  List<BipCoins> get coins {
    if (coinParam.mainnet) {
      return [Bip44Coins.ethereum];
    }
    return [Bip44Coins.ethereumTestnet];
  }

  @override
  List get variables => [value];
  @override
  bool get supportImportNetwork => true;

  @override
  bool get supportCustomNode => true;
  @override
  NetworkType get type => NetworkType.ethereum;

  static WalletEthereumNetwork create() {
    return WalletEthereumNetwork(
      -1,
      EthereumNetworkParams(
          transactionExplorer: null,
          addressExplorer: null,
          defaultNetwork: false,
          token: Token(name: "", symbol: "", decimal: 18),
          chainId: BigInt.zero,
          supportEIP1559: false,
          chainType: ChainType.testnet),
    );
  }

  @override
  Object get identifier => coinParam.identifier;

  @override
  String? get accountExplorer =>
      coinParam.addressExplorer ?? ChainConst.getAddressExplorer(value);
  @override
  String? get txExplorer =>
      coinParam.transactionExplorer ?? ChainConst.getTxExplorer(value);
}

class WalletTronNetwork extends WalletNetwork<TronNetworkParams> {
  @override
  final int value;
  @override
  final TronNetworkParams coinParam;
  const WalletTronNetwork(this.value, this.coinParam);
  @override
  bool get supportWeb3 => true;
  TronChainType get tronNetworkType => TronChainType.fromId(value);

  @override
  String get caip =>
      ChainConst.buildCaip2(type, tronNetworkType.genesisBlockNumber.toRadix16);

  @override
  String get wsIdentifier => caip;

  factory WalletTronNetwork.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.tvmNetwork);
    return WalletTronNetwork(
      cbor.rawValueAt(0),
      TronNetworkParams.deserialize(object: cbor.objectAt<CborTagValue>(1)),
    );
  }
  @override
  List<BipCoins> get coins {
    if (coinParam.mainnet) {
      return [Bip44Coins.tron];
    }
    return [Bip44Coins.tronTestnet];
  }

  @override
  List get variables => [value];

  @override
  bool get supportCustomNode => true;

  @override
  NetworkType get type => NetworkType.tron;

  @override
  WalletTronNetwork copyWith({int? value, TronNetworkParams? coinParam}) {
    return WalletTronNetwork(value ?? this.value, coinParam ?? this.coinParam);
  }

  String get genesisBlock => ChainConst.getDefaultGenesisBlock(value);
  @override
  Object get identifier => genesisBlock;
}

class WalletSolanaNetwork extends WalletNetwork<SolanaNetworkParams> {
  @override
  final int value;
  @override
  final SolanaNetworkParams coinParam;
  String get genesisBlock => ChainConst.getDefaultGenesisBlock(value);

  @override
  String get caip => ChainConst.buildCaip2(type, coinParam.type.genesis);

  @override
  bool get supportWeb3 => true;
  const WalletSolanaNetwork(this.value, this.coinParam);
  factory WalletSolanaNetwork.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.solanaNetwork);
    return WalletSolanaNetwork(
      cbor.rawValueAt(0),
      SolanaNetworkParams.deserialize(object: cbor.objectAt<CborTagValue>(1)),
    );
  }
  @override
  WalletSolanaNetwork copyWith({int? value, SolanaNetworkParams? coinParam}) {
    return WalletSolanaNetwork(value ?? this.value, coinParam ?? this.coinParam);
  }

  @override
  List<BipCoins> get coins {
    if (coinParam.mainnet) {
      return [Bip44Coins.solana];
    }
    return [Bip44Coins.solanaTestnet];
  }

  @override
  List get variables => [value];

  @override
  bool get supportCustomNode => true;

  @override
  NetworkType get type => NetworkType.solana;
  @override
  Object get identifier => genesisBlock;

  @override
  String get wsIdentifier => coinParam.type.identifier;
}

class WalletCardanoNetwork extends WalletNetwork<CardanoNetworkParams> {
  @override
  final int value;
  @override
  final CardanoNetworkParams coinParam;
  const WalletCardanoNetwork(this.value, this.coinParam);
  factory WalletCardanoNetwork.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.cardanoNetwork);
    return WalletCardanoNetwork(
      cbor.rawValueAt(0),
      CardanoNetworkParams.deserialize(object: cbor.objectAt<CborTagValue>(1)),
    );
  }

  @override
  List<BipCoins> get coins {
    return [
      if (coinParam.mainnet) ...[
        Bip44Coins.cardanoByronLedger,
        Bip44Coins.cardanoByronIcarus,
        Cip1852Coins.cardanoIcarus,
        Cip1852Coins.cardanoLedger,
        Cip0019Coins.byronLegacy
      ] else ...[
        Bip44Coins.cardanoByronIcarusTestnet,
        Bip44Coins.cardanoByronLedgerTestnet,
        Cip1852Coins.cardanoIcarusTestnet,
        Cip1852Coins.cardanoLedgerTestnet,
        Cip0019Coins.byronLegacyTestnet
      ]
    ];
  }

  @override
  List get variables => [value];

  @override
  bool get supportCustomNode => true;

  @override
  NetworkType get type => NetworkType.cardano;

  @override
  WalletCardanoNetwork copyWith({int? value, CardanoNetworkParams? coinParam}) {
    return WalletCardanoNetwork(value ?? this.value, coinParam ?? this.coinParam);
  }

  @override
  Object get identifier => coinParam.identifier;

  @override
  String get caip => ChainConst.buildCaip2(type, coinParam.chainId);

  @override
  String get wsIdentifier => caip;

  @override
  bool get supportWeb3 => true;
}

class WalletCosmosNetwork extends WalletNetwork<CosmosNetworkParams> {
  @override
  final int value;
  @override
  final CosmosNetworkParams coinParam;
  @override
  bool get supportWeb3 => true;
  @override
  String get caip => ChainConst.buildCaip2(type, coinParam.chainId);

  @override
  String get wsIdentifier => caip;
  const WalletCosmosNetwork(this.value, this.coinParam);
  factory WalletCosmosNetwork.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.cosmosNetwork);
    return WalletCosmosNetwork(
      cbor.rawValueAt(0),
      CosmosNetworkParams.deserialize(object: cbor.objectAt<CborTagValue>(1)),
    );
  }

  @override
  List<BipCoins> get coins {
    return coinParam.coins();
  }

  @override
  List get variables => [value];

  @override
  bool get supportCustomNode => true;
  @override
  bool get supportImportNetwork => true;

  @override
  NetworkType get type => NetworkType.cosmos;

  @override
  WalletCosmosNetwork copyWith({int? value, CosmosNetworkParams? coinParam}) {
    return WalletCosmosNetwork(value ?? this.value, coinParam ?? this.coinParam);
  }

  @override
  Object get identifier => coinParam.identifier;

  @override
  String? get accountExplorer =>
      coinParam.addressExplorer ?? ChainConst.getAddressExplorer(value);
  @override
  String? get txExplorer =>
      coinParam.transactionExplorer ?? ChainConst.getTxExplorer(value);
}

class WalletTonNetwork extends WalletNetwork<TonNetworkParams> {
  @override
  final int value;
  @override
  final TonNetworkParams coinParam;
  @override
  bool get supportWeb3 => true;

  const WalletTonNetwork(this.value, this.coinParam);
  factory WalletTonNetwork.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.tonNetwork);
    return WalletTonNetwork(
      cbor.rawValueAt(0),
      TonNetworkParams.deserialize(object: cbor.objectAt<CborTagValue>(1)),
    );
  }

  @override
  List<BipCoins> get coins {
    if (coinParam.mainnet) {
      return [Bip44Coins.tonMainnet];
    }
    return [Bip44Coins.tonTestnet];
  }

  @override
  List get variables => [value];

  @override
  bool get supportCustomNode => true;
  @override
  NetworkType get type => NetworkType.ton;

  @override
  WalletTonNetwork copyWith({int? value, TonNetworkParams? coinParam}) {
    return WalletTonNetwork(value ?? this.value, coinParam ?? this.coinParam);
  }

  @override
  Object get identifier => coinParam.chainId.id;

  @override
  String get caip => ChainConst.buildCaip2(type, coinParam.chainId.id.toString());

  @override
  String get wsIdentifier => caip;
}

class WalletSubstrateNetwork extends WalletNetwork<SubstrateNetworkParams> {
  @override
  final int value;
  @override
  final SubstrateNetworkParams coinParam;
  const WalletSubstrateNetwork(this.value, this.coinParam);
  factory WalletSubstrateNetwork.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.substrateNetwork);
    return WalletSubstrateNetwork(cbor.rawValueAt(0),
        SubstrateNetworkParams.deserialize(object: cbor.objectAt<CborTagValue>(1)));
  }

  @override
  List<CryptoCoins> get coins {
    List<CryptoCoins> coins = [];
    for (final i in coinParam.keyAlgorithms) {
      final List<CryptoCoins> keys = switch (i) {
        SubstrateKeyAlgorithm.ecdsa => [SubstrateCoins.genericSecp256k1],
        SubstrateKeyAlgorithm.ed25519 => [
            SubstrateCoins.genericEd25519,
            if (coinParam.mainnet)
              Bip44Coins.polkadotEd25519Slip
            else
              Bip44Coins.polkadotTestnetEd25519Slip,
          ],
        SubstrateKeyAlgorithm.sr25519 => [SubstrateCoins.genericSr25519],
        SubstrateKeyAlgorithm.ethereum => [
            if (coinParam.mainnet) Bip44Coins.ethereum else Bip44Coins.ethereumTestnet,
          ],
      };
      coins.addAll(keys);
    }
    return coins;
  }

  @override
  List get variables => [value];

  @override
  bool get supportCustomNode => true;

  @override
  NetworkType get type => NetworkType.substrate;

  @override
  WalletSubstrateNetwork copyWith({int? value, SubstrateNetworkParams? coinParam}) {
    return WalletSubstrateNetwork(value ?? this.value, coinParam ?? this.coinParam);
  }

  String get genesisBlock =>
      coinParam.gnesisBlock ?? ChainConst.getDefaultGenesisBlock(value);

  @override
  Object get identifier => genesisBlock;

  @override
  bool get supportImportNetwork => true;

  @override
  bool get supportWeb3 => true;
  @override
  String get caip => ChainConst.buildCaip2(type, genesisBlock);
  @override
  String get wsIdentifier => caip;
}

class WalletStellarNetwork extends WalletNetwork<StellarNetworkParams> {
  @override
  final int value;
  @override
  final StellarNetworkParams coinParam;

  @override
  bool get supportWeb3 => true;

  @override
  String get caip => ChainConst.buildCaip2(type, coinParam.stellarChainType.name);

  @override
  String get wsIdentifier => caip;

  const WalletStellarNetwork(this.value, this.coinParam);
  factory WalletStellarNetwork.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.stellar);
    return WalletStellarNetwork(
      cbor.rawValueAt(0),
      StellarNetworkParams.deserialize(object: cbor.objectAt<CborTagValue>(1)),
    );
  }

  @override
  List<BipCoins> get coins {
    if (coinParam.mainnet) {
      return [Bip44Coins.stellar];
    }
    return [Bip44Coins.stellarTestnet];
  }

  @override
  List get variables => [value];

  @override
  bool get supportCustomNode => false;
  @override
  NetworkType get type => NetworkType.stellar;

  @override
  WalletStellarNetwork copyWith({int? value, StellarNetworkParams? coinParam}) {
    return WalletStellarNetwork(value ?? this.value, coinParam ?? this.coinParam);
  }

  @override
  Object get identifier => coinParam.identifier;
}

class WalletMoneroNetwork extends WalletNetwork<MoneroNetworkParams> {
  @override
  final int value;
  @override
  final MoneroNetworkParams coinParam;

  @override
  bool get supportWeb3 => coinParam.network != MoneroNetwork.testnet;

  const WalletMoneroNetwork(this.value, this.coinParam);
  factory WalletMoneroNetwork.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.monero);
    return WalletMoneroNetwork(
      cbor.rawValueAt(0),
      MoneroNetworkParams.deserialize(object: cbor.objectAt<CborTagValue>(1)),
    );
  }

  @override
  List<BipCoins> get coins {
    if (coinParam.mainnet) {
      return [Bip44Coins.moneroEd25519Slip];
    }
    return [Bip44Coins.moneroEd25519Slip];
  }

  @override
  List get variables => [value];

  @override
  bool get supportCustomNode => true;
  @override
  NetworkType get type => NetworkType.monero;

  @override
  WalletMoneroNetwork copyWith({int? value, MoneroNetworkParams? coinParam}) {
    return WalletMoneroNetwork(value ?? this.value, coinParam ?? this.coinParam);
  }

  String get genesisBlock => ChainConst.getDefaultGenesisBlock(value);
  @override
  Object get identifier => genesisBlock;

  @override
  String get caip => ChainConst.buildCaip2(type, genesisBlock);

  @override
  String get wsIdentifier => caip;
}

class WalletAptosNetwork extends WalletNetwork<AptosNetworkParams> {
  @override
  final int value;
  @override
  final AptosNetworkParams coinParam;
  @override
  bool get supportWeb3 => true;

  @override
  String get caip => ChainConst.buildCaip2(type, coinParam.aptosChainType.name);

  @override
  String get wsIdentifier => coinParam.aptosChainType.identifier;
  const WalletAptosNetwork(this.value, this.coinParam);
  factory WalletAptosNetwork.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.aptos);
    return WalletAptosNetwork(
      cbor.rawValueAt(0),
      AptosNetworkParams.deserialize(object: cbor.objectAt<CborTagValue>(1)),
    );
  }
  @override
  WalletAptosNetwork copyWith({int? value, AptosNetworkParams? coinParam}) {
    return WalletAptosNetwork(value ?? this.value, coinParam ?? this.coinParam);
  }

  @override
  List<BipCoins> get coins {
    return [
      Bip44Coins.aptos,
      Bip44Coins.aptosEd25519SingleKey,
      Bip44Coins.aptosSecp256k1SingleKey,
    ];
  }

  @override
  List get variables => [value];

  @override
  bool get supportCustomNode => true;

  @override
  NetworkType get type => NetworkType.aptos;
  @override
  Object get identifier => coinParam.aptosChainType;
}

class WalletSuiNetwork extends WalletNetwork<SuiNetworkParams> {
  @override
  final int value;
  @override
  final SuiNetworkParams coinParam;
  @override
  bool get supportWeb3 => true;
  @override
  String get caip => ChainConst.buildCaip2(type, coinParam.suiChain.name);
  const WalletSuiNetwork(this.value, this.coinParam);
  factory WalletSuiNetwork.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: AppSerializationIdentifier.sui);
    return WalletSuiNetwork(
      cbor.rawValueAt(0),
      SuiNetworkParams.deserialize(object: cbor.objectAt<CborTagValue>(1)),
    );
  }
  @override
  WalletSuiNetwork copyWith({int? value, SuiNetworkParams? coinParam}) {
    return WalletSuiNetwork(value ?? this.value, coinParam ?? this.coinParam);
  }

  @override
  List<BipCoins> get coins {
    return [
      Bip44Coins.sui,
      Bip44Coins.suiSecp256k1,
      Bip44Coins.suiSecp256r1,
    ];
  }

  @override
  List get variables => [value];

  @override
  bool get supportCustomNode => true;

  @override
  NetworkType get type => NetworkType.sui;
  @override
  Object get identifier => coinParam.identifier;

  @override
  String get wsIdentifier => coinParam.suiChain.identifier;
}

class WalletZcashNetwork extends WalletNetwork<ZcashNetworkParams> {
  @override
  final int value;
  @override
  final ZcashNetworkParams coinParam;
  @override
  bool get supportWeb3 => true;
  @override
  bool get allowSwap => false;
  const WalletZcashNetwork(this.value, this.coinParam);

  @override
  String get caip => ChainConst.buildCaip2(type, coinParam.web3ChainIdentifier);

  @override
  String get wsIdentifier => caip;
  factory WalletZcashNetwork.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.zcash);
    return WalletZcashNetwork(cbor.rawValueAt(0),
        ZcashNetworkParams.deserialize(object: cbor.objectAt<CborTagValue>(1)));
  }

  @override
  NetworkType get type => NetworkType.zcash;

  @override
  List<CryptoCoins> get coins => switch (coinParam.network) {
        ZcashNetwork.mainnet => [
            ZIP32Coins.zCashOrchard,
            ZIP32Coins.zCashSapling,
            Bip44Coins.zcash,
            Bip49Coins.zcash
          ],
        ZcashNetwork.testnet => [
            ZIP32Coins.zCashTestnetOrchard,
            ZIP32Coins.zCashTestnetSapling,
            Bip44Coins.zcashTestnet,
            Bip49Coins.zcashTestnet
          ],
        ZcashNetwork.regtest => [
            ZIP32Coins.zCashRegtestOrchard,
            ZIP32Coins.zCashRegtestSapling,
            Bip44Coins.zcashRegtest,
            Bip49Coins.zcashRegtest
          ],
      };

  @override
  List get variables => [value];

  @override
  bool get supportCustomNode => true;

  @override
  WalletZcashNetwork copyWith({int? value, ZcashNetworkParams? coinParam}) {
    return WalletZcashNetwork(value ?? this.value, coinParam ?? this.coinParam);
  }

  @override
  String get identifier => switch (coinParam.network) {
        ZcashNetwork.regtest => ChainConst.zeroBlockHash,
        _ => ChainConst.getDefaultGenesisBlock(value),
      };

  String? getNu6BlockHash() {
    if (coinParam.network == ZcashNetwork.regtest) return null;
    return ChainConst.getSpeceficBlockHash(value);
  }
}
