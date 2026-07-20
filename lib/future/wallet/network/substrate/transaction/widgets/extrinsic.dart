import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/metadata/fields/fields.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/metadata/forms/metadata.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/operations/extrinsic.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/widgets/payload.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/widgets/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/widgets/substrate_transaction_fee.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';

class SubstrateTransactionExtrinsicWidget extends StatelessWidget {
  final SubstrateTransactionExtrinsicOperation form;
  final BuildContext mainContext;
  List<MetadataFormValidator> get payloadFields => form.extrinsicPayloadValidators;
  List<MetadataFormValidator> get extrinsicFields => form.extrinsicValidators;
  const SubstrateTransactionExtrinsicWidget(
      {required this.form, required this.mainContext, super.key});

  @override
  Widget build(BuildContext context) {
    return APPStreamBuilder(
      value: form.page.live,
      builder: (context, value) {
        return APPSliverAnimatedSwitcher(enable: value, widgets: {
          BuildExtrinsicPage.payload: (context) => _CreatePayload(field: form),
          BuildExtrinsicPage.extrinsic: (context) => _CreateExtrinsic(field: form),
          BuildExtrinsicPage.review: (context) =>
              _Review(field: form, mainContext: mainContext)
        });
      },
    );
  }
}

class _CreatePayload extends StatelessWidget {
  List<MetadataFormValidator> get payloadFields => field.extrinsicPayloadValidators;
  List<MetadataFormValidator> get extrinsicFields => field.extrinsicValidators;
  final SubstrateTransactionExtrinsicOperation field;
  const _CreatePayload({required this.field});
  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      Text("payload".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      ...payloadFields.map((i) => SubstrateMetadataValidatorView(
            validator: i,
            account: field.account,
            metadata: field.metadata,
          )),
      _SubstrateTransactionStateSendTransaction(
          controller: field, name: 'create_payload'.tr, onTap: field.onCreatePayload)
    ]);
  }
}

class _CreateExtrinsic extends StatelessWidget {
  List<MetadataFormValidator> get extrinsicFields => field.extrinsicValidators;
  final SubstrateTransactionExtrinsicOperation field;
  const _CreateExtrinsic({required this.field});
  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      SubstrateShowPayloadInfoView(
          payload: field.payload, onEditPayload: field.onEditPayload),
      WidgetConstant.height20,
      Text("extrinsic".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      ...extrinsicFields.map((i) => SubstrateMetadataValidatorView(
            validator: i,
            account: field.account,
            metadata: field.metadata,
          )),
      _SubstrateTransactionStateSendTransaction(
          controller: field, name: 'create_extrinsic'.tr, onTap: field.onCreateExtrinsic)
    ]);
  }
}

class _Review extends StatelessWidget {
  List<MetadataFormValidator> get extrinsicFields => field.extrinsicValidators;
  final SubstrateTransactionExtrinsicOperation field;
  final BuildContext mainContext;
  const _Review({required this.field, required this.mainContext});
  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      SubstrateShowPayloadInfoView(
          payload: field.payload, onEditPayload: field.onEditPayload),
      WidgetConstant.height20,
      Text("extrinsic".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      ContainerWithBorder(
          child: LargeTextContainer(
              text: field.payload.serializedExtrinsic,
              color: context.onPrimaryContainer,
              maxLines: 3)),
      WidgetConstant.height20,
      // TransactionFeeView(
      //   controller: field,
      //   onRetryFeeEstimate: () => field.estimateFee(),
      // ),
      SubstrateTransactionFeeWidget(
        fee: field.txFee,
        onRetryFeeEstimate: field.estimateFee,
      ),
      SubstrateTransactionStateSendTransaction(
          controller: field, mainContext: mainContext)
    ]);
  }
}

class _SubstrateTransactionStateSendTransaction extends StatelessWidget {
  final TransactionStateController controller;
  final String name;
  final DynamicVoid onTap;
  const _SubstrateTransactionStateSendTransaction(
      {required this.controller, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return APPStreamBuilder(
        value: controller.stateStatus,
        builder: (context, value) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ErrorTextContainer(error: value.error),
            AlertTextContainer(message: value.warning),
            Padding(
              padding: WidgetConstant.paddingVertical40,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                FixedElevatedButton(
                    onPressed: onTap, activePress: true, child: Text(name))
              ]),
            )
          ]);
        });
  }
}
