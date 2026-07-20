import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/swap/controller/controller/controller.dart';
import 'package:on_chain_wallet/wallet/models/swap/swap/models.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';

class SwapAmountOutView extends StatelessWidget {
  final APPSwapAssets? destinationAsset;
  final DynamicVoid onChangeAsset;
  final APPSwapRoutes? route;
  final SwapStateController controller;
  const SwapAmountOutView(
      {super.key,
      required this.destinationAsset,
      required this.onChangeAsset,
      required this.route,
      required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer(
            enable: controller.status.isIdle,
            onActive: (enable, context) {
              return ContainerWithBorder(
                onRemove: onChangeAsset,
                focusColor: context.colors.transparent,
                hoverColor: context.colors.transparent,
                onRemoveIcon: IconButton(
                    onPressed: onChangeAsset,
                    icon: Icon(Icons.edit, color: context.colors.onPrimaryContainer)),
                child: Row(
                  children: [
                    SizedBox(
                      width: APPConst.circleRadius25 * 2,
                      height: APPConst.circleRadius25 * 2,
                      child: Material(
                        elevation: 5,
                        color: context.colors.primaryContainer,
                        shape: CircleBorder(),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircleAPPImageView(destinationAsset?.token.assetLogo,
                                radius: APPConst.circleRadius25),
                            Align(
                              alignment: Alignment.topRight,
                              child: CircleAPPImageView(
                                  destinationAsset?.network.token.assetLogo,
                                  radius: APPConst.circleRadius12),
                            )
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: IgnorePointer(
                        child: Padding(
                          padding: WidgetConstant.paddingHorizontal10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              APPAnimated(
                                  isActive: true,
                                  onActive: (context) => ConditionalWidget(
                                        key: ValueKey(route?.index),
                                        enable: route != null,
                                        onDeactive: (context) => Text(
                                          "0.0",
                                          style: context.textTheme.titleLarge?.copyWith(
                                              color: context.colors.onPrimaryContainer,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        onActive: (context) => APPStreamBuilder(
                                            value: route!.route,
                                            builder: (context, currentRoute) {
                                              return CoinAndMarketPriceView(
                                                balance: currentRoute.amount,
                                                symbolColor:
                                                    context.colors.onPrimaryContainer,
                                                style: context.textTheme.titleLarge
                                                    ?.copyWith(
                                                        color: context
                                                            .colors.onPrimaryContainer,
                                                        fontWeight: FontWeight.bold),
                                              );
                                            }),
                                      ),
                                  onDeactive: (context) => WidgetConstant.sizedBox),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
      ],
    );
  }
}
