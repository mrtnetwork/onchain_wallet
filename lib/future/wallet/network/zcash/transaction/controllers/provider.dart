import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:zcash_dart/zcash.dart';

typedef CbRequestSaplingParameters = Future<
        IResult<({LivePercentProgressBar? progress, SaplingPickParamOptions option})>>
    Function(ZcashSaplingParameter type, double lengthInMb, List<String> links);

mixin ZcashTransactionApiController on DisposableMixin {
  ZcashNetworkClient get client;
  WalletProvider get walletProvider;
  final CancelableListener _cancelable = CancelableListener();
  Future<IResult<void>> _getOrDownloadSaplingParam(
      {required CbRequestSaplingParameters onDownloadRequired,
      required ZcashSaplingParameter type,
      required AppContext context}) async {
    return walletProvider.context.resourceApi
        .zcashParamLocation()
        .andThenAsync((paramsLocation) async {
      final resource = switch (type) {
        ZcashSaplingParameter.spend => paramsLocation.spend,
        ZcashSaplingParameter.output => paramsLocation.output,
      };

      final int expectedLength = switch (type) {
        ZcashSaplingParameter.spend => ZKLibConst.saplingSpendBytesLength,
        ZcashSaplingParameter.output => ZKLibConst.saplingOutputBytesLength,
      };

      final fileExists = await context.utils.verifyStoreData(resource);
      return fileExists.andThenAsync((e) async {
        if (e) return ResultOk.okVoid;
        final links = ZKLibConst.getZcashDownloadParamLinks(type);
        final ok = await onDownloadRequired(
            type, QuickBytesUtils.bytesToMb(expectedLength), links);
        return ok.andThenAsync((options) async {
          switch (options.option) {
            case SaplingPickParamsDownload():
              options.progress?.init(ZKLibConst.saplingSpendBytesLength);

              return await context.utils.fetchAndStoreNetworkData(
                urls: links,
                location: resource,
                cancelable: _cancelable,
                onProgress: (progress) {
                  if (progress.isValid) {
                    options.progress?.add(progress.loaded);
                  }
                },
              );
            case SaplingPickParamsFile(:final file):
              final result =
                  await context.utils.storeFile(location: resource, file: file);
              return result.mapErr((e) {
                if (e.exception == AppExceptionConst.dataChecksumMismatch) {
                  return WalletExceptionConst.saplingParamVerificationFailed;
                }
                return e.exception;
              });
          }
        });
      });
    });
  }

  Future<IResult<void>> getOrDownloadSaplingParams(
      {required bool hasOutput,
      required bool hasSpend,
      required CbRequestSaplingParameters onDownloadRequired,
      required AppContext context}) async {
    if (hasSpend) {
      final result = await _getOrDownloadSaplingParam(
          onDownloadRequired: onDownloadRequired,
          type: ZcashSaplingParameter.spend,
          context: context);
      if (result.isErr) return result;
    }
    if (hasOutput) {
      final result = await _getOrDownloadSaplingParam(
          onDownloadRequired: onDownloadRequired,
          type: ZcashSaplingParameter.output,
          context: context);
      if (result.isErr) return result;
    }
    return ResultOk.okVoid;
  }

  @override
  void dispose() {
    super.dispose();
    _cancelable.cancel();
  }
}
