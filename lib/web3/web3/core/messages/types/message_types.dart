import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';

enum Web3MessageTypes {
  chains(AppSerializationIdentifier.web3MsgChains),
  walletRequest(AppSerializationIdentifier.web3MsgWalletRequest),
  walletResponse(AppSerializationIdentifier.web3MsgWalletResponse),
  error(AppSerializationIdentifier.web3MsgError),
  walletGlobalRequest(AppSerializationIdentifier.web3MsgWalletGlobalRequest),
  globalResponse(AppSerializationIdentifier.web3MsgGlobalResponse);

  final AppSerializationIdentifier tag;
  const Web3MessageTypes(this.tag);
  static Web3MessageTypes fromIdentifier(List<int>? tags) {
    final method =
        values.firstWhereOrNull((e) => e.tag.isValid(tags?.elementAtOrNull(0)));
    return switch (method) {
      Web3MessageTypes.walletRequest when tags?.length == 2 => method!,
      Web3MessageTypes _ when tags?.length == 1 => method,
      _ => throw Web3RequestExceptionConst.internalErr("Web3MessageTypes")
    };
  }
}
