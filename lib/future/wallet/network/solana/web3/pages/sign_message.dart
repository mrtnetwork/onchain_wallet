import 'package:flutter/material.dart';
import 'package:on_chain/ethereum/src/eip_4361/types/eip_4631.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/web3_request_page_builder.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/web3/operations/sign_message.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/web3/types/types.dart';
import 'package:on_chain_wallet/web3/web3/networks/solana/params/models/sign_message.dart';

class Web3SolanaSignMessageStateView extends StatelessWidget {
  final Web3SolanaSignMessageStateController controller;
  const Web3SolanaSignMessageStateView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final messages = controller.messages;
    // final info = transactionData.transactionInfo;
    return MultiSliver(children: [
      ContainerWithBorder(
          backgroundColor: context.colors.errorContainer,
          enableTap: false,
          child: Row(
            children: [
              Icon(
                Icons.warning,
                color: context.colors.error,
                size: APPConst.double40,
              ),
              WidgetConstant.width8,
              Expanded(
                child: Text("sign_message_private_key_desc".tr,
                    style: context.textTheme.bodyMedium
                        ?.copyWith(color: context.colors.onErrorContainer)),
              ),
            ],
          )),
      WidgetConstant.height20,
      SliverList.separated(
          itemBuilder: (context, index) {
            final message = messages[index];
            return _SignMessageItemView(message: message);
          },
          separatorBuilder: (context, index) {
            return WidgetConstant.divider;
          },
          itemCount: messages.length),
      Web3StateAcceptRequestView(
          controller: controller,
          title: messages.length == 1 ? "sign_message".tr : "sign_messages".tr),
    ]);
  }
}

class _SignMessageItemView extends StatelessWidget {
  final Web3SolanaSignParamsData message;
  const _SignMessageItemView({required this.message});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("account".tr, style: context.textTheme.titleMedium),
      Text("web3_request_account_desc".tr),
      WidgetConstant.height8,
      ContainerWithBorder(
          child: AddressDetailsView(
              address: message.address, color: context.onPrimaryContainer)),
      WidgetConstant.height20,
      Text("message".tr, style: context.textTheme.titleMedium),
      Text("sign_message_private_key".tr),
      WidgetConstant.height8,
      ContainerWithBorder(
          onRemove: () {},
          enableTap: false,
          onRemoveWidget: WidgetConstant.sizedBox,
          child: CopyableTextWidget(text: message.params.data, isSensitive: false)),
      if (message.params.content != null) ...[
        WidgetConstant.height20,
        Text("content".tr, style: context.textTheme.titleMedium),
        ContainerWithBorder(
          onRemove: () {},
          onRemoveWidget: WidgetConstant.sizedBox,
          enableTap: false,
          child: CopyableTextWidget(
            text: message.params.content!,
            widget: SelectableText(
              message.params.content!,
              style: context.onPrimaryTextTheme.bodyMedium,
              minLines: 1,
              maxLines: 5,
            ),
            isSensitive: false,
            maxLines: 10,
          ),
        ),
      ],
      ConditionalWidget(
          enable: message.isSignIn,
          onActive: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WidgetConstant.height20,
                  Text("sign_in_data".tr, style: context.textTheme.titleMedium),
                  WidgetConstant.height8,
                  ContainerWithBorder(
                    child: APPExpansionListTile(
                      title: Text('content'.tr,
                          style: context.onPrimaryTextTheme.bodyMedium),
                      children: [
                        ContainerWithBorder(
                          child: _EIP4631ContentView(
                              params: message.params as Web3SolanaSignInParams),
                        )
                      ],
                    ),
                  ),
                ],
              ))
    ]);
  }
}

class _EIP4631ContentView extends StatelessWidget {
  final Web3SolanaSignInParams params;
  EIP4631 get message => params.message;
  const _EIP4631ContentView({required this.params});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('domain'.tr, style: context.onPrimaryTextTheme.titleMedium),
      WidgetConstant.height8,
      ContainerWithBorder(
          backgroundColor: context.onPrimaryContainer,
          child: CopyableTextWidget(
            text: message.domain,
            color: context.primaryContainer,
          )),
      if (message.hasStatement) ...[
        WidgetConstant.height20,
        Text('statement'.tr, style: context.onPrimaryTextTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            backgroundColor: context.onPrimaryContainer,
            child: CopyableTextWidget(
              text: message.statement!,
              color: context.primaryContainer,
            ))
      ],
      if (message.hasUri) ...[
        WidgetConstant.height20,
        Text('uri'.tr, style: context.onPrimaryTextTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            backgroundColor: context.onPrimaryContainer,
            child: CopyableTextWidget(
              text: message.uri!,
              color: context.primaryContainer,
            ))
      ],
      if (message.hasIssuedAt) ...[
        WidgetConstant.height20,
        Text('issued_at'.tr, style: context.onPrimaryTextTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            backgroundColor: context.onPrimaryContainer,
            child: CopyableTextWidget(
              text: message.issuedAt!,
              color: context.primaryContainer,
            ))
      ],
      if (message.hasNotBefore) ...[
        WidgetConstant.height20,
        Text('not_before'.tr, style: context.onPrimaryTextTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            backgroundColor: context.onPrimaryContainer,
            child: CopyableTextWidget(
              text: message.notBefore!,
              color: context.primaryContainer,
            ))
      ],
      if (message.hasExpirationTime) ...[
        WidgetConstant.height20,
        Text('expiration_time'.tr, style: context.onPrimaryTextTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            backgroundColor: context.onPrimaryContainer,
            child: CopyableTextWidget(
              text: message.expirationTime!,
              color: context.primaryContainer,
            ))
      ],
      if (message.hasNonce) ...[
        WidgetConstant.height20,
        Text('nonce'.tr, style: context.onPrimaryTextTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            backgroundColor: context.onPrimaryContainer,
            child: CopyableTextWidget(
              text: message.nonce!,
              color: context.primaryContainer,
            ))
      ],
      if (message.hasVersion) ...[
        WidgetConstant.height20,
        Text('version'.tr, style: context.onPrimaryTextTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            backgroundColor: context.onPrimaryContainer,
            child: CopyableTextWidget(
              text: message.version!,
              color: context.primaryContainer,
            ))
      ],
      if (message.hasRequestId) ...[
        WidgetConstant.height20,
        Text('request_id'.tr, style: context.onPrimaryTextTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            backgroundColor: context.onPrimaryContainer,
            child: CopyableTextWidget(
              text: message.requestId!,
              color: context.primaryContainer,
            ))
      ],
      if (message.hasResources) ...[
        WidgetConstant.height20,
        Text('resources'.tr, style: context.onPrimaryTextTheme.titleMedium),
        WidgetConstant.height8,
        ...List.generate(message.resources!.length, (i) {
          final resource = message.resources![i];
          return ContainerWithBorder(
              backgroundColor: context.onPrimaryContainer,
              child: CopyableTextWidget(
                text: resource,
                color: context.primaryContainer,
              ));
        }),
      ],
    ]);
  }
}
