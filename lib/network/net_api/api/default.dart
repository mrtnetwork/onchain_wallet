import 'package:on_chain_bridge/net_sdk/core/core.dart';
import 'package:on_chain_bridge/net_sdk/exception/exception.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_wallet/app/error/exception/exception.dart';
import 'package:on_chain_wallet/app/utils/method/utiils.dart';
import 'package:on_chain_wallet/network/constants/constants.dart';
import 'package:on_chain_wallet/network/net_api/api/api.dart';
import 'package:on_chain_wallet/network/net_api/impl/transport.dart';
import 'package:on_chain_wallet/network/net_api/models/auth.dart';
import 'package:on_chain_wallet/network/net_api/models/models.dart';
import 'package:on_chain_wallet/app/utils/method/result.dart';

class DefaultNetApi implements INetApi {
  final INetSdkApi netSdkApi;
  final IHttpTransportClient httpTransport;
  DefaultNetApi(this.netSdkApi) : httpTransport = DefaultHttpTransportClient(netSdkApi);

  static IResult<T> decodeBody<T extends Object?>(
      {required NetResponseHttp body,
      required String url,
      required StreamEncoding encoding}) {
    if (!body.isSuccess) {
      return StreamEncoding.string
          .decodeBinary<String>(body.body)
          .toResult()
          .mapErr((e) => APIError.fromException(
              message: null, statusCode: body.statusCode, url: url))
          .andThen((data) => ResultErr.fromException(APIError.fromException(
              message: data, statusCode: body.statusCode, url: url)));
    }
    return encoding.decodeBinary<T>(body.body).toResult();
  }

  static StreamEncoding _detectTemplateType<T>({StreamEncoding? responseType}) {
    if (responseType != null) return responseType;
    if (dynamic is T) return StreamEncoding.json;
    if (<String, dynamic>{} is T) return StreamEncoding.map;
    if (<Map<String, dynamic>>[] is T) return StreamEncoding.listOfMap;
    if (<int>[] is T) return StreamEncoding.raw;
    switch (T) {
      case const (String):
        return StreamEncoding.string;
      default:
        return StreamEncoding.json;
    }
  }

  @override
  IResult<IHttpTransportClient> http() {
    return ResultOk(httpTransport);
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
    final rType = _detectTemplateType<T>(responseType: responseType);
    final result = await httpTransport.get(
      uri: Uri.parse(uri),
      timeout: timeout,
      clientMode: clientMode,
      headers: headers,
      mode: mode,
      authenticated: authenticated,
    );
    return result.andThen((e) {
      return decodeBody<T>(body: e, url: uri, encoding: rType);
    });
  }

  @override
  Future<IResult<void>> initTor(
      {Duration? timeout = NetworkConst.torInitializationTimeout}) {
    final sdk = netSdk();
    return sdk.andThenAsync((sdk) async {
      final init = await sdk.initTor(timeout: timeout);
      return init.transformError((error) => NetSdkException(error));
    });
  }

  @override
  Future<IResult<List<int>>> makeStream(
      {required String uri,
      CancelableListener? cancelable,
      Duration timeout = NetworkConst.defaultHttpRequestTimeout,
      Duration streamTimeout = NetworkConst.defaultHttpStreamTimeout,
      Map<String, String> headers = const {},
      CbOnHttpStreamProgress? onProgress}) async {
    final result = await httpTransport.getStream(
        uri: Uri.parse(uri),
        onProgress: onProgress,
        cancelable: cancelable,
        headers: headers,
        timeout: timeout,
        streamingTimeout: streamTimeout);
    return result.andThen((e) {
      return decodeBody<List<int>>(body: e, url: uri, encoding: StreamEncoding.raw);
    });
  }

  @override
  IResult<INetSdkApi> netSdk() {
    return ResultOk(netSdkApi);
  }

  @override
  bool get supportTorConnection => netSdkApi.modes.contains(NetMode.tor);
}
