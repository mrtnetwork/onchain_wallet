import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/serialization/serialization.dart';

import 'package:on_chain_wallet/app/utils/string/utils.dart';
import 'content_type.dart';

typedef OnLoadUrl = Future<String> Function();
typedef OnLoadCacheKey = Future<String> Function();

abstract class APPImageInfo with Equality {
  abstract final OnLoadUrl loadUrl;
  abstract final ContentType type;
}

class APPImage with AppSerialization, Equality implements APPImageInfo {
  @override
  final ContentType type;
  final String uri;
  const APPImage._({required this.type, required this.uri});
  const APPImage.local(this.uri) : type = ContentType.local;
  factory APPImage.hex({required String hexData}) {
    return APPImage._(type: ContentType.hex, uri: hexData);
  }
  factory APPImage.base64({required String hexData}) {
    return APPImage._(type: ContentType.base64, uri: hexData);
  }
  static APPImage? network(String? imageUrl) {
    final validateUrl = StrUtils.validateUri(imageUrl);
    if (validateUrl == null) return null;
    return APPImage._(type: ContentType.network, uri: imageUrl!);
  }

  factory APPImage.faviIcon(String websiteUrl) {
    final host = Uri.tryParse(websiteUrl);
    String cacheKey = host?.host ?? "";
    if (cacheKey.isEmpty) {
      cacheKey = websiteUrl;
    }
    return APPImage._(type: ContentType.favIcon, uri: websiteUrl);
  }

  factory APPImage.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.imageTag);
    final String uri = cbor.rawValueAt(1);
    return APPImage._(type: ContentType.fromValue(cbor.rawValueAt(0)), uri: uri);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.imageTag;

  @override
  List<CborObject?> get serializationItems => [type.value.toCbor(), CborStringValue(uri)];
  @override
  List get variables => [type, uri];

  @override
  OnLoadUrl get loadUrl => () async => uri;
}
