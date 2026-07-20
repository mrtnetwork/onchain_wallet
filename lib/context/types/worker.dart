import 'package:blockchain_utils/helper/helper.dart';
import 'package:on_chain_wallet/app/error/exception/app_exception.dart';

enum IsolateMessageTypes {
  netSdkTransport(0),
  netSdkStream(1),
  netSdkRequest(2),
  databaseIStorageAction(5),
  databaseITableAction(6),
  databaseResponse(7),
  createConnection(8),
  stablishConnection(9),
  logging(13),
  shutdown(15),
  crypto(16),
  lockingTask(18),
  releaseTask(20),
  utilsFetchAndStoreBinary(22),
  utilsStreamProgress(24),
  utilsGetData(25),
  utilsStoreData(27),
  utilsVerifyData(29),
  createCryptoConnector(31),
  createMainContext(32),
  utilsStoreFile(34),
  stopStreaming(35),
  ;

  static IsolateMessageTypes fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw AppInternalError.internalError("IsolateMessageTypes"),
    );
  }

  static IsolateMessageTypes? tryFromValue(int? value) {
    return values.firstWhereNullable((e) => e.value == value);
  }

  final int value;
  const IsolateMessageTypes(this.value);
}
