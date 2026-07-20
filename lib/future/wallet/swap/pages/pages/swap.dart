import 'package:blockchain_utils/bip/bip/conf/core/coin_conf.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/swap/controller/controller/controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/swap/swap.dart';
import 'package:on_chain_swap/on_chain_swap.dart';

import 'address.dart';
import 'amount_in.dart';
import 'config.dart';
import 'out_amout.dart';
import 'select_asset.dart';

class SwapView extends StatelessWidget {
  final SwapStateController swapController;
  final Chain account;
  const SwapView({required this.swapController, required this.account, super.key});

  @override
  Widget build(BuildContext context) {
    return APPStreamBuilder(
      value: swapController.notifier,
      builder: (context, value) {
        return Shimmer(
            onActive: (enable, context) {
              return IgnorePointer(
                  ignoring: swapController.page == SwapPage.review,
                  child: _SwapView(account: account, controller: swapController));
            },
            enable: swapController.status != SwapRouteStatus.init);
      },
    );
  }
}

class _SwapView extends StatelessWidget {
  final SwapStateController controller;
  final Chain account;
  const _SwapView({required this.controller, required this.account});

  @override
  Widget build(BuildContext context) {
    return Form(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      key: controller.formKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Material(
                    shape: CircleBorder(),
                    elevation: APPConst.elevation,
                    child: CircleAPPImageView(controller.sourceAsset?.token.assetLogo,
                        radius: APPConst.largeCircleRadius120),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 80),
                    child: Opacity(
                      opacity: 0.9,
                      child: Material(
                        shape: CircleBorder(),
                        elevation: APPConst.elevation,
                        child: CircleAPPImageView(
                          controller.destinationAsset?.token.assetLogo,
                          radius: APPConst.largeCircleRadius120,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            color: context.colors.surface.wOpacity(0.3),
            child: Center(
              child: CustomScrollView(
                // shrinkWrap: true,
                slivers: [
                  SliverConstraintsBoxView(
                    padding: WidgetConstant.paddingHorizontal10,
                    sliver: MultiSliver(children: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            SetupSwapAmoutView(
                                controller: controller,
                                sourceAsset: controller.sourceAsset,
                                onChangeAsset: () {
                                  context.openDialogPage('',
                                      child: (context) => SwapSelectAssetView(
                                            isSource: true,
                                            controller: controller,
                                          ));
                                }),
                            SwapAmountOutView(
                              destinationAsset: controller.destinationAsset,
                              route: controller.currentRoute,
                              controller: controller,
                              onChangeAsset: () {
                                context.openDialogPage('',
                                    child: (context) => SwapSelectAssetView(
                                        controller: controller, isSource: false));
                              },
                            ),
                            ...List.generate(controller.errors.length, (index) {
                              final error = controller.errors[index];
                              return ContainerWithBorder(
                                backgroundColor: context.colors.errorContainer,
                                child: Row(
                                  children: [
                                    if (error.provider != null) ...[
                                      CircleServiceProviderImageView(error.provider!,
                                          radius: APPConst.circleRadius25),
                                      WidgetConstant.width8
                                    ],
                                    Expanded(
                                        child: Text(error.error.tr,
                                            style: context.textTheme.bodyMedium?.copyWith(
                                                color: context.colors.onErrorContainer)))
                                  ],
                                ),
                              );
                            }),
                            ConditionalWidget(
                                enable: controller.hasRoute,
                                onActive: (context) => Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        RouteConfigView(
                                          routes: controller.currentRoute!,
                                          controller: controller,
                                        ),
                                        WidgetConstant.height20,
                                        SwapAddressesView(controller: controller)
                                      ],
                                    ),
                                onDeactive: (context) => WidgetConstant.sizedBox),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  WidgetConstant.sliverPaddingVertial40,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectSwapProvidersView extends StatefulWidget {
  final SwapStateController controller;
  const SelectSwapProvidersView(this.controller, {super.key});

  @override
  State<SelectSwapProvidersView> createState() => _SelectSwapProvidersViewState();
}

class _SelectSwapProvidersViewState extends State<SelectSwapProvidersView>
    with SafeState<SelectSwapProvidersView> {
  SwapStateController get controller => widget.controller;
  APPSwapSettings get settings => controller.settings;
  ChainType chainType = ChainType.testnet;
  List<SwapServiceProvider> activeProviders = [];
  List<SwapServiceProvider> supportProviders = [];

  bool get toleranceDisabled => tolerance == 0;

  double sliderOpacity = 1;

  late double tolerance = settings.tolerance ?? 0;

  void onChangeTolerance(double tolerance) {
    this.tolerance = tolerance;
    if (toleranceDisabled) {
      sliderOpacity = 0.3;
      context.showAlert("tolerance_disabled".tr);
    } else {
      sliderOpacity = 1;
    }
    updateState();
  }

  void addOrRemoveProvider(SwapServiceProvider provider) {
    if (activeProviders.length == 1 && activeProviders.contains(provider)) {
      context.showAlert("at_least_one_provider_must_enabled".tr);
      return;
    }
    if (!activeProviders.remove(provider)) {
      activeProviders.add(provider);
    }
    updateState();
  }

  Map<ChainType, Widget> networkItems = {
    for (final i in ChainType.values) i: Text(i.name.tr)
  };

  void updateSettings() {
    final providers = activeProviders.clone();
    providers.sort(
        (a, b) => supportProviders.indexOf(a).compareTo(supportProviders.indexOf(b)));
    final setting = settings.copyWith(
        tolerance: tolerance, chainType: chainType, swapProviders: providers);
    context.pop(setting);
  }

  void onSelectChainType(ChainType? chainType) {
    if (chainType == null) return;
    this.chainType = chainType;
    activeProviders.clear();
    switch (chainType) {
      case ChainType.testnet:
        supportProviders = SwapConstants.testnetProviders;
        break;
      case ChainType.mainnet:
        supportProviders = SwapConstants.supportProviders;
        break;
    }
    activeProviders.addAll(supportProviders);
    updateState();
  }

  @override
  void onInitOnce() {
    chainType = settings.chainType;
    switch (chainType) {
      case ChainType.mainnet:
        supportProviders = SwapConstants.supportProviders;
        break;
      case ChainType.testnet:
        supportProviders = SwapConstants.testnetProviders;
        break;
    }
    activeProviders = settings.swapProviders.clone();
    if (toleranceDisabled) {
      sliderOpacity = 0.3;
    }
    super.onInitOnce();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("network".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      AppDropDownBottom(
        value: chainType,
        items: networkItems,
        onChanged: onSelectChainType,
        hint: "network".tr,
      ),
      WidgetConstant.height20,
      Text("max_tolerance".tr, style: context.textTheme.titleMedium),
      Text("max_tolerance_desc".tr),
      WidgetConstant.height8,
      Opacity(
        opacity: sliderOpacity,
        child: Slider(
            value: tolerance,
            onChanged: onChangeTolerance,
            min: APPSwapSettingsConst.minTelerance,
            max: APPSwapSettingsConst.maxTolerance,
            label: "${tolerance.toStringAsFixed(1)}%",
            divisions: 50),
      ),
      WidgetConstant.height8,
      Text("services".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      APPAnimatedSize(
        isActive: true,
        onDeactive: (context) => WidgetConstant.sizedBox,
        onActive: (context) => ListView(
          key: ValueKey(supportProviders.length),
          shrinkWrap: true,
          physics: WidgetConstant.noScrollPhysics,
          children: List.generate(supportProviders.length, (index) {
            final provider = supportProviders[index];
            return ContainerWithBorder(
              onRemove: () {
                addOrRemoveProvider(provider);
              },
              onRemoveIcon: APPCheckBox(
                value: activeProviders.contains(provider),
                backgroundColor: context.onPrimaryContainer,
                color: context.primaryContainer,
              ),
              child: Row(
                children: [
                  CircleServiceProviderImageView(provider,
                      radius: APPConst.circleRadius25),
                  WidgetConstant.width8,
                  Expanded(
                      child: OneLineTextWidget(provider.name,
                          style: context.onPrimaryTextTheme.bodyMedium))
                ],
              ),
            );
          }),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FixedElevatedButton(
              padding: WidgetConstant.paddingVertical40,
              onPressed: updateSettings,
              child: Text("update_settings".tr))
        ],
      ),
    ]);
  }
}
