import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/web3/global/core/controller.dart';
import 'package:on_chain_wallet/future/wallet/web3/types/types.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';

class Web3GlobalRequestConnectStateController
    extends Web3GlobalRequestStateContoller<Web3GlobalRequest> {
  final WalletProvider wallet;
  late Web3UpdatePermissionRequest _authenticated;
  Web3UpdatePermissionRequest get authenticated => _authenticated;
  @override
  final Web3GlobalRequest request;
  Web3GlobalRequestConnectStateController({required this.request, required this.wallet});

  Future<bool> onUpdateApplication(Web3PermissionUpdateResponse update) async {
    controller.response(text: "client_permission_have_been_updated".tr);
    request.completeResponse(update.chains);
    return true;
  }

  @override
  Future<void> initWeb3() async {
    final param = request.params.cast<Web3ConnectApplication>();
    final lockNetwork = param.chain;
    if (lockNetwork != null) {
      _authenticated = Web3UpdatePermissionRequest.network(
          authentication: request.authenticated, client: request.info.client);
    } else if (param.networks != null) {
      final networkIds = param.networks!;
      _authenticated = Web3UpdatePermissionRequest.chain(
          authentication: request.authenticated,
          client: request.info.client,
          lockedChains: wallet.wallet
              .getChains()
              .where((e) => networkIds.contains(e.network.value))
              .toList());
    } else {
      _authenticated = Web3UpdatePermissionRequest(
          authentication: request.authenticated, client: request.info.client);
    }

    controller.idle();
  }
}
