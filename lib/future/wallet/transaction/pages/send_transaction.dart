import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';

class TransactionStateSendTransaction extends StatelessWidget {
  final TransactionStateController controller;
  final BuildContext? mainContext;
  const TransactionStateSendTransaction(
      {super.key, this.mainContext, required this.controller});

  @override
  Widget build(BuildContext context) {
    return APPStreamBuilder(
        value: controller.stateStatus,
        builder: (context, value) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ErrorTextContainer(error: value.error, enableTap: false),
            AlertTextContainer(message: value.warning, enableTap: false),
            Padding(
              padding: WidgetConstant.paddingVertical40,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                FixedElevatedButton(
                    onPressed: () => controller.signAndSendTransaction(
                        context: mainContext ?? context),
                    activePress: value.isReady,
                    child: Text("send_transaction".tr))
              ]),
            )
          ]);
        });
  }
}
