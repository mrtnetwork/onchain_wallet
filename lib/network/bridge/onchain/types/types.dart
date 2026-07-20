import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/json/json.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/exception/exception.dart';
import 'package:on_chain_wallet/network/bridge/types/server/types.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/types.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/topic_message.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/network/bridge/onchain/types/actions.dart';
import 'package:on_chain_wallet/network/bridge/onchain/types/events.dart';
import 'package:on_chain_wallet/network/bridge/utils/id_generator.dart';
import 'package:on_chain_wallet/crypto/types/sym_key.dart';
import 'package:on_chain_wallet/wallet/models/wallet/models/backup.dart';

sealed class BridgeEventOnChain extends IBridgeEvent {
  const BridgeEventOnChain() : super(BridgeEventTarget.onchain);

  T cast<T extends BridgeEventOnChain>() {
    if (this is T) return this as T;
    throw BridgeExceptionConst.internalError;
  }
}

class BridgeEventOnChainConnected extends BridgeEventOnChain {
  final BridgeProtocol protocol;
  const BridgeEventOnChainConnected(this.protocol);
}

class BridgeEventOnChainDisconnected extends BridgeEventOnChain {
  final BridgeProtocol protocol;
  const BridgeEventOnChainDisconnected(this.protocol);
}

class BridgeEventOnChainPairingAction extends BridgeEventOnChain {
  BridgeProtocol get protocol => message.protocol;

  final TopicMessagePairing message;
  final WCMActionPairing request;
  const BridgeEventOnChainPairingAction({required this.message, required this.request});
}

class BridgeEventOnChainMessageStatus extends BridgeEventOnChain {
  final BridgeRequestMessage message;
  const BridgeEventOnChainMessageStatus({required this.message});
}

sealed class BridgeEventOnChainSession<REQUEST extends WCMActionSession>
    extends BridgeEventOnChain {
  final WCMSession session;
  final REQUEST request;
  final TopicMessageRequest message;
  const BridgeEventOnChainSession(
      {required this.session, required this.request, required this.message});
  int get correlationId => message.message.id;
  factory BridgeEventOnChainSession.fromSessionMessage(
      {required TopicMessageRequest message, List<int>? bytes, CborObject? obj}) {
    final method = message.method;
    final action = WCMActionSession.deserialize(method: method, bytes: bytes);

    final BridgeEventOnChainSession event = switch (action) {
      WCMActionRequest<Object?> request => switch (request) {
          WCMActionRequestNetworkClient<Object?>() =>
            BridgeEventOnChainSessionActionClient(
                message: message, request: request, session: message.session.cast()),
          _ => throw UnimplementedError(),
        },
      WCMActionEvent event => switch (event) {
          WCMEventNetworkClientStream stream =>
            BridgeEventOnChainSessionActionClientEventStream(
                message: message, request: stream, session: message.session.cast()),
          WCMEventNetworkClientProviderChanged e =>
            BridgeEventOnChainSessionActionClientEventProviderChanged(
                message: message, request: e, session: message.session.cast()),
          _ => throw UnimplementedError(),
        },
      _ => throw UnimplementedError(),
    };
    return event.cast();
  }
}

class BridgeEventOnChainSessionActionClient
    extends BridgeEventOnChainSession<WCMActionRequestNetworkClient> {
  const BridgeEventOnChainSessionActionClient(
      {required super.message, required super.request, required super.session});
}

//
class BridgeEventOnChainSessionActionClientEventStream
    extends BridgeEventOnChainSession<WCMEventNetworkClientStream> {
  const BridgeEventOnChainSessionActionClientEventStream(
      {required super.message, required super.request, required super.session});
}

class BridgeEventOnChainSessionActionClientEventProviderChanged
    extends BridgeEventOnChainSession<WCMEventNetworkClientProviderChanged> {
  const BridgeEventOnChainSessionActionClientEventProviderChanged(
      {required super.message, required super.request, required super.session});
}

// class BridgeEventOnChainSessionAction extends BridgeEventOnChain {
//   BridgeProtocol get protocol => message.protocol;
//   final TopicMessageRequest message;
//   final WCMActionSession request;
//   final WCMSession session;
//   int get correlationId => message.message.id;
//   const BridgeEventOnChainSessionAction(
//       {required this.message, required this.request, required this.session});
// }

class BridgeEventOnChainPairingPorpose extends BridgeEventOnChain {
  final TopicMessagePairing message;
  final WCMActionPairingPorpose request;
  BridgeProtocol get protocol => message.protocol;
  int get correlationId => message.message.id;
  String get topic => message.session.topic;

  const BridgeEventOnChainPairingPorpose({required this.message, required this.request});
}

class WCMSession extends IBridgeSession {
  final ViewExternalWalletConnectionInfo session;
  @override
  late final WCNextIdGenerator idGenerator = WCNextIdGenerator(session.clientId);
  WCMSession(this.session, {super.protocol = BridgeProtocol.onChain})
      : super(
            symKey: session.sharedKey,
            topic: session.topic,
            type: BridgeSessionType.onChain);
  @override
  BridgeSessionType get type => BridgeSessionType.onChain;
  @override
  String get topic => session.topic;

  @override
  List<int> get symKey => session.sharedKey;

  @override
  String toString() {
    return "session: $session";
  }

  @override
  int get clientId => session.clientId;
}

abstract class WCMAction<RESPONSE extends Object?> extends IBrdigeAction<RESPONSE>
    with AppSerialization {
  final PublishMessageStorageType storageType;
  final PublishMessageMode mode;
  final int? requestId;
  const WCMAction(
      {required super.method,
      required WCMBridgeMessageType super.messageType,
      required this.storageType,
      required this.mode,
      this.requestId});

  @override
  List<int> serialize() {
    return toCbor().encode();
  }
}

abstract class WCMActionSession<RESPONSE extends Object?> extends WCMAction<RESPONSE> {
  const WCMActionSession(
      {required super.storageType,
      required super.mode,
      required super.method,
      required super.messageType,
      super.requestId});

  @override
  List<int> serialize() {
    return toCbor().encode();
  }

  factory WCMActionSession.deserialize(
      {required BridgeKnownMethods method, List<int>? bytes, CborObject? obj}) {
    final WCMActionSession action = switch (method) {
      BridgeKnownMethods.sessionEvent =>
        WCMActionEvent.deserialize(bytes: bytes, object: obj),
      BridgeKnownMethods.sessionRequest =>
        WCMActionRequest.deserialize(bytes: bytes, object: obj),
      _ => throw BridgeExceptionConst.unsuportedMethod
    };
    return action.cast();
  }
}

sealed class WCMActionPairing<RESPONSE extends Object?> extends WCMAction<RESPONSE> {
  const WCMActionPairing({required super.method})
      : super(
            messageType: WCMBridgeMessageType.pairing,
            mode: PublishMessageMode.publishAndResult,
            storageType: PublishMessageStorageType.memory);
  factory WCMActionPairing.deserialize({List<int>? bytes, CborObject? object}) {
    final decode = AppSerialization.decodeTaggedValueWithInfo(
        cborBytes: bytes,
        expectedTags: [AppSerializationIdentifier.wcmResponsePairInfo],
        cborObject: object);
    final action = switch (decode.identifier) {
      AppSerializationIdentifier.wcmResponsePairInfo =>
        WCMActionPairingPorpose.deserialize(object: decode.tag),
      _ => throw AppInternalError.internalError("WCMActionPairing")
    };
    return action.cast();
  }
}

class WCMActionPairingPorposeResponse with AppSerialization {
  final List<int> encryptedWallet;
  final List<int> publicKey;
  WCMActionPairingPorposeResponse(
      {required List<int> encryptedWallet, required List<int> publicKey})
      : encryptedWallet = encryptedWallet.asImmutableBytes,
        publicKey = publicKey.asImmutableBytes;
  factory WCMActionPairingPorposeResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.wcmResponsePairInfo);
    return WCMActionPairingPorposeResponse(
        encryptedWallet: values.rawValueAt(0), publicKey: values.rawValueAt(1));
  }
  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcmResponsePairInfo;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(encryptedWallet), CborBytesValue(publicKey)];
}

class WCMActionPairingPorpose extends WCMActionPairing<WCMActionPairingPorposeResponse>
    with AppSerialization {
  final DateTime expiry;
  final List<int> publicKey;
  const WCMActionPairingPorpose({required this.publicKey, required this.expiry})
      : super(method: BridgeKnownMethods.sessionPropose);
  factory WCMActionPairingPorpose.deserialize({CborObject? object, List<int>? bytes}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.wcmParingPorpoose,
        cborBytes: bytes,
        cborObject: object);
    return WCMActionPairingPorpose(
        publicKey: values.rawValueAt(0), expiry: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.wcmParingPorpoose;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(publicKey), expiry.toCbor()];

  @override
  WCMActionPairingPorposeResponse onResponse(Object? result) {
    return WCMActionPairingPorposeResponse.deserialize(
        bytes: JsonParser.valueAsBytes(result));
  }
}

class WCMPairingRequest {
  final WCMActionPairingPorpose request;
  final SymKey key;
  const WCMPairingRequest({
    required this.request,
    required this.key,
  });
}

class WCMPairingReponse {
  final WCMActionPairingPorposeResponse pairInfo;
  final String topic;
  const WCMPairingReponse({required this.pairInfo, required this.topic});
}

class ExternalWalletBackupWithSession {
  final List<int> encodedBackup;
  final ViewExternalWalletConnectionInfo session;
  const ExternalWalletBackupWithSession(
      {required this.encodedBackup, required this.session});
}

class PairedConnectionSession {
  final WCMSession session;
  final SymKey symKey;
  final BridgeUri uri;
  const PairedConnectionSession(
      {required this.session, required this.symKey, required this.uri});
}

class PairingConnectionKey {
  final List<int> key;
  final String topic;
  const PairingConnectionKey({required this.key, required this.topic});
}

class WCMExternalWalletBackup {
  final ExternalWalletBackup backup;
  final SymKey key;
  WCMExternalWalletBackup({required this.backup, required this.key});
}
