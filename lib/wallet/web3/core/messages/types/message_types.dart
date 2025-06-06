import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_wallet/wallet/web3/constant/constant/exception.dart';

enum Web3MessageTypes {
  chains([100, 11]),
  walletRequest([100, 12]),
  // response([100, 13]),
  walletResponse([100, 14]),
  error([100, 15]),
  walletGlobalRequest([100, 17]),
  globalResponse([100, 18]);

  final List<int> tag;
  const Web3MessageTypes(this.tag);
  static Web3MessageTypes fromTag(List<int>? tags) {
    return values.firstWhere((e) => BytesUtils.bytesEqual(e.tag, tags),
        orElse: () => throw Web3RequestExceptionConst.internalError);
  }
}
