import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_wallet/app/core.dart';

abstract class IPlatformUtils {
  // Future<IResult<String>> writeString(String data, String fileName,
  //     {bool validate = true});

  // Future<IResult<String>> writeBytes(
  //     {required List<int> bytes, required String fileName, bool validate = true});

  Future<IResult<List<int>>> loadAssets(APPAssetUri asset);

  Future<IResult<String>> loadAssetText(APPAssetUri assetPath);

  Future<IResult<T>> loadAssetsJson<T>(APPAssetUri assetPath);

  Future<IResult<bool>> writeClipboard(String text);

  Future<IResult<String?>> readClipboard();

  Future<IResult<PickedFileContent?>> pickFile(
      {PickFileContentEncoding encoding = PickFileContentEncoding.utf8});
  Future<IResult<ICrossFile?>> pickPlatformFile({AppFileType? type});
  Future<IResult<void>> saveFile({
    required IBuffer buffer,
    required String name,
    required AppFileType type,
    String? title,
  });

  Future<IResult<bool>> shareFile({
    required IBuffer buffer,
    required String name,
    required AppFileType type,
    String? text,
    String? subject,
  });

  Future<IResult<bool>> lunchUri(String? uri);

  Future<IResult<int>> readSupportFileLength(String fileName);

  Future<IResult<void>> writeSupportFileBytes(String fileName, List<int> bytes);

  IResult<Stream<bool>> connectivity();

  Future<IResult<void>> stopBarcodeScanner();

  Future<IResult<Stream<BarcodeScannerResult>>> startBarcodeScanner(
      BarcodeScannerParams param);

  Future<IResult<bool>> secureFlag(bool isSecure);
}

class DisabledPlatformUtils implements IPlatformUtils {
  @override
  IResult<Stream<bool>> connectivity() {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<String>> loadAssetText(APPAssetUri assetPath) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<List<int>>> loadAssets(APPAssetUri asset) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<T>> loadAssetsJson<T>(APPAssetUri assetPath) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<bool>> lunchUri(String? uri) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<PickedFileContent?>> pickFile(
      {PickFileContentEncoding encoding = PickFileContentEncoding.utf8}) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<String?>> readClipboard() async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<int>> readSupportFileLength(String fileName) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<Stream<BarcodeScannerResult>>> startBarcodeScanner(
      BarcodeScannerParams param) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<void>> stopBarcodeScanner() async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<bool>> writeClipboard(String text) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<void>> writeSupportFileBytes(String fileName, List<int> bytes) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<bool>> secureFlag(bool isSecure) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<ICrossFile?>> pickPlatformFile({AppFileType? type}) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<bool>> shareFile({
    required IBuffer buffer,
    required String name,
    required AppFileType type,
    String? text,
    String? subject,
  }) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<void>> saveFile({
    required IBuffer buffer,
    required String name,
    required AppFileType type,
    String? title,
  }) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }
}
