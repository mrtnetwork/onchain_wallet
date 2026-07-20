import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/web3/global/connect/pages/connect.dart';
import 'package:on_chain_wallet/future/widgets/widgets/widget_constant.dart';
import 'package:on_chain_wallet/web3/web3/networks/global/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/global/params/core/core.dart';

class GlobalWeb3FieldsView extends StatelessWidget {
  const GlobalWeb3FieldsView({super.key});
  @override
  Widget build(BuildContext context) {
    final Web3GlobalRequest request = context.getArgruments();
    final wallet = context.wallet;
    switch (request.params.method) {
      case Web3GlobalRequestMethods.connect:
        return GlobalWeb3ConnectView(wallet: wallet, request: request);
      default:
        return WidgetConstant.sizedBox;
    }
  }
}
