import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class BannerChainInfoWidget extends StatelessWidget {
  final Chain chain;
  final String subtitle;
  final DynamicVoid onLogin;
  const BannerChainInfoWidget(
      {required this.chain, required this.subtitle, required this.onLogin, super.key});

  @override
  Widget build(BuildContext context) {
    return APPStreamWidget(
      stream: context.wallet.wallet.status,
      allowNotify: (value) {
        if (value.inProgress) return false;
        if (value.walletStatus.isUnlock) {
          onLogin();
        }
        return false;
      },
      builder: (context, value) => InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: () => context.openDialogPage(
          "",
          child: (context) => AccessWalletView(
            request: WalletCredentialLogin.instance,
            onWalletAccess: (credential) => onLogin(),
          ),
        ),
        child: Padding(
          padding: WidgetConstant.paddingVertical8,
          child: Row(children: [
            CircleAssetsImageView(chain.network.coinParam.logo,
                radius: APPConst.circleRadius25),
            WidgetConstant.width8,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chain.network.networkName, style: context.textTheme.titleSmall),
                Text(subtitle)
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

class BannerElevatedButtonWidget extends StatelessWidget {
  final Widget title;
  final VoidContext callback;
  const BannerElevatedButtonWidget(
      {super.key, required this.title, required this.callback});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: () {
          callback(context);
        },
        child: title);
  }
}

class SnackbarAlert extends StatelessWidget {
  final DynamicVoid onTap;
  final String message;
  const SnackbarAlert({required this.message, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: ConstraintsBoxView(
          maxWidth: 350,
          child: Card(
            elevation: 3,
            child: Container(
              padding: WidgetConstant.padding10,
              decoration: BoxDecoration(
                  color: context.theme.colorScheme.inverseSurface,
                  borderRadius: WidgetConstant.border8),
              child: Stack(
                children: [
                  Center(
                    child: OneLineTextWidget(
                      message,
                      maxLine: 3,
                      align: TextAlign.center,
                      style: context.theme.textTheme.bodyMedium
                          ?.copyWith(color: context.theme.colorScheme.onInverseSurface),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
