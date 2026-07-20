import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/webview/controller/controller/controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';

class WebViewTabsView extends StatelessWidget {
  const WebViewTabsView(this.controller, {super.key});
  final WebViewController controller;

  @override
  Widget build(BuildContext context) {
    return APPStreamBuilder(
        value: controller.notifier,
        builder: (context, value) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                  automaticallyImplyLeading: false,
                  title: Text("tabs".tr),
                  leading: IconButton(
                      onPressed: () {
                        controller.backToBorwser();
                      },
                      icon: Icon(Icons.arrow_back)),
                  actions: [
                    TextButton.icon(
                        onPressed: () {
                          controller.newTab((v) {});
                        },
                        label: Text("new_tab".tr),
                        icon: const Icon(Icons.add_box)),
                  ]),
              SliverConstraintsBoxView(
                padding: WidgetConstant.paddingHorizontal20,
                sliver: SliverList.builder(
                  itemCount: controller.controllers.length,
                  itemBuilder: (context, i) {
                    final view = controller.controllers[i];
                    final String? title = view.tab.value.viewTitle;
                    return ContainerWithBorder(
                      enableTap: false,
                      onRemove: () => controller.switchTab(view),
                      onRemoveWidget: Row(
                        children: [
                          IconButton(
                              onPressed: () => controller.removeTab(view),
                              icon:
                                  Icon(Icons.delete, color: context.onPrimaryContainer)),
                          IconButton(
                              onPressed: () => controller.switchTab(view),
                              icon: Icon(Icons.open_in_new_outlined,
                                  color: context.onPrimaryContainer)),
                        ],
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        CircleAPPImageView(
                          view.tab.value.image,
                          radius: APPConst.circleRadius25,
                          onProgress: (c) => const Icon(Icons.travel_explore_rounded),
                        ),
                        WidgetConstant.width8,
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (title != null)
                              OneLineTextWidget(title,
                                  style: context.textTheme.labelLarge),
                            OneLineTextWidget(view.tab.value.url,
                                style: context.textTheme.bodySmall),
                          ],
                        ))
                      ]),
                    );
                  },
                ),
              )
            ],
          );
        });
  }
}
