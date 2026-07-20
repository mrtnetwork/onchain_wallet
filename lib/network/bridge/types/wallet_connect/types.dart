import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/constants/constants.dart';
import 'package:on_chain_wallet/network/bridge/exception/exception.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/types.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/topic_message.dart';
import 'package:on_chain_wallet/network/bridge/types/server/types.dart';
import 'package:on_chain_wallet/network/bridge/utils/id_generator.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/exception/exception.dart';

sealed class BridgeEventWeb3 extends IBridgeEvent {
  const BridgeEventWeb3() : super(BridgeEventTarget.web3);
  static BridgeEventWeb3? fromPairingMessage(TopicMessagePairing message) {
    final method = message.method;
    final params = message.message.params;
    final msg = WCActionPairing.deserialize(
        method: method, json: JsonParser.valueAsMap<Map<String, dynamic>?>(params) ?? {});
    return switch (msg) {
      WCActionPairingPropose() =>
        BridgeEventWeb3PairingPropose(message: message, request: msg),
      WCActionPairingDelete() =>
        BridgeEventWeb3PairingDelete(message: message, request: msg),
      _ => null,
    };
  }

  static BridgeEventWeb3? fromSessionMessage(TopicMessageRequest message) {
    final method = message.method;
    final params = message.message.params;
    final msg = WCActionSession.deserialize(
        method: method, json: JsonParser.valueAsMap<Map<String, dynamic>?>(params) ?? {});
    return switch (msg) {
      WCActionSessionRqeuest() => BridgeEventWeb3SessionRequest(
          message: message, request: msg, session: message.session.cast()),
      WCActionSessionDelete() => BridgeEventWeb3SessionDelete(
          message: message, request: msg, session: message.session.cast()),
      _ => null
    };
  }
}

class BridgeEventWeb3Connected extends BridgeEventWeb3 {
  final BridgeProtocol protocol;
  const BridgeEventWeb3Connected(this.protocol);
}

class BridgeEventWeb3Disconnected extends BridgeEventWeb3 {
  final BridgeProtocol protocol;
  const BridgeEventWeb3Disconnected(this.protocol);
}

class BridgeEventWeb3PairingDelete extends BridgeEventWeb3 {
  BridgeProtocol get protocol => message.protocol;
  final TopicMessagePairing message;
  final WCActionPairingDelete request;
  String get topic => message.session.topic;
  const BridgeEventWeb3PairingDelete({required this.message, required this.request});
}

class BridgeEventWeb3PairingPropose extends BridgeEventWeb3 {
  final TopicMessagePairing message;
  final WCActionPairingPropose request;
  BridgeProtocol get protocol => message.protocol;
  int get correlationId => message.message.id;
  String get topic => message.session.topic;

  const BridgeEventWeb3PairingPropose({required this.message, required this.request});

  Duration? timeout() {
    final expiry = request.expiry ?? message.expire;
    final n = expiry.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;
    if (n.isNegative) return null;
    return Duration(milliseconds: n);
  }
}

class BridgeEventWeb3SessionRequest extends BridgeEventWeb3 {
  BridgeProtocol get protocol => message.protocol;

  final TopicMessageRequest message;
  int get id => message.message.id;
  final WCActionSessionRqeuest request;
  final WCSession session;
  const BridgeEventWeb3SessionRequest(
      {required this.message, required this.request, required this.session});

  Duration? timeout() {
    final expiry = request.expiry ?? message.expire;
    final n = expiry.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;
    if (n.isNegative) return null;
    return Duration(milliseconds: n);
  }
}

class BridgeEventWeb3SessionDelete extends BridgeEventWeb3 {
  BridgeProtocol get protocol => message.protocol;

  final TopicMessageRequest message;
  int get correlationId => message.message.id;
  final WCActionSessionDelete request;
  final WCSession session;
  const BridgeEventWeb3SessionDelete(
      {required this.message, required this.request, required this.session});
}

class BridgeEventWeb3MessageStatus extends BridgeEventWeb3 {
  final BridgeRequestMessage message;
  const BridgeEventWeb3MessageStatus({required this.message});
  int get correlationId => message.correlationId;
}

/// Wallet connect types.
class WCSession extends IBridgeSession with AppSerialization {
  final WCProtocolOptions relay;
  final WCSessionNamespaces namespaces;
  final WCSessionNamespaces requiredNamespaces;
  final WCSessionNamespaces optionalNamespaces;
  final WCTransportType transportType;
  final bool isActive;
  final DateTime expireTime;
  final DateTime latestAction;
  final WCProposer peer;
  @override
  final int clientId;
  @override
  late final WCNextIdGenerator idGenerator = WCNextIdGenerator(clientId);
  bool get isExpired => expireTime.isBefore(DateTime.now());
  factory WCSession.deserialize({List<int>? bytes, CborTagValue? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.wcBridgeSession);
    return WCSession(
        symkey: values.rawValueAt(0),
        topic: values.rawValueAt(1),
        relay: WCProtocolOptions.deserialize(object: values.objectAt<CborTagValue>(2)),
        namespaces:
            WCSessionNamespaces.deserialize(object: values.objectAt<CborTagValue>(3)),
        peer: WCProposer.deserialize(object: values.objectAt<CborTagValue>(4)),
        transportType: WCTransportType.fromTag(values.rawValueAt(5)),
        isActive: values.rawValueAt(6),
        expireTime: values.rawValueAt(7),
        latestAction: values.rawValueAt(8),
        requiredNamespaces:
            WCSessionNamespaces.deserialize(object: values.objectAt<CborTagValue>(9)),
        optionalNamespaces:
            WCSessionNamespaces.deserialize(object: values.objectAt<CborTagValue>(10)),
        clientId: values.rawValueAt(11),
        protocol: BridgeProtocol.fromValue(values.rawValueAt(12)));
  }

  WCSession({
    required super.topic,
    required this.relay,
    required this.namespaces,
    required this.peer,
    required List<int> symkey,
    required this.requiredNamespaces,
    required this.optionalNamespaces,
    this.isActive = false,
    required this.expireTime,
    required this.clientId,
    DateTime? latestAction,
    super.protocol = BridgeProtocol.walletConnect,
    this.transportType = WCTransportType.relay,
  })  : latestAction = latestAction ?? DateTime.now(),
        super(symKey: symkey, type: BridgeSessionType.web3);

  WCSession copyWith(
      {String? topic,
      WCProtocolOptions? relay,
      WCSessionNamespaces? namespaces,
      WCProposer? peer,
      Map<String, String>? sessionProperties,
      WCTransportType? transportType,
      List<int>? symKey,
      bool? isActive,
      DateTime? expireTime,
      DateTime? latestAction,
      int? clientId,
      BridgeProtocol? protocol,
      WCSessionNamespaces? requiredNamespaces,
      WCSessionNamespaces? optionalNamespaces}) {
    return WCSession(
        clientId: clientId ?? this.clientId,
        protocol: protocol ?? this.protocol,
        topic: topic ?? this.topic,
        relay: relay ?? this.relay,
        namespaces: namespaces ?? this.namespaces,
        peer: peer ?? this.peer,
        transportType: transportType ?? this.transportType,
        symkey: symKey ?? this.symKey,
        isActive: isActive ?? this.isActive,
        expireTime: expireTime ?? this.expireTime,
        latestAction: latestAction ?? this.latestAction,
        requiredNamespaces: requiredNamespaces ?? this.requiredNamespaces,
        optionalNamespaces: optionalNamespaces ?? this.optionalNamespaces);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcBridgeSession;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(symKey),
        topic.toCbor(),
        relay.toCbor(),
        namespaces.toCbor(),
        peer.toCbor(),
        transportType.value.toCbor(),
        isActive.toCbor(),
        expireTime.toCbor(),
        latestAction.toCbor(),
        requiredNamespaces.toCbor(),
        optionalNamespaces.toCbor(),
        clientId.toCbor(),
        protocol.value.toCbor()
      ];

  String get peerKey => peer.publicKey;

  @override
  BridgeSessionType get type => BridgeSessionType.web3;

  @override
  BridgeProtocol get protocol => BridgeProtocol.walletConnect;
}

class WCProtocolOptions with AppSerialization {
  final String protocol;
  final String? data;

  const WCProtocolOptions({
    this.protocol = BridgeConstants.wcRelayProtocol,
    this.data,
  });
  factory WCProtocolOptions.deserialize({List<int>? bytes, CborTagValue? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.wcRelay);
    return WCProtocolOptions(data: values.rawValueAt(0), protocol: values.rawValueAt(1));
  }

  factory WCProtocolOptions.fromJson(Map<String, dynamic> json) {
    return WCProtocolOptions(
      protocol: json['protocol'],
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() => {
        'protocol': protocol,
        'data': data,
      }.withoutNullValue;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcRelay;

  @override
  List<CborObject?> get serializationItems => [data?.toCbor(), protocol.toCbor()];
}

class WCSessionNamespaces with Equality, AppSerialization {
  final List<WCChainNamespace> namespaces;
  WCSessionNamespaces._(List<WCChainNamespace> namespaces)
      : namespaces = namespaces.immutable;
  factory WCSessionNamespaces(List<WCChainNamespace> namespaces,
      {bool allowEmptyAccount = false}) {
    namespaces = namespaces.clone();
    if (!allowEmptyAccount) {
      namespaces = namespaces.where((e) => e.namespace.accounts.isNotEmpty).toList();
    }
    namespaces.sort((a, b) => a.identifier.compareTo(b.identifier));
    return WCSessionNamespaces._(namespaces);
  }
  factory WCSessionNamespaces.fromJson(Map<String, dynamic> json,
      {bool allowEmptyAccount = false}) {
    final keys = json.keys.toList();
    final namespaces = keys
        .map((e) =>
            WCChainNamespace(identifier: e, namespace: WCNamespace.fromJson(json[e])))
        .toList();
    return WCSessionNamespaces(namespaces, allowEmptyAccount: allowEmptyAccount);
  }
  factory WCSessionNamespaces.deserialize({List<int>? bytes, CborTagValue? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.wcSessionNamespace);
    return WCSessionNamespaces._(values
        .listAt<CborTagValue>(0)
        .map((e) => WCChainNamespace.deserialize(object: e))
        .toList());
  }

  Set<String> get chainIds =>
      namespaces.expand<String>((e) => e.namespace.chains).toSet();

  Map<String, dynamic> toJson() {
    return {
      for (final i in namespaces) i.identifier: i.namespace.toJson(),
    };
  }

  bool chainApproved(String chainId) {
    return namespaces.any(
        (e) => (e.namespace.chains.contains(chainId)) && e.namespace.accounts.isNotEmpty);
  }

  bool allowNamespace(WCSessionNamespaces other) {
    for (final i in other.namespaces) {
      final namspace = namespaces.firstWhereOrNull((e) => e.identifier == i.identifier);
      if (namspace == null) return false;
      if (!i.namespace.methods.every((e) => namspace.namespace.methods.contains(e))) {
        return false;
      }
      if (!i.namespace.events.every((e) => namspace.namespace.events.contains(e))) {
        return false;
      }
      final otherChains = i.namespace.chains;
      final chains = namspace.namespace.chains;
      if (!otherChains.every((e) => chains.contains(e))) {
        return false;
      }
    }
    return true;
  }

  WCSessionNamespaces allowedNamespace(WCSessionNamespaces other) {
    List<WCChainNamespace> allowedNamespace = [];
    for (final i in other.namespaces) {
      final namspace = namespaces.firstWhereOrNull((e) => e.identifier == i.identifier);
      if (namspace == null) continue;
      final methods = i.namespace.methods
          .where((e) => namspace.namespace.methods.contains(e))
          .toList();
      final events =
          i.namespace.events.where((e) => namspace.namespace.events.contains(e)).toList();
      final chains =
          i.namespace.chains.where((e) => namspace.namespace.chains.contains(e)).toList();
      final namespace = WCChainNamespace(
          identifier: namspace.identifier,
          namespace: WCNamespace(chains: chains, methods: methods, events: events));
      allowedNamespace.add(namespace);
    }
    return WCSessionNamespaces(allowedNamespace, allowEmptyAccount: true);
  }

  @override
  List get variables => [namespaces];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcSessionNamespace;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(namespaces.map((e) => e.toCbor()).toList()),
      ];
}

class WCMetadata with AppSerialization {
  final String name;
  final String description;
  final String url;
  final List<String> icons;
  final String? verifyUrl;
  final WCRedirect? redirect;
  const WCMetadata(
      {required this.name,
      required this.description,
      required this.url,
      required this.icons,
      this.verifyUrl,
      this.redirect});
  factory WCMetadata.deserialize({List<int>? bytes, CborTagValue? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.wcMetadata);
    return WCMetadata(
        name: values.rawValueAt(0),
        description: values.rawValueAt(1),
        url: values.rawValueAt(2),
        icons: values.listAt<CborStringValue>(3).map((e) => e.value).toList(),
        verifyUrl: values.rawValueAt(4),
        redirect: values.maybeObjectAt<WCRedirect, CborTagValue>(
            5, (c) => WCRedirect.deserialize(object: c)));
  }
  factory WCMetadata.fromJson(Map<String, dynamic> json) {
    return WCMetadata(
      name: json['name'],
      description: json['description'],
      url: json['url'],
      icons: List<String>.from(json['icons'] ?? []),
      verifyUrl: json['verifyUrl'],
      redirect: json['redirect'] != null ? WCRedirect.fromJson(json['redirect']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'url': url,
      'icons': icons,
      'verifyUrl': verifyUrl,
      'redirect': redirect?.toJson(),
    };
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcMetadata;

  @override
  List<CborObject?> get serializationItems => [
        name.toCbor(),
        description.toCbor(),
        url.toCbor(),
        icons.toCbor(),
        verifyUrl?.toCbor(),
        redirect?.toCbor()
      ];
}

class WCRedirect with AppSerialization {
  final String? native;
  final String? universal;
  final bool? linkMode;
  const WCRedirect(
      {required this.native, required this.universal, required this.linkMode});
  factory WCRedirect.deserialize({List<int>? bytes, CborTagValue? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.wcRedirect);
    return WCRedirect(
        native: values.rawValueAt(0),
        universal: values.rawValueAt(1),
        linkMode: values.rawValueAt(2));
  }
  factory WCRedirect.fromJson(Map<String, dynamic> json) {
    return WCRedirect(
      native: json['native'],
      universal: json['universal'],
      linkMode: json['linkMode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'native': native,
      'universal': universal,
      'linkMode': linkMode,
    };
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcRedirect;

  @override
  List<CborObject?> get serializationItems =>
      [native?.toCbor(), universal?.toCbor(), linkMode?.toCbor()];
}

class WCChainNamespace with Equality, AppSerialization {
  final String identifier;
  final WCNamespace namespace;
  const WCChainNamespace({required this.identifier, required this.namespace});
  factory WCChainNamespace.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.wcChainNamespace);
    return WCChainNamespace(
        identifier: values.rawValueAt(0),
        namespace: WCNamespace.deserialize(object: values.objectAt<CborTagValue>(1)));
  }

  @override
  List get variables => [identifier, namespace];

  Map<String, dynamic> toJson() {
    return {identifier: namespace.toJson()};
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcChainNamespace;

  @override
  List<CborObject?> get serializationItems => [identifier.toCbor(), namespace.toCbor()];
}

class WCNamespace with Equality, AppSerialization {
  final List<String> chains;
  final List<String> accounts;
  final List<String> methods;
  final List<String> events;
  factory WCNamespace.deserialize({List<int>? bytes, CborTagValue? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.wcNamespace);
    return WCNamespace(
        chains: values.listAt<CborStringValue>(0).map((e) => e.value).toList(),
        accounts: values.listAt<CborStringValue>(1).map((e) => e.value).toList(),
        methods: values.listAt<CborStringValue>(2).map((e) => e.value).toList(),
        events: values.listAt<CborStringValue>(3).map((e) => e.value).toList());
  }

  const WCNamespace._(
      {required this.chains,
      required this.accounts,
      required this.methods,
      required this.events});
  factory WCNamespace(
      {required List<String> chains,
      List<String> accounts = const [],
      required List<String> methods,
      required List<String> events}) {
    accounts = accounts.toSet().toList()..sort();
    chains = chains.toSet().toList()..sort();
    methods = methods.toSet().toList()..sort();
    events = events.toSet().toList()..sort();
    return WCNamespace._(
        accounts: accounts, methods: methods, events: events, chains: chains);
  }

  WCNamespace copyWith({
    List<String>? chains,
    List<String>? accounts,
    List<String>? methods,
    List<String>? events,
  }) {
    return WCNamespace(
      chains: chains ?? this.chains,
      accounts: accounts ?? this.accounts,
      methods: methods ?? this.methods,
      events: events ?? this.events,
    );
  }

  factory WCNamespace.fromJson(Map<String, dynamic> json) {
    return WCNamespace(
      chains: (json['chains'] as List?)?.toList().cast() ?? [],
      accounts: (json['accounts'] as List?)?.toList().cast() ?? [],
      methods: (json['methods'] as List).toList().cast(),
      events: (json['events'] as List).toList().cast(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chains': chains,
      'accounts': accounts,
      'methods': methods,
      'events': events,
    };
  }

  @override
  List get variables => [chains, accounts, methods, events];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcNamespace;

  @override
  List<CborObject?> get serializationItems => [
        chains.toCbor(),
        accounts.toCbor(),
        methods.toCbor(),
        events.toCbor(),
      ];
}

enum WCTransportType {
  relay(0),
  linkMode(1);

  final int value;
  const WCTransportType(this.value);

  bool get isLinkMode => this == linkMode;
  bool get isRelay => this == relay;
  static WCTransportType fromTag(int? tag) {
    return values.firstWhere(
      (e) => e.value == tag,
      orElse: () => throw BridgeExceptionConst.internalError,
    );
  }
}

class WCProposer with AppSerialization {
  final String publicKey;
  final WCMetadata metadata;
  factory WCProposer.deserialize({List<int>? bytes, CborTagValue? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.wcRelay);
    return WCProposer(
        publicKey: values.rawValueAt(0),
        metadata: WCMetadata.deserialize(object: values.objectAt<CborTagValue>(1)));
  }

  const WCProposer({
    required this.publicKey,
    required this.metadata,
  });

  factory WCProposer.fromJson(Map<String, dynamic> json) {
    return WCProposer(
      publicKey: json['publicKey'],
      metadata: WCMetadata.fromJson(json['metadata']),
    );
  }

  Map<String, dynamic> toJson() => {
        'publicKey': publicKey,
        'metadata': metadata.toJson(),
      };

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcRelay;

  @override
  List<CborObject?> get serializationItems => [publicKey.toCbor(), metadata.toCbor()];
}

sealed class WCAction extends IBrdigeAction<bool> {
  const WCAction(
      {required super.method, required Web3BridgeMessageType super.messageType});

  @override
  bool onResponse(Object? _) {
    return true;
  }
}

sealed class WCActionPairing extends WCAction {
  const WCActionPairing({required super.method})
      : super(messageType: Web3BridgeMessageType.pairing);
  factory WCActionPairing.deserialize({
    required BridgeKnownMethods method,
    required Map<String, dynamic> json,
  }) {
    return switch (method) {
      BridgeKnownMethods.pairingPing => WCActionPairingPing.fromJson(json),
      BridgeKnownMethods.pairingDelete => WCActionPairingDelete.fromJson(json),
      BridgeKnownMethods.sessionPropose => WCActionPairingPropose.fromJson(json),
      _ => throw BridgeExceptionConst.unsuportedMethod,
    };
  }
}

sealed class WCActionSession extends WCAction {
  const WCActionSession({required super.method, required super.messageType});
  factory WCActionSession.deserialize({
    required BridgeKnownMethods method,
    required Map<String, dynamic> json,
  }) {
    return switch (method) {
      BridgeKnownMethods.sessionSettle => WCActionSessionSettle.fromJson(json),
      BridgeKnownMethods.sessionUpdate => WCActionSessionUpdate.fromJson(json),
      BridgeKnownMethods.sessionEvent => WCActionSessionEvent.fromJson(json),
      BridgeKnownMethods.sessionDelete => WCActionSessionDelete.fromJson(json),
      BridgeKnownMethods.sessionPing => WCActionSessionPing.fromJson(json),
      BridgeKnownMethods.sessionRequest => WCActionSessionRqeuest.fromJson(json),
      _ => throw BridgeExceptionConst.unsuportedMethod,
    };
  }
}

class WCSessionConfig {
  final bool? disableDeepLink;
  const WCSessionConfig({this.disableDeepLink});
  Map<String, dynamic> toJson() {
    return {"disableDeepLink": disableDeepLink};
  }

  factory WCSessionConfig.fromJson(Map<String, dynamic> json) {
    return WCSessionConfig(disableDeepLink: json.valueAs("disableDeepLink"));
  }
}

class WCActionSessionSettle extends WCActionSession {
  final WCProtocolOptions relay;
  final WCSessionNamespaces namespaces;
  final Map<String, String>? sessionProperties;
  final Map<String, dynamic>? scopedProperties;
  final WCSessionConfig? sessionConfig;
  final int expiry;
  final WCProposer controller;

  const WCActionSessionSettle({
    required this.relay,
    required this.namespaces,
    this.sessionProperties,
    this.scopedProperties,
    this.sessionConfig,
    required this.expiry,
    required this.controller,
  }) : super(
            method: BridgeKnownMethods.sessionSettle,
            messageType: Web3BridgeMessageType.settle);
  factory WCActionSessionSettle.fromJson(Map<String, dynamic> json) {
    return WCActionSessionSettle(
      relay: WCProtocolOptions.fromJson(json.valueAs("relay")),
      namespaces: WCSessionNamespaces.fromJson(json.valueEnsureAsMap("namespaces")),
      sessionConfig: json.valueTo<WCSessionConfig?, Map<String, dynamic>>(
        key: "sessionConfig",
        parse: (v) => WCSessionConfig.fromJson(v),
      ),
      expiry: json.valueAs("expiry"),
      controller: WCProposer.fromJson(json.valueAs("controller")),
      scopedProperties: json.valueAsMap<Map<String, dynamic>?>("scopedProperties"),
      sessionProperties: json.valueAsMap<Map<String, String>?>("sessionProperties"),
    );
  }

  @override
  Map<String, dynamic> serialize() => {
        'relay': relay.toJson(),
        'namespaces': namespaces.toJson(),
        'sessionProperties': sessionProperties,
        'scopedProperties': scopedProperties,
        'sessionConfig': sessionConfig?.toJson(),
        'expiry': expiry,
        'controller': controller.toJson(),
      }.withoutNullValue;
}

class WCActionSessionUpdate extends WCActionSession {
  final WCSessionNamespaces namespaces;

  const WCActionSessionUpdate({required this.namespaces})
      : super(
            method: BridgeKnownMethods.sessionUpdate,
            messageType: Web3BridgeMessageType.update);
  factory WCActionSessionUpdate.fromJson(Map<String, dynamic> json) =>
      WCActionSessionUpdate(
          namespaces: WCSessionNamespaces.fromJson(
              json.valueEnsureAsMap<String, dynamic>("namespaces")));

  @override
  Map<String, dynamic> serialize() => {'namespaces': namespaces.toJson()};
}

class WCSessionParams {
  final String method;
  final dynamic params;
  final int? expiryTimestamp;

  const WCSessionParams({
    required this.method,
    required this.params,
    this.expiryTimestamp,
  });

  factory WCSessionParams.fromJson(Map<String, dynamic> json) {
    return WCSessionParams(
      method: json['method'],
      params: json['params'],
      expiryTimestamp: json['expiryTimestamp'],
    );
  }

  Map<String, dynamic> toJson() => {
        'method': method,
        'params': params,
        'expiryTimestamp': expiryTimestamp,
      }.withoutNullValue;
}

class WCActionSessionEvent extends WCActionSession {
  final WCSessionEvent event;
  final String chainId;

  const WCActionSessionEvent({
    required this.event,
    required this.chainId,
  }) : super(
            method: BridgeKnownMethods.sessionEvent,
            messageType: Web3BridgeMessageType.event);

  factory WCActionSessionEvent.fromJson(Map<String, dynamic> json) {
    return WCActionSessionEvent(
      event: WCSessionEvent.fromJson(json['event']),
      chainId: json['chainId'],
    );
  }

  @override
  Map<String, dynamic> serialize() => {
        'event': event.toJson(),
        'chainId': chainId,
      };
}

class WCSessionEvent {
  final String name;
  final dynamic data;

  const WCSessionEvent({
    required this.name,
    required this.data,
  });

  factory WCSessionEvent.fromJson(Map<String, dynamic> json) {
    return WCSessionEvent(
      name: json['name'],
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'data': data,
      };
}

class WCActionPairingPropose extends WCActionPairing {
  final DateTime? expiry;
  final WCProposer proposer;
  final String? pairingTopic;
  final WCSessionNamespaces requiredNamespaces;
  final List<WCProtocolOptions> relays;
  final WCSessionNamespaces optionalNamespaces;
  final Map<String, String> sessionProperties;
  final Map<String, dynamic> scopedProperties;

  const WCActionPairingPropose({
    this.expiry,
    required this.proposer,
    required this.requiredNamespaces,
    required this.optionalNamespaces,
    required this.sessionProperties,
    required this.scopedProperties,
    required this.pairingTopic,
    required this.relays,
  }) : super(method: BridgeKnownMethods.sessionPropose);

  factory WCActionPairingPropose.fromJson(Map<String, dynamic> json) {
    final expire = IntUtils.tryParse(json['expiryTimestamp'] ?? json['expiry']);
    return WCActionPairingPropose(
      expiry: expire == null ? null : DateTimeUtils.detectEpochUnit(expire),
      proposer: WCProposer.fromJson(json['proposer']),
      relays:
          (json["relays"] as List?)?.map((e) => WCProtocolOptions.fromJson(e)).toList() ??
              [],
      requiredNamespaces: WCSessionNamespaces.fromJson(json['requiredNamespaces'] ?? {},
          allowEmptyAccount: true),
      optionalNamespaces: WCSessionNamespaces.fromJson(json['optionalNamespaces'] ?? {},
          allowEmptyAccount: true),
      sessionProperties: Map<String, String>.from(json['sessionProperties'] ?? {}),
      scopedProperties: Map<String, dynamic>.from(json['scopedProperties'] ?? {}),
      pairingTopic: json['pairingTopic'],
    );
  }

  @override
  Map<String, dynamic> serialize() {
    final expiry = this.expiry;
    return {
      "expiryTimestamp": expiry == null ? null : DateTimeUtils.secondsSinceEpoch(expiry),
      "proposer": proposer.toJson(),
      "relays": relays.map((e) => e.toJson()).toList(),
      "requiredNamespaces": requiredNamespaces.toJson(),
      "optionalNamespaces": optionalNamespaces.toJson(),
      "sessionProperties": sessionProperties,
      "scopedProperties": scopedProperties,
      "pairingTopic": pairingTopic
    };
  }
}

class WCActionSessionDelete extends WCActionSession {
  final int code;
  final String message;

  const WCActionSessionDelete({
    required this.code,
    required this.message,
  }) : super(
            method: BridgeKnownMethods.sessionDelete,
            messageType: Web3BridgeMessageType.delete);

  factory WCActionSessionDelete.fromJson(Map<String, dynamic> json) {
    return WCActionSessionDelete(
      code: json['code'],
      message: json['message'],
    );
  }

  @override
  Map<String, dynamic> serialize() => {
        'code': code,
        'message': message,
      };
}

class WCActionPairingDelete extends WCActionPairing {
  final int? code;
  final String? message;

  const WCActionPairingDelete({
    required this.code,
    required this.message,
  }) : super(method: BridgeKnownMethods.pairingDelete);

  factory WCActionPairingDelete.fromJson(Map<String, dynamic>? json) {
    return WCActionPairingDelete(
      code: json?.valueAs("code"),
      message: json?.valueAs("message"),
    );
  }

  @override
  Map<String, dynamic> serialize() => {
        'code': code,
        'message': message,
      };
}

class WCActionPairingPing extends WCActionPairing {
  const WCActionPairingPing() : super(method: BridgeKnownMethods.pairingPing);

  factory WCActionPairingPing.fromJson(dynamic _) {
    return WCActionPairingPing();
  }

  @override
  Map<String, dynamic> serialize() => {};
}

class WCActionSessionPing extends WCActionSession {
  const WCActionSessionPing()
      : super(
            method: BridgeKnownMethods.sessionPing,
            messageType: Web3BridgeMessageType.ping);

  factory WCActionSessionPing.fromJson(dynamic _) {
    return WCActionSessionPing();
  }

  @override
  Map<String, dynamic> serialize() => {};
}

class WCActionSessionRqeuest extends WCActionSession {
  final WCSessionParams request;
  final String chainId;
  final DateTime? expiry;

  const WCActionSessionRqeuest._(
      {required this.request, required this.chainId, this.expiry})
      : super(
            method: BridgeKnownMethods.sessionRequest,
            messageType: Web3BridgeMessageType.request);
  factory WCActionSessionRqeuest(
      {required WCSessionParams request, required String chainId}) {
    final expire = request.expiryTimestamp;
    return WCActionSessionRqeuest._(
        request: request,
        chainId: chainId,
        expiry: expire == null ? null : DateTimeUtils.detectEpochUnit(expire));
  }

  factory WCActionSessionRqeuest.fromJson(Map<String, dynamic> json) {
    return WCActionSessionRqeuest(
      request: WCSessionParams.fromJson(json['request']),
      chainId: json['chainId'],
    );
  }

  @override
  Map<String, dynamic> serialize() => {
        'request': request.toJson(),
        'chainId': chainId,
      };

  Duration? timeout() {
    final expiry = this.expiry;
    if (expiry == null) return null;
    final now = DateTime.now();
    final n = expiry.millisecondsSinceEpoch - now.millisecondsSinceEpoch;
    if (n <= 0) return null;
    return Duration(milliseconds: n);
  }
}

class WCActionResponsePropose {
  final WCProtocolOptions relay;
  final String responderPublicKey;

  const WCActionResponsePropose({required this.relay, required this.responderPublicKey});

  factory WCActionResponsePropose.fromJson(Map<String, dynamic> json) {
    return WCActionResponsePropose(
      relay: WCProtocolOptions.fromJson(json['relay']),
      responderPublicKey: json['responderPublicKey'],
    );
  }

  Map<String, dynamic> toJson() => {
        'relay': relay.toJson(),
        'responderPublicKey': responderPublicKey,
      };
}

sealed class WCSessionProposeResponse {
  final BridgeEventWeb3PairingPropose request;
  const WCSessionProposeResponse({required this.request});

  T cast<T extends WCSessionProposeResponse>() {
    if (this is! T) {
      throw BridgeExceptionConst.internalError;
    }
    return this as T;
  }
}

final class WCSessionProposeAprove extends WCSessionProposeResponse {
  final String publicKey;
  final WCSession session;
  final Map<String, String>? sessionProperties;
  final String? relayProtocol;
  WCSessionProposeAprove(
      {required super.request,
      required this.publicKey,
      required this.session,
      this.sessionProperties,
      this.relayProtocol});
}

final class WCSessionProposeReject extends WCSessionProposeResponse {
  final Web3RequestException exception;
  const WCSessionProposeReject({required super.request, required this.exception})
      : super();
  factory WCSessionProposeReject.fromIException(
      {required BridgeEventWeb3PairingPropose request, required IException exception}) {
    return WCSessionProposeReject(
        request: request, exception: Web3RequestExceptionConst.fromException(exception));
  }
  JsonRpcError toRpcError() => switch (exception) {
        Web3RequestExceptionConst.rejectedByUser =>
          JsonRpcError(code: 5000, message: 'User Rejected.'),
        _ => JsonRpcError(code: -1, message: "Unknown error")
      };
}
