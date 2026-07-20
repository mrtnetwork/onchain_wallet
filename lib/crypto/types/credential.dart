import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';

enum WalletPlatformCredentialType {
  webAuth(AppSerializationIdentifier.walletPlatformCredentialWebAuth),
  localAuth(AppSerializationIdentifier.walletPlatformCredentialLocalAuth);

  final AppSerializationIdentifier tags;
  const WalletPlatformCredentialType(this.tags);
  static WalletPlatformCredentialType fromValue(List<int>? tags) {
    return values.firstWhere((e) => e.tags.isValidTags(tags),
        orElse: () => throw AppInternalError.internalError(
            "WalletPlatformCredentialType.fromValue"));
  }
}

abstract final class WalletPlatformCredential with AppSerialization {
  final WalletPlatformCredentialType type;
  const WalletPlatformCredential({required this.type});
  factory WalletPlatformCredential.deserialize({List<int>? bytes, CborObject? object}) {
    final CborTagValue decode =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    final type = WalletPlatformCredentialType.fromValue(decode.tags);
    return switch (type) {
      WalletPlatformCredentialType.localAuth =>
        WalletPlatformCredentialIo.deserialize(object: decode),
      WalletPlatformCredentialType.webAuth =>
        WalletPlatformCredentialWeb.deserialize(object: decode)
    };
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tags;
}

final class WalletPlatformCredentialIo extends WalletPlatformCredential {
  const WalletPlatformCredentialIo()
      : super(type: WalletPlatformCredentialType.localAuth);
  factory WalletPlatformCredentialIo.deserialize({List<int>? bytes, CborObject? object}) {
    AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletPlatformCredentialType.localAuth.tags);
    return WalletPlatformCredentialIo();
  }
  @override
  List<CborObject?> get serializationItems => [];
}

final class WalletPlatformCredentialWeb extends WalletPlatformCredential {
  final List<int> id;
  final List<int> publicKey;
  WalletPlatformCredentialWeb({required List<int> id, required List<int> publicKey})
      : id = id.asImmutableBytes,
        publicKey = publicKey.asImmutableBytes,
        super(type: WalletPlatformCredentialType.webAuth);
  factory WalletPlatformCredentialWeb.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletPlatformCredentialType.webAuth.tags);
    return WalletPlatformCredentialWeb(
        id: values.rawValueAt(0), publicKey: values.rawValueAt(1));
  }

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(id), CborBytesValue(publicKey)];
}
