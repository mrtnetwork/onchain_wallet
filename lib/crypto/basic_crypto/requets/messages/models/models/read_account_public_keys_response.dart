import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/account.dart';

sealed class ReadAccountPublicKeyRequest with AppSerialization {
  const ReadAccountPublicKeyRequest();
  factory ReadAccountPublicKeyRequest.deserialize(
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
        return ReadAccountPublicKeyRequestZcash.deserialize(object: values.tag);
      case AppSerializationIdentifier.runtimeTag2:
        return ReadAccountPublicKeyRequestDefault.deserialize(object: values.tag);
      default:
        throw AppInternalError.internalError("ReadAccountPublicKeyRequest");
    }
  }
}

class ReadAccountPublicKeyRequestDefault extends ReadAccountPublicKeyRequest {
  final AccessCryptoKeysRequest keys;
  const ReadAccountPublicKeyRequestDefault(this.keys);
  factory ReadAccountPublicKeyRequestDefault.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.runtimeTag2,
    );
    return ReadAccountPublicKeyRequestDefault(
        AccessCryptoKeysRequest.deserialize(object: values.objectAt(0)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag2;

  @override
  List<CborObject?> get serializationItems => [keys.toCbor()];
}

class ReadAccountPublicKeyRequestZcashReceivers with AppSerialization {
  final ZcashAccountInfoType type;
  final DiversifierIndex? index;
  final Bip44Changes? change;
  final List<DerivableIndex> indexes;

  const ReadAccountPublicKeyRequestZcashReceivers._(
      {required this.type,
      required this.indexes,
      required this.index,
      required this.change});
  factory ReadAccountPublicKeyRequestZcashReceivers.transparent(
      {required ZcashAccountInfoType type, required List<DerivableIndex> indexes}) {
    if (!type.isTransparent || indexes.isEmpty) {
      throw AppInternalError.internalError("Invalid request.");
    }
    return ReadAccountPublicKeyRequestZcashReceivers._(
        type: type, indexes: indexes, index: null, change: null);
  }
  factory ReadAccountPublicKeyRequestZcashReceivers.sheilded(
      {required ZcashAccountInfoType type,
      required List<DerivableIndex> indexes,
      required DiversifierIndex index,
      required Bip44Changes change}) {
    if (type.isTransparent || indexes.isEmpty) {
      throw AppInternalError.internalError("Invalid request.");
    }
    return ReadAccountPublicKeyRequestZcashReceivers._(
        type: type, indexes: indexes, index: index, change: change);
  }
  factory ReadAccountPublicKeyRequestZcashReceivers.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.runtimeTag,
    );
    return ReadAccountPublicKeyRequestZcashReceivers._(
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
        AppSerialization.bytesToCbor(index?.toBytes()),
        change?.value.toCbor()
      ];
}

class ReadAccountPublicKeyRequestZcash extends ReadAccountPublicKeyRequest {
  final List<ReadAccountPublicKeyRequestZcashReceivers> receivers;
  final ZcashNetwork network;
  ReadAccountPublicKeyRequestZcash(
      {required List<ReadAccountPublicKeyRequestZcashReceivers> receivers,
      required this.network})
      : receivers = receivers.min(
          length: 1,
          operation: "ReadAccountPublicKeyRequestZcash",
          onErr: () => throw AppInternalError.internalError("Invalid request."),
        );
  factory ReadAccountPublicKeyRequestZcash.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.runtimeTag,
    );
    return ReadAccountPublicKeyRequestZcash(
        receivers: values
            .listAt<CborTagValue>(0)
            .map((e) => ReadAccountPublicKeyRequestZcashReceivers.deserialize(object: e))
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

sealed class ReadAccountPublicKeysResponse with AppSerialization {
  const ReadAccountPublicKeysResponse();
  factory ReadAccountPublicKeysResponse.deserialize(
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
        ReadAccountPublicKeysResponseDefault.deserialize(object: decode.tag),
      AppSerializationIdentifier.runtimeTag2 =>
        ReadAccountPublicKeysResponseZcash.deserialize(object: decode.tag),
      _ => throw AppInternalError.internalError("ReadAccountPublicKeysResponse")
    };
  }
}

class ReadAccountPublicKeysResponseDefault extends ReadAccountPublicKeysResponse {
  final List<CryptoPublicKeyDataWithInfo> keys;
  ReadAccountPublicKeysResponseDefault(List<CryptoPublicKeyDataWithInfo> keys)
      : keys = keys.immutable;

  factory ReadAccountPublicKeysResponseDefault.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.runtimeTag,
    );
    return ReadAccountPublicKeysResponseDefault(values
        .listAt<CborTagValue>(0)
        .map((e) => CryptoPublicKeyDataWithInfo.deserialize(object: e))
        .toList());
  }

  ReadAccountPublicKeysResponseDefault copyWith(
      {List<CryptoPublicKeyDataWithInfo>? keys}) {
    return ReadAccountPublicKeysResponseDefault(keys ?? this.keys);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(keys.map((e) => e.toCbor()).toList()),
      ];
}

class ReadAccountPublicKeysResponseZcashReceivers with AppSerialization {
  final List<CryptoPublicKeyDataWithInfo> keys;

  final BigInt? index;
  final Bip44Changes? change;
  final ZcashAccountInfoType type;
  ReadAccountPublicKeysResponseZcashReceivers({
    required List<CryptoPublicKeyDataWithInfo> keys,
    required this.type,
    required this.index,
    required this.change,
  }) : keys = keys.immutable;
  factory ReadAccountPublicKeysResponseZcashReceivers.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.runtimeTag,
    );
    return ReadAccountPublicKeysResponseZcashReceivers(
        type: ZcashAccountInfoType.fromIdentifier(values.rawValueAt(0)),
        keys: values
            .listAt<CborTagValue>(1)
            .map((e) => CryptoPublicKeyDataWithInfo.deserialize(object: e))
            .toList(),
        index: values.rawValueAt(2),
        change: values.maybeRawValueAt<Bip44Changes, int>(
            3, (e) => Bip44Changes.fromValue(e)));
  }
  ReadAccountPublicKeysResponseZcashReceivers copyWith(
      {List<CryptoPublicKeyDataWithInfo>? keys,
      ZcashAccountInfoType? type,
      BigInt? index,
      Bip44Changes? change}) {
    return ReadAccountPublicKeysResponseZcashReceivers(
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

class ReadAccountPublicKeysResponseZcashFvk with AppSerialization {
  final String ufvk;
  final String uivk;
  final List<ZcashAccountInfoType> types;
  ReadAccountPublicKeysResponseZcashFvk(
      {required this.ufvk, required this.uivk, required List<ZcashAccountInfoType> types})
      : types = types.immutable;
  factory ReadAccountPublicKeysResponseZcashFvk.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.runtimeTag2,
    );
    return ReadAccountPublicKeysResponseZcashFvk(
      ufvk: values.rawValueAt(0),
      uivk: values.rawValueAt(1),
      types: values
          .listAt<CborIntValue>(2)
          .map((e) => ZcashAccountInfoType.fromIdentifier(e.value))
          .toList(),
    );
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag2;

  @override
  List<CborObject?> get serializationItems => [
        ufvk.toCbor(),
        uivk.toCbor(),
        AppSerialization.listFromObjects(
            types.map((e) => CborIntValue(e.tag.id)).toList())
      ];
}

class ReadAccountPublicKeysResponseZcash extends ReadAccountPublicKeysResponse {
  final List<ReadAccountPublicKeysResponseZcashReceivers> keys;
  final ReadAccountPublicKeysResponseZcashFvk? ufvk;
  ReadAccountPublicKeysResponseZcash(
      {required List<ReadAccountPublicKeysResponseZcashReceivers> keys, this.ufvk})
      : keys = keys.immutable;
  factory ReadAccountPublicKeysResponseZcash.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.runtimeTag2,
    );
    return ReadAccountPublicKeysResponseZcash(
      keys: values
          .listAt<CborTagValue>(0)
          .map((e) => ReadAccountPublicKeysResponseZcashReceivers.deserialize(object: e))
          .toList(),
      ufvk: values.maybeObjectAt<ReadAccountPublicKeysResponseZcashFvk, CborTagValue>(
          1, (e) => ReadAccountPublicKeysResponseZcashFvk.deserialize(object: e)),
    );
  }
  ReadAccountPublicKeysResponseZcash copyWith(
      {List<ReadAccountPublicKeysResponseZcashReceivers>? keys,
      ReadAccountPublicKeysResponseZcashFvk? ufvk}) {
    return ReadAccountPublicKeysResponseZcash(
        keys: keys ?? this.keys, ufvk: ufvk ?? this.ufvk);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag2;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(keys.map((e) => e.toCbor()).toList()),
        ufvk?.toCbor(),
      ];
}
