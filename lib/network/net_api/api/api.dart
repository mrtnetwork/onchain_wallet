import 'package:on_chain_bridge/net_sdk/net_sdk.dart';
import 'package:on_chain_wallet/app/utils/method/utiils.dart';
import 'package:on_chain_wallet/network/constants/constants.dart';
import 'package:on_chain_wallet/network/net_api/impl/transport.dart';
import 'package:on_chain_wallet/network/net_api/models/auth.dart';
import 'package:on_chain_wallet/network/net_api/models/models.dart';
import 'package:on_chain_wallet/app/utils/method/result.dart';

abstract class INetApi {
  IResult<INetSdkApi> netSdk();
  IResult<IHttpTransportClient> http();
  Future<IResult<List<int>>> makeStream(
      {required String uri,
      CancelableListener? cancelable,
      Duration timeout = NetworkConst.defaultHttpRequestTimeout,
      Duration streamTimeout = NetworkConst.defaultHttpStreamTimeout,
      Map<String, String> headers = const {},
      CbOnHttpStreamProgress? onProgress});

  Future<IResult<T>> httpGet<T>(
    String uri, {
    Map<String, String>? headers,
    Duration timeout = NetworkConst.defaultHttpRequestTimeout,
    StreamEncoding? responseType,
    HTTPClientType clientMode = HTTPClientType.single,
    NetMode mode = NetMode.clearnet,
    ProviderAuthenticated? authenticated,
    bool logError = true,
  });
  Future<IResult<void>> initTor({Duration? timeout});
  bool get supportTorConnection;
}
