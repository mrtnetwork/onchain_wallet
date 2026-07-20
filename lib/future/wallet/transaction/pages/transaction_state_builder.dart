import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/wallet/api/client/core/client.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';

class TransactionStateBuilder extends StatefulWidget {
  const TransactionStateBuilder({super.key});

  @override
  State<TransactionStateBuilder> createState() => _TransactionStateBuilderState();
}

class _TransactionStateBuilderState extends State<TransactionStateBuilder>
    with SafeState<TransactionStateBuilder> {
  late TransactionStateController controller;
  late TransactionStateController internalController;

  Future<void> init() async {
    final controller = await this.controller.init(context);
    if (!identical(controller, internalController)) {
      internalController = controller;
      updateState();
      await internalController.init(context);
    }
  }

  Future<void> switchAccount(ChainAccount? address) async {
    if (address == null) return;
    final currentController = internalController;
    final initController = controller;
    currentController.setPageProgress("switching_account_please_wait".tr);
    await MethodUtils.delayed(duration: APPConst.animationDuraion);
    final newController = await internalController.cloneController(address);
    internalController = newController;
    controller = newController;
    updateState();
    await init();
    MethodUtils.executeAfterDelay(() async {
      currentController.dispose();
      if (!identical(currentController, initController)) {
        initController.dispose();
      }
    }, duration: APPConst.animationDuraion);
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    controller = context.getArgruments();
    internalController = controller;
    init();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    controller.dispose();
    if (!identical(controller, internalController)) {
      internalController.dispose();
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return NetworkAccountControllerView<NetworkClient, ChainAccount, Chain>(
        key: ValueKey(internalController),
        title: internalController.operation.value.tr,
        childBulder: (wallet, account, client, address) {
          return StreamPageProgress(
            controller: internalController.pageKey,
            initialWidget: ProgressWithTextView(text: 'retrieving_network_condition'.tr),
            builder: (context) {
              return CustomScrollView(slivers: [
                SliverConstraintsBoxView(
                    padding: WidgetConstant.paddingHorizontal20,
                    sliver: MultiSliver(children: [
                      Text("account".tr, style: context.textTheme.titleMedium),
                      WidgetConstant.height8,
                      ContainerWithBorder(
                        onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
                        onRemove: internalController.swtichAddressEnabled
                            ? () {
                                context
                                    .selectOrSwitchAccount(
                                        account: internalController.account,
                                        showMultiSig: true)
                                    .then(switchAccount);
                              }
                            : null,
                        child: AddressDetailsView(
                            address: internalController.address,
                            chain: internalController.account,
                            color: context.onPrimaryContainer,
                            key: ValueKey(internalController.address)),
                      ),
                      WidgetConstant.height20,
                      internalController.onPageBuilder(ctx)
                    ]))
              ]);
            },
          );
        },
        addressRequired: true,
        clientRequired: true,
        account: internalController.account);
  }
}
