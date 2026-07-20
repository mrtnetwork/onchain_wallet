import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/widgets/widgets/json/json/widgets.dart';
import 'package:on_chain_wallet/wallet/models/networks/substrate/models/metadata_fields.dart';

class SubstrateShowPayloadInfoWidget extends StatelessWidget {
  final ExtrinsicPayloadInfo payload;
  final Color? backgroundColor;
  const SubstrateShowPayloadInfoWidget(
      {super.key, required this.payload, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final labelStyle = context.textTheme.labelLarge?.copyWith(color: backgroundColor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("payload_info".tr, style: labelStyle),
        WidgetConstant.height8,
        ContainerWithBorder(
          onRemoveIcon: Icon(Icons.open_in_full, color: context.onPrimaryContainer),
          onRemove: () {
            context.openDialogPage('',
                child: (context) =>
                    JsonView(text: payload.payloadInfo!, title: 'payload_info'.tr));
          },
          child: Text("content".tr, style: context.onPrimaryTextTheme.bodyMedium),
        ),
        WidgetConstant.height20,
        Text("serialized_call".tr, style: labelStyle),
        WidgetConstant.height8,
        ContainerWithBorder(
            child: LargeTextContainer(
                text: payload.method, color: context.onPrimaryContainer)),
        WidgetConstant.height20,
        Text("serialized_data".tr, style: labelStyle),
        WidgetConstant.height8,
        ContainerWithBorder(
            child: LargeTextContainer(
                text: payload.serializedExtrinsic, color: context.onPrimaryContainer)),
        WidgetConstant.height20,
        ConditionalWidget(
            enable: payload.payload != payload.serializedExtrinsic,
            onActive: (context) =>
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("payload".tr, style: labelStyle),
                  WidgetConstant.height8,
                  ContainerWithBorder(
                      child: LargeTextContainer(
                          text: payload.payload, color: context.onPrimaryContainer)),
                  WidgetConstant.height20,
                ])),
      ],
    );
  }
}

class SubstrateShowPayloadInfoView extends StatelessWidget {
  final ExtrinsicPayloadInfo payload;
  final DynamicVoid? onEditPayload;
  const SubstrateShowPayloadInfoView(
      {super.key, required this.payload, required this.onEditPayload});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WidgetConstant.height20,
          Text("payload".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          ContainerWithBorder(
            iconAlginment: CrossAxisAlignment.start,
            onRemove: onEditPayload,
            enableTap: false,
            onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
            child: APPExpansionListTile(
              title:
                  Text("payload_info".tr, style: context.onPrimaryTextTheme.bodyMedium),
              tilePadding: EdgeInsets.zero,
              children: [
                ContainerWithBorder(
                  backgroundColor: context.colors.onPrimaryContainer,
                  child: SubstrateShowPayloadInfoWidget(
                    payload: payload,
                    backgroundColor: context.primaryContainer,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
