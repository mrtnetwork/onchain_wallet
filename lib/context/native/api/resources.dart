import 'package:on_chain_wallet/app/resources/resources/constants.dart';
import 'package:on_chain_wallet/app/resources/resources/types.dart';
import 'package:on_chain_wallet/app/utils/method/result.dart';
import 'package:on_chain_wallet/context/api/resources.dart';

class AppResourceNative extends AppResourcesApi {
  @override
  IResult<String> netSdkLibName() => ResultOk(AppResourceConst.native.netSdkLibName);
  @override
  IResult<String> sqliteLibName() => ResultOk(AppResourceConst.native.sqliteLibName);
  @override
  IResult<RuntimeFileLocation> loggingFileLocation() =>
      ResultOk(AppResourceConst.native.loggingFileLocation);

  @override
  IResult<TorParamsLocation> torParamsLocation() =>
      ResultOk(AppResourceConst.native.torParams);
  @override
  IResult<String> zcashLibName() => ResultOk(AppResourceConst.native.zcashLibName);
  @override
  IResult<String> moneroLibName() => ResultOk(AppResourceConst.native.moneroLibName);
}
