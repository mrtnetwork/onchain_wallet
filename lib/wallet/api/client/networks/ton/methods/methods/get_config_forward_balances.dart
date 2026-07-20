import 'package:ton_dart/ton_dart.dart';

class _TonRquestGetFeeConst {
  static const int masterChainConfigId = 24;
  static const int workChainConfigId = 25;
}

class TonRquestGetMsgForwardPricesConfig
    extends TonApiRequest<MsgForwardPricesResponse, dynamic> {
  final TonApiType api;
  final bool isMasterChan;
  TonRquestGetMsgForwardPricesConfig(this.api, {this.isMasterChan = true});
  TonApiRequest? _request;
  TonApiRequest _getRequest() {
    if (!api.isTonCenter) {
      return TonApiGetBlockchainConfig();
    }
    final int conifgId = isMasterChan
        ? _TonRquestGetFeeConst.masterChainConfigId
        : _TonRquestGetFeeConst.workChainConfigId;
    return TonCenterGetConfigParam(configId: conifgId);
  }

  @override
  TonRequestDetails buildRequest(int v) {
    _request = _getRequest();
    return _request!.buildRequest(v);
  }

  @override
  String get method => throw UnimplementedError();

  /// BlockchainConfig24
  @override
  MsgForwardPricesResponse onResonse(json) {
    if (api.isTonCenter) {
      final result = (_request as TonCenterGetConfigParam).onResonse(json);
      final slice = TonHelper.toCell(result.bytes).beginParse();
      final config = BlockchainConfig24.derserialize(slice);
      return config.msgForwardPrices;
    }

    final result = (_request as TonApiGetBlockchainConfig).onResonse(json);
    if (isMasterChan) return result.r24!.msgForwardPrices;
    return result.r25!.msgForwardPrices;
  }
}

class TonRquestGetMsgForwardGasLimitPrice
    extends TonApiRequest<GasLimitPricesResponse, dynamic> {
  final TonApiType api;
  final bool isMasterChan;
  TonRquestGetMsgForwardGasLimitPrice(this.api, {this.isMasterChan = true});
  TonApiRequest? _request;
  TonApiRequest _getRequest() {
    if (!api.isTonCenter) {
      return TonApiGetBlockchainConfig();
    }
    final int conifgId = isMasterChan ? 20 : 21;
    return TonCenterGetConfigParam(configId: conifgId);
  }

  @override
  TonRequestDetails buildRequest(int v) {
    _request = _getRequest();
    return _request!.buildRequest(v);
  }

  @override
  String get method => throw UnimplementedError();

  /// BlockchainConfig24
  @override
  GasLimitPricesResponse onResonse(json) {
    if (api.isTonCenter) {
      final result = (_request as TonCenterGetConfigParam).onResonse(json);
      final slice = TonHelper.toCell(result.bytes).beginParse();
      final config = BlockchainConfig21.deserialize(slice);
      return config.gasLimitsPrices;
    }

    final result = (_request as TonApiGetBlockchainConfig).onResonse(json);
    if (isMasterChan) return result.r20!.gasLimitsPrices;
    return result.r21!.gasLimitsPrices;
  }
}

class TonRquestGetMsgForwardStoragePrices
    extends TonApiRequest<List<BlockchainConfig18StoragePricesItem>, dynamic> {
  final TonApiType api;
  final bool isMasterChan;
  TonRquestGetMsgForwardStoragePrices(this.api, {this.isMasterChan = true});
  TonApiRequest? _request;
  TonApiRequest _getRequest() {
    if (!api.isTonCenter) {
      return TonApiGetBlockchainConfig();
    }
    return TonCenterGetConfigParam(configId: 18);
  }

  @override
  TonRequestDetails buildRequest(int v) {
    _request = _getRequest();
    return _request!.buildRequest(v);
  }

  @override
  String get method => throw UnimplementedError();

  /// BlockchainConfig24
  @override
  List<BlockchainConfig18StoragePricesItem> onResonse(json) {
    if (api.isTonCenter) {
      final result = (_request as TonCenterGetConfigParam).onResonse(json);
      final slice = TonHelper.toCell(result.bytes).beginParse();
      final config = BlockchainConfig18.deserialize(slice);
      return config.storagePrices;
    }

    final result = (_request as TonApiGetBlockchainConfig).onResonse(json);
    return result.r18!.storagePrices;
  }
}
