import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/serialization/serialization.dart';

import 'image.dart';

class WebViewTab with AppSerialization, Equality {
  final String id;
  final String url;
  final String? path;
  final String? title;
  final APPImage? image;
  final DateTime lastVisit;
  final String? host;

  late final String? viewTitle = title ?? host;
  WebViewTab._(
      {required this.id,
      required this.url,
      this.path,
      this.title,
      this.image,
      required this.lastVisit,
      required this.host});
  factory WebViewTab(
      {required String id,
      required String url,
      required String? title,
      required APPImage? image,
      DateTime? lastVisit}) {
    String? path;
    String? host;
    Uri? uri = Uri.tryParse(url);
    if (uri != null && uri.host.isNotEmpty) {
      host = uri.host;
      uri = Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
        path: uri.path,
      );
      path = uri.toString();
    }
    return WebViewTab._(
        id: id,
        url: url,
        title: (title?.trim().isEmpty ?? true) ? null : title,
        image: image,
        lastVisit: lastVisit ?? DateTime.now(),
        path: path,
        host: host);
  }
  factory WebViewTab.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.webviewTab);
    return WebViewTab(
      id: values.rawValueAt(0),
      url: values.rawValueAt(1),
      title: values.rawValueAt(2),
      image: values.maybeObjectAt<APPImage, CborTagValue>(
          3, (e) => APPImage.deserialize(object: e)),
      lastVisit: values.rawValueAt(4),
    );
  }

  @override
  List get variables => [url, lastVisit];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.webviewTab;

  @override
  List<CborObject?> get serializationItems => [
        id.toCbor(),
        url.toCbor(),
        title?.toCbor(),
        image?.toCbor(),
        CborEpochIntValue(lastVisit),
        path?.toCbor()
      ];
}
