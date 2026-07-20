import 'dart:js_interop';

import 'package:on_chain_bridge/models/files/picked_file_data.dart';
import 'package:on_chain_bridge/web/api/api.dart';
import 'package:on_chain_bridge/web/types/file.dart';
import 'package:on_chain_bridge/web/utils/utils.dart';
import 'package:on_chain_wallet/app/resources/resources/types.dart';
import 'package:on_chain_wallet/app/utils/method/result.dart';
import 'package:on_chain_wallet/context/api/utils.dart';
import 'package:on_chain_wallet/repository/repository.dart';

class WebAppContextUtils extends BaseAppContextUtils {
  final IAppDatabaseApi database;
  WebAppContextUtils({required super.netApi, required this.database});

  @override
  Future<IResult<ICrossFile?>> getStoredData(RuntimeResourceLocation location) async {
    return location.getTableLocation().andThenAsync((column) async {
      final data = await database.readColumn(column);
      return data.andThen((e) {
        final bytes = e?.data;
        if (bytes == null) return ResultOk(null);
        final data = verifyChecksum(location: location, data: bytes);
        return data.map((e) => WebFile(JSFile(
            [JsUtils.toAppJsUint8Array(e)].toJS,
            "file.${AppFileType.txt.extension}",
            JSFileOption(type: AppFileType.txt.mimeType))));
      });
    });
  }

  @override
  Future<IResult<void>> storeOrRemoveData(
      {required RuntimeResourceLocation location, List<int>? data}) async {
    return location.getTableLocation().andThenAsync((column) async {
      if (data == null) {
        return await database.removeColumn(column);
      }
      return verifyChecksum(location: location, data: data).andThenAsync((_) async {
        return await database.writeColumn(column: column, data: data);
      });
    });
  }
}
