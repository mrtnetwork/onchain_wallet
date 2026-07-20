import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/swap/controller/controller/controller.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/wallet/models/swap/swap/models.dart';
import 'amount_in.dart';

class RouteConfigView extends StatelessWidget {
  final APPSwapRoutes routes;
  final SwapStateController controller;

  const RouteConfigView({required this.routes, required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return APPStreamBuilder(
        value: routes.route,
        builder: (context, route) {
          return ContainerWithBorder(
            child: DefaultTabController(
              length: routes.routes.length,
              initialIndex: routes.index,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TabBar(
                            onTap: (value) {
                              routes.onChangeRoute(value);
                            },
                            isScrollable: true,
                            tabs: List.generate(routes.routes.length, (i) {
                              final route = routes.routes[i];
                              return Tab(
                                child: Badge(
                                  // offset: Offset(-5, 0),
                                  alignment: Alignment(-3, -1),

                                  isLabelVisible: route.bps != null,
                                  textStyle: context.textTheme.labelSmall,
                                  backgroundColor: (route.bps?.minus ?? false)
                                      ? context.colors.error
                                      : context.colors.green,
                                  label: ConditionalWidget(
                                      enable: route.bps?.bpsPercentage != null,
                                      onActive: (context) => Text(
                                            route.bps!.bpsPercentage,
                                            style: context.textTheme.labelSmall?.copyWith(
                                                color: (route.bps?.minus ?? false)
                                                    ? context.colors.onError
                                                    : context.colors.onGreen),
                                          )),
                                  child: AnimatedContainer(
                                      padding: WidgetConstant.padding5,
                                      duration: APPConst.animationDuraion,
                                      decoration: BoxDecoration(
                                          color: i == routes.index
                                              ? context.colors.inversePrimary
                                              : context.colors.transparent,
                                          shape: BoxShape.circle),
                                      child: CircleServiceProviderImageView(
                                          route.provider,
                                          radius: APPConst.circleRadius12)),
                                ),
                                // child: CircleServiceProviderImageView(
                                //     routes.routes[i].provider,
                                //     radius: APPConst.circleRadius12),
                              );
                            })),
                      ),
                      APPStreamBuilder(
                          value: controller.timeout,
                          builder: (context, timeout) {
                            return SizedBox(
                              width: APPConst.double80,
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(Icons.timer, color: context.onPrimaryContainer),
                                    Expanded(
                                      child: Text(timeout.toString(),
                                          style: context.onPrimaryTextTheme.labelLarge),
                                    )
                                  ]),
                            );
                          }),
                    ],
                  ),
                  APPAnimated(
                      isActive: true,
                      onActive: (context) => Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RouteInfoView(route: route),
                              ThorSwapConfigView(routes: routes)
                            ],
                          ),
                      onDeactive: (context) => WidgetConstant.sizedBox)
                ],
              ),
            ),
          );
        });
  }
}

class RouteInfoView extends StatelessWidget {
  const RouteInfoView({required this.route, super.key});
  final SwapRouteWithBps route;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ContainerWithBorder(
                backgroundColor: context.onPrimaryContainer,
                child: Row(
                  children: [
                    CircleServiceProviderImageView(route.provider, radius: 12),
                    WidgetConstant.width8,
                    Expanded(
                        child: OneLineTextWidget(route.provider.name,
                            style: context.primaryTextTheme.bodyMedium))
                  ],
                ),
              ),
            ),
            Expanded(
              child: TappedTooltipView(
                tooltipWidget: ToolTipView(
                    message: "lowest_expected_amount".tr,
                    child: ContainerWithBorder(
                      backgroundColor: context.onPrimaryContainer,
                      onRemove: () {},
                      enableTap: false,
                      onRemoveWidget: Text(
                          "${route.route.worstPercentage.toStringAsFixed(1)}%",
                          style: context.primaryTextTheme.labelSmall),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward, color: context.primaryContainer),
                          WidgetConstant.width8,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CoinAndMarketPriceView(
                                    balance: route.worstCaseAmount,
                                    symbolColor: context.primaryContainer,
                                    style: context.primaryTextTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
              ),
            )
          ],
        ),
        Row(
          children: [
            Expanded(
                child: ConditionalWidget(
                    enable: route.bps != null,
                    onDeactive: (context) => ContainerWithBorder(
                          backgroundColor: context.onPrimaryContainer,
                          child: Row(
                            children: [
                              Icon(Icons.show_chart, color: context.primaryContainer),
                              WidgetConstant.width8,
                              Expanded(
                                  child: Text("market_price_unavailable".tr,
                                      style: context.primaryTextTheme.bodyMedium)),
                            ],
                          ),
                        ),
                    onActive: (context) {
                      final bps = route.bps!;
                      return ContainerWithBorder(
                        backgroundColor: context.onPrimaryContainer,
                        enableTap: false,
                        onRemoveWidget: Text(
                          bps.bpsPercentage,
                          style: context.primaryTextTheme.labelSmall,
                        ),
                        onRemove: () {},
                        child: Row(
                          children: [
                            Icon(Icons.show_chart, color: context.primaryContainer),
                            WidgetConstant.width8,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CoinPriceView(
                                    balance: bps.amount,
                                    style: context.primaryTextTheme.bodyMedium,
                                    symbolColor: context.primaryContainer,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    })),
            Expanded(
              child: ContainerWithBorder(
                backgroundColor: context.onPrimaryContainer,
                onRemove: () {
                  context.openSliverDialog(
                      widget: (context) => _RouteFeesView(fees: route.fees),
                      label: 'fees'.tr);
                },
                onRemoveIcon: Icon(Icons.info, color: context.colors.primaryContainer),
                child: Row(
                  children: [
                    Icon(Icons.local_gas_station, color: context.colors.primaryContainer),
                    WidgetConstant.width8,
                    Expanded(
                        child: ConditionalWidget(
                      enable: route.totalFee != null,
                      onDeactive: (context) => Text("tap_to_review_fees".tr,
                          style: context.primaryTextTheme.bodyMedium),
                      onActive: (context) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CoinPriceView(
                              balance: route.totalFee,
                              symbolColor: context.primaryContainer,
                              style: context.primaryTextTheme.bodyMedium)
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            )
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TappedTooltipView(
                  tooltipWidget: ToolTipView(
                      message: "expected_swap_duration".tr,
                      child: ContainerWithBorder(
                        backgroundColor: context.onPrimaryContainer,
                        child: Row(
                          children: [
                            Icon(Icons.timer, color: context.colors.primaryContainer),
                            WidgetConstant.width8,
                            Expanded(
                                child: Text(
                                    "n_minutes"
                                        .tr
                                        .replaceOne(route.route.estimateTime.toString()),
                                    style: context.primaryTextTheme.bodyMedium))
                          ],
                        ),
                      ))),
            ),
            Expanded(
              child: ContainerWithBorder(
                backgroundColor: context.onPrimaryContainer,
                child: Row(
                  children: [
                    Icon(Icons.timer_off, color: context.colors.primaryContainer),
                    WidgetConstant.width8,
                    Expanded(
                        child: ConditionalWidget(
                            enable: route.route.expireTime != null,
                            onActive: (context) => Text(
                                route.route.expireTime!.toDateAndTime(),
                                style: context.primaryTextTheme.bodyMedium)))
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ThorSwapConfigView extends StatelessWidget {
  final APPSwapRoutes routes;
  const ThorSwapConfigView({required this.routes, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ConditionalWidget(
          enable: routes.supportTolerance,
          onActive: (context) => ContainerWithBorder(
                backgroundColor: context.onPrimaryContainer,
                child: Row(
                  children: [
                    Text("tolerance".tr, style: context.primaryTextTheme.bodyMedium),
                    Expanded(
                      child: Slider(
                        min: 0.0,
                        max: routes.maxTolerance,
                        divisions: (routes.maxTolerance * 4).toInt(),
                        value: routes.tolerance,
                        onChanged: routes.updateTolerance,
                        label: '${routes.tolerance.toStringAsFixed(1)}%',
                      ),
                    )
                  ],
                ),
              ))
    ]);
  }
}

class _RouteFeesView extends StatelessWidget {
  final List<APPSwapFee> fees;
  const _RouteFeesView({required this.fees});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        itemBuilder: (context, index) => _FeeInfo(fee: fees[index]),
        separatorBuilder: (context, index) => Divider(),
        itemCount: fees.length,
        shrinkWrap: true,
        physics: WidgetConstant.noScrollPhysics);
  }
}

class _FeeInfo extends StatelessWidget {
  final APPSwapFee fee;
  const _FeeInfo({required this.fee});

  @override
  Widget build(BuildContext context) {
    return ContainerWithBorder(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("provider".tr, style: context.onPrimaryTextTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
          backgroundColor: context.onPrimaryContainer,
          child: Text(fee.fee.type.camelCase, style: context.primaryTextTheme.bodyMedium),
        ),
        WidgetConstant.height20,
        ConditionalWidget(
            enable: fee.token != null,
            onDeactive: (context) =>
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("asset".tr, style: context.onPrimaryTextTheme.titleMedium),
                  WidgetConstant.height8,
                  ContainerWithBorder(
                      backgroundColor: context.onPrimaryContainer,
                      child: Text(fee.fee.asset,
                          style: context.primaryTextTheme.bodyMedium)),
                  WidgetConstant.height20,
                  Text("amount".tr, style: context.onPrimaryTextTheme.titleMedium),
                  WidgetConstant.height8,
                  ContainerWithBorder(
                      backgroundColor: context.onPrimaryContainer,
                      child: Text(fee.amount.viewPrice,
                          style: context.primaryTextTheme.bodyMedium)),
                ]),
            onActive: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("amount".tr, style: context.onPrimaryTextTheme.titleMedium),
                    WidgetConstant.height8,
                    ContainerWithBorder(
                        backgroundColor: context.onPrimaryContainer,
                        child: CoinAndMarketPriceView(
                            balance: fee.amount,
                            showTokenImage: true,
                            symbolColor: context.primaryContainer,
                            style: context.primaryTextTheme.titleMedium)),
                  ],
                )),
      ]),
    );
  }
}
