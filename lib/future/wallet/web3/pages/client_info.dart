import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';

///
class Web3ApplicationView extends StatelessWidget {
  const Web3ApplicationView(
      {required this.permission, this.client, this.info, this.color, super.key});
  final Web3RequestAuthentication permission;
  final Web3RequestInformation? info;
  final Web3ClientInfo? client;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final client = this.client ?? info?.client;
    return ConditionalWidget(
      enable: client != null,
      onDeactive: (context) => _PermissionInfo(
        logo: permission.icon,
        name: permission.name,
        url: permission.url ?? permission.applicationId,
        color: color,
      ),
      onActive: (context) => _PermissionInfo(
          logo: client!.image, name: client.name, url: client.url, color: color),
    );
  }
}

class _PermissionInfo extends StatelessWidget {
  final APPImage? logo;
  final String name;
  final String url;
  final Color? color;
  const _PermissionInfo(
      {required this.logo, required this.name, required this.url, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ContainerWithBorder(
          child: Row(
            children: [
              CircleAPPImageView(
                logo,
                radius: APPConst.circleRadius25,
                onError: (c) => const Icon(Icons.broken_image, size: APPConst.double40),
              ),
              WidgetConstant.width8,
              Flexible(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OneLineTextWidget(name, style: context.onPrimaryTextTheme.labelLarge),
                  OneLineTextWidget(url, style: context.onPrimaryTextTheme.bodySmall),
                ],
              )),
            ],
          ),
        ),
      ],
    );
  }
}

class Web3ClientInfoView extends StatelessWidget {
  const Web3ClientInfoView({super.key, required this.cleint});
  final Web3ClientInfo cleint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("client".tr, style: context.textTheme.titleMedium),
        Text("web3_client_desc".tr),
        WidgetConstant.height8,
        ContainerWithBorder(
          child: Row(
            children: [
              CircleAPPImageView(
                cleint.image,
                radius: APPConst.circleRadius25,
                onError: (c) => const Icon(Icons.broken_image, size: APPConst.double40),
              ),
              WidgetConstant.width8,
              Flexible(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OneLineTextWidget(cleint.name,
                      style: context.onPrimaryTextTheme.labelLarge),
                  OneLineTextWidget(cleint.view,
                      style: context.onPrimaryTextTheme.bodySmall),
                ],
              )),
            ],
          ),
        ),
      ],
    );
  }
}

typedef ONWEB3CLIENTTAP = void Function(Web3ClientInfo? client);

class Web3ClientInfoIconView extends StatelessWidget {
  const Web3ClientInfoIconView({super.key, required this.client, required this.onTap});
  final LastWeb3ActiveClient client;
  final ONWEB3CLIENTTAP onTap;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: client.web3Status.inProgress,
      child: IconButton(
        onPressed: () {
          switch (client.web3Status) {
            case WalletJSScriptStatus.unknownHost:
              context.showAlert("unable_to_verify_page_origin".tr);
              break;
            case WalletJSScriptStatus.failed:
              context.showAlert("page_didnot_work_as_expected".tr);
              break;
            default:
              onTap(client.client?.client);
              break;
          }
        },
        icon: ConditionalWidget(
          enable: client.client != null,
          onActive: (context) => _Web3ClientInfoIcon(
              icon: switch (client.web3Status) {
                WalletJSScriptStatus.active => const Icon(Icons.link),
                WalletJSScriptStatus.block => const Icon(Icons.block),
                WalletJSScriptStatus.progress => Opacity(
                    opacity: APPConst.disabledOpacity, child: Icon(CustomIcons.web3)),
                _ => Icon(Icons.error)
              },
              client: client.client?.client),
          onDeactive: (context) => switch (client.web3Status) {
            WalletJSScriptStatus.progress =>
              Opacity(opacity: APPConst.disabledOpacity, child: Icon(CustomIcons.web3)),
            _ => Icon(Icons.error)
          },
        ),
      ),
    );
  }
}

class _Web3ClientInfoIcon extends StatelessWidget {
  final Widget icon;
  final Web3ClientInfo? client;
  const _Web3ClientInfoIcon({required this.icon, required this.client});

  @override
  Widget build(BuildContext context) {
    return APPImageView(
      client?.image,
      radius: APPConst.circleRadius12,
      onLoading: {
        APPImageLoaderStatus.loading: (context) => icon,
        APPImageLoaderStatus.failed: (context) => icon,
        APPImageLoaderStatus.nullImage: (context) => icon
      },
    );
  }
}
