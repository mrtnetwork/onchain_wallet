import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/account.dart';

sealed class ReadAccountPrivateKeyRequest with AppSerialization {
  const ReadAccountPrivateKeyRequest();
  factory ReadAccountPrivateKeyRequest.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValueWithInfo(
        cborBytes: bytes,
        cborObject: object,
        expectedTags: [
          AppSerializationIdentifier.runtimeTag2,
          AppSerializationIdentifier.runtimeTag
        ]);
    switch (values.identifier) {
      case AppSerializationIdentifier.runtimeTag:
        return ReadAccountPrivateKeyRequestZcash.deserialize(object: values.tag);
      case AppSerializationIdentifier.runtimeTag2:
        return ReadAccountPrivateKeyRequestDefault.deserialize(object: values.tag);
      default:
        throw AppInternalError.internalError("ReadAccountPrivateKeyRequest");
    }
  }
}

class ReadAccountPrivateKeyRequestDefault extends ReadAccountPrivateKeyRequest {
  final AccessCryptoKeysRequest keys;
  const ReadAccountPrivateKeyRequestDefault(this.keys);
  factory ReadAccountPrivateKeyRequestDefault.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.runtimeTag2,
    );
    return ReadAccountPrivateKeyRequestDefault(
        AccessCryptoKeysRequest.deserialize(object: values.objectAt(0)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag2;

  @override
  List<CborObject?> get serializationItems => [keys.toCbor()];
}

class ReadAccountPrivateKeyRequestZcashReceivers with AppSerialization {
  final ZcashAccountInfoType type;
  final DiversifierIndex? index;
  final Bip44Changes? change;
  final List<DerivableIndex> indexes;

  const ReadAccountPrivateKeyRequestZcashReceivers._(
      {required this.type,
      required this.indexes,
      required this.index,
      required this.change});
  factory ReadAccountPrivateKeyRequestZcashReceivers.transparent(
      {required ZcashAccountInfoType type, required List<DerivableIndex> indexes}) {
    if (!type.isTransparent || indexes.isEmpty) {
      throw AppInternalError.internalError("Invalid request.");
    }
    return ReadAccountPrivateKeyRequestZcashReceivers._(
        type: type, indexes: indexes, index: null, change: null);
  }
  factory ReadAccountPrivateKeyRequestZcashReceivers.sheilded(
      {required ZcashAccountInfoType type,
      required List<DerivableIndex> indexes,
      required DiversifierIndex index,
      required Bip44Changes change}) {
    if (type.isTransparent || indexes.isEmpty) {
      throw AppInternalError.internalError("Invalid request.");
    }
    return ReadAccountPrivateKeyRequestZcashReceivers._(
        type: type, indexes: indexes, index: index, change: change);
  }
  factory ReadAccountPrivateKeyRequestZcashReceivers.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.runtimeTag,
    );
    return ReadAccountPrivateKeyRequestZcashReceivers._(
        type: ZcashAccountInfoType.fromIdentifier(values.rawValueAt(0)),
        indexes: values
            .listAt<CborTagValue>(1)
            .map((e) => DerivableIndex.deserialize(object: e))
            .toList(),
        index: values.maybeRawValueAt<DiversifierIndex, List<int>>(
            2, (e) => DiversifierIndex(e)),
        change: values.maybeRawValueAt<Bip44Changes, int>(
            3, (e) => Bip44Changes.fromValue(e)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        type.tag.id.toCbor(),
        AppSerialization.listFromObjects(indexes.map((e) => e.toCbor()).toList()),
        index?.toBytes().toCborBytes(),
        change?.value.toCbor()
      ];
}

class ReadAccountPrivateKeyRequestZcash extends ReadAccountPrivateKeyRequest {
  final List<ReadAccountPrivateKeyRequestZcashReceivers> receivers;
  final ZcashNetwork network;
  ReadAccountPrivateKeyRequestZcash(
      {required List<ReadAccountPrivateKeyRequestZcashReceivers> receivers,
      required this.network})
      : receivers = receivers.min(
          length: 1,
          operation: "ReadAccountPrivateKeyRequestZcash",
          onErr: () => throw AppInternalError.internalError("Invalid request."),
        );
  factory ReadAccountPrivateKeyRequestZcash.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.runtimeTag,
    );
    return ReadAccountPrivateKeyRequestZcash(
        receivers: values
            .listAt<CborTagValue>(0)
            .map((e) => ReadAccountPrivateKeyRequestZcashReceivers.deserialize(object: e))
            .toList(),
        network: ZcashNetwork.fromValue(values.rawValueAt(1)));
  }
  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(receivers.map((e) => e.toCbor()).toList()),
        network.value.toCbor()
      ];
}

sealed class ReadAccountPrivateKeysResponse with AppSerialization {
  const ReadAccountPrivateKeysResponse();
  factory ReadAccountPrivateKeysResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final decode = AppSerialization.decodeTaggedValueWithInfo(
        cborBytes: bytes,
        cborObject: object,
        expectedTags: [
          AppSerializationIdentifier.runtimeTag,
          AppSerializationIdentifier.runtimeTag2
        ]);
    return switch (decode.identifier) {
      AppSerializationIdentifier.runtimeTag =>
        ReadAccountPrivateKeysResponseDefault.deserialize(object: decode.tag),
      AppSerializationIdentifier.runtimeTag2 =>
        ReadAccountPrivateKeysResponseZcash.deserialize(object: decode.tag),
      _ => throw AppInternalError.internalError("ReadAccountPrivateKeysResponse")
    };
  }
}

class ReadAccountPrivateKeysResponseDefault extends ReadAccountPrivateKeysResponse {
  final List<CryptoPrivateKeyDataWithInfo> keys;
  ReadAccountPrivateKeysResponseDefault(List<CryptoPrivateKeyDataWithInfo> keys)
      : keys = keys.immutable;

  factory ReadAccountPrivateKeysResponseDefault.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.runtimeTag,
    );
    return ReadAccountPrivateKeysResponseDefault(values
        .listAt<CborTagValue>(0)
        .map((e) => CryptoPrivateKeyDataWithInfo.deserialize(object: e))
        .toList());
  }

  ReadAccountPrivateKeysResponseDefault copyWith(
      {List<CryptoPrivateKeyDataWithInfo>? keys}) {
    return ReadAccountPrivateKeysResponseDefault(keys ?? this.keys);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(keys.map((e) => e.toCbor()).toList()),
      ];
}

class ReadAccountPrivateKeysResponseZcashReceivers with AppSerialization {
  final List<CryptoPrivateKeyDataWithInfo> keys;

  final BigInt? index;
  final Bip44Changes? change;
  final ZcashAccountInfoType type;
  ReadAccountPrivateKeysResponseZcashReceivers({
    required List<CryptoPrivateKeyDataWithInfo> keys,
    required this.type,
    required this.index,
    required this.change,
  }) : keys = keys.immutable;
  factory ReadAccountPrivateKeysResponseZcashReceivers.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.runtimeTag,
    );
    return ReadAccountPrivateKeysResponseZcashReceivers(
        type: ZcashAccountInfoType.fromIdentifier(values.rawValueAt(0)),
        keys: values
            .listAt<CborTagValue>(1)
            .map((e) => CryptoPrivateKeyDataWithInfo.deserialize(object: e))
            .toList(),
        index: values.rawValueAt(2),
        change: values.maybeRawValueAt<Bip44Changes, int>(
            3, (e) => Bip44Changes.fromValue(e)));
  }
  ReadAccountPrivateKeysResponseZcashReceivers copyWith(
      {List<CryptoPrivateKeyDataWithInfo>? keys,
      ZcashAccountInfoType? type,
      BigInt? index,
      Bip44Changes? change}) {
    return ReadAccountPrivateKeysResponseZcashReceivers(
        keys: keys ?? this.keys,
        change: change ?? this.change,
        index: index ?? this.index,
        type: type ?? this.type);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        type.tag.id.toCbor(),
        AppSerialization.listFromObjects(keys.map((e) => e.toCbor()).toList()),
        index?.toCbor(),
        change?.value.toCbor()
      ];
}

class ReadAccountPrivateKeysResponseZcash extends ReadAccountPrivateKeysResponse {
  final List<ReadAccountPrivateKeysResponseZcashReceivers> keys;
  final String? ufsk;
  ReadAccountPrivateKeysResponseZcash(
      {required List<ReadAccountPrivateKeysResponseZcashReceivers> keys, this.ufsk})
      : keys = keys.immutable;
  factory ReadAccountPrivateKeysResponseZcash.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.runtimeTag2,
    );
    return ReadAccountPrivateKeysResponseZcash(
      keys: values
          .listAt<CborTagValue>(0)
          .map((e) => ReadAccountPrivateKeysResponseZcashReceivers.deserialize(object: e))
          .toList(),
      ufsk: values.rawValueAt(1),
    );
  }
  ReadAccountPrivateKeysResponseZcash copyWith(
      {List<ReadAccountPrivateKeysResponseZcashReceivers>? keys, String? ufsk}) {
    return ReadAccountPrivateKeysResponseZcash(
        keys: keys ?? this.keys, ufsk: ufsk ?? this.ufsk);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag2;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(keys.map((e) => e.toCbor()).toList()),
        ufsk?.toCbor()
      ];
}
