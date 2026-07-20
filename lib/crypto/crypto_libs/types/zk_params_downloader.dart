import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/app/resources/resources/types.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:zcash_dart/zcash.dart';

class ZcashParamDownloader with ZcashDownloadService {
  final ZcashParamsLocation params;
  final AppContext context;
  const ZcashParamDownloader({required this.params, required this.context});
  @override
  Future<List<int>> doRequest(Uri uri, ZcashSaplingParameter type) async {
    final params = await context.utils.getStoredData(switch (type) {
      ZcashSaplingParameter.spend => this.params.spend,
      ZcashSaplingParameter.output => this.params.output,
    });
    final result = (await params.unwrap()?.readBytes())?.toResult().unwrap();
    if (result == null) throw WalletExceptionConst.zcashMissingSaplingParameters;
    return result;
  }
}
