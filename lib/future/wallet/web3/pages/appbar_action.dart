import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/client_info.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/core/request/web_request.dart';

class Web3PermissionAppbarActionView extends StatelessWidget {
  const Web3PermissionAppbarActionView({required this.request, super.key});
  final Web3NetworkRequest request;
  Chain get chain => request.chain;
  WalletNetwork get network => chain.network;
  @override
  Widget build(BuildContext context) {
    return TappedTooltipView(
      tooltipWidget: ToolTipView(
          padding: EdgeInsets.zero,
          tooltipWidget: (c) => IgnorePointer(
                child: ToolTipConstrainedBox(
                  child: Column(
                    children: [
                      ContainerWithBorder(
                        child: Row(
                          children: [
                            CircleTokenImageView(network.coinParam.token,
                                radius: APPConst.circleRadius25),
                            WidgetConstant.width8,
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OneLineTextWidget(
                                  network.token.name,
                                  style: context.onPrimaryTextTheme.bodyMedium,
                                ),
                                CoinAndMarketPriceView(
                                  balance: chain.totalBalance.value,
                                  style: context.onPrimaryTextTheme.labelLarge,
                                  symbolColor: context.onPrimaryContainer,
                                )
                              ],
                            )),
                          ],
                        ),
                      ),
                      WidgetConstant.height20,
                      Web3ApplicationView(
                        permission: request.authenticated,
                        info: request.info,
                        color: context.colors.onInverseSurface,
                      ),
                    ],
                  ),
                ),
              ),
          child: CircleTokenImageView(network.token, radius: APPConst.circleRadius12)),
    );
  }
}
