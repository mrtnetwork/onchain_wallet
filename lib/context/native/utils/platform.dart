import 'package:on_chain_bridge/interface/interface.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_bridge/native/types/file.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/api/platform_utils.dart';
import 'dart:io';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/exception/exception.dart';
import 'package:flutter/services.dart' show PlatformException, rootBundle;

class DefaultPlatformUtilsNative implements IPlatformUtils {
  DefaultPlatformUtilsNative(IOnChainBridgeInterface platform)
      : _utils = _NativeMethods(platform);
  final _NativeMethods _utils;

  @override
  Future<IResult<List<int>>> loadAssets(APPAssetUri asset) async {
    return await _utils.loadAssets(asset.url, package: asset.package);
  }

  @override
  Future<IResult<String>> loadAssetText(APPAssetUri assetPath) async {
    return await _utils.loadAssetsText(assetPath.url, package: assetPath.package);
  }

  @override
  Future<IResult<T>> loadAssetsJson<T>(APPAssetUri assetPath) async {
    final data = await loadAssetText(assetPath);
    return data.mapCatchAsync((e) => StringUtils.toJson<T>(e));
  }

  @override
  Future<IResult<bool>> writeClipboard(String text) async {
    return await _utils.writeClipboard(text);
  }

  @override
  Future<IResult<String?>> readClipboard() {
    return _utils.readClipboard();
  }

  @override
  Future<IResult<PickedFileContent?>> pickFile(
      {PickFileContentEncoding encoding = PickFileContentEncoding.utf8}) async {
    final file = await _utils.pickFile(encoding: encoding);
    return file;
  }

  @override
  Future<IResult<bool>> shareFile({
    required IBuffer buffer,
    required String name,
    required AppFileType type,
    String? text,
    String? subject,
  }) async {
    return await _utils.shareFile(
        buffer: buffer, name: name, type: type, text: text, subject: subject);
  }

  @override
  Future<IResult<bool>> lunchUri(String? uri) async {
    if (uri == null) return ResultOk(false);
    return await _utils.lunchUri(uri);
  }

  @override
  Future<IResult<int>> readSupportFileLength(String fileName) async {
    return _utils.readSupportFileLength(fileName);
  }

  @override
  Future<IResult<void>> writeSupportFileBytes(String fileName, List<int> bytes) async {
    return _utils.writeSupportFileBytes(fileName, bytes);
  }

  @override
  IResult<Stream<bool>> connectivity() {
    return _utils.platform.onNetworkStatus.toResult();
  }

  @override
  Future<IResult<void>> stopBarcodeScanner() async {
    return (await _utils.platform.stopBarcodeScanner()).toResult();
  }

  @override
  Future<IResult<Stream<BarcodeScannerResult>>> startBarcodeScanner(
      BarcodeScannerParams param) async {
    return (await _utils.platform.startBarcodeScanner(param: param)).toResult();
  }

  @override
  Future<IResult<bool>> secureFlag(bool isSecure) async {
    return (await _utils.platform.secureFlag(isSecure: isSecure)).toResult();
  }

  @override
  Future<IResult<ICrossFile?>> pickPlatformFile({AppFileType? type}) async {
    return (await _utils.platform.pickFile(type: type)).toResult();
  }

  @override
  Future<IResult<void>> saveFile({
    required IBuffer buffer,
    required String name,
    required AppFileType type,
    String? title,
  }) {
    return _utils.saveFile(buffer: buffer, name: name, type: type, title: title);
  }
}

class NativeFileUtils {
  static Future<IResult<String>> bytesToFile(
      {required List<int> bytes, required String location}) async {
    try {
      final File file =
          await File(location).create(recursive: true).then((File file) async {
        await file.writeAsBytes(bytes);
        return file;
      });
      return ResultOk(file.path);
    } on PlatformException catch (e) {
      return ResultErr.fromException(IExceptionUtils.findError(e));
    }
  }

  static Future<IResult<List<int>?>> readFileContent(String location) async {
    try {
      final file = File(location);
      if (await file.exists()) {
        final content = await file.readAsBytes();
        return ResultOk(content);
      }
      return ResultOk(null);
    } on PlatformException catch (e) {
      return ResultErr.fromException(IExceptionUtils.findError(e));
    }
  }

  static Future<IResult<void>> removeFile(String location) async {
    try {
      final file = File(location);
      if (await file.exists()) {
        await file.delete();
      }
      return ResultOk.okVoid;
    } on PlatformException catch (e) {
      return ResultErr.fromException(IExceptionUtils.findError(e));
    }
  }
}

class _NativeMethods {
  final IOnChainBridgeInterface platform;
  _NativeMethods(this.platform);

  Future<IResult<NativeFile>> _stringToFile({
    required String data,
    required String path,
  }) async {
    final decode = StringUtils.encode(data);
    final File file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    final created = await file.create(recursive: true);
    await created.writeAsBytes(decode);
    return ResultOk(NativeFile.fromFile(created));
  }

  Future<IResult<NativeFile>> _bytesToFile(
      {required List<int> bytes, required String path}) async {
    final File barcodeFile =
        await File(path).create(recursive: true).then((File file) async {
      await file.writeAsBytes(bytes);
      return file;
    });
    return ResultOk(NativeFile.fromFile(barcodeFile));
  }

  Future<IResult<List<int>>> _loadAssetBuffer(String assetPath, {String? package}) async {
    try {
      final buffer = await rootBundle.load(_toAssetPath(assetPath, package: package));
      return ResultOk(buffer.buffer.asUint8List());
    } catch (_) {
      return ResultErr.fromException(AppExceptionConst.fileDoesNotExists);
    }
  }

  Future<IResult<String>> _loadAssetText(String assetPath, {String? package}) async {
    try {
      final data = await rootBundle.loadString(_toAssetPath(assetPath, package: package));
      return ResultOk(data);
    } catch (_) {
      return ResultErr.fromException(AppExceptionConst.fileDoesNotExists);
    }
  }

  String _toAssetPath(String assetPath, {String? package}) {
    if (package != null) {
      return 'packages/$package/$assetPath';
    }
    return assetPath;
  }

  Future<IResult<int>> _readSupportFileLength(String path) async {
    if (await File(path).exists()) {
      return ResultOk(await File(path).length());
    }
    return ResultErr.fromException(AppExceptionConst.fileDoesNotExists);
  }

  Future<IResult<void>> _writeSupportFileBytes(String path, List<int> bytes) async {
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    return ResultOk(null);
  }

  Future<IResult<NativeFile>> writeString(
    String data,
    String fileName,
  ) async {
    final path = await getPaths();
    return path.andThenAsync((path) {
      return _stringToFile(
          data: data,
          path:
              path.toFilePath(relativePath: fileName, directory: AppPathDirectory.cache));
    });
  }

  Future<IResult<NativeFile>> writeBytes(
      {required List<int> bytes, required String fileName}) async {
    final path = await getPaths();
    return path.andThenAsync((path) async {
      return await _bytesToFile(
        bytes: bytes,
        path: path.toFilePath(relativePath: fileName, directory: AppPathDirectory.cache),
      );
    });
  }

  Future<IResult<NativeFile>> writeBuffer(
      {required IBuffer buffer, required String fileName}) async {
    final path = await getPaths();
    return path.andThenAsync((path) async {
      final fPath =
          path.toFilePath(relativePath: fileName, directory: AppPathDirectory.cache);
      if (buffer case BufferString(:final data)) {
        return await _stringToFile(data: data, path: fPath);
      }
      return await _bytesToFile(bytes: buffer.toBytes(), path: fPath);
    });
  }

  Future<IResult<List<int>>> loadAssets(String assetPath, {String? package}) async {
    return await _loadAssetBuffer(assetPath, package: package);
  }

  Future<IResult<String>> loadAssetsText(String assetPath, {String? package}) async {
    return await _loadAssetText(assetPath, package: package);
  }

  Future<IResult<bool>> writeClipboard(String text) async {
    final data = await platform.writeClipboard(text);
    return data.toResult();
  }

  Future<IResult<String?>> readClipboard() async {
    final result = await platform.readClipboard();
    return result.toResult();
  }

  Future<IResult<PickedFileContent?>> pickFile(
      {PickFileContentEncoding encoding = PickFileContentEncoding.utf8}) async {
    final file = await platform.pickAndReadFileContent(encoding: encoding);
    return file.toResult().mapErr((e) {
      if (e.exception == OnChainBridgeException.invalidFileData) {
        return AppExceptionConst.invalidFileFormat;
      }
      return AppExceptionConst.failedToReadFileContent;
    });
  }

  Future<IResult<void>> saveFile({
    required IBuffer buffer,
    required String name,
    required AppFileType type,
    String? title,
  }) async {
    final fName = type.toFileName(name);
    final file = await writeBuffer(buffer: buffer, fileName: fName);
    return file.andThenAsync((file) async {
      final f = await platform.saveFile(file: file, type: type, title: title);
      return f.toResult();
    });
  }

  Future<IResult<AppPath>> getPaths() async {
    final result = await platform.path(APPConst.applicationId);
    return result.toResult();
  }

  Future<IResult<bool>> shareFile({
    required IBuffer buffer,
    required String name,
    required AppFileType type,
    String? text,
    String? subject,
  }) async {
    final appPlatform = platform.platform;
    return appPlatform.toResult().andThenAsync((appPlatform) async {
      final fName = type.toFileName(name);
      final file = await writeBuffer(buffer: buffer, fileName: fName);
      return file.andThenAsync((file) async {
        if (appPlatform.isWindows || appPlatform.isLinux) {
          final result = await platform.launchUri(file.path);
          return result.toResult();
        }
        final result = await platform
            .share(IShareFile(file: file, type: type, message: text, subject: subject));
        return result.toResult();
      });
    });
  }

  Future<IResult<bool>> lunchUri(String uri) async {
    return (await platform.launchUri(uri)).toResult();
  }

  Future<IResult<int>> readSupportFileLength(String fileName) async {
    final path = await getPaths();
    return path.andThenAsync((e) => _readSupportFileLength(
        e.toFilePath(relativePath: fileName, directory: AppPathDirectory.support)));
  }

  Future<IResult<void>> writeSupportFileBytes(String fileName, List<int> bytes) async {
    final path = await getPaths();
    return path.andThenAsync((e) => _writeSupportFileBytes(
        e.toFilePath(relativePath: fileName, directory: AppPathDirectory.support),
        bytes));
  }
}
