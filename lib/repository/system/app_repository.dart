part of 'package:on_chain_wallet/repository/repository.dart';

mixin APPRepository on BaseRepository {
  Future<void> saveAppSetting(APPSetting setting) async {
    await write(
      key: StorageConst.appSetting,
      value: setting.toCbor().toCborHex(),
    );
  }
}
