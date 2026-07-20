import 'package:on_chain_bridge/models/files/picked_file_data.dart';
import 'package:on_chain_bridge/models/path/path.dart';
import 'package:on_chain_bridge/native/types/file.dart';
import 'package:on_chain_wallet/app/resources/resources/types.dart';
import 'package:on_chain_wallet/app/utils/method/result.dart';
import 'package:on_chain_wallet/context/api/utils.dart';
import 'package:on_chain_wallet/context/native/utils/platform.dart';

class NativeAppContextUtils extends BaseAppContextUtils {
  final AppPath path;
  NativeAppContextUtils({required super.netApi, required this.path});

  @override
  Future<IResult<ICrossFile?>> getStoredData(RuntimeResourceLocation location) async {
    return location.getFileLocation().andThenAsync((fileLocation) async {
      final path = fileLocation.getAbsolutePath(this.path);
      final data = await NativeFileUtils.readFileContent(path);
      return data.andThen((e) {
        if (e == null) return ResultOk(null);
        final result = verifyChecksum(location: location, data: e);
        return result.andThen((e) => NativeFile.fromPath(path).toResult());
      });
    });
  }

  @override
  Future<IResult<void>> storeOrRemoveData(
      {required RuntimeResourceLocation location, List<int>? data}) async {
    return location.getFileLocation().andThenAsync((fileLocation) async {
      final path = fileLocation.getAbsolutePath(this.path);
      if (data == null) {
        return NativeFileUtils.removeFile(path);
      }
      return verifyChecksum(location: location, data: data).andThenAsync((_) async {
        return await NativeFileUtils.bytesToFile(bytes: data, location: path);
      });
    });
  }
}
