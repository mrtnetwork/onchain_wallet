import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/service/models/params.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/api/client/core/client.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/aptos/aptos.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/bitcoin/clients/bitcoin.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/cardano/client/cardano.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/cosmos/clients/cosmos.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/ethereum/client/ethereum.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/monero/monero.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/ripple/client/ripple.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/solana/solana.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/stellar/stellar.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/substrate/client/substrate.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/sui/client/client.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/ton/client/ton.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/tron/client/tron.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/zcash/clients/client.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/exception/bridge.dart';
import 'package:on_chain_wallet/wallet/api/service/services/default.dart';
import 'package:on_chain_wallet/wallet/api/types/types.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:polkadot_dart/polkadot_dart.dart';
import 'package:stellar_dart/stellar_dart.dart';
import 'package:ton_dart/ton_dart.dart';
import 'package:xrpl_dart/xrpl_dart.dart';
import 'package:zcash_dart/zcash.dart';

typedef CbCreateService = Future<MultiChainServiceClient> Function(
    DefaultAPIProvider provider);

sealed class NetworkApiProvider<NETWORK extends WalletNetwork,
    CLIENT extends CLIENTNWORK<NETWORK>> with AppSerialization, Equality {
  const NetworkApiProvider();
  factory NetworkApiProvider.deserialize({List<int>? bytes, CborObject? object}) {
    final decode = AppSerialization.decodeTaggedValueWithInfo(
      expectedTags: NetworkType.values.map((e) => e.identifier).toList(),
    );
    final network = NetworkType.fromIdentifier(decode.identifier.id);
    return switch (network) {
      NetworkType.bitcoinAndForked ||
      NetworkType.bitcoinCash =>
        BitcoinNetworkProvider.deserialize(object: decode.tag),
      NetworkType.xrpl => XRPNetworkProvider.deserialize(object: decode.tag),
      NetworkType.ethereum => EthereumNetworkProvider.deserialize(object: decode.tag),
      NetworkType.tron => TronNetworkProvider.deserialize(object: decode.tag),
      NetworkType.solana => SolanaNetworkProvider.deserialize(object: decode.tag),
      NetworkType.cardano => CardanoNetworkProvider.deserialize(object: decode.tag),
      NetworkType.cosmos => CosmosNetworkProvider.deserialize(object: decode.tag),
      NetworkType.ton => TonNetworkProvider.deserialize(object: decode.tag),
      NetworkType.substrate => SubstrateNetworkProvider.deserialize(object: decode.tag),
      NetworkType.stellar => StellarNetworkProvider.deserialize(object: decode.tag),
      NetworkType.monero => MoneroNetworkProvider.deserialize(object: decode.tag),
      NetworkType.aptos => AptosNetworkProvider.deserialize(object: decode.tag),
      NetworkType.sui => SuiNetworkProvider.deserialize(object: decode.tag),
      NetworkType.zcash => ZcashNetworkProvider.deserialize(object: decode.tag),
    } as NetworkApiProvider<NETWORK, CLIENT>;
  }
  NetworkType get network;
  @override
  SerializationIdentifier get serializationIdentifier => network.identifier;
  Future<CLIENT> toClient(
      {required NETWORK network, required CbCreateService createService});

  IResult<DefaultAPIProvider> getRequestProvider(IServiceRequestParams service);

  T cast<T extends NetworkApiProvider<WalletNetwork, NetworkClient>>() {
    if (this is! T) {
      throw AppInternalError.internalError("casting failed");
    }
    return this as T;
  }

  List<DefaultAPIProvider> get providers;
}

sealed class DefaultNetworkProvider<NETWORK extends WalletNetwork,
    CLIENT extends CLIENTNWORK<NETWORK>> extends NetworkApiProvider<NETWORK, CLIENT> {
  final DefaultAPIProvider provider;
  const DefaultNetworkProvider(this.provider);

  @override
  List<CborObject?> get serializationItems => [provider.toCbor()];
  @override
  List<dynamic> get variables => [provider];

  @override
  List<DefaultAPIProvider> get providers => [provider];
}

class BitcoinNetworkProvider
    extends DefaultNetworkProvider<WalletBitcoinNetwork, BitcoinNetworkClient> {
  const BitcoinNetworkProvider(super.provider);
  factory BitcoinNetworkProvider.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: NetworkType.bitcoinAndForked.identifier,
        cborBytes: bytes,
        cborObject: object);
    return BitcoinNetworkProvider(
        DefaultAPIProvider.deserialize(object: values.objectAt(0)));
  }

  @override
  NetworkType get network => NetworkType.bitcoinAndForked;

  @override
  Future<BitcoinNetworkClient<IBitcoinAddress>> toClient(
      {required WalletBitcoinNetwork network,
      required CbCreateService createService}) async {
    return BitcoinNetworkClient.fromService(
        provider: this, network: network, service: await createService(provider));
  }

  @override
  IResult<DefaultAPIProvider> getRequestProvider(IServiceRequestParams service) {
    return switch (service) {
      BitcoinRequestDetails bitcoin => switch (bitcoin.api) {
          BitcoinProviderApi.electrum => switch (provider.service) {
              APIProviderServices.electrum => ResultOk(provider),
              _ => ResultErr.fromException(NetworkClientError.protocolServiceChanged)
            },
          BitcoinProviderApi.mempool => switch (provider.service) {
              APIProviderServices.mempool => ResultOk(provider),
              _ => ResultErr.fromException(NetworkClientError.protocolServiceChanged)
            },
          BitcoinProviderApi.blockCypher => switch (provider.service) {
              APIProviderServices.blockCypher => ResultOk(provider),
              _ => ResultErr.fromException(NetworkClientError.protocolServiceChanged)
            },
        },
      _ => ResultErr.fromException(NetworkClientError.protocolServiceChanged)
    };
  }
}

class CardanoNetworkProvider
    extends DefaultNetworkProvider<WalletCardanoNetwork, ADANetworkClient> {
  const CardanoNetworkProvider(super.provider);
  @override
  NetworkType get network => NetworkType.cardano;
  factory CardanoNetworkProvider.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: NetworkType.cardano.identifier, cborBytes: bytes, cborObject: object);
    return CardanoNetworkProvider(
        DefaultAPIProvider.deserialize(object: values.objectAt(0)));
  }

  @override
  Future<ADANetworkClient> toClient(
      {required WalletCardanoNetwork network,
      required CbCreateService createService}) async {
    return ADANetworkClient.fromService(
        provider: this, network: network, service: await createService(provider));
  }

  @override
  IResult<DefaultAPIProvider> getRequestProvider(IServiceRequestParams service) {
    return switch (service) {
      BlockFrostRequestDetails _ => ResultOk(provider),
      _ => ResultErr.fromException(NetworkClientError.protocolServiceChanged)
    };
  }
}

class CosmosNetworkProvider
    extends DefaultNetworkProvider<WalletCosmosNetwork, CosmosNetworkClient> {
  const CosmosNetworkProvider(super.provider);
  factory CosmosNetworkProvider.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: NetworkType.cosmos.identifier, cborBytes: bytes, cborObject: object);
    return CosmosNetworkProvider(
        DefaultAPIProvider.deserialize(object: values.objectAt(0)));
  }
  @override
  NetworkType get network => NetworkType.cosmos;

  @override
  Future<CosmosNetworkClient> toClient(
      {required WalletCosmosNetwork network,
      required CbCreateService createService}) async {
    return CosmosNetworkClient.fromService(
        provider: this, network: network, service: await createService(provider));
  }

  @override
  IResult<DefaultAPIProvider> getRequestProvider(IServiceRequestParams service) {
    return switch (service) {
      TendermintRequestDetails _ => ResultOk(provider),
      _ => ResultErr.fromException(NetworkClientError.protocolServiceChanged)
    };
  }

  CosmosProviderApi cosmosService() {
    return switch (provider.service) {
      APIProviderServices.tendermint => CosmosProviderApi.tendermint,
      APIProviderServices.cosmosRest => CosmosProviderApi.rest,
      APIProviderServices.cosmosGrpc => CosmosProviderApi.grpc,
      _ => throw AppInternalError.internalError("CosmosClient.fromProvider",
          reason: "Invalid cosmos provider service.",
          details: {"service": provider.service.name})
    };
  }
}

class EthereumNetworkProvider
    extends DefaultNetworkProvider<WalletEthereumNetwork, EthereumNetworkClient> {
  const EthereumNetworkProvider(super.provider);
  factory EthereumNetworkProvider.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: NetworkType.ethereum.identifier,
        cborBytes: bytes,
        cborObject: object);
    return EthereumNetworkProvider(
        DefaultAPIProvider.deserialize(object: values.objectAt(0)));
  }
  @override
  NetworkType get network => NetworkType.ethereum;

  @override
  Future<EthereumNetworkClient> toClient(
      {required WalletEthereumNetwork network,
      required CbCreateService createService}) async {
    return EthereumNetworkClient.fromService(
        provider: this, network: network, service: await createService(provider));
  }

  @override
  IResult<DefaultAPIProvider> getRequestProvider(IServiceRequestParams service) {
    return switch (service) {
      EthereumRequestDetails _ => ResultOk(provider),
      _ => ResultErr.fromException(NetworkClientError.protocolServiceChanged)
    };
  }
}

class SolanaNetworkProvider
    extends DefaultNetworkProvider<WalletSolanaNetwork, SolanaNetworkClient> {
  const SolanaNetworkProvider(super.provider);
  factory SolanaNetworkProvider.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: NetworkType.solana.identifier, cborBytes: bytes, cborObject: object);
    return SolanaNetworkProvider(
        DefaultAPIProvider.deserialize(object: values.objectAt(0)));
  }
  @override
  NetworkType get network => NetworkType.solana;

  @override
  Future<SolanaNetworkClient> toClient(
      {required WalletSolanaNetwork network,
      required CbCreateService createService}) async {
    return SolanaNetworkClient.fromService(
        provider: this, network: network, service: await createService(provider));
  }

  @override
  IResult<DefaultAPIProvider> getRequestProvider(IServiceRequestParams service) {
    return switch (service) {
      SolanaRequestDetails _ => ResultOk(provider),
      _ => ResultErr.fromException(NetworkClientError.protocolServiceChanged)
    };
  }
}

class SubstrateNetworkProvider
    extends DefaultNetworkProvider<WalletSubstrateNetwork, SubstrateNetworkClient> {
  const SubstrateNetworkProvider(super.provider);
  factory SubstrateNetworkProvider.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: NetworkType.substrate.identifier,
        cborBytes: bytes,
        cborObject: object);
    return SubstrateNetworkProvider(
        DefaultAPIProvider.deserialize(object: values.objectAt(0)));
  }

  @override
  NetworkType get network => NetworkType.substrate;

  @override
  Future<SubstrateNetworkClient> toClient(
      {required WalletSubstrateNetwork network,
      required CbCreateService createService}) async {
    return SubstrateNetworkClient.fromService(
        provider: this, network: network, service: await createService(provider));
  }

  @override
  IResult<DefaultAPIProvider> getRequestProvider(IServiceRequestParams service) {
    return switch (service) {
      SubstrateRequestDetails _ => ResultOk(provider),
      _ => ResultErr.fromException(NetworkClientError.protocolServiceChanged)
    };
  }
}

class SuiNetworkProvider
    extends DefaultNetworkProvider<WalletSuiNetwork, SuiNetworkClient> {
  const SuiNetworkProvider(super.provider);
  factory SuiNetworkProvider.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: NetworkType.sui.identifier, cborBytes: bytes, cborObject: object);
    return SuiNetworkProvider(DefaultAPIProvider.deserialize(object: values.objectAt(0)));
  }
  @override
  NetworkType get network => NetworkType.sui;

  @override
  Future<SuiNetworkClient> toClient(
      {required WalletSuiNetwork network, required CbCreateService createService}) async {
    return SuiNetworkClient.fromService(
        provider: this, network: network, service: await createService(provider));
  }

  @override
  IResult<DefaultAPIProvider> getRequestProvider(IServiceRequestParams service) {
    return switch (service) {
      SuiRequestDetails _ => ResultOk(provider),
      _ => ResultErr.fromException(NetworkClientError.protocolServiceChanged)
    };
  }
}

class TonNetworkProvider
    extends DefaultNetworkProvider<WalletTonNetwork, TonNetworkClient> {
  const TonNetworkProvider(super.provider);
  factory TonNetworkProvider.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: NetworkType.ton.identifier, cborBytes: bytes, cborObject: object);
    return TonNetworkProvider(DefaultAPIProvider.deserialize(object: values.objectAt(0)));
  }
  @override
  NetworkType get network => NetworkType.ton;

  @override
  Future<TonNetworkClient> toClient(
      {required WalletTonNetwork network, required CbCreateService createService}) async {
    return TonNetworkClient.fromService(
        provider: this, network: network, service: await createService(provider));
  }

  @override
  IResult<DefaultAPIProvider> getRequestProvider(IServiceRequestParams service) {
    return switch (service) {
      TonRequestDetails request => switch (request.api) {
          TonApiType.tonApi => switch (provider.service) {
              APIProviderServices.tonApi => ResultOk(provider),
              _ => ResultErr.fromException(NetworkClientError.protocolServiceChanged)
            },
          TonApiType.tonCenter => switch (provider.service) {
              APIProviderServices.tonCenter => ResultOk(provider),
              _ => ResultErr.fromException(NetworkClientError.protocolServiceChanged)
            },
        },
      _ => ResultErr.fromException(NetworkClientError.protocolServiceChanged)
    };
  }
}

class XRPNetworkProvider
    extends DefaultNetworkProvider<WalletXRPNetwork, XRPNetworkClient> {
  const XRPNetworkProvider(super.provider);
  factory XRPNetworkProvider.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: NetworkType.xrpl.identifier, cborBytes: bytes, cborObject: object);
    return XRPNetworkProvider(DefaultAPIProvider.deserialize(object: values.objectAt(0)));
  }
  @override
  NetworkType get network => NetworkType.xrpl;

  @override
  Future<XRPNetworkClient> toClient(
      {required WalletXRPNetwork network, required CbCreateService createService}) async {
    return XRPNetworkClient.fromService(
        provider: this, network: network, service: await createService(provider));
  }

  @override
  IResult<DefaultAPIProvider> getRequestProvider(IServiceRequestParams service) {
    return switch (service) {
      XRPRequestDetails _ => ResultOk(provider),
      _ => ResultErr.fromException(NetworkClientError.protocolServiceChanged)
    };
  }
}

class MoneroNetworkProvider
    extends DefaultNetworkProvider<WalletMoneroNetwork, MoneroNetworkClient> {
  const MoneroNetworkProvider(super.provider);
  factory MoneroNetworkProvider.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: NetworkType.monero.identifier, cborBytes: bytes, cborObject: object);
    return MoneroNetworkProvider(
        DefaultAPIProvider.deserialize(object: values.objectAt(0)));
  }
  @override
  NetworkType get network => NetworkType.monero;

  @override
  Future<MoneroNetworkClient> toClient(
      {required WalletMoneroNetwork network,
      required CbCreateService createService}) async {
    return MoneroNetworkClient.fromService(
        provider: this, network: network, service: await createService(provider));
  }

  @override
  IResult<DefaultAPIProvider> getRequestProvider(IServiceRequestParams service) {
    return switch (service) {
      MoneroRequestDetails _ => ResultOk(provider),
      _ => ResultErr.fromException(NetworkClientError.protocolServiceChanged)
    };
  }
}

class ZcashNetworkProvider
    extends DefaultNetworkProvider<WalletZcashNetwork, ZcashNetworkClient> {
  const ZcashNetworkProvider(super.provider);
  factory ZcashNetworkProvider.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: NetworkType.zcash.identifier, cborBytes: bytes, cborObject: object);
    return ZcashNetworkProvider(
        DefaultAPIProvider.deserialize(object: values.objectAt(0)));
  }
  @override
  NetworkType get network => NetworkType.zcash;

  @override
  Future<ZcashNetworkClient> toClient(
      {required WalletZcashNetwork network,
      required CbCreateService createService}) async {
    return ZcashNetworkClient.fromService(
        provider: this, network: network, service: await createService(provider));
  }

  @override
  IResult<DefaultAPIProvider> getRequestProvider(IServiceRequestParams service) {
    return switch (service) {
      ZcashWalletdRequestDetails _ => ResultOk(provider),
      _ => ResultErr.fromException(NetworkClientError.protocolServiceChanged)
    };
  }
}

class AptosNetworkProvider
    extends NetworkApiProvider<WalletAptosNetwork, AptosNetworkClient> {
  final DefaultAPIProvider fullNode;
  final DefaultAPIProvider graphQl;
  const AptosNetworkProvider({required this.fullNode, required this.graphQl});
  factory AptosNetworkProvider.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: NetworkType.aptos.identifier, cborBytes: bytes, cborObject: object);
    return AptosNetworkProvider(
        fullNode: DefaultAPIProvider.deserialize(object: values.objectAt(0)),
        graphQl: DefaultAPIProvider.deserialize(object: values.objectAt(1)));
  }
  @override
  List<CborObject?> get serializationItems => [fullNode.toCbor(), graphQl.toCbor()];

  @override
  NetworkType get network => NetworkType.aptos;

  @override
  IResult<DefaultAPIProvider> getRequestProvider(IServiceRequestParams service) {
    return switch (service) {
      AptosRequestDetails request => switch (request.api) {
          AptosRequestType.fullnode => ResultOk(fullNode),
          AptosRequestType.graphQl => ResultOk(graphQl),
        },
      _ => ResultErr.fromException(NetworkClientError.protocolServiceChanged)
    };
  }

  @override
  Future<AptosNetworkClient> toClient(
      {required WalletAptosNetwork network,
      required CbCreateService createService}) async {
    return AptosNetworkClient.fromService(
      provider: this,
      network: network,
      fullNode: await createService(fullNode),
      graphQl: await createService(graphQl),
    );
  }

  @override
  List<dynamic> get variables => [fullNode, graphQl];

  @override
  List<DefaultAPIProvider> get providers => [fullNode, graphQl];
}

class TronNetworkProvider extends NetworkApiProvider<WalletTronNetwork, TronClient> {
  final DefaultAPIProvider ethereum;
  final DefaultAPIProvider node;
  const TronNetworkProvider({required this.ethereum, required this.node});
  factory TronNetworkProvider.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: NetworkType.tron.identifier, cborBytes: bytes, cborObject: object);
    return TronNetworkProvider(
        ethereum: DefaultAPIProvider.deserialize(object: values.objectAt(0)),
        node: DefaultAPIProvider.deserialize(object: values.objectAt(1)));
  }
  @override
  List<CborObject?> get serializationItems => [ethereum.toCbor(), node.toCbor()];

  @override
  NetworkType get network => NetworkType.tron;

  @override
  Future<TronClient> toClient(
      {required WalletTronNetwork network,
      required CbCreateService createService}) async {
    return TronClient.fromService(
      provider: this,
      network: network,
      ethereum: await createService(ethereum),
      node: await createService(node),
    );
  }

  @override
  List<dynamic> get variables => [ethereum, node];

  @override
  IResult<DefaultAPIProvider> getRequestProvider(IServiceRequestParams service) {
    return switch (service) {
      TronRequestDetails _ => ResultOk(node),
      EthereumRequestDetails _ => ResultOk(ethereum),
      _ => ResultErr.fromException(NetworkClientError.protocolServiceChanged)
    };
  }

  @override
  List<DefaultAPIProvider> get providers => [ethereum, node];
}

class StellarNetworkProvider
    extends NetworkApiProvider<WalletStellarNetwork, StellarClient> {
  final DefaultAPIProvider horizon;
  final DefaultAPIProvider soroban;
  const StellarNetworkProvider({required this.horizon, required this.soroban});
  factory StellarNetworkProvider.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: NetworkType.stellar.identifier, cborBytes: bytes, cborObject: object);
    return StellarNetworkProvider(
        horizon: DefaultAPIProvider.deserialize(object: values.objectAt(0)),
        soroban: DefaultAPIProvider.deserialize(object: values.objectAt(1)));
  }
  @override
  List<CborObject?> get serializationItems => [horizon.toCbor(), soroban.toCbor()];

  @override
  NetworkType get network => NetworkType.stellar;

  @override
  Future<StellarClient> toClient(
      {required WalletStellarNetwork network,
      required CbCreateService createService}) async {
    return StellarClient.fromService(
      provider: this,
      network: network,
      horizon: await createService(horizon),
      soroban: await createService(soroban),
    );
  }

  @override
  List<dynamic> get variables => [horizon, soroban];

  @override
  IResult<DefaultAPIProvider> getRequestProvider(IServiceRequestParams service) {
    return switch (service) {
      StellarRequestDetails request => switch (request.api) {
          StellarAPIType.horizon => ResultOk(horizon),
          StellarAPIType.soroban => ResultOk(soroban),
        },
      _ => ResultErr.fromException(NetworkClientError.protocolServiceChanged)
    };
  }

  @override
  List<DefaultAPIProvider> get providers => [horizon, soroban];
}

class NetworkClientRequirment {
  final Set<APIProviderServices> allowServices;

  /// must only provided if client need more than one service provider.
  final Set<APIProviderServices> requirementServices;
  const NetworkClientRequirment._(
      {required this.allowServices, this.requirementServices = const {}});
  factory NetworkClientRequirment.oneOf(Set<APIProviderServices> sevices) {
    return NetworkClientRequirment._(allowServices: sevices);
  }
  factory NetworkClientRequirment.allOf(Set<APIProviderServices> sevices) {
    assert(sevices.length > 1);
    return NetworkClientRequirment._(
        allowServices: sevices, requirementServices: sevices.length > 1 ? sevices : {});
  }

  int get requiredServiceLength =>
      requirementServices.isEmpty ? 1 : requirementServices.length;
}
