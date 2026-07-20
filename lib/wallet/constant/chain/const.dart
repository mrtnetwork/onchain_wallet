import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/bip/bip.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/constant/constant.dart';
import 'package:on_chain_wallet/wallet/models/models.dart';
import 'package:polkadot_dart/polkadot_dart.dart'
    show
        SS58Const,
        SubstrateConsensusRole,
        SubstrateChainType,
        SubstrateRelaySystem,
        SubstrateKeyAlgorithm;

class _DefaultAppCoins {
  static const BitcoinParams bitcoinCashMainnet = BitcoinParams(
    transacationNetwork: BitcoinCashNetwork.mainnet,
    chainType: ChainType.mainnet,
    token: Token.unsafe(
        name: "BitcoinCash",
        market: CoingeckoCoin(apiId: "bitcoin-cash", coinName: "bitcoin-cash"),
        symbol: "BCH",
        decimal: 8,
        assetLogo: APPConst.bch,
        nameView: "BitcoinCash",
        symbolView: "BCH"),
  );
  static const BitcoinParams bitcoinCashChipnet = BitcoinParams(
    transacationNetwork: BitcoinCashNetwork.testnet,
    chainType: ChainType.testnet,
    token: Token.unsafe(
        name: "BitcoinCash chipnet",
        symbol: "tBCH",
        market: CoingeckoCoin(apiId: "bitcoin-cash", coinName: "bitcoin-cash"),
        decimal: 8,
        assetLogo: APPConst.bch,
        nameView: "BitcoinCash chipnet",
        symbolView: "tBCH"),
  );
  static const BitcoinParams bitcoinMainnet = BitcoinParams(
    transacationNetwork: BitcoinNetwork.mainnet,
    chainType: ChainType.mainnet,
    token: Token.unsafe(
        name: "Bitcoin",
        symbol: "BTC",
        market: CoingeckoCoin(apiId: "bitcoin", coinName: "bitcoin"),
        decimal: 8,
        nameView: "Bitcoin",
        symbolView: "BTC",
        assetLogo: APPConst.btc),
  );
  static const BitcoinParams bitcoinTestnet = BitcoinParams(
    transacationNetwork: BitcoinNetwork.testnet,
    chainType: ChainType.testnet,
    token: Token.unsafe(
      name: "Bitcoin testnet",
      symbol: "tBTC",
      market: CoingeckoCoin(apiId: "bitcoin", coinName: "bitcoin"),
      decimal: 8,
      assetLogo: APPConst.btc,
      nameView: "Bitcoin testnet",
      symbolView: "tBTC",
    ),
  );
  static const BitcoinParams bitcoinTestnet4 = BitcoinParams(
    transacationNetwork: BitcoinNetwork.testnet4,
    chainType: ChainType.testnet,
    token: Token.unsafe(
        name: "Bitcoin testnet4",
        symbol: "tBTC",
        market: CoingeckoCoin(apiId: "bitcoin", coinName: "bitcoin"),
        decimal: 8,
        nameView: "Bitcoin testnet4",
        symbolView: "tBTC",
        assetLogo: APPConst.btc),
  );
  static const BitcoinParams litecoinMainnet = BitcoinParams(
    transacationNetwork: LitecoinNetwork.mainnet,
    chainType: ChainType.mainnet,
    token: Token.unsafe(
        name: "Litecoin",
        symbol: "LTC",
        market: CoingeckoCoin(apiId: "litecoin", coinName: "litecoin"),
        decimal: 8,
        nameView: "Litecoin",
        symbolView: "LTC",
        assetLogo: APPConst.ltc),
  );
  static const BitcoinParams litecoinTestnet = BitcoinParams(
    transacationNetwork: LitecoinNetwork.testnet,
    chainType: ChainType.testnet,
    token: Token.unsafe(
        name: "Litecoin testnet",
        symbol: "tLTC",
        market: CoingeckoCoin(apiId: "litecoin", coinName: "litecoin"),
        decimal: 8,
        nameView: "Litecoin testnet",
        symbolView: "tLTC",
        assetLogo: APPConst.ltc),
  );
  static const BitcoinParams dogecoinMainnet = BitcoinParams(
    transacationNetwork: DogecoinNetwork.mainnet,
    chainType: ChainType.mainnet,
    token: Token.unsafe(
        name: "Dogecoin",
        symbol: "Ɖ",
        market: CoingeckoCoin(apiId: "dogecoin", coinName: "dogecoin"),
        decimal: 8,
        nameView: "Dogecoin",
        symbolView: "Ɖ",
        assetLogo: APPConst.doge),
  );
  static const BitcoinParams pepecoinMainnet = BitcoinParams(
    transacationNetwork: PepeNetwork.mainnet,
    chainType: ChainType.mainnet,
    token: Token.unsafe(
        name: "Pepecoin",
        symbol: "₱",
        nameView: "Pepecoin",
        symbolView: "₱",
        decimal: 8,
        market: CoingeckoCoin(apiId: "pepecoin-network", coinName: "pepecoin-network"),
        assetLogo: APPConst.pepecoin),
  );
  static const BitcoinParams dogeTestnet = BitcoinParams(
    transacationNetwork: DogecoinNetwork.testnet,
    chainType: ChainType.testnet,
    token: Token.unsafe(
      name: "Dogecoin testnet",
      symbol: "tƉ",
      nameView: "Dogecoin testnet",
      symbolView: "tƉ",
      market: CoingeckoCoin(apiId: "dogecoin", coinName: "dogecoin"),
      decimal: 8,
      assetLogo: APPConst.doge,
    ),
  );
  static const BitcoinParams bsvMainnet = BitcoinParams(
    transacationNetwork: BitcoinSVNetwork.mainnet,
    chainType: ChainType.mainnet,
    token: Token.unsafe(
      name: "BitcoinSV",
      symbol: "BSV",
      nameView: "BitcoinSV",
      symbolView: "BSV",
      market: CoingeckoCoin(apiId: "bitcoin-cash-sv", coinName: "bitcoin-sv"),
      decimal: 8,
      assetLogo: APPConst.bsv,
    ),
  );
  static const BitcoinParams bsvRegtest = BitcoinParams(
    transacationNetwork: BitcoinSVNetwork.testnet,
    chainType: ChainType.testnet,
    token: Token.unsafe(
      name: "BitcoinSV Regtest",
      symbol: "tBSV",
      nameView: "BitcoinSV Regtest",
      symbolView: "tBSV",
      market: CoingeckoCoin(apiId: "bitcoin-cash-sv", coinName: "bitcoin-sv"),
      decimal: 8,
      assetLogo: APPConst.bsv,
    ),
  );
  static const BitcoinParams dashMainnet = BitcoinParams(
    chainType: ChainType.mainnet,
    token: Token.unsafe(
      name: "Dash",
      symbol: "DASH",
      nameView: "Dash",
      symbolView: "DASH",
      market: CoingeckoCoin(apiId: "dash", coinName: "dash"),
      decimal: 8,
      assetLogo: APPConst.dash,
    ),
    transacationNetwork: DashNetwork.mainnet,
  );
  static const RippleNetworkParams xrpMainnet = RippleNetworkParams(
      token: Token.unsafe(
        name: "Ripple",
        symbol: "XRP",
        nameView: "Ripple",
        symbolView: "XRP",
        decimal: 6,
        market: CoingeckoCoin(apiId: "ripple", coinName: "xrp"),
        assetLogo: APPConst.xrp,
      ),
      chainType: ChainType.mainnet,
      networkId: 0);
  static const RippleNetworkParams xrpTestnet = RippleNetworkParams(
      token: Token.unsafe(
        name: "Ripple testnet",
        symbol: "tXRP",
        nameView: "Ripple testnet",
        symbolView: "tXRP",
        decimal: 6,
        market: CoingeckoCoin(apiId: "ripple", coinName: "xrp"),
        assetLogo: APPConst.xrp,
      ),
      chainType: ChainType.testnet,
      networkId: 1);
  static const RippleNetworkParams xrpDevnet = RippleNetworkParams(
      token: Token.unsafe(
        name: "Ripple devnet",
        symbol: "tXRP",
        nameView: "Ripple devnet",
        symbolView: "tXRP",
        decimal: 6,
        market: CoingeckoCoin(apiId: "ripple", coinName: "xrp"),
        assetLogo: APPConst.xrp,
      ),
      chainType: ChainType.testnet,
      networkId: 2);

  static const EthereumNetworkParams ethreumMainnet = EthereumNetworkParams.unsafe(
    id: "1",
    chainType: ChainType.mainnet,
    supportEIP1559: true,
    token: Token.unsafe(
      name: "Ethereum",
      symbol: "ETH",
      market: CoingeckoCoin(apiId: "ethereum", coinName: "ethereum"),
      decimal: 18,
      assetLogo: APPConst.eth,
      nameView: "Ethereum",
      symbolView: "ETH",
    ),
  );

  static const EthereumNetworkParams moonbeamEthereum = EthereumNetworkParams.unsafe(
    id: "1284",
    chainType: ChainType.mainnet,
    supportEIP1559: true,
    token: Token.unsafe(
      name: "Moonbeam",
      symbol: "GLMR",
      nameView: "Moonbeam",
      symbolView: "GLMR",
      market: CoingeckoCoin(apiId: "moonbeam", coinName: "moonbeam", symbol: "GLMR"),
      decimal: 18,
      assetLogo: APPConst.moonbeam,
    ),
  );
  static const EthereumNetworkParams moonRiveEthereum = EthereumNetworkParams.unsafe(
    id: "1285",
    chainType: ChainType.mainnet,
    supportEIP1559: true,
    token: Token.unsafe(
      name: "Moonriver",
      symbol: "MOVR",
      nameView: "Moonriver",
      symbolView: "MOVR",
      market: CoingeckoCoin(apiId: "moonriver", coinName: "moonriver", symbol: "MOVR"),
      decimal: 18,
      assetLogo: APPConst.moonriver,
    ),
  );
  static const EthereumNetworkParams avalanche = EthereumNetworkParams.unsafe(
    id: "43114",
    chainType: ChainType.mainnet,
    supportEIP1559: true,
    token: Token.unsafe(
      name: "Avalanche",
      symbol: "AVAX",
      nameView: "Avalanche",
      symbolView: "AVAX",
      market: CoingeckoCoin(apiId: "avalanche-2", coinName: "avalanche"),
      decimal: 18,
      assetLogo: APPConst.avalance,
    ),
  );
  static const EthereumNetworkParams arbitrum = EthereumNetworkParams.unsafe(
    id: "42161",
    chainType: ChainType.mainnet,
    supportEIP1559: true,
    token: Token.unsafe(
      name: "Arbitrum",
      symbol: "ARB",
      nameView: "Arbitrum",
      symbolView: "ARB",
      market: CoingeckoCoin(apiId: "arbitrum", coinName: "arbitrum"),
      decimal: 18,
      assetLogo: APPConst.arbitrum,
    ),
  );
  static const EthereumNetworkParams arbitrumTestnet = EthereumNetworkParams.unsafe(
    id: "421614",
    chainType: ChainType.testnet,
    supportEIP1559: true,
    token: Token.unsafe(
      name: "Arbitrum Sepolia",
      symbol: "tARB",
      nameView: "Arbitrum Sepolia",
      symbolView: "tARB",
      market: CoingeckoCoin(apiId: "arbitrum", coinName: "arbitrum"),
      decimal: 18,
      assetLogo: APPConst.arbitrum,
    ),
  );

  static const EthereumNetworkParams base = EthereumNetworkParams.unsafe(
    id: "8453",
    chainType: ChainType.mainnet,
    supportEIP1559: true,
    token: Token.unsafe(
      name: "Base Mainnet",
      symbol: "ETH",
      nameView: "Base Mainnet",
      symbolView: "ETH",
      decimal: 18,
      assetLogo: APPConst.base,
    ),
  );
  static const EthereumNetworkParams optimism = EthereumNetworkParams.unsafe(
    id: "10",
    chainType: ChainType.mainnet,
    supportEIP1559: true,
    token: Token.unsafe(
      name: "OP Mainnet",
      symbol: "ETH",
      nameView: "OP Mainnet",
      symbolView: "ETH",
      decimal: 18,
      assetLogo: APPConst.optimistic,
    ),
  );
  static const EthereumNetworkParams ethreumTestnet = EthereumNetworkParams.unsafe(
    id: "11155111",
    chainType: ChainType.testnet,
    supportEIP1559: true,
    token: Token.unsafe(
      name: "Ethereum Sepolia testnet",
      symbol: "tETH",
      nameView: "Ethereum Sepolia testnet",
      symbolView: "tETH",
      market: CoingeckoCoin(apiId: "ethereum", coinName: "ethereum"),
      decimal: 18,
      assetLogo: APPConst.eth,
    ),
  );
  static const EthereumNetworkParams polygon = EthereumNetworkParams.unsafe(
    id: "137",
    supportEIP1559: true,
    chainType: ChainType.mainnet,
    token: Token.unsafe(
      name: "Polygon",
      symbol: "MATIC",
      nameView: "Polygon",
      symbolView: "MATIC",
      market: CoingeckoCoin(apiId: "matic-network", coinName: "polygon"),
      decimal: 18,
      assetLogo: APPConst.matic,
    ),
  );
  static const EthereumNetworkParams polygonTestnet = EthereumNetworkParams.unsafe(
    id: "80001",
    supportEIP1559: true,
    chainType: ChainType.testnet,
    token: Token.unsafe(
      name: "Polygon mumbai testnet",
      symbol: "tMATIC",
      nameView: "Polygon mumbai testnet",
      symbolView: "tMATIC",
      market: CoingeckoCoin(apiId: "matic-network", coinName: "polygon"),
      decimal: 18,
      assetLogo: APPConst.matic,
    ),
  );
  static const EthereumNetworkParams bnb = EthereumNetworkParams.unsafe(
    id: "56",
    supportEIP1559: false,
    chainType: ChainType.mainnet,
    token: Token.unsafe(
        name: "BNB Smart Chain",
        symbol: "BNB",
        nameView: "BNB Smart Chain",
        symbolView: "BNB",
        market: CoingeckoCoin(apiId: "binancecoin", coinName: "bnb"),
        decimal: 18,
        assetLogo: APPConst.bnb),
  );
  static const EthereumNetworkParams bnbTestnet = EthereumNetworkParams.unsafe(
    id: "97",
    chainType: ChainType.testnet,
    supportEIP1559: false,
    token: Token.unsafe(
        name: "BNB Smart chain testnet",
        symbol: "tBNB",
        nameView: "BNB Smart chain testnet",
        symbolView: "tBNB",
        market: CoingeckoCoin(apiId: "binancecoin", coinName: "bnb"),
        decimal: 18,
        assetLogo: APPConst.bnb),
  );

  /// tron networks
  static const TronNetworkParams tronShasta = TronNetworkParams(
    chainType: ChainType.testnet,
    token: Token.unsafe(
      name: "Tron shasta testnet",
      symbol: "tTRX",
      nameView: "Tron shasta testnet",
      symbolView: "tTRX",
      market: CoingeckoCoin(apiId: "tron", coinName: "tron"),
      decimal: 6,
      assetLogo: APPConst.trx,
    ),
  );
  static const TronNetworkParams tronNile = TronNetworkParams(
    chainType: ChainType.testnet,
    token: Token.unsafe(
      name: "Tron nile testnet",
      symbol: "tTRX",
      nameView: "Tron nile testnet",
      symbolView: "tTRX",
      market: CoingeckoCoin(apiId: "tron", coinName: "tron"),
      decimal: 6,
      assetLogo: APPConst.trx,
    ),
  );
  static const TronNetworkParams tron = TronNetworkParams(
    chainType: ChainType.mainnet,
    token: Token.unsafe(
      name: "Tron",
      symbol: "TRX",
      nameView: "Tron",
      symbolView: "TRX",
      decimal: 6,
      market: CoingeckoCoin(apiId: "tron", coinName: "tron"),
      assetLogo: APPConst.trx,
    ),
  );

  static const SolanaNetworkParams solana = SolanaNetworkParams(
      chainType: ChainType.mainnet,
      token: Token.unsafe(
        name: "Solana",
        symbol: "SOL",
        nameView: "Solana",
        symbolView: "SOL",
        market: CoingeckoCoin(apiId: "solana", coinName: "solana"),
        decimal: SolanaConst.decimal,
        assetLogo: APPConst.sol,
      ),
      chainId: 101,
      type: SolanaNetworkType.mainnet);
  static const SolanaNetworkParams solanaTestnet = SolanaNetworkParams(
      chainType: ChainType.testnet,
      token: Token.unsafe(
        name: "Solana testnet",
        symbol: "tSOL",
        nameView: "Solana testnet",
        symbolView: "tSOL",
        market: CoingeckoCoin(apiId: "solana", coinName: "solana"),
        decimal: SolanaConst.decimal,
        assetLogo: APPConst.sol,
      ),
      chainId: 102,
      type: SolanaNetworkType.testnet);
  static const SolanaNetworkParams solanaDevnet = SolanaNetworkParams(
      chainType: ChainType.testnet,
      token: Token.unsafe(
          name: "Solana devnet",
          symbol: "tSOL",
          nameView: "Solana devnet",
          symbolView: "tSOL",
          market: CoingeckoCoin(apiId: "solana", coinName: "solana"),
          decimal: SolanaConst.decimal,
          assetLogo: APPConst.sol),
      chainId: 103,
      type: SolanaNetworkType.devnet);

  static const CardanoNetworkParams cardanoPreprod = CardanoNetworkParams(
      chainType: ChainType.testnet,
      token: Token.unsafe(
        name: "Cardano preprod",
        symbol: "tADA",
        nameView: "Cardano preprod",
        symbolView: "tADA",
        market: CoingeckoCoin(apiId: "cardano", coinName: "cardano"),
        decimal: 6,
        assetLogo: APPConst.ada,
      ),
      networkType: ADANetwork.testnetPreprod);
  static const CardanoNetworkParams cardano = CardanoNetworkParams(
      chainType: ChainType.mainnet,
      token: Token.unsafe(
        name: "Cardano",
        symbol: "ADA",
        nameView: "Cardano",
        symbolView: "ADA",
        market: CoingeckoCoin(apiId: "cardano", coinName: "cardano"),
        decimal: 6,
        assetLogo: APPConst.ada,
      ),
      networkType: ADANetwork.mainnet);
  static const CosmosNetworkParams cosmosTestnet = CosmosNetworkParams.unsafe(
      networkType: CosmosNetworkTypes.main,
      chainType: ChainType.testnet,
      hrp: CosmosAddrConst.accHRP,
      chainRegisteryName: "cosmosicsprovidertestnet",
      denom: "uatom",
      chainId: "provider",
      feeTokens: [
        CosmosFeeToken.unsafe(
            average: "0.025",
            hight: "0.03",
            low: "0.01",
            token: Token.unsafe(
                name: "ICS Provider Testnet",
                symbol: "tATOM",
                nameView: "ICS Provider Testnet",
                symbolView: "tATOM",
                market: CoingeckoCoin(apiId: "cosmos", coinName: "cosmos-hub"),
                decimal: 6,
                assetLogo: APPConst.atom),
            denom: 'uatom')
      ],
      token: Token.unsafe(
          name: "ICS Provider Testnet",
          symbol: "tATOM",
          nameView: "ICS Provider Testnet",
          symbolView: "tATOM",
          market: CoingeckoCoin(apiId: "cosmos", coinName: "cosmos-hub"),
          decimal: 6,
          assetLogo: APPConst.atom),
      keysAlgs: [
        CosmosKeysAlgs.secp256k1,
      ]);
  static const CosmosNetworkParams cosmos = CosmosNetworkParams.unsafe(
      networkType: CosmosNetworkTypes.main,
      chainType: ChainType.mainnet,
      hrp: CosmosAddrConst.accHRP,
      chainRegisteryName: "cosmoshub",
      chainId: "cosmoshub-4",
      denom: "uatom",
      feeTokens: [
        CosmosFeeToken.unsafe(
            average: "0.025",
            hight: "0.03",
            low: "0.01",
            token: Token.unsafe(
              name: "Cosmos hub",
              symbol: "ATOM",
              nameView: "Cosmos hub",
              symbolView: "ATOM",
              market: CoingeckoCoin(apiId: "cosmos", coinName: "cosmos-hub"),
              decimal: 6,
              assetLogo: APPConst.atom,
            ),
            denom: 'uatom')
      ],
      token: Token.unsafe(
        name: "Cosmos hub",
        symbol: "ATOM",
        nameView: "Cosmos hub",
        symbolView: "ATOM",
        market: CoingeckoCoin(apiId: "cosmos", coinName: "cosmos-hub"),
        decimal: 6,
        assetLogo: APPConst.atom,
      ),
      keysAlgs: [
        CosmosKeysAlgs.secp256k1,
      ]);
  static const CosmosNetworkParams maya = CosmosNetworkParams.unsafe(
      chainType: ChainType.mainnet,
      hrp: CosmosAddrConst.mayaProtocol,
      chainRegisteryName: "mayachain",
      denom: "cacao",
      feeTokens: [
        CosmosFeeToken.unsafe(
            average: "2000000000",
            token: Token.unsafe(
              name: "Maya Protocol",
              symbol: "Cacao",
              nameView: "Maya Protocol",
              symbolView: "Cacao",
              market: CoingeckoCoin(apiId: "cacao", coinName: "maya-protocol"),
              decimal: 10,
              assetLogo: APPConst.cacao,
            ),
            denom: 'cacao')
      ],
      // coins: [const CosmosFeeToken.unsafe(decimal: 10, denom: 'cacao')],
      networkType: CosmosNetworkTypes.thorAndForked,
      token: Token.unsafe(
        name: "Maya Protocol",
        symbol: "Cacao",
        nameView: "Maya Protocol",
        symbolView: "Cacao",
        market: CoingeckoCoin(apiId: "cacao", coinName: "maya-protocol"),
        decimal: 10,
        assetLogo: APPConst.cacao,
      ),
      chainId: "mayachain-mainnet-v1",
      networkConstantUri: "https://mayanode.mayachain.info/mayachain/constants",
      keysAlgs: [
        CosmosKeysAlgs.secp256k1,
      ]);
  static const CosmosNetworkParams thorchain = CosmosNetworkParams.unsafe(
      chainType: ChainType.mainnet,
      hrp: CosmosAddrConst.thor,
      chainRegisteryName: "thorchain",
      denom: "rune",
      feeTokens: [
        CosmosFeeToken.unsafe(
            average: "2000000",
            token: Token.unsafe(
                name: "THORChain",
                symbol: "Rune",
                nameView: "THORChain",
                symbolView: "Rune",
                market: CoingeckoCoin(apiId: "thorchain", coinName: "thorchain"),
                decimal: 8,
                assetLogo: APPConst.thor),
            denom: 'rune')
      ],
      bip32CoinType: 931,
      networkType: CosmosNetworkTypes.thorAndForked,
      token: Token.unsafe(
          name: "THORChain",
          symbol: "Rune",
          nameView: "THORChain",
          symbolView: "Rune",
          market: CoingeckoCoin(apiId: "thorchain", coinName: "thorchain"),
          decimal: 8,
          assetLogo: APPConst.thor),
      chainId: "thorchain-1",
      networkConstantUri: "https://thornode.ninerealms.com/thorchain/constants",
      keysAlgs: [CosmosKeysAlgs.secp256k1]);
  static const CosmosNetworkParams kujiraTestnet = CosmosNetworkParams.unsafe(
      chainType: ChainType.testnet,
      hrp: CosmosAddrConst.kujira,
      chainRegisteryName: "kujiratestnet",
      denom: "ukuji",
      feeTokens: [
        CosmosFeeToken.unsafe(
            average: "0.0051",
            hight: "0.00681",
            low: "0.0034",
            token: Token.unsafe(
                name: "Kujira Testnet",
                symbol: "tKuji",
                nameView: "Kujira Testnet",
                symbolView: "tKuji",
                market: CoingeckoCoin(apiId: "kujira", coinName: "kujira"),
                decimal: 6,
                assetLogo: APPConst.kujira),
            denom: 'ukuji')
      ],
      networkType: CosmosNetworkTypes.forked,
      token: Token.unsafe(
          name: "Kujira Testnet",
          symbol: "tKuji",
          nameView: "Kujira Testnet",
          symbolView: "tKuji",
          market: CoingeckoCoin(apiId: "kujira", coinName: "kujira"),
          decimal: 6,
          assetLogo: APPConst.kujira),
      chainId: "harpoon-4",
      keysAlgs: [
        CosmosKeysAlgs.secp256k1,
      ]);
  static const CosmosNetworkParams kujira = CosmosNetworkParams.unsafe(
      chainType: ChainType.mainnet,
      hrp: CosmosAddrConst.kujira,
      denom: "ukuji",
      chainRegisteryName: "kujira",
      feeTokens: [
        CosmosFeeToken.unsafe(
            average: "0.0051",
            hight: "0.00681",
            low: "0.0034",
            token: Token.unsafe(
                name: "Kujira",
                symbol: "Kuji",
                nameView: "Kujira",
                symbolView: "Kuji",
                market: CoingeckoCoin(apiId: "kujira", coinName: "kujira"),
                decimal: 6,
                assetLogo: APPConst.kujira),
            denom: 'ukuji')
      ],
      networkType: CosmosNetworkTypes.forked,
      token: Token.unsafe(
          name: "Kujira",
          symbol: "Kuji",
          nameView: "Kujira",
          symbolView: "Kuji",
          market: CoingeckoCoin(apiId: "kujira", coinName: "kujira"),
          decimal: 6,
          assetLogo: APPConst.kujira),
      chainId: "kaiyo-1",
      keysAlgs: [
        CosmosKeysAlgs.secp256k1,
      ]);

  static const CosmosNetworkParams osmosisTestnet = CosmosNetworkParams.unsafe(
      networkType: CosmosNetworkTypes.main,
      chainType: ChainType.testnet,
      hrp: CosmosConst.osmoHrp,
      chainRegisteryName: "osmosistestnet",
      feeTokens: [
        CosmosFeeToken.unsafe(
            average: "0.04",
            hight: "0.04",
            low: "0.0025",
            token: Token.unsafe(
              name: "Osmo testnet",
              symbol: "tOsmo",
              nameView: "Osmo testnet",
              symbolView: "tOsmo",
              decimal: 6,
              market: CoingeckoCoin(apiId: "osmosis", coinName: "osmosis"),
              assetLogo: APPConst.osmo,
            ),
            denom: 'uosmo')
      ],
      denom: "uosmo",
      token: Token.unsafe(
        name: "Osmo testnet",
        symbol: "tOsmo",
        nameView: "Osmo testnet",
        symbolView: "tOsmo",
        decimal: 6,
        market: CoingeckoCoin(apiId: "osmosis", coinName: "osmosis"),
        assetLogo: APPConst.osmo,
      ),
      chainId: "osmo-test-5",
      keysAlgs: [CosmosKeysAlgs.secp256k1]);
  static const CosmosNetworkParams osmosis = CosmosNetworkParams.unsafe(
      networkType: CosmosNetworkTypes.main,
      chainRegisteryName: "osmosis",
      chainType: ChainType.mainnet,
      hrp: CosmosConst.osmoHrp,
      denom: "uosmo",
      feeTokens: [
        CosmosFeeToken.unsafe(
            average: "0.04",
            hight: "0.04",
            low: "0.0025",
            token: Token.unsafe(
              name: "Osmosis",
              symbol: "Osmo",
              nameView: "Osmosis",
              symbolView: "Osmo",
              decimal: 6,
              market: CoingeckoCoin(apiId: "osmosis", coinName: "osmosis"),
              assetLogo: APPConst.osmo,
            ),
            denom: 'uosmo')
      ],
      token: Token.unsafe(
        name: "Osmosis",
        symbol: "Osmo",
        nameView: "Osmosis",
        symbolView: "Osmo",
        decimal: 6,
        market: CoingeckoCoin(apiId: "osmosis", coinName: "osmosis"),
        assetLogo: APPConst.osmo,
      ),
      chainId: "osmosis-1",
      keysAlgs: [
        CosmosKeysAlgs.secp256k1,
      ]);
  static const TonNetworkParams tonTestnet = TonNetworkParams(
    chainType: ChainType.testnet,
    token: Token.unsafe(
      name: "Gram testnet",
      symbol: "tGRAM",
      nameView: "Gram testnet",
      symbolView: "tGRAM",
      decimal: 9,
      market: CoingeckoCoin(apiId: "the-open-network", coinName: "gram"),
      assetLogo: APPConst.gram,
    ),
  );

  static const TonNetworkParams tonMainnet = TonNetworkParams(
    chainType: ChainType.mainnet,
    token: Token.unsafe(
        name: "Gram",
        symbol: "GRAM",
        nameView: "Gram",
        symbolView: "GRAM",
        market: CoingeckoCoin(apiId: "the-open-network", coinName: "gram"),
        decimal: 9,
        assetLogo: APPConst.gram),
  );
  static const SubstrateNetworkParams westend = SubstrateNetworkParams(
      chainType: ChainType.testnet,
      ss58Format: SS58Const.genericSubstrate,
      token: Token.unsafe(
        name: "Westend",
        symbol: "WND",
        decimal: 12,
        assetLogo: null,
        nameView: "Westend",
        symbolView: "WND",
      ),
      substrateChainType: SubstrateChainType.substrate,
      consensusRole: SubstrateConsensusRole.relay,
      specVersion: 1017001,
      relaySystem: SubstrateRelaySystem.westend);

  static const SubstrateNetworkParams cf = SubstrateNetworkParams(
      chainType: ChainType.testnet,
      ss58Format: SS58Const.polkadot,
      token: Token.unsafe(
          name: "ChainFlip",
          symbol: "tDOT",
          nameView: "ChainFlip",
          symbolView: "tDOT",
          decimal: 10,
          assetLogo: APPConst.cf),
      substrateChainType: SubstrateChainType.substrate,
      specVersion: 1017001,
      relaySystem: null,
      consensusRole: null);
  static const SubstrateNetworkParams cfAssetHub = SubstrateNetworkParams(
      chainType: ChainType.testnet,
      ss58Format: SS58Const.polkadot,
      token: Token.unsafe(
          name: "AssetHub ChainFlip",
          symbol: "tDOT",
          nameView: "AssetHub ChainFlip",
          symbolView: "tDOT",
          decimal: 10,
          assetLogo: APPConst.cf),
      substrateChainType: SubstrateChainType.substrate,
      specVersion: 1017001,
      relaySystem: null,
      consensusRole: null);
  static const SubstrateNetworkParams westendAssetHub = SubstrateNetworkParams(
      chainType: ChainType.testnet,
      ss58Format: SS58Const.genericSubstrate,
      token: Token.unsafe(
          name: "Westend Asset Hub",
          symbol: "WND",
          nameView: "Westend Asset Hub",
          symbolView: "WND",
          decimal: 12,
          assetLogo: null),
      substrateChainType: SubstrateChainType.substrate,
      specVersion: 1017004,
      consensusRole: SubstrateConsensusRole.system,
      relaySystem: SubstrateRelaySystem.westend);
  static const SubstrateNetworkParams westendBridgeHub = SubstrateNetworkParams(
      chainType: ChainType.testnet,
      ss58Format: SS58Const.genericSubstrate,
      token: Token.unsafe(
          name: "Westend Bridge Hub",
          symbol: "WND",
          nameView: "Westend Bridge Hub",
          symbolView: "WND",
          decimal: 12,
          assetLogo: null),
      substrateChainType: SubstrateChainType.substrate,
      specVersion: 1017001,
      consensusRole: SubstrateConsensusRole.system,
      relaySystem: SubstrateRelaySystem.westend);
  static const SubstrateNetworkParams polkadot = SubstrateNetworkParams(
      chainType: ChainType.mainnet,
      ss58Format: SS58Const.polkadot,
      token: Token.unsafe(
        market: CoingeckoCoin(apiId: "polkadot", coinName: "polkadot", symbol: "DOT"),
        name: "Polkadot",
        symbol: "DOT",
        nameView: "Polkadot",
        symbolView: "DOT",
        decimal: 10,
        assetLogo: APPConst.polkadot,
      ),
      substrateChainType: SubstrateChainType.substrate,
      specVersion: 1003004,
      consensusRole: SubstrateConsensusRole.relay,
      relaySystem: SubstrateRelaySystem.polkadot);
  static const SubstrateNetworkParams polkadotAssetHub = SubstrateNetworkParams(
      chainType: ChainType.mainnet,
      ss58Format: SS58Const.polkadot,
      token: Token.unsafe(
          market: CoingeckoCoin(apiId: "polkadot", coinName: "polkadot", symbol: "DOT"),
          name: "Polkadot Asset Hub",
          symbol: "DOT",
          nameView: "Polkadot Asset Hub",
          symbolView: "DOT",
          decimal: 10,
          assetLogo: APPConst.polkadot),
      substrateChainType: SubstrateChainType.substrate,
      specVersion: 1003004,
      consensusRole: SubstrateConsensusRole.system,
      relaySystem: SubstrateRelaySystem.polkadot);
  static const SubstrateNetworkParams polkadotBridgeHub = SubstrateNetworkParams(
      chainType: ChainType.mainnet,
      ss58Format: SS58Const.polkadot,
      token: Token.unsafe(
          name: "polkadot Bridge Hub",
          symbol: "DOT",
          market: CoingeckoCoin(apiId: "polkadot", coinName: "polkadot", symbol: "DOT"),
          nameView: "polkadot Bridge Hub",
          symbolView: "DOT",
          decimal: 10,
          assetLogo: APPConst.polkadot),
      substrateChainType: SubstrateChainType.substrate,
      specVersion: 1003003,
      relaySystem: SubstrateRelaySystem.polkadot,
      consensusRole: SubstrateConsensusRole.system);
  static const SubstrateNetworkParams kusama = SubstrateNetworkParams(
      chainType: ChainType.mainnet,
      ss58Format: SS58Const.kusama,
      token: Token.unsafe(
          name: "Kusama",
          symbol: "KSM",
          nameView: "Kusama",
          symbolView: "KSM",
          decimal: 12,
          market: CoingeckoCoin(apiId: "kusama", coinName: "kusama", symbol: "KSM"),
          assetLogo: APPConst.kusama),
      substrateChainType: SubstrateChainType.substrate,
      specVersion: 1003003,
      relaySystem: SubstrateRelaySystem.kusama,
      consensusRole: SubstrateConsensusRole.relay);
  static const SubstrateNetworkParams kusamaAssetHub = SubstrateNetworkParams(
      chainType: ChainType.mainnet,
      ss58Format: SS58Const.kusama,
      token: Token.unsafe(
          name: "Kusama Asset Hub",
          symbol: "KSM",
          nameView: "Kusama Asset Hub",
          symbolView: "KSM",
          decimal: 12,
          market: CoingeckoCoin(apiId: "kusama", coinName: "kusama", symbol: "KSM"),
          assetLogo: APPConst.kusama),
      substrateChainType: SubstrateChainType.substrate,
      specVersion: 1003004,
      relaySystem: SubstrateRelaySystem.kusama,
      consensusRole: SubstrateConsensusRole.system);
  static const SubstrateNetworkParams kusamaBridgeHub = SubstrateNetworkParams(
      chainType: ChainType.mainnet,
      ss58Format: SS58Const.kusama,
      token: Token.unsafe(
          name: "Kusama Bridge Hub",
          symbol: "KSM",
          nameView: "Kusama Bridge Hub",
          symbolView: "KSM",
          decimal: 12,
          market: CoingeckoCoin(apiId: "kusama", coinName: "kusama", symbol: "KSM"),
          assetLogo: APPConst.kusama),
      substrateChainType: SubstrateChainType.substrate,
      specVersion: 1003003,
      relaySystem: SubstrateRelaySystem.kusama,
      consensusRole: SubstrateConsensusRole.system);

  static const SubstrateNetworkParams moonBase = SubstrateNetworkParams(
    chainType: ChainType.testnet,
    ss58Format: SS58Const.moonbeam,
    token: Token.unsafe(
        symbol: "GLMR",
        name: "Moonbase Alpha",
        symbolView: "GLMR",
        nameView: "Moonbase Alpha",
        market: CoingeckoCoin(apiId: "moonbeam", coinName: "moonbeam", symbol: "GLMR"),
        decimal: 18,
        assetLogo: APPConst.moonbeam),
    substrateChainType: SubstrateChainType.ethereum,
    keyAlgorithms: [SubstrateKeyAlgorithm.ethereum],
    specVersion: 3400,
    consensusRole: SubstrateConsensusRole.parachain,
    relaySystem: null,
  );
  static const SubstrateNetworkParams moonbeam = SubstrateNetworkParams(
      chainType: ChainType.mainnet,
      ss58Format: SS58Const.moonbeam,
      token: Token.unsafe(
          name: "Moonbeam",
          symbol: "GLMR",
          nameView: "Moonbeam",
          symbolView: "GLMR",
          market: CoingeckoCoin(apiId: "moonbeam", coinName: "moonbeam", symbol: "GLMR"),
          decimal: 18,
          assetLogo: APPConst.moonbeam),
      substrateChainType: SubstrateChainType.ethereum,
      keyAlgorithms: [SubstrateKeyAlgorithm.ethereum],
      specVersion: 3300,
      relaySystem: SubstrateRelaySystem.polkadot,
      consensusRole: SubstrateConsensusRole.parachain);
  static const SubstrateNetworkParams moonriver = SubstrateNetworkParams(
      chainType: ChainType.mainnet,
      ss58Format: SS58Const.moonriver,
      token: Token.unsafe(
          market:
              CoingeckoCoin(apiId: "moonriver", coinName: "moonriver", symbol: "MOVR"),
          name: "Moonriver",
          symbol: "MOVR",
          nameView: "Moonriver",
          symbolView: "MOVR",
          decimal: 18,
          assetLogo: APPConst.moonriver),
      substrateChainType: SubstrateChainType.ethereum,
      keyAlgorithms: [SubstrateKeyAlgorithm.ethereum],
      specVersion: 3400,
      consensusRole: SubstrateConsensusRole.parachain,
      relaySystem: null);
  static const SubstrateNetworkParams astar = SubstrateNetworkParams(
      chainType: ChainType.mainnet,
      ss58Format: SS58Const.astar,
      token: Token.unsafe(
          name: "Astar",
          symbol: "ASTR",
          nameView: "Astar",
          symbolView: "ASTR",
          market: CoingeckoCoin(apiId: "astar", coinName: "astar", symbol: "ASTR"),
          decimal: 18,
          assetLogo: APPConst.astar),
      substrateChainType: SubstrateChainType.substrate,
      specVersion: 1200,
      relaySystem: SubstrateRelaySystem.polkadot,
      consensusRole: SubstrateConsensusRole.parachain);

  static const SubstrateNetworkParams hydration = SubstrateNetworkParams(
      chainType: ChainType.mainnet,
      ss58Format: SS58Const.polkadot,
      token: Token.unsafe(
          market: CoingeckoCoin(apiId: "hydradx", coinName: "hydration", symbol: "HDX"),
          name: "Hydration",
          symbol: "HDX",
          nameView: "Hydration",
          symbolView: "HDX",
          decimal: 12,
          assetLogo: APPConst.hydration),
      substrateChainType: SubstrateChainType.substrate,
      specVersion: 347,
      relaySystem: SubstrateRelaySystem.polkadot,
      consensusRole: SubstrateConsensusRole.parachain);

  static const SubstrateNetworkParams bifrost = SubstrateNetworkParams(
      chainType: ChainType.mainnet,
      ss58Format: SS58Const.polkadot,
      token: Token.unsafe(
          name: "Bifrost",
          symbol: "BNC",
          nameView: "Bifrost",
          symbolView: "BNC",
          market: CoingeckoCoin(
              apiId: "bifrost-native-coin",
              coinName: "bifrost-native-coin",
              symbol: "BNC"),
          decimal: 12,
          assetLogo: APPConst.bifrost),
      substrateChainType: SubstrateChainType.substrate,
      specVersion: 22001,
      relaySystem: SubstrateRelaySystem.polkadot,
      consensusRole: SubstrateConsensusRole.parachain);

  static const SubstrateNetworkParams centrifuge = SubstrateNetworkParams(
      chainType: ChainType.mainnet,
      ss58Format: SS58Const.centrifuge,
      token: Token.unsafe(
          name: "Centrifuge",
          symbol: "CFG",
          nameView: "Centrifuge",
          symbolView: "CFG",
          market:
              CoingeckoCoin(apiId: "centrifuge", coinName: "centrifuge", symbol: "CFG"),
          decimal: 18,
          assetLogo: APPConst.centrifuge),
      substrateChainType: SubstrateChainType.substrate,
      specVersion: 1400,
      consensusRole: SubstrateConsensusRole.parachain,
      relaySystem: SubstrateRelaySystem.polkadot);

  static const SubstrateNetworkParams acala = SubstrateNetworkParams(
      chainType: ChainType.mainnet,
      ss58Format: SS58Const.acala,
      token: Token.unsafe(
          name: "Acala",
          symbol: "ACA",
          nameView: "Acala",
          symbolView: "ACA",
          market: CoingeckoCoin(apiId: "acala", coinName: "acala", symbol: "ACA"),
          decimal: 12,
          assetLogo: APPConst.acala),
      substrateChainType: SubstrateChainType.substrate,
      specVersion: 2270,
      consensusRole: SubstrateConsensusRole.parachain,
      relaySystem: SubstrateRelaySystem.polkadot);

  static const StellarNetworkParams stellarMainnet = StellarNetworkParams(
    token: Token.unsafe(
        name: "Stellar",
        symbol: "XLM",
        nameView: "Stellar",
        symbolView: "XLM",
        decimal: StellarConst.decimal,
        market: CoingeckoCoin(apiId: "stellar", coinName: "stellar", symbol: "XLM"),
        assetLogo: APPConst.stellar),
    chainType: ChainType.mainnet,
    stellarChainType: StellarChainType.pubnet,
  );
  static const StellarNetworkParams stellarTestnet = StellarNetworkParams(
      token: Token.unsafe(
          name: "Stellar testnet",
          symbol: "tXLM",
          nameView: "Stellar testnet",
          symbolView: "tXLM",
          decimal: StellarConst.decimal,
          market: CoingeckoCoin(apiId: "stellar", coinName: "stellar", symbol: "XLM"),
          assetLogo: APPConst.stellar),
      chainType: ChainType.testnet,
      stellarChainType: StellarChainType.testnet);

  static const MoneroNetworkParams moneroTestnet = MoneroNetworkParams(
      token: Token.unsafe(
          name: "Monero stagenet",
          symbol: "tXMR",
          nameView: "Monero stagenet",
          symbolView: "tXMR",
          decimal: MoneroConst.decimal,
          market: CoingeckoCoin(apiId: "monero", coinName: "monero", symbol: "XMR"),
          assetLogo: APPConst.monero),
      chainType: ChainType.testnet,
      network: MoneroNetwork.stagenet,
      rctHeight: 96211);
  static const MoneroNetworkParams monero = MoneroNetworkParams(
      token: Token.unsafe(
          name: "Monero",
          symbol: "XMR",
          nameView: "Monero",
          symbolView: "XMR",
          decimal: MoneroConst.decimal,
          market: CoingeckoCoin(apiId: "monero", coinName: "monero", symbol: "XMR"),
          assetLogo: APPConst.monero),
      chainType: ChainType.mainnet,
      network: MoneroNetwork.mainnet,
      rctHeight: 1220517);
  static const MoneroNetworkParams moneroOfflie = MoneroNetworkParams(
      token: Token.unsafe(
          name: "Monero Offline",
          symbol: "tXMR",
          nameView: "Monero Offline",
          symbolView: "tXMR",
          decimal: MoneroConst.decimal,
          market: CoingeckoCoin(apiId: "monero", coinName: "monero", symbol: "XMR"),
          assetLogo: APPConst.monero),
      chainType: ChainType.testnet,
      network: MoneroNetwork.testnet,
      rctHeight: 1);
  static const AptosNetworkParams aptos = AptosNetworkParams(
      token: Token.unsafe(
          name: "Aptos",
          symbol: "APT",
          nameView: "Aptos",
          symbolView: "APT",
          decimal: AptosConst.decimal,
          market: CoingeckoCoin(apiId: "aptos", coinName: "aptos", symbol: "APT"),
          assetLogo: APPConst.aptos),
      chainType: ChainType.mainnet,
      aptosChainType: AptosChainType.mainnet);
  static const AptosNetworkParams aptosTestnet = AptosNetworkParams(
      token: Token.unsafe(
          name: "Aptos Testnet",
          symbol: "tAPT",
          nameView: "Aptos Testnet",
          symbolView: "tAPT",
          decimal: AptosConst.decimal,
          market: CoingeckoCoin(apiId: "aptos", coinName: "aptos", symbol: "APT"),
          assetLogo: APPConst.aptos),
      chainType: ChainType.testnet,
      aptosChainType: AptosChainType.testnet,
      bip32CoinType: 1);
  static const AptosNetworkParams aptosDevnet = AptosNetworkParams(
      token: Token.unsafe(
          name: "Aptos Devnet",
          symbol: "tAPT",
          nameView: "Aptos Devnet",
          symbolView: "tAPT",
          decimal: AptosConst.decimal,
          market: CoingeckoCoin(apiId: "aptos", coinName: "aptos", symbol: "APT"),
          assetLogo: APPConst.aptos),
      chainType: ChainType.testnet,
      aptosChainType: AptosChainType.devnet,
      bip32CoinType: 1);

  static const SuiNetworkParams sui = SuiNetworkParams(
      token: Token.unsafe(
          name: "Sui",
          symbol: "SUI",
          nameView: "Sui",
          symbolView: "SUI",
          decimal: SUIConst.decimal,
          market: CoingeckoCoin(apiId: "sui", coinName: "sui", symbol: "SUI"),
          assetLogo: APPConst.sui),
      chainType: ChainType.mainnet,
      identifier: SUIConst.mainnetIdentifier,
      suiChain: SuiChainType.mainnet);
  static const SuiNetworkParams suiDevnet = SuiNetworkParams(
      token: Token.unsafe(
        name: "Sui Devnet",
        symbol: "tSUI",
        nameView: "Sui Devnet",
        symbolView: "tSUI",
        decimal: SUIConst.decimal,
        market: CoingeckoCoin(apiId: "sui", coinName: "sui", symbol: "SUI"),
        assetLogo: APPConst.sui,
      ),
      chainType: ChainType.testnet,
      identifier: SUIConst.devnetIdentifier,
      bip32CoinType: 1,
      suiChain: SuiChainType.devnet);

  static const SuiNetworkParams suiTestnet = SuiNetworkParams(
      token: Token.unsafe(
          name: "Sui Testnet",
          symbol: "tSUI",
          nameView: "Sui Testnet",
          symbolView: "tSUI",
          decimal: SUIConst.decimal,
          market: CoingeckoCoin(apiId: "sui", coinName: "sui", symbol: "SUI"),
          assetLogo: APPConst.sui),
      chainType: ChainType.testnet,
      identifier: SUIConst.testnetIdentifier,
      bip32CoinType: 1,
      suiChain: SuiChainType.testnet);

  static const ZcashNetworkParams zcashMainnet = ZcashNetworkParams(
      token: Token.unsafe(
          name: "Zcash",
          symbol: "Zec",
          nameView: "Zcash",
          symbolView: "Zec",
          decimal: 8,
          market: CoingeckoCoin(apiId: "zcash", coinName: "zcash", symbol: "ZEC"),
          assetLogo: APPConst.zcash),
      chainType: ChainType.mainnet,
      network: ZcashNetwork.mainnet);

  static const ZcashNetworkParams zcashTestnet = ZcashNetworkParams(
      token: Token.unsafe(
          name: "Zcash testnet",
          symbol: "tZec",
          nameView: "Zcash testnet",
          symbolView: "tZec",
          decimal: 8,
          market: CoingeckoCoin(apiId: "zcash", coinName: "zcash", symbol: "ZEC"),
          assetLogo: APPConst.zcash),
      chainType: ChainType.testnet,
      network: ZcashNetwork.testnet);
  static const ZcashNetworkParams zcashRegtest = ZcashNetworkParams(
      token: Token.unsafe(
          name: "Zcash regtest",
          symbol: "tZec",
          nameView: "Zcash regtest",
          symbolView: "tZec",
          decimal: 8,
          market: CoingeckoCoin(apiId: "zcash", coinName: "zcash", symbol: "ZEC"),
          assetLogo: APPConst.zcash),
      chainType: ChainType.testnet,
      network: ZcashNetwork.regtest);
  static const Map<int, String> speceficBlockHashes = {
    /// zcash nu6 active protocol block hash
    901: "0017d56ed80077f45eb88f11d50f4306ee1fbf95892c9a9cb7a9538e72ceabc1",
    900: "000000000032935a403a29822df72549d9a201e08cfbd5b3c770bb0d66615247",
  };

  static const Map<int, String> defaultChainGenesis = {
    0: "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f",
    1: "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943",
    5: "00000000da84f2bafbbc53dee25a72ae507ff4914b867c565be350b0da8bf043",
    2: "12a765e31ffd4059bada1e25190f6e98c99d9714d334efa41a195a7e7e04bfe2",
    7: "4966625a4b2851d9fdee139e56211a0d88575f59ed816ff5e6a63deb4e3e29a0",
    3: "1a91e3dace36e2be3bf030a65679fe821aa1d6ef92e7c9902eb318182c355691",
    8: "bb0a78264637406b6360aad926284d544d7049f45189db5664f3c4d07350559e",
    9: "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f",
    4: "00000ffd590b1485b3caadc19b22e6379c733355108f107a430458cdf3407ab6",
    10: "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f",
    11: "000000001dd410c49a788668ce26751718cc797474d3152a5fc073dd44fd9f7b",
    12: "37981c0c48b8d48965376c8a42ece9a0838daadb93ff975cb091f57f8c2a5faa",
    400: "91b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3",
    401: "68d56f15f85d3136970ec16946040bc1752654e906147f7e43e9d539d7c3de2f",
    402: "dcf691b5a3fbe24adc99ddc959c0561b973e329b1aef4c4b22e7bb2ddecb4464",
    450: "b0a8d493285c2df73290dfb7e61f870f17b41801197a149ca93654499ea3dafe",
    451: "e143f23803ac50e8f6f8e62695d1ce9e4e1d68aa36c1cd2cfd15340213f3423e",
    452: "67f9723393ef76214df0118c34bbbd3dbebc8ed46a10973a8c969d48fe7598c9",
    453: "48239ef607d7928874027a43a67689209727dfb3d3dc5e5b03a39bdc2eda771a",
    454: "00dcb981df86429de8bbacf9803401f09485366c44efbf53af9ecfab03adc7e5",
    455: "0441383e31d1266a92b4cb2ddd4c2e3661ac476996db7e5844c52433b81fe782",
    461: "91bc6e169807aaa54802737e1c504b2577d4fafedd5a02c10293b1cd60e39527",
    462: "401a1f9dca3da46f5c4091016c8a2f26dcea05865116b286f60f668207d1474b",
    460: "fe58ea77779b7abda7da4ec526d14db9b1e9cd40a217c34892af80a9b332b76d",
    463: "9eb76c5184c4ab8679d2d5d819fdf90b9c001403e9e17da2e14b6d8aec4029c6",
    464: "b3db41421702df9a7fcac62b53ffeac85f7853cc4e689e0b93aeb3db18c09d82",
    465: "fc41b9bd8ef8fe53d58c7ea67c794c7ec9a73daf05e6d54b14ff6342c99ba64c",
    466: "e566d149729892a803c3c4b1e652f09445926234d956a0f166be4d4dea91f536",
    467: "4fb7a1b11ba4a38827cf211b3effc87971413e4a9fd79c6bcc2c633383496832",
    468: "afdc188f45c71dacbaa0b62e16a91f726c7b8699a9748cdf715459de6b7f366d",
    469: "262e1b2ad728475fd6fe88e62d34c200abe6fd693931ddad144059b1eb884e5b",
    1001: "00000000000000001ebf88508a03865c71d452e25f4d51194196a1d22b6653dc",
    1002: "0000000000000000de1aa88295e1fcf982742f773e0419c5a9c134c994a9059e",
    1003: "0000000000000000d698d4192c56cb6be724a558448e2684802de4d6cd8690dc",
    700: "418015bb9ae982a1975da7d79277c2705727a56894ba0fb246adaabb1f4632e3",
    701: "76ee3cc98646292206cd3e86f74d88b4dcc1d937088645e9b0cbca84b7ce74eb",
    900: "00040fe8ec8471911baa1db1266ea15dd06b4a8a5c453883c000b031973dce08",
    901: "05a60a92d99d85997cce3b87616c089f6124d7342af37106edc76126334a2c38",
    33: SolanaConst.mainnetGenesis,
    34: SolanaConst.testnetGenesis,
    35: SolanaConst.devnetGenesis,
  };

  static const Map<int, String> addressExplorer = {
    0: "https://live.blockcypher.com/btc/address/#address/",
    1: "https://mempool.space/testnet/address/#address/",
    5: "https://mempool.space/testnet4/address/#address/",
    2: "https://live.blockcypher.com/ltc/address/#address/",
    7: "https://live.blockcypher.com/ltc/address/#address/",
    3: "https://live.blockcypher.com/doge/address/#address/",
    8: "https://live.blockcypher.com/doge/address/#address/",
    9: "https://whatsonchain.com/address/#address",
    4: "https://live.blockcypher.com/dash/address/#address/",
    10: "https://bch.loping.net/address/#address",
    11: "https://cbch.loping.net/address/#address",
    12: "https://pepeexplorer.com/address/#address",
    30: "https://livenet.xrpl.org/accounts/#address",
    31: "https://testnet.xrpl.org/accounts/#address",
    32: "https://devnet.xrpl.org/accounts/#address",
    33: "https://explorer.solana.com/address/#address",
    34: "https://explorer.solana.com/address/#address?cluster=testnet",
    35: "https://explorer.solana.com/address/#address?cluster=devnet",
    50: "https://cardanoscan.io/address/#address",
    51: "https://preprod.cardanoscan.io/address/#address",
    100: "https://etherscan.io/address/#address",
    101: "https://sepolia.etherscan.io/address/#address",
    102: "https://polygonscan.com/address/#address",
    103: "https://mumbai.polygonscan.com/address/#address",
    104: "https://bscscan.com/address/#address",
    105: "https://testnet.bscscan.com/address/#address",
    106: "https://subnets.avax.network/c-chain/address/#address",
    107: "https://arbitrum.blockscout.com/address/#address",
    108: "https://base.blockscout.com/address/#address",
    109: "https://optimistic.etherscan.io/address/#address",
    111: "https://moonscan.io/address/#address",
    112: "https://moonriver.moonscan.io/address/#address",
    200: "https://ping.pub/cosmos/account/#address",
    201: "https://explorer.polypore.xyz/provider/account/#address",
    202: "https://www.mayascan.org/address/#address",
    203: "https://www.thorscanner.org/address/#address",
    204: "https://finder.kujira.network/harpoon-4/address/#address",
    205: "https://finder.kujira.network/kaiyo-1/address/#address",
    206: "https://celatone.osmosis.zone/osmo-test-5/accounts/#address",
    207: "https://celatone.osmosis.zone/osmosis-1/accounts/#address",
    300: "https://tonscan.org/address/#address",
    301: "https://testnet.tonscan.org/address/#address",
    400: "https://polkadot.subscan.io/account/#address",
    401: "https://assethub-polkadot.subscan.io/account/#address",
    402: "https://bridgehub-polkadot.subscan.io/account/#address",
    450: "https://kusama.subscan.io/account/#address",
    451: "https://westend.subscan.io/account/#address",
    452: "https://assethub-westend.subscan.io/account/#address",
    453: "https://assethub-kusama.subscan.io/account/#address",
    454: "https://bridgehub-kusama.subscan.io/account/#address",
    455: "https://bridgehub-westend.subscan.io/account/#address",
    461: "https://moonbase.subscan.io/account/#address",
    462: "https://moonriver.subscan.io/account/#address",
    463: "https://astar.subscan.io/account/#address",
    464: "https://centrifuge.subscan.io/account/#address",
    465: "https://acala.subscan.io/account/#address",
    468: "https://hydration.subscan.io/account/#address",
    469: "https://bifrost.subscan.io/account/#address",
    460: "https://moonbeam.subscan.io/account/#address",
    600: "https://stellar.expert/explorer/public/account/#address",
    601: "https://stellar.expert/explorer/testnet/account/#address",
    800: "https://suiscan.xyz/mainnet/account/#address",
    801: "https://suiscan.xyz/devnet/account/#address",
    802: "https://suiscan.xyz/testnet/account/#address",
    810: "https://explorer.aptoslabs.com/account/#address?network=mainnet",
    811: "https://explorer.aptoslabs.com/account/#address?network=testnet",
    812: "https://explorer.aptoslabs.com/account/#address?network=devnet",
    1001: "https://tronscan.org/#/address/#address",
    1002: "https://shasta.tronscan.org/#/address/#address",
    1003: "https://nile.tronscan.org/#/address/#address"
  };

  static const Map<int, String> txExplorer = {
    0: "https://live.blockcypher.com/btc/tx/#txid/",
    1: "https://mempool.space/testnet/tx/#txid/",
    5: "https://mempool.space/testnet4/tx/#txid/",
    2: "https://live.blockcypher.com/ltc/tx/#txid/",
    7: "https://live.blockcypher.com/ltc/tx/#txid/",
    3: "https://live.blockcypher.com/doge/tx/#txid/",
    8: "https://live.blockcypher.com/doge/tx/#txid/",
    9: "https://whatsonchain.com/tx/#txid",
    4: "https://live.blockcypher.com/dash/tx/#txid/",
    10: "https://bch.loping.net/tx/#txid",
    11: "https://cbch.loping.net/tx/#txid",
    12: "https://pepeexplorer.com/tx/#txid",
    30: "https://livenet.xrpl.org/transactions/#txid",
    31: "https://testnet.xrpl.org/transactions/#txid",
    32: "https://devnet.xrpl.org/transactions/#txid",
    33: "https://explorer.solana.com/tx/#txid",
    34: "https://explorer.solana.com/tx/#txid?cluster=testnet",
    35: "https://explorer.solana.com/tx/#txid?cluster=devnet",
    50: "https://cardanoscan.io/transaction/#txid",
    51: "https://preprod.cardanoscan.io/transaction/#txid",
    100: "https://etherscan.io/tx/#txid",
    101: "https://sepolia.etherscan.io/tx/#txid",
    102: "https://polygonscan.com/tx/#txid",
    103: "https://mumbai.polygonscan.com/tx/#txid",
    104: "https://bscscan.com/tx/#txid",
    105: "https://testnet.bscscan.com/tx/#txid",
    106: "https://subnets.avax.network/c-chain/tx/#txid",
    107: "https://arbitrum.blockscout.com/tx/#txid",
    108: "https://base.blockscout.com/tx/#txid",
    109: "https://optimistic.etherscan.io/tx/#txid",
    111: "https://moonscan.io/tx/#txid",
    112: "https://moonriver.moonscan.io/tx/#txid",
    200: "https://ping.pub/cosmos/tx/#txid",
    201: "https://explorer.polypore.xyz/provider/tx/#txid",
    202: "https://www.mayascan.org/tx/#txid",
    203: "https://www.thorscanner.org/tx/#txid",
    204: "https://finder.kujira.network/harpoon-4/tx/#txid",
    205: "https://finder.kujira.network/kaiyo-1/tx/#txid",
    206: "https://celatone.osmosis.zone/osmo-test-5/txs/#txid",
    207: "https://celatone.osmosis.zone/osmosis-1/txs/#txid",
    300: "https://tonscan.org/tx/#txid",
    301: "https://testnet.tonscan.org/tx/#txid",
    400: "https://polkadot.subscan.io/extrinsic/#txid",
    401: "https://assethub-polkadot.subscan.io/extrinsic/#txid",
    402: "https://bridgehub-polkadot.subscan.io/extrinsic/#txid",
    450: "https://kusama.subscan.io/extrinsic/#txid",
    451: "https://westend.subscan.io/extrinsic/#txid",
    452: "https://assethub-westend.subscan.io/extrinsic/#txid",
    453: "https://assethub-kusama.subscan.io/extrinsic/#txid",
    454: "https://bridgehub-kusama.subscan.io/extrinsic/#txid",
    455: "https://bridgehub-westend.subscan.io/extrinsic/#txid",
    460: "https://moonbeam.subscan.io/extrinsic/#txid",
    462: "https://moonriver.subscan.io/extrinsic/#txid",
    461: "https://moonbase.subscan.io/extrinsic/#txid",
    463: "https://astar.subscan.io/extrinsic/#txid",
    464: "https://centrifuge.subscan.io/extrinsic/#txid",
    465: "https://acala.subscan.io/extrinsic/#txid",
    468: "https://hydration.subscan.io/extrinsic/#txid",
    469: "https://bifrost.subscan.io/extrinsic/#txid",
    600: "https://stellar.expert/explorer/public/tx/#txid",
    601: "https://stellar.expert/explorer/testnet/tx/#txid",
    700: "https://xmrchain.net/tx/#txid",
    701: "https://stagenet.xmrchain.net/tx/#txid",
    800: "https://suiscan.xyz/mainnet/tx/#txid",
    801: "https://suiscan.xyz/devnet/tx/#txid",
    802: "https://suiscan.xyz/testnet/tx/#txid",
    811: "https://explorer.aptoslabs.com/txn/#txid?network=testnet",
    810: "https://explorer.aptoslabs.com/txn/#txid?network=mainnet",
    812: "https://explorer.aptoslabs.com/txn/#txid?network=devnet",
    1001: "https://tronscan.org/#/transaction/#txid",
    1002: "https://shasta.tronscan.org/#/transaction/#txid",
    1003: "https://nile.tronscan.org/#/transaction/#txid"
  };
}

class ChainConst {
  static const int maxNetworkId = 10000 - 1;
  static const int importedNetworkStartId = 2000;
  static const int maxAccountTokens = 1000;
  static const String zeroBlockHash =
      "00000000000000000000000000000000000000000000000000000000";
  static const Map<int, WalletNetwork> defaultCoins = {
    0: WalletBitcoinNetwork(0, _DefaultAppCoins.bitcoinMainnet),
    1: WalletBitcoinNetwork(1, _DefaultAppCoins.bitcoinTestnet),
    5: WalletBitcoinNetwork(5, _DefaultAppCoins.bitcoinTestnet4),
    2: WalletBitcoinNetwork(2, _DefaultAppCoins.litecoinMainnet),
    7: WalletBitcoinNetwork(7, _DefaultAppCoins.litecoinTestnet),
    3: WalletBitcoinNetwork(3, _DefaultAppCoins.dogecoinMainnet),
    8: WalletBitcoinNetwork(8, _DefaultAppCoins.dogeTestnet),
    9: WalletBitcoinNetwork(9, _DefaultAppCoins.bsvMainnet),
    4: WalletBitcoinNetwork(4, _DefaultAppCoins.dashMainnet),
    10: WalletBitcoinCashNetwork(10, _DefaultAppCoins.bitcoinCashMainnet),
    11: WalletBitcoinCashNetwork(11, _DefaultAppCoins.bitcoinCashChipnet),
    12: WalletBitcoinNetwork(12, _DefaultAppCoins.pepecoinMainnet),
    13: WalletBitcoinNetwork(13, _DefaultAppCoins.bsvRegtest),
    30: WalletXRPNetwork(30, _DefaultAppCoins.xrpMainnet),
    31: WalletXRPNetwork(31, _DefaultAppCoins.xrpTestnet),
    32: WalletXRPNetwork(32, _DefaultAppCoins.xrpDevnet),
    33: WalletSolanaNetwork(33, _DefaultAppCoins.solana),
    34: WalletSolanaNetwork(34, _DefaultAppCoins.solanaTestnet),
    35: WalletSolanaNetwork(35, _DefaultAppCoins.solanaDevnet),

    50: WalletCardanoNetwork(50, _DefaultAppCoins.cardano),
    51: WalletCardanoNetwork(51, _DefaultAppCoins.cardanoPreprod),

    100: WalletEthereumNetwork(100, _DefaultAppCoins.ethreumMainnet),
    101: WalletEthereumNetwork(101, _DefaultAppCoins.ethreumTestnet),
    102: WalletEthereumNetwork(102, _DefaultAppCoins.polygon),
    103: WalletEthereumNetwork(103, _DefaultAppCoins.polygonTestnet),
    104: WalletEthereumNetwork(104, _DefaultAppCoins.bnb),
    105: WalletEthereumNetwork(105, _DefaultAppCoins.bnbTestnet),
    106: WalletEthereumNetwork(106, _DefaultAppCoins.avalanche),
    107: WalletEthereumNetwork(107, _DefaultAppCoins.arbitrum),
    108: WalletEthereumNetwork(108, _DefaultAppCoins.base),
    109: WalletEthereumNetwork(109, _DefaultAppCoins.optimism),
    110: WalletEthereumNetwork(110, _DefaultAppCoins.arbitrumTestnet),
    111: WalletEthereumNetwork(111, _DefaultAppCoins.moonbeamEthereum),
    112: WalletEthereumNetwork(112, _DefaultAppCoins.moonRiveEthereum),
    200: WalletCosmosNetwork(200, _DefaultAppCoins.cosmos),
    201: WalletCosmosNetwork(201, _DefaultAppCoins.cosmosTestnet),
    202: WalletCosmosNetwork(202, _DefaultAppCoins.maya),
    203: WalletCosmosNetwork(203, _DefaultAppCoins.thorchain),
    204: WalletCosmosNetwork(204, _DefaultAppCoins.kujiraTestnet),
    205: WalletCosmosNetwork(205, _DefaultAppCoins.kujira),
    206: WalletCosmosNetwork(206, _DefaultAppCoins.osmosisTestnet),
    207: WalletCosmosNetwork(207, _DefaultAppCoins.osmosis),
    300: WalletTonNetwork(300, _DefaultAppCoins.tonMainnet),
    301: WalletTonNetwork(301, _DefaultAppCoins.tonTestnet),
    400: WalletSubstrateNetwork(400, _DefaultAppCoins.polkadot),
    401: WalletSubstrateNetwork(401, _DefaultAppCoins.polkadotAssetHub),
    402: WalletSubstrateNetwork(402, _DefaultAppCoins.polkadotBridgeHub),
    450: WalletSubstrateNetwork(450, _DefaultAppCoins.kusama),
    451: WalletSubstrateNetwork(451, _DefaultAppCoins.westend),
    452: WalletSubstrateNetwork(452, _DefaultAppCoins.westendAssetHub),
    453: WalletSubstrateNetwork(453, _DefaultAppCoins.kusamaAssetHub),
    454: WalletSubstrateNetwork(454, _DefaultAppCoins.kusamaBridgeHub),
    455: WalletSubstrateNetwork(455, _DefaultAppCoins.westendBridgeHub),
    460: WalletSubstrateNetwork(460, _DefaultAppCoins.moonbeam),
    461: WalletSubstrateNetwork(461, _DefaultAppCoins.moonBase),
    462: WalletSubstrateNetwork(462, _DefaultAppCoins.moonriver),
    463: WalletSubstrateNetwork(463, _DefaultAppCoins.astar),
    464: WalletSubstrateNetwork(464, _DefaultAppCoins.centrifuge),
    465: WalletSubstrateNetwork(465, _DefaultAppCoins.acala),
    466: WalletSubstrateNetwork(466, _DefaultAppCoins.cf),
    467: WalletSubstrateNetwork(467, _DefaultAppCoins.cfAssetHub),
    468: WalletSubstrateNetwork(468, _DefaultAppCoins.hydration),
    469: WalletSubstrateNetwork(469, _DefaultAppCoins.bifrost),

    ///
    600: WalletStellarNetwork(600, _DefaultAppCoins.stellarMainnet),
    601: WalletStellarNetwork(601, _DefaultAppCoins.stellarTestnet),

    /// monero
    700: WalletMoneroNetwork(700, _DefaultAppCoins.monero),
    701: WalletMoneroNetwork(701, _DefaultAppCoins.moneroTestnet),
    702: WalletMoneroNetwork(702, _DefaultAppCoins.moneroOfflie),
    // sui
    800: WalletSuiNetwork(800, _DefaultAppCoins.sui),
    801: WalletSuiNetwork(801, _DefaultAppCoins.suiDevnet),
    802: WalletSuiNetwork(802, _DefaultAppCoins.suiTestnet),

    /// aptos
    810: WalletAptosNetwork(810, _DefaultAppCoins.aptos),
    811: WalletAptosNetwork(811, _DefaultAppCoins.aptosTestnet),
    812: WalletAptosNetwork(812, _DefaultAppCoins.aptosDevnet),

    /// zcash
    900: WalletZcashNetwork(900, _DefaultAppCoins.zcashMainnet),
    901: WalletZcashNetwork(901, _DefaultAppCoins.zcashTestnet),
    902: WalletZcashNetwork(902, _DefaultAppCoins.zcashRegtest),

    ///
    1001: WalletTronNetwork(1001, _DefaultAppCoins.tron),
    1002: WalletTronNetwork(1002, _DefaultAppCoins.tronShasta),
    1003: WalletTronNetwork(1003, _DefaultAppCoins.tronNile),
  };

  static WalletNetwork updateNetwork(int networkId, {WalletNetwork? network}) {
    if (network != null && networkId != network.value) {
      throw WalletExceptionConst.networkDoesNotExist;
    }
    final WalletNetwork? defaultNetwork = defaultCoins[networkId];
    if (defaultNetwork == null) {
      if (network == null) {
        throw WalletExceptionConst.networkDoesNotExist;
      }
      return network;
    }
    return network ?? defaultNetwork;
  }

  static List<String> services(WalletNetwork network) {
    switch (network.type) {
      case NetworkType.xrpl:
      case NetworkType.tron:
      case NetworkType.solana:
      case NetworkType.stellar:
      case NetworkType.cosmos:
      case NetworkType.aptos:
      case NetworkType.sui:
      case NetworkType.ton:
      case NetworkType.ethereum:
      case NetworkType.substrate:
        return ["services", "tokens", "activity"];
      default:
        return ["services", "activity"];
    }
  }

  static String getDefaultGenesisBlock(int value) {
    final genesis = _DefaultAppCoins.defaultChainGenesis[value];
    if (genesis == null) {
      throw WalletExceptionConst.networkDoesNotExist;
    }
    return genesis;
  }

  static String getSpeceficBlockHash(int value) {
    final genesis = _DefaultAppCoins.speceficBlockHashes[value];
    if (genesis == null) {
      throw WalletExceptionConst.networkDoesNotExist;
    }
    return genesis;
  }

  static String buildCaip2(NetworkType type, String identifier) {
    String part = identifier;
    switch (type) {
      case NetworkType.bitcoinAndForked:
      case NetworkType.monero:
      case NetworkType.substrate:
        if (!StringUtils.isHexBytes(part)) {
          throw AppCryptoExceptionConst.invalidHexBytes;
        }
        part = StringUtils.strip0x(identifier.toLowerCase()).substring(0, 32);
        break;
      default:
    }
    return "${type.caip2}:$part";
  }

  static String? getAddressExplorer(int value) {
    return _DefaultAppCoins.addressExplorer[value];
  }

  static String? getTxExplorer(int value) {
    return _DefaultAppCoins.txExplorer[value];
  }
}
