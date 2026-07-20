import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/text_field/input_formaters.dart';
import 'package:on_chain_wallet/future/wallet/swap/controller/controller/controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/swap/swap/models.dart';
import 'package:on_chain_swap/on_chain_swap.dart';
import 'package:flutter/material.dart';

class SetupSwapAmoutView extends StatelessWidget {
  final APPSwapAssets? sourceAsset;
  final DynamicVoid onChangeAsset;
  final SwapStateController controller;
  const SetupSwapAmoutView(
      {super.key,
      required this.onChangeAsset,
      required this.sourceAsset,
      required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ContainerWithBorder(
          onRemove: onChangeAsset,
          focusColor: context.colors.transparent,
          hoverColor: context.colors.transparent,
          onRemoveIcon: IconButton(
              onPressed: onChangeAsset,
              icon: Icon(Icons.edit, color: context.colors.onPrimaryContainer)),
          child: Stack(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: APPConst.circleRadius25 * 2,
                    height: APPConst.circleRadius25 * 2,
                    child: Material(
                      elevation: 5,
                      color: context.colors.primaryContainer,
                      shape: CircleBorder(),
                      child: Stack(
                        children: [
                          CircleAPPImageView(sourceAsset?.token.assetLogo,
                              radius: APPConst.circleRadius25),
                          Align(
                              alignment: Alignment.topRight,
                              child: CircleAPPImageView(
                                  sourceAsset?.network.token.assetLogo,
                                  radius: 10))
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller.amountController,
                      style: context.textTheme.titleLarge?.copyWith(
                          color: context.colors.onSecondaryContainer,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      cursorColor: context.colors.onSecondaryContainer,
                      autocorrect: false,
                      canRequestFocus: controller.walletPage.inSwap,
                      inputFormatters: [
                        BigRetionalTextInputFormatter(
                            allowSign: false,
                            allowDecimal: true,
                            maxScale: sourceAsset?.token.decimal),
                      ],
                      textAlign: TextAlign.start,
                      decoration: InputDecoration(
                          hintText: "0.0",
                          fillColor: context.colors.onSecondaryContainer,
                          filled: false,
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide.none)),
                    ),
                  ),
                ],
              ),
              APPStreamBuilder(
                value: controller.inputPrice,
                builder: (context, value) {
                  return Positioned(
                      bottom: 0,
                      left: APPConst.circleRadius25 * 2 + 10,
                      child: APPAnimated(
                          isActive: true,
                          onActive: (context) => CoinPriceView(
                                key: ValueKey(value),
                                balance: value,
                                style: context.onPrimaryTextTheme.labelMedium,
                                symbolColor: context.onPrimaryContainer,
                              ),
                          onDeactive: (context) => WidgetConstant.sizedBox));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CircleSwapAssetImageView extends StatelessWidget {
  const CircleSwapAssetImageView(this.token, {this.radius = 120, super.key});
  final BaseSwapAsset? token;
  final double radius;

  @override
  Widget build(BuildContext context) {
    String symbol = (token?.symbol.nullOnEmpty?[0] ?? 'U').toUpperCase();
    return CircleAPPImageView(APPImage.network(token?.logoUrl),
        onNull: symbol, radius: radius);
  }
}

class CircleServiceProviderImageView extends StatelessWidget {
  const CircleServiceProviderImageView(this.provider, {this.radius = 40, super.key});
  final SwapServiceProvider? provider;
  final double radius;

  @override
  Widget build(BuildContext context) {
    String symbol = (provider?.name.nullOnEmpty?[0] ?? 'U').toUpperCase();
    return CircleAPPImageView(APPImage.network(provider?.logoUrl),
        onNull: symbol, radius: radius);
  }
}

class CircleNetworkImageView extends StatelessWidget {
  const CircleNetworkImageView(this.network, {this.radius = 40, super.key});
  final SwapNetwork? network;
  final double radius;

  @override
  Widget build(BuildContext context) {
    String symbol = (network?.name.nullOnEmpty?[0] ?? 'U').toUpperCase();
    return CircleAPPImageView(APPImage.network(network?.logoUrl),
        onNull: symbol, radius: radius);
  }
}
