import 'package:on_chain_wallet/future/wallet/global/pages/address_details.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/receipt_address_view.dart';
import 'package:on_chain_wallet/future/wallet/swap/controller/controller/transaction.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/swap/swap/models.dart';
import 'package:on_chain_swap/on_chain_swap.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';

import 'config.dart';

class TransactionReviewView extends StatelessWidget {
  // final APPSwapRoute route;
  const TransactionReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return StateBuilder<SwapTransactionStateController>(
      disposeStrategy: StateBuilderDisposeStrategy.onDispose,
      controller: () => SwapTransactionStateController(
          route: context.getArgruments<APPSwapRoute>(), wallet: context.wallet),
      builder: (controller) {
        return PopScope(
          canPop: controller.allowPop,
          onPopInvokedWithResult: (didPop, result) async {
            if (!controller.allowPop) {
              final close = await controller.onPop(() async {
                return context.openSliverDialog<bool>(
                  widget: (context) => DialogTextView(
                      text: "close_swap_page_desc".tr,
                      buttonWidget: DialogDoubleButtonView()),
                  label: 'close_page'.tr,
                );
              });
              if (close == true && context.mounted) context.popToHome();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text("transaction".tr),
              // actions: [
              //   IconButton(
              //       onPressed: () {
              //         controller.reset();
              //       },
              //       icon: Icon(Icons.abc)),
              // ],
            ),
            body: StreamPageProgress(
              controller: controller.progressKey,
              builder: (context) => CustomScrollView(
                slivers: [
                  SliverConstraintsBoxView(
                      padding: WidgetConstant.paddingHorizontal20,
                      sliver: MultiSliver(children: [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    children: [
                                      Material(
                                        shape: CircleBorder(),
                                        elevation: 10,
                                        child: CircleTokenImageView(
                                            controller.route.sourceAsset.token,
                                            radius: 60),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 80),
                                        child: Opacity(
                                          opacity: 0.9,
                                          child: Material(
                                            shape: CircleBorder(),
                                            elevation: 10,
                                            child: CircleTokenImageView(
                                                controller.route.destAsset.token,
                                                radius: 60),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              WidgetConstant.height20,
                              ContainerWithBorder(
                                child: Column(children: [
                                  Row(
                                    children: [
                                      Expanded(
                                          child: ContainerWithBorder(
                                        backgroundColor: context.onPrimaryContainer,
                                        child: CoinAndMarketPriceView(
                                          showTokenImage: true,
                                          balance: controller.route.sourceAmount,
                                          style: context.primaryTextTheme.titleMedium,
                                          symbolColor: context.primaryContainer,
                                        ),
                                      )),
                                      Icon(Icons.forward, size: 45),
                                      Expanded(
                                          child: ContainerWithBorder(
                                        backgroundColor: context.onPrimaryContainer,
                                        child: CoinAndMarketPriceView(
                                          showTokenImage: true,
                                          balance: controller.route.destAmount,
                                          style: context.primaryTextTheme.titleMedium,
                                          symbolColor: context.primaryContainer,
                                        ),
                                      ))
                                    ],
                                  ),
                                  RouteInfoView(route: controller.route.route),
                                  ContainerWithBorder(
                                    backgroundColor: context.onPrimaryContainer,
                                    child: CopyableTextWidget(
                                        text: controller
                                            .route.transaction.params.destinationAddress,
                                        color: context.primaryContainer),
                                  ),
                                ]),
                              ),
                              ConditionalWidget(
                                  enable: controller
                                          .route.transaction.route.provider.service ==
                                      SwapServiceType.chainFlip,
                                  onActive: (context) => Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          WidgetConstant.height20,
                                          Text("channel".tr,
                                              style: context.textTheme.titleMedium),
                                          WidgetConstant.height8,
                                          _CfChannelInformation(
                                              channel: controller.route.transaction.params
                                                  .cast())
                                        ],
                                      )),
                              WidgetConstant.height20,
                              Text("source_accounts".tr,
                                  style: context.textTheme.titleMedium),
                              WidgetConstant.height8,
                              ...List.generate(controller.sources.length, (i) {
                                final account = controller.sources[i];
                                return ContainerWithBorder(
                                  child: AddressDetailsView(
                                      address: account,
                                      color: context.onPrimaryContainer),
                                );
                              }),
                              WidgetConstant.height20,
                              ReceiptAddressView(address: controller.destAddress),
                              WidgetConstant.height20,
                              Text("operations".tr, style: context.textTheme.titleMedium),
                              WidgetConstant.height8,
                            ],
                          ),
                        ),
                        SliverPadding(
                          padding: WidgetConstant.padding5,
                          sliver: SliverList.separated(
                            itemCount: controller.route.transaction.operations.length,
                            separatorBuilder: (context, index) => WidgetConstant.height8,
                            itemBuilder: (context, index) {
                              final operation =
                                  controller.route.transaction.operations[index];
                              if (operation is SwapRouteTransactionTransferDetails) {
                                return _TransactionNativeTransferOperationView(
                                  operation: operation,
                                  route: controller.route.transaction.route,
                                  sourceAmount: controller.route.sourceAmount,
                                );
                              } else if (operation
                                  is SwapRouteTransactionContractDetails) {
                                return _TransactionNativeContractOperationView(
                                  operation: operation,
                                  route: controller.route.transaction.route,
                                  sourceAmount: controller.route.sourceAmount,
                                );
                              }
                              return WidgetConstant.sizedBox;
                            },
                          ),
                        ),
                        SliverToBoxAdapter(
                            child: ErrorTextContainer(
                                error: controller.latestError, enableTap: false)),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: WidgetConstant.paddingVertical40,
                            child: Shimmer(
                              enable: !controller.inProgress,
                              onActive: (enable, context) => FixedElevatedButton(
                                onPressed: () {
                                  controller.signTransaction();
                                },
                                child: APPAnimatedSwitcher<TransactionOperationStep?>(
                                  enable: controller.step,
                                  widgets: {
                                    null: (context) =>
                                        Text("sign_and_send_transaction".tr),
                                    TransactionOperationStep.client: (context) =>
                                        Text("connecting_to_network".tr),
                                    TransactionOperationStep.generateTx: (context) =>
                                        Text("generating_transaction".tr),
                                    TransactionOperationStep.signing: (context) =>
                                        Text("signing_transaction".tr),
                                    TransactionOperationStep.broadcast: (context) =>
                                        Text("broadcasting_transaction".tr),
                                    TransactionOperationStep.complete: (context) =>
                                        Text("complete".tr),
                                  },
                                ),
                              ),
                            ),
                          ),
                        )
                      ])),
                  WidgetConstant.sliverPaddingVertial40,
                ],
              ),
            ),
          ),
        );
      },
      repositoryId: 'transaction',
    );
  }
}

class _TransactionNativeTransferOperationView extends StatelessWidget {
  const _TransactionNativeTransferOperationView({
    required this.sourceAmount,
    required this.operation,
    required this.route,
  });
  final SwapRouteTransactionTransferDetails operation;
  final SwapRoute route;
  final IntegerBalance sourceAmount;

  @override
  Widget build(BuildContext context) {
    return APPExpansionListTile(
      title: operation.tokenAddress != null
          ? Text('token_transfer'.tr, style: context.onPrimaryTextTheme.bodyMedium)
          : Text('transfer'.tr, style: context.onPrimaryTextTheme.bodyMedium),
      children: [
        ContainerWithBorder(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("source".tr, style: context.onPrimaryTextTheme.titleMedium),
              WidgetConstant.height8,
              ContainerWithBorder(
                backgroundColor: context.onPrimaryContainer,
                child: CopyableTextWidget(
                  text: operation.sourceAddress,
                  color: context.primaryContainer,
                ),
              ),
              WidgetConstant.height20,
              Text("destionation".tr, style: context.onPrimaryTextTheme.titleMedium),
              WidgetConstant.height8,
              ContainerWithBorder(
                backgroundColor: context.onPrimaryContainer,
                onRemove: () {},
                enableTap: false,
                onRemoveWidget: BarcodeImageIconView(
                    data: operation.destinationAddress, color: context.primaryContainer),
                child: CopyableTextWidget(
                    text: operation.destinationAddress, color: context.primaryContainer),
              ),
              WidgetConstant.height20,
              Text("amount".tr, style: context.onPrimaryTextTheme.titleMedium),
              WidgetConstant.height8,
              ContainerWithBorder(
                backgroundColor: context.onPrimaryContainer,
                child: CoinAndMarketPriceView(
                  balance: sourceAmount,
                  symbolColor: context.primaryContainer,
                  style: context.primaryTextTheme.titleMedium,
                  showTokenImage: true,
                ),
              ),
              ConditionalWidget(
                enable: operation.tokenAddress != null,
                onActive: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WidgetConstant.height20,
                    Text("token".tr, style: context.onPrimaryTextTheme.titleMedium),
                    WidgetConstant.height8,
                    ContainerWithBorder(
                      backgroundColor: context.onPrimaryContainer,
                      child: CopyableTextWidget(
                          text: operation.tokenAddress!, color: context.primaryContainer),
                    ),
                  ],
                ),
              ),
              ConditionalWidget(
                enable: operation.memo != null,
                onActive: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WidgetConstant.height20,
                    Text("memo".tr, style: context.onPrimaryTextTheme.titleMedium),
                    WidgetConstant.height8,
                    ContainerWithBorder(
                      backgroundColor: context.onPrimaryContainer,
                      child: CopyableTextWidget(
                          text: operation.memo!,
                          maxLines: 2,
                          color: context.primaryContainer),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionNativeContractOperationView extends StatelessWidget {
  const _TransactionNativeContractOperationView(
      {required this.operation, required this.route, required this.sourceAmount});
  final SwapRouteTransactionContractDetails operation;
  final SwapRoute route;
  final IntegerBalance sourceAmount;

  @override
  Widget build(BuildContext context) {
    return APPExpansionListTile(
      title: Text('contract_intraction'.tr),
      children: [
        ContainerWithBorder(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("source".tr, style: context.onPrimaryTextTheme.titleMedium),
              WidgetConstant.height8,
              ContainerWithBorder(
                backgroundColor: context.onPrimaryContainer,
                child: CopyableTextWidget(
                  text: operation.sourceAddress,
                  color: context.primaryContainer,
                ),
              ),
              WidgetConstant.height20,
              Text("contract".tr, style: context.onPrimaryTextTheme.titleMedium),
              WidgetConstant.height8,
              ContainerWithBorder(
                backgroundColor: context.onPrimaryContainer,
                child: CopyableTextWidget(
                  text: operation.contractAddress,
                  color: context.primaryContainer,
                ),
              ),
              ConditionalWidget(
                  enable: operation.amount != null,
                  onActive: (context) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WidgetConstant.height20,
                        Text("amount".tr, style: context.onPrimaryTextTheme.titleMedium),
                        WidgetConstant.height8,
                        ContainerWithBorder(
                          backgroundColor: context.onPrimaryContainer,
                          child: CoinAndMarketPriceView(
                            balance: sourceAmount,
                            symbolColor: context.primaryContainer,
                            style: context.primaryTextTheme.titleMedium,
                          ),
                        ),
                      ],
                    );
                  }),
              WidgetConstant.height20,
              Text("function".tr, style: context.onPrimaryTextTheme.titleMedium),
              WidgetConstant.height8,
              ContainerWithBorder(
                backgroundColor: context.onPrimaryContainer,
                child: CopyableTextWidget(
                    text: operation.functionName, color: context.primaryContainer),
              ),
              WidgetConstant.height20,
              Text("input".tr, style: context.onPrimaryTextTheme.titleMedium),
              WidgetConstant.height8,
              ContainerWithBorder(
                backgroundColor: context.onPrimaryContainer,
                child: CopyableTextWidget(
                    text: operation.data, color: context.primaryContainer, maxLines: 3),
              ),
            ],
          ),
        )
      ],
    );
  }
}

class _CfChannelInformation extends StatelessWidget {
  final SwapRouteCfGeneralTransactionBuilderParam channel;
  const _CfChannelInformation({required this.channel});

  @override
  Widget build(BuildContext context) {
    return APPExpansionListTile(
      title: Text('channel_information'.tr, style: context.onPrimaryTextTheme.bodyMedium),
      children: [
        ContainerWithBorder(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("channel_id".tr, style: context.onPrimaryTextTheme.titleMedium),
              WidgetConstant.height8,
              ContainerWithBorder(
                backgroundColor: context.onPrimaryContainer,
                onRemove: () {},
                enableTap: false,
                onRemoveWidget: LaunchBrowserIcon(
                    url: channel.channelUrl, color: context.primaryContainer),
                child: CopyableTextWidget(
                  text: channel.channelUrl,
                  color: context.primaryContainer,
                ),
              ),
              WidgetConstant.height20,
              Text("expiration_block".tr, style: context.onPrimaryTextTheme.titleMedium),
              WidgetConstant.height8,
              ContainerWithBorder(
                backgroundColor: context.onPrimaryContainer,
                child: Text(
                  channel.channel.srcChainExpiryBlock,
                  style: context.primaryTextTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
