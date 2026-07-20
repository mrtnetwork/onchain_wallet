import 'dart:async';
import 'dart:ui' as ui;
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class CacheMemoryImageProvider extends ImageProvider<CacheMemoryImageProvider> {
  final APPImageInfo image;
  final INetApi netApi;
  CacheMemoryImageProvider({required this.image, required this.netApi});

  @override
  ImageStreamCompleter loadImage(
      CacheMemoryImageProvider key, ImageDecoderCallback decode) {
    SafeStreamController<ImageChunkEvent>? chunkEvent;
    if (image.type == ContentType.favIcon || image.type == ContentType.network) {
      chunkEvent =
          SafeStreamController<ImageChunkEvent>(name: "CacheMemoryImageProvider");
      chunkEvent.add(ImageChunkEvent(cumulativeBytesLoaded: 0, expectedTotalBytes: 100));
    }
    final Future<ui.Codec> codec = _loadAsync(
        decode: decode,
        onStreamResponse: (progress) {
          if (progress.isValid) {
            chunkEvent?.add(ImageChunkEvent(
                cumulativeBytesLoaded: progress.loaded,
                expectedTotalBytes: progress.total));
          }
        },
        onDone: () {
          chunkEvent?.close();
          chunkEvent = null;
        });
    return MultiFrameImageStreamCompleter(
        codec: codec,
        scale: 1.0,
        debugLabel: image.toString(),
        informationCollector: () sync* {
          yield ErrorDescription('Tag: ${image.toString()}');
        },
        chunkEvents: chunkEvent?.stream());
  }

  Future<ui.Codec> _loadAsync(
      {required ImageDecoderCallback decode,
      required CbOnHttpStreamProgress onStreamResponse,
      required DynamicVoid onDone}) async {
    ui.ImmutableBuffer buffer;
    try {
      // final cacheKey = await image.loadCacheKey();
      String uri = await image.loadUrl();
      if (uri.isEmpty) {
        throw StateError('${image.type} cannot be loaded as an image.');
      }
      switch (image.type) {
        case ContentType.local:
          final bytes = await IResult.call(() async {
            return rootBundle.loadBuffer(uri);
          });
          buffer = await bytes.foldAsync(
            onOk: (value) async => value,
            onErr: (_) => throw StateError('${image.type} cannot be loaded as an image.'),
          );
          break;
        case ContentType.hex:
          final data = Uint8List.fromList(BytesUtils.fromHexString(uri));
          buffer = await ui.ImmutableBuffer.fromUint8List(data);
          break;
        case ContentType.favIcon:
        case ContentType.network:
          if (image.type == ContentType.favIcon) {
            uri = LinkConst.faviIconGenerator + uri;
          }
          final fetch = await netApi.makeStream(uri: uri, onProgress: onStreamResponse);
          buffer = await fetch.foldAsync(
            onOk: (value) async =>
                await ui.ImmutableBuffer.fromUint8List(Uint8List.fromList(value)),
            onErr: (_) => throw StateError('${image.type} cannot be loaded as an image.'),
          );

          break;
        default:
          throw StateError('${image.type} cannot be loaded as an image.');
      }

      return await decode(buffer);
    } finally {
      onDone();
    }
  }

  @override
  Future<CacheMemoryImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<CacheMemoryImageProvider>(this);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is CacheMemoryImageProvider && other.image == image;
  }

  @override
  int get hashCode => image.hashCode;

  @override
  String toString() =>
      '${objectRuntimeType(this, 'CacheImageProvider')}("${image.hashCode}")';
}
