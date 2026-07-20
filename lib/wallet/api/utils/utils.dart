import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/cbor/serialization/cbor/tag.dart';
import 'package:blockchain_utils/cbor/types/cbor_tag.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/networks/networks.dart';
import 'package:blockchain_utils/serialization/identifier.dart';
import 'package:blockchain_utils/service/models/params.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_swap/on_chain_swap.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/api/types/types.dart';
import 'package:polkadot_dart/polkadot_dart.dart';
import 'package:stellar_dart/stellar_dart.dart';
import 'package:ton_dart/ton_dart.dart';
import 'package:xrpl_dart/xrpl_dart.dart';
import 'package:zcash_dart/zcash.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class APIUtils {
  static IServiceRequestParams deserializeRequest(
      {List<int>? bytes, CborTagValue? object}) {
    final tag = AppSerialization.decodeTaggedValueWithInfo<SerializationIdentifier>(
      cborBytes: bytes,
      cborObject: object,
      expectedTags: [
        ...BlockchainNetwork.values.map((e) => e.identifier),
        OnChainSwapSerializationIdentifier.provider
      ],
    );
    final obj = tag.tag;
    switch (tag.identifier) {
      case OnChainSwapSerializationIdentifier.provider:
        return OnChainSwapRequestDetails.deserialize(obj: obj);
      case BlockchainUtilsSerializationIdentifier.aptosNetwork:
        return AptosRequestDetails.deserialize(obj: obj);
      case BlockchainUtilsSerializationIdentifier.ethereumNetwork:
        return EthereumRequestDetails.deserialize(obj: obj);
      case BlockchainUtilsSerializationIdentifier.cardanoNetwork:
        return BlockFrostRequestDetails.deserialize(obj: obj);
      case BlockchainUtilsSerializationIdentifier.solanaNetwork:
        return SolanaRequestDetails.deserialize(obj: obj);
      case BlockchainUtilsSerializationIdentifier.suiNetwork:
        return SuiRequestDetails.deserialize(obj: obj);
      case BlockchainUtilsSerializationIdentifier.tronNetwork:
        return TronRequestDetails.deserialize(obj: obj);
      case BlockchainUtilsSerializationIdentifier.bitcoinAndRelatedNetwork:
        return BitcoinRequestDetails.deserialize(object: obj);
      case BlockchainUtilsSerializationIdentifier.tonNetwork:
        return TonRequestDetails.deserialize(obj: obj);
      case BlockchainUtilsSerializationIdentifier.substrateAndRelatedNetworks:
        return SubstrateRequestDetails.deserialize(obj: obj);
      case BlockchainUtilsSerializationIdentifier.cosmosAndRelatedNetworks:
        return BaseCosmosServiceRequestParams.deserialize(obj: obj);
      case BlockchainUtilsSerializationIdentifier.moneroNetwork:
        return MoneroRequestDetails.deserialize(obj: obj);
      case BlockchainUtilsSerializationIdentifier.stellarNetwork:
        return StellarRequestDetails.deserialize(obj: obj);
      case BlockchainUtilsSerializationIdentifier.xrplNetwork:
        return XRPRequestDetails.deserialize(obj: obj);
      case BlockchainUtilsSerializationIdentifier.zcashNetwork:
        return ZcashWalletdRequestDetails.deserialize(obj: obj);
      default:
        throw AppInternalError.internalError("IServiceRequestParams");
    }
  }

  static BaseGRPCServiceRequestParams deserializeGrpcRequest(
      {List<int>? bytes, CborTagValue? object}) {
    final tag = AppSerialization.decodeTaggedValueWithInfo(
      cborBytes: bytes,
      cborObject: object,
      expectedTags: [BlockchainNetwork.zcash.identifier],
    );
    final obj = tag.tag;
    switch (tag.identifier) {
      case BlockchainUtilsSerializationIdentifier.zcashNetwork:
        return ZcashWalletdRequestDetails.deserialize(obj: obj);
      default:
        throw AppInternalError.internalError("IServiceRequestParams");
    }
  }

  static BaseServiceSubscribtionRequest deserializationStreamRequest(
      {List<int>? bytes, CborTagValue? object}) {
    final decode = AppSerialization.decodeTaggedValueWithInfo(
      cborBytes: bytes,
      cborObject: object,
      expectedTags: [
        OnChainSerializationIdentifiers.ethereumRpcSubscribtionParams,
        OnChainSerializationIdentifiers.ethereumRpcLogSubscribtionParams,
        OnChainSerializationIdentifiers.ethereumRpcHeadSubscribtionParams,
        OnChainSerializationIdentifiers.ethereumRpcPendingTxSubscribtionParams,
        OnChainSerializationIdentifiers.ethereumRpcSyncingSubscribtionParams,
      ],
    );
    return EthereumSubscribionRequest.deserialize(obj: decode.tag);
  }

  static String getProviderIdentifier({
    required String url,
    required ServiceProtocol protocol,
    ProviderAuthenticated? auth,
    int? extraType,
  }) {
    return BytesUtils.toHexString(QuickCrypto.blake2b160Hash([
      ...url.codeUnits,
      protocol.id,
      ...auth?.toCbor().encode() ?? [],
      extraType ?? 0,
    ]));
  }

  static ServiceUrlInfo? getUrlDetails(String url,
      {List<ServiceProtocol>? supportedProtocols}) {
    final union = StrUtils.isOnion(url);
    List<ServiceProtocol> protocols = [];
    if (StrUtils.validateUri(url, schame: ["wss", "ws"]) != null) {
      protocols.add(ServiceProtocol.websocket);
    } else if (StrUtils.validateUri(url, schame: ["http", "https"]) != null) {
      protocols.add(ServiceProtocol.http);
      protocols.add(ServiceProtocol.grpc);
    } else if (StrUtils.validateRawSocket(url, schame: ["tcp"]) != null) {
      protocols.add(ServiceProtocol.tcp);
    } else if (StrUtils.validateRawSocket(url, schame: ["tls"]) != null) {
      protocols.add(ServiceProtocol.ssl);
    }
    if (protocols.isEmpty) return null;
    return ServiceUrlInfo(
        url: url, protocols: protocols, mode: union ? NetMode.tor : NetMode.clearnet);
  }
}
