import 'package:ton_dart/ton_dart.dart';

class TonRquestGetBalance extends TonApiRequest<BigInt, dynamic> {
  final TonAddress address;
  final TonApiType api;
  TonRquestGetBalance({required this.address, required this.api});
  TonApiRequest? _request;
  TonApiRequest _getRequest() {
    if (!api.isTonCenter) return TonApiGetAccount(address.toString());
    return TonCenterGetAddressBalance(address.toString());
  }

  @override
  TonRequestDetails buildRequest(int v) {
    final request = _request = _getRequest();
    return request.buildRequest(v);
  }

  @override
  String get method => throw UnimplementedError();

  @override
  BigInt onResonse(result) {
    if (api.isTonCenter) {
      return (_request as TonCenterGetAddressBalance).onResonse(result);
    }
    return (_request as TonApiGetAccount).onResonse(result).balance;
  }
}
