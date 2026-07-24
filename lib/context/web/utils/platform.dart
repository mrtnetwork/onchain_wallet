import 'dart:js_interop';

import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_bridge/web/interface/interface.dart';
import 'package:on_chain_bridge/web/types/file.dart';
import 'package:on_chain_bridge/web/utils/utils.dart';
import 'package:on_chain_bridge/web/web.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/api/platform_utils.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/exception/exception.dart';
import 'package:on_chain_wallet/context/web/api/resources.dart';

class DefaultPlatformUtilsWeb implements IPlatformUtils {
  DefaultPlatformUtilsWeb(
      {required IWebOnChainBridgeInterface platform,
      required WebAssetPathResolver pathResolver})
      : _utils = _NativeMethods(platform: platform, pathResolver: pathResolver);
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

class _NativeMethods {
  final WebAssetPathResolver pathResolver;
  final IWebOnChainBridgeInterface platform;
  const _NativeMethods({required this.pathResolver, required this.platform});

  Future<IResult<List<int>>> _loadAssetBuffer(String path, {String? package}) async {
    final assetPath = _assetPath(path, package: package);
    return assetPath.andThenAsync((assetPath) async {
      final data = await JSFetchApi.fetchBuffer(assetPath);
      return data
          .transformError(
            (error) => AppExceptionConst.fileDoesNotExists,
          )
          .map((e) => e.asUint8List());
    });
  }

  Future<IResult<String>> _loadAssetText(String path, {String? package}) async {
    final assetPath = _assetPath(path, package: package);
    return assetPath.andThenAsync((assetPath) async {
      final data = await JSFetchApi.fetchText(assetPath);
      return data
          .transformError(
            (error) => AppExceptionConst.fileDoesNotExists,
          )
          .map((e) => e);
    });
  }

  IResult<String> _assetPath(String assetPath, {String? package}) {
    String path = () {
      if (package != null) {
        return "assets/packages/$package/$assetPath";
      }
      assert(assetPath.startsWith("assets/"));
      return "assets/$assetPath";
    }();
    if (platform.isExtensionContext) {
      final extension = platform.chromeApi();
      if (extension.isErr) return extension.toResult().cast();
      path = extension.unwrap().runtime.getURL(path);
    }
    return ResultOk(path);
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
    final fName = type.toFileName(name);
    final jsBuffer = JsUtils.toAppJsUint8Array(buffer.toBytes());
    final jsFile =
        JSFile([jsBuffer.buffer].toJS, fName, JSFileOption(type: type.mimeType));
    final result = await platform.share(
        IShareFile(file: WebFile(jsFile), type: type, message: text, subject: subject));
    return result.toResult();
  }

  Future<IResult<void>> saveFile({
    required IBuffer buffer,
    required String name,
    required AppFileType type,
    String? title,
  }) async {
    final fName = type.toFileName(name);
    final jsBuffer = JsUtils.toAppJsUint8Array(buffer.toBytes());
    final jsFile =
        JSFile([jsBuffer.buffer].toJS, fName, JSFileOption(type: type.mimeType));
    final result =
        await platform.saveFile(file: WebFile(jsFile), title: title, type: type);
    return result.toResult();
  }

  Future<IResult<bool>> lunchUri(String uri) async {
    return (await platform.launchUri(uri)).toResult();
  }

  Future<IResult<int>> readSupportFileLength(String fileName) async {
    return ResultErr.fromException(OnChainBridgeException.unsuported);
  }

  Future<IResult<void>> writeSupportFileBytes(String fileName, List<int> bytes) async {
    return ResultErr.fromException(OnChainBridgeException.unsuported);
  }
}
