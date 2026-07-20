import 'dart:async';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/models/files/picked_file_data.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/app/resources/resources/types.dart';
import 'package:on_chain_wallet/context/api/api_connection.dart';
import 'package:on_chain_wallet/context/types/messages.dart';
import 'package:on_chain_wallet/network/constants/constants.dart';
import 'package:on_chain_wallet/network/net_api/api/api.dart';
import 'package:on_chain_wallet/network/net_api/models/models.dart';
import 'package:on_chain_wallet/network/net_api/models/stream.dart';

abstract class IAppContextUtils {
  Future<IResult<ICrossFile?>> getStoredData(RuntimeResourceLocation location);
  Future<IResult<bool>> verifyStoreData(RuntimeResourceLocation location);
  Future<IResult<void>> storeOrRemoveData(
      {required RuntimeResourceLocation location, List<int>? data});
  Future<IResult<void>> fetchAndStoreNetworkData(
      {required List<String> urls,
      required RuntimeResourceLocation location,
      String? streamingId,
      CancelableListener? cancelable,
      Duration timeout = NetworkConst.defaultHttpRequestTimeout,
      Duration streamTimeout = NetworkConst.defaultHttpStreamTimeout,
      Map<String, String> headers = const {},
      CbOnHttpStreamProgress? onProgress});
  Future<IResult<void>> storeFile(
      {required RuntimeResourceLocation location, required ICrossFile file});
  Future<IResult<void>> stopStreaming(String identifier);
}

abstract class BaseAppContextUtils implements IAppContextUtils {
  final INetApi netApi;
  BaseAppContextUtils({required this.netApi});
  final Map<String, CancelableListener> _streaming = {};

  IResult<List<int>> verifyChecksum(
      {required RuntimeResourceLocation location, required List<int> data}) {
    final checksum = location.checksum;
    if (checksum == null) return ResultOk(data);
    final c = Crc32().quickIntDigest(data);
    if (c == checksum) return ResultOk(data);
    return ResultErr.fromException(AppExceptionConst.dataChecksumMismatch);
  }

  @override
  Future<IResult<bool>> verifyStoreData(RuntimeResourceLocation location) async {
    final data = await getStoredData(location);
    return data.and((result, _) => ResultOk(result != null));
  }

  @override
  Future<IResult<void>> fetchAndStoreNetworkData(
      {required List<String> urls,
      required RuntimeResourceLocation location,
      String? streamingId,
      CancelableListener? cancelable,
      Duration timeout = NetworkConst.defaultHttpRequestTimeout,
      Duration streamTimeout = NetworkConst.defaultHttpStreamTimeout,
      Map<String, String> headers = const {},
      CbOnHttpStreamProgress? onProgress}) async {
    final data = (await getStoredData(location)).and<ICrossFile?>((result, err) {
      if (err != null) {
        if (err == AppExceptionConst.dataChecksumMismatch) {
          return ResultOk(null);
        }
        return ResultErr.fromException(err);
      }
      return ResultOk(result);
    });
    return data.andThenAsync((data) async {
      if (data != null) return ResultOk.okVoid;
      if (streamingId != null) {
        _streaming[streamingId] = cancelable ?? CancelableListener();
      }
      final result = await IResult.anyError(urls.map((e) async => await netApi.makeStream(
          uri: e,
          headers: headers,
          streamTimeout: streamTimeout,
          timeout: timeout,
          cancelable: cancelable,
          onProgress: onProgress)));
      if (streamingId != null) _streaming.remove(streamingId);
      return result.andThenAsync((e) async {
        // return ResultErr.fromException(AppExceptionConst.invalidFileFormat);
        return await storeOrRemoveData(
            location: location, data: e.expand((e) => e).toList());
      });
    });
  }

  @override
  Future<IResult<void>> storeFile(
      {required RuntimeResourceLocation location, required ICrossFile file}) async {
    final bytes = await file.readBytes();
    return bytes.toResult().andThenAsync(
        (bytes) async => await storeOrRemoveData(location: location, data: bytes));
  }

  @override
  Future<IResult<void>> stopStreaming(String identifier) async {
    _streaming.remove(identifier)?.cancel();
    return ResultOk.okVoid;
  }
}

class MainAppContextUtils extends IAppContextRequestController<
    AppContextMessageUtilsRequest,
    AppContextMessageResponse> implements IAppContextUtils {
  final Map<String, SafeStreamController<StreamProgress>> _pendingStreams = {};
  MainAppContextUtils({required super.connection});

  @override
  void onUnknownResponse(AppContextMessageResponse response) {
    super.onUnknownResponse(response);
    if (response
        case AppContextMessageUtilsResponseStreamProgress(
          :final progress,
          :final identifier
        )) {
      final controller = _pendingStreams[identifier];
      controller?.add(progress);
      return;
    }
  }

  @override
  Future<IResult<void>> fetchAndStoreNetworkData(
      {required List<String> urls,
      required RuntimeResourceLocation location,
      String? streamingId,
      CancelableListener? cancelable,
      Duration timeout = NetworkConst.defaultHttpRequestTimeout,
      Duration streamTimeout = NetworkConst.defaultHttpStreamTimeout,
      Map<String, String> headers = const {},
      CbOnHttpStreamProgress? onProgress}) async {
    String? streamId;
    Future<IResult<void>> onCancel() async {
      if (streamingId == null) return ResultOk.okVoid;
      return stopStreaming(streamingId);
    }

    if (onProgress != null) {
      streamId = UUID.generateUUIDv4();
      final controller =
          SafeStreamController<StreamProgress>(name: "fetchAndStoreNetworkData");
      _pendingStreams[streamId] = controller;
      controller.stream().listen(onProgress);
      cancelable?.addListener(onCancel);
    }

    final result = await sendRequest<AppContextMessageResponseSuccess>(
        AppContextMessageUtilsRequestFetchAndStoreBinary(
            urls: urls,
            location: location,
            timeout: timeout,
            streamTimeout: streamTimeout,
            streamTrackerId: streamId,
            headers: headers),
        timeout: streamTimeout);
    final controller = _pendingStreams.remove(streamId);
    controller?.close();
    cancelable?.removeListener(onCancel);
    return result.map((e) {});
  }

  @override
  Future<IResult<ICrossFile?>> getStoredData(RuntimeResourceLocation location) async {
    final result = await sendRequest<AppContextMessageUtilsResponseGetData>(
        AppContextMessageUtilsRequestGetData(location: location));
    return result.map((e) => e.data);
  }

  @override
  Future<IResult<void>> storeOrRemoveData(
      {required RuntimeResourceLocation location, List<int>? data}) async {
    final result = await sendRequest<AppContextMessageResponseSuccess>(
        AppContextMessageUtilsRequestStoreOrRemoveData(location: location, data: data));
    return result.map((e) {});
  }

  @override
  Future<IResult<bool>> verifyStoreData(RuntimeResourceLocation location) async {
    final result = await sendRequest<AppContextMessageUtilsResponseVerifyData>(
        AppContextMessageUtilsRequestVerifyData(location: location));
    return result.map((e) => e.verify);
  }

  @override
  Future<IResult<void>> storeFile(
      {required RuntimeResourceLocation location, required ICrossFile file}) async {
    final result = await sendRequest<AppContextMessageResponseSuccess>(
        AppContextMessageUtilsRequestStoreFile(location: location, file: file));
    return result.map((e) {});
  }

  @override
  Future<IResult<void>> stopStreaming(String identifier) async {
    final result = await sendRequest<AppContextMessageResponseSuccess>(
        AppContextMessageUtilsRequestStopStreaming(identifier: identifier));
    return result.map((e) {});
  }
}

class DisabledAppContextUtils implements IAppContextUtils {
  @override
  Future<IResult<void>> fetchAndStoreNetworkData(
      {required List<String> urls,
      required RuntimeResourceLocation location,
      String? streamingId,
      CancelableListener? cancelable,
      Duration timeout = NetworkConst.defaultHttpRequestTimeout,
      Duration streamTimeout = NetworkConst.defaultHttpStreamTimeout,
      Map<String, String> headers = const {},
      CbOnHttpStreamProgress? onProgress}) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<ICrossFile?>> getStoredData(RuntimeResourceLocation location) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<void>> storeOrRemoveData(
      {required RuntimeResourceLocation location, List<int>? data}) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<bool>> verifyStoreData(RuntimeResourceLocation location) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<void>> storeFile(
      {required RuntimeResourceLocation location, required ICrossFile file}) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<void>> stopStreaming(String identifier) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }
}
