import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/models/device/models/platform.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';

import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/api/constant/constant.dart';
import 'package:on_chain_wallet/wallet/api/service/types/protocols.dart';
import 'package:on_chain_wallet/wallet/api/types/types.dart';
import 'package:on_chain_wallet/wallet/api/utils/utils.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class DefaultAPIProvider with Equality, AppSerialization {
  final String url;
  final String identifier;
  final ServiceProtocol protocol;
  final ProviderAuthenticated? auth;
  final bool allowInWeb3;
  final NetMode mode;
  final APIProviderServices service;
  final Duration? timeout;
  final Duration? requestCooldown;

  bool isLocalHost() {
    return StrUtils.isLocalHost(url);
  }

  factory DefaultAPIProvider.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.defaultServiceProvider,
        cborBytes: bytes,
        cborObject: object);
    return DefaultAPIProvider.unsafe(
      url: values.rawValueAt(0),
      identifier: values.rawValueAt(1),
      protocol: ServiceProtocol.fromValue(values.rawValueAt(2)),
      auth: values.maybeObjectAt<ProviderAuthenticated, CborTagValue>(
          3, (e) => ProviderAuthenticated.deserialize(object: e)),
      allowInWeb3: values.rawValueAt(4),
      mode: NetMode.fromValue(values.rawValueAt(5)),
      service: APIProviderServices.fromValue(values.rawValueAt(6)),
      timeout: values.maybeRawValueAt<Duration, int>(7, (m) => Duration(milliseconds: m)),
      requestCooldown:
          values.maybeRawValueAt<Duration, int>(8, (m) => Duration(milliseconds: m)),
    );
  }

  const DefaultAPIProvider.unsafe({
    required this.identifier,
    required this.protocol,
    required this.allowInWeb3,
    required this.mode,
    required this.service,
    required this.url,
    this.timeout,
    this.requestCooldown,
    this.auth,
  });
  const DefaultAPIProvider.defaultMempool({
    this.allowInWeb3 = true,
    this.mode = NetMode.clearnet,
    required this.url,
    this.timeout,
    this.requestCooldown,
    this.auth,
  })  : identifier = ProvidersConst.defaultidentifierName,
        service = APIProviderServices.mempool,
        protocol = ServiceProtocol.http;
  const DefaultAPIProvider.defaultBlockCypher({
    this.allowInWeb3 = true,
    this.mode = NetMode.clearnet,
    required this.url,
    this.timeout,
    this.requestCooldown,
    this.auth,
  })  : identifier = ProvidersConst.defaultidentifierName,
        service = APIProviderServices.blockCypher,
        protocol = ServiceProtocol.http;
  const DefaultAPIProvider.defaultElectrum({
    this.allowInWeb3 = true,
    this.mode = NetMode.clearnet,
    required this.url,
    required this.protocol,
    this.timeout,
    this.requestCooldown,
    this.auth,
  })  : identifier = ProvidersConst.defaultidentifierName,
        service = APIProviderServices.electrum;
  const DefaultAPIProvider.defaultRipple({
    this.allowInWeb3 = true,
    this.mode = NetMode.clearnet,
    required this.url,
    required this.protocol,
    this.timeout,
    this.requestCooldown,
    this.auth,
  })  : identifier = ProvidersConst.defaultidentifierName,
        service = APIProviderServices.ripple;
  const DefaultAPIProvider.solanaDefault({
    this.allowInWeb3 = true,
    this.mode = NetMode.clearnet,
    required this.url,
    this.timeout,
    this.requestCooldown,
    this.auth,
  })  : identifier = ProvidersConst.defaultidentifierName,
        service = APIProviderServices.solanaJsonRpc,
        protocol = ServiceProtocol.http;
  const DefaultAPIProvider.blockfrostDefault({
    this.allowInWeb3 = true,
    this.mode = NetMode.clearnet,
    required this.url,
    this.timeout,
    this.requestCooldown,
    this.auth,
  })  : identifier = ProvidersConst.defaultidentifierName,
        service = APIProviderServices.blockfrost,
        protocol = ServiceProtocol.http;
  const DefaultAPIProvider.ethereumDefault({
    this.allowInWeb3 = true,
    this.mode = NetMode.clearnet,
    this.timeout,
    this.requestCooldown,
    required this.url,
    required this.protocol,
    this.auth,
  })  : identifier = ProvidersConst.defaultidentifierName,
        service = APIProviderServices.ethereumJsonRpc;
  const DefaultAPIProvider.tendermintDefault({
    this.allowInWeb3 = true,
    this.mode = NetMode.clearnet,
    required this.url,
    this.timeout,
    this.requestCooldown,
    this.auth,
  })  : identifier = ProvidersConst.defaultidentifierName,
        service = APIProviderServices.tendermint,
        protocol = ServiceProtocol.http;
  const DefaultAPIProvider.moneroDefault({
    this.allowInWeb3 = true,
    this.mode = NetMode.clearnet,
    required this.url,
    this.timeout,
    this.requestCooldown,
    this.auth,
  })  : identifier = ProvidersConst.defaultidentifierName,
        service = APIProviderServices.monero,
        protocol = ServiceProtocol.http;
  const DefaultAPIProvider.aptosDefault({
    this.allowInWeb3 = true,
    this.mode = NetMode.clearnet,
    required this.service,
    required this.url,
    this.timeout,
    this.requestCooldown,
    this.auth,
  })  : identifier = ProvidersConst.defaultidentifierName,
        protocol = ServiceProtocol.http;
  const DefaultAPIProvider.zcashDefault({
    this.allowInWeb3 = true,
    this.mode = NetMode.clearnet,
    required this.url,
    this.timeout,
    this.requestCooldown,
    this.auth,
  })  : identifier = ProvidersConst.defaultidentifierName,
        service = APIProviderServices.walletD,
        protocol = ServiceProtocol.grpc;
  const DefaultAPIProvider.tronDefault({
    this.allowInWeb3 = true,
    this.mode = NetMode.clearnet,
    required this.url,
    this.timeout,
    this.requestCooldown,
    this.auth,
  })  : identifier = ProvidersConst.defaultidentifierName,
        service = APIProviderServices.tron,
        protocol = ServiceProtocol.http;
  const DefaultAPIProvider.suiDefault({
    this.allowInWeb3 = true,
    this.mode = NetMode.clearnet,
    required this.url,
    this.timeout,
    this.requestCooldown,
    this.auth,
  })  : identifier = ProvidersConst.defaultidentifierName,
        service = APIProviderServices.sui,
        protocol = ServiceProtocol.http;
  const DefaultAPIProvider.tonDefault({
    this.allowInWeb3 = true,
    this.mode = NetMode.clearnet,
    required this.url,
    required this.service,
    this.timeout,
    this.requestCooldown,
    this.auth,
  })  : identifier = ProvidersConst.defaultidentifierName,
        protocol = ServiceProtocol.http;
  const DefaultAPIProvider.substateDefault({
    this.allowInWeb3 = true,
    this.mode = NetMode.clearnet,
    required this.url,
    required this.protocol,
    this.timeout,
    this.requestCooldown,
    this.auth,
  })  : identifier = ProvidersConst.defaultidentifierName,
        service = APIProviderServices.substrateJsonRpc;

  const DefaultAPIProvider.chainFlipDefault({
    this.allowInWeb3 = true,
    this.mode = NetMode.clearnet,
    required this.url,
    this.timeout,
    this.requestCooldown,
    this.auth,
  })  : identifier = ProvidersConst.defaultidentifierName,
        service = APIProviderServices.chainFlip,
        protocol = ServiceProtocol.http;
  const DefaultAPIProvider.thorDefault({
    this.allowInWeb3 = true,
    this.mode = NetMode.clearnet,
    required this.url,
    this.timeout,
    this.requestCooldown,
    this.auth,
  })  : identifier = ProvidersConst.defaultidentifierName,
        service = APIProviderServices.thor,
        protocol = ServiceProtocol.http;
  const DefaultAPIProvider.mayaDefault({
    this.allowInWeb3 = true,
    this.mode = NetMode.clearnet,
    required this.url,
    this.timeout,
    this.requestCooldown,
    this.auth,
  })  : identifier = ProvidersConst.defaultidentifierName,
        service = APIProviderServices.maya,
        protocol = ServiceProtocol.http;
  const DefaultAPIProvider.skipGoDefault({
    this.allowInWeb3 = true,
    this.mode = NetMode.clearnet,
    required this.url,
    this.timeout,
    this.requestCooldown,
    this.auth,
  })  : identifier = ProvidersConst.defaultidentifierName,
        service = APIProviderServices.skipGo,
        protocol = ServiceProtocol.http;
  const DefaultAPIProvider.swapKitDefault({
    this.allowInWeb3 = true,
    this.mode = NetMode.clearnet,
    required this.url,
    this.timeout,
    this.requestCooldown,
    this.auth,
  })  : identifier = ProvidersConst.defaultidentifierName,
        service = APIProviderServices.swapKit,
        protocol = ServiceProtocol.http;

  const DefaultAPIProvider.stellarDefault({
    this.allowInWeb3 = true,
    this.mode = NetMode.clearnet,
    required this.url,
    required this.service,
    this.timeout,
    this.requestCooldown,
    this.auth,
  })  : identifier = ProvidersConst.defaultidentifierName,
        protocol = ServiceProtocol.http;
  factory DefaultAPIProvider.create(
      {required APIProviderServices service,
      required String url,
      NetworkType? network,
      ServiceProtocol? protocol,
      Duration? timeout,
      ProviderAuthenticated? auth,
      Duration? requestCooldown,
      bool allowInWeb3 = true,
      NetMode? mode}) {
    final info = APIUtils.getUrlDetails(url);
    if (info == null) {
      throw WalletExceptionConst.invalidProviderInformation;
    }
    if (protocol == null) {
      if (service.supportProtocols.length == 1) {
        protocol = service.supportProtocols.first;
      } else if (info.protocols.length == 1) {
        protocol = info.protocols.first;
      } else {
        final supportedProtocols =
            service.supportProtocols.where((e) => info.protocols.contains(e));
        if (supportedProtocols.length != 1) {
          throw WalletExceptionConst.invalidProviderInformation;
        }
        protocol = supportedProtocols.first;
      }

      if (!info.protocols.contains(protocol)) {
        throw WalletExceptionConst.invalidProviderInformation;
      }
    }
    if (!service.supportProtocols.contains(protocol)) {
      throw WalletExceptionConst.invalidProviderInformation;
    }
    if (!info.protocols.contains(protocol)) {
      throw WalletExceptionConst.invalidProviderInformation;
    }
    if (mode == NetMode.clearnet && info.mode == NetMode.tor) {
      throw WalletExceptionConst.invalidProviderInformation;
    }
    if (network != null && !service.supportNetworks.contains(network)) {
      throw WalletExceptionConst.invalidProviderInformation;
    }
    mode ??= info.mode;
    final identifier = APIUtils.getProviderIdentifier(
        url: url, protocol: protocol, auth: auth, extraType: service.value);
    return DefaultAPIProvider.unsafe(
        identifier: identifier,
        protocol: protocol,
        allowInWeb3: allowInWeb3,
        mode: mode,
        service: service,
        auth: auth,
        url: url,
        timeout: timeout,
        requestCooldown: requestCooldown);
  }

  DefaultAPIProvider withIdentifier() {
    if (isDefaultProvider) {
      return DefaultAPIProvider.unsafe(
          identifier: APIUtils.getProviderIdentifier(
              url: url, protocol: protocol, auth: auth, extraType: service.value),
          protocol: protocol,
          allowInWeb3: allowInWeb3,
          mode: mode,
          service: service,
          auth: auth,
          url: url);
    }
    return this;
  }

  bool supportByNetwork(NetworkType network) {
    return service.supportNetworks.contains(network);
  }

  bool supportByPlatform(AppPlatform platform) {
    final support = protocol.supportOnThisPlatform(platform);
    if (support && platform.isWeb) return !StrUtils.isOnion(url);
    return support;
  }

  bool get isDefaultProvider => identifier == ProvidersConst.defaultidentifierName;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.defaultServiceProvider;
  @override
  List<CborObject?> get serializationItems => [
        url.toCbor(),
        identifier.toCbor(),
        protocol.id.toCbor(),
        auth?.toCbor(),
        allowInWeb3.toCbor(),
        mode.value.toCbor(),
        service.value.toCbor(),
        timeout?.inMilliseconds.toCbor(),
        requestCooldown?.inMilliseconds.toCbor()
      ];

  @override
  List<dynamic> get variables =>
      [url, identifier, protocol, auth, allowInWeb3, mode, service];

  DefaultAPIProvider updateMode(NetMode mode) {
    if (mode == this.mode) return this;
    return DefaultAPIProvider.unsafe(
        identifier: identifier,
        protocol: protocol,
        allowInWeb3: allowInWeb3,
        mode: mode,
        service: service,
        url: url,
        auth: auth);
  }

  DefaultAPIProvider copyWith(
      {String? url,
      String? identifier,
      ServiceProtocol? protocol,
      ProviderAuthenticated? auth,
      bool? allowInWeb3,
      NetMode? mode,
      APIProviderServices? service,
      Duration? timeout,
      Duration? requestCooldown}) {
    return DefaultAPIProvider.unsafe(
        identifier: identifier ?? this.identifier,
        protocol: protocol ?? this.protocol,
        auth: auth ?? this.auth,
        allowInWeb3: allowInWeb3 ?? this.allowInWeb3,
        mode: mode ?? this.mode,
        service: service ?? this.service,
        url: url ?? this.url,
        timeout: timeout ?? this.timeout,
        requestCooldown: requestCooldown ?? this.requestCooldown);
  }

  @override
  String toString() {
    return "$url, $identifier, $protocol $mode";
  }
}
