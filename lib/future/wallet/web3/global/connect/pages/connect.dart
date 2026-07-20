import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/web3/global/connect/controller/connect.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/permission_view.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/global_controller.dart';
import 'package:on_chain_wallet/web3/web3/networks/global/params/core/core.dart';

class GlobalWeb3ConnectView extends StatelessWidget {
  const GlobalWeb3ConnectView({required this.wallet, super.key, required this.request});
  final Web3GlobalRequest request;
  final WalletProvider wallet;

  @override
  Widget build(BuildContext context) {
    return Web3GlobalPageRequestControllerView(
        controller: () =>
            Web3GlobalRequestConnectStateController(request: request, wallet: wallet),
        builder: (context, controller) {
          return Web3ApplicationPermissionView(
              authenticated: controller.authenticated,
              onPermissionUpdate: controller.onUpdateApplication);
        },
        request: request);
  }
}
