import 'package:on_chain_bridge/net_sdk/core/core.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_wallet/app/error/exception.dart';
import 'package:on_chain_wallet/app/utils/method/utiils.dart';
import 'package:on_chain_wallet/network/constants/constants.dart';
import 'package:on_chain_wallet/network/net_api/api/api.dart';
import 'package:on_chain_wallet/network/net_api/impl/transport.dart';
import 'package:on_chain_wallet/network/net_api/models/auth.dart';
import 'package:on_chain_wallet/network/net_api/models/models.dart';
import 'package:on_chain_wallet/app/utils/method/result.dart';

class DisabledNetApi implements INetApi {
  @override
  IResult<IHttpTransportClient> http() {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<T>> httpGet<T>(String uri,
      {Map<String, String>? headers,
      Duration timeout = NetworkConst.defaultHttpRequestTimeout,
      StreamEncoding? responseType,
      HTTPClientType clientMode = HTTPClientType.single,
      NetMode mode = NetMode.clearnet,
      ProviderAuthenticated? authenticated,
      bool logError = true}) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<void>> initTor({Duration? timeout}) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<List<int>>> makeStream(
      {required String uri,
      Duration timeout = NetworkConst.defaultHttpRequestTimeout,
      Duration streamTimeout = NetworkConst.defaultHttpStreamTimeout,
      CancelableListener? cancelable,
      Map<String, String> headers = const {},
      CbOnHttpStreamProgress? onProgress}) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  IResult<INetSdkApi> netSdk() {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  bool get supportTorConnection => false;
}
