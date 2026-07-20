import 'package:flutter/material.dart';
import 'package:on_chain/tron/src/address/tron_address.dart';
import 'package:on_chain/tron/src/models/contract/base_contract/transaction_type.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/tron/tron.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/operations/account/account_permission_update.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/networks/tron/models/tron_account_info.dart';

import 'fee.dart';

class TronTransactionAccountPermissionUpdateContractWidget extends StatelessWidget {
  final TronTransactionAccountPermissionUpdateContractOperation form;
  const TronTransactionAccountPermissionUpdateContractWidget(
      {required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return APPStreamBuilder(
        value: form.notifier,
        builder: (context, _) {
          return MultiSliver(children: [
            LiveFormWidget(
              field: form.permission,
              showFieldTitle: !form.permission.hasValue,
              builder: (context, field, value) {
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  APPAnimatedSize(
                      duration: APPConst.animationDuraion,
                      isActive: value != null,
                      onActive: (context) =>
                          _EditPermissionView(validator: value!, form: form),
                      onDeactive: (context) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppDropDownBottom<TronPermissionBuilder?>(
                                  value: value,
                                  key: ValueKey(value),
                                  items: {
                                    for (final i in form.permissions)
                                      i: RichText(
                                          text: TextSpan(
                                              style: context.textTheme.bodyMedium,
                                              text: i.permission.type.name.camelCase,
                                              children: [
                                            if (i.permission.permissionName != null)
                                              TextSpan(
                                                  text:
                                                      " (${i.permission.permissionName}) ",
                                                  style: context.textTheme.bodySmall)
                                          ])),
                                    null: Text(
                                      "choose_a_permission".tr,
                                      style: context.textTheme.bodyMedium,
                                    ),
                                  },
                                  selectedItemBuilder: {
                                    for (final i in form.permissions)
                                      i: RichText(
                                          text: TextSpan(
                                              style: context.textTheme.bodyMedium,
                                              text: i.permission.type.name.camelCase,
                                              children: [
                                            if (i.permission.permissionName != null)
                                              TextSpan(
                                                  text:
                                                      " (${i.permission.permissionName}) ",
                                                  style: context.textTheme.bodySmall)
                                          ])),
                                    null: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_box),
                                        WidgetConstant.width8,
                                        Text("new_active_permission".tr,
                                            style: context.textTheme.bodySmall)
                                      ],
                                    )
                                  },
                                  onChanged: form.onUpdatePermission,
                                  hint: "permissions".tr),
                              WidgetConstant.height20,
                              LiveFormWidgetMemo(
                                  field: form.memo, onUpdateMemo: form.onUpdateMemo),
                              WidgetConstant.height20,
                              TronTransactionFeeDataView(controller: form),
                              TransactionStateSendTransaction(controller: form)
                            ],
                          ))
                ]);
              },
            ),
          ]);
        });
  }
}

class _EditPermissionView extends StatelessWidget {
  const _EditPermissionView({
    required this.validator,
    required this.form,
  });
  AccountPermission get permission => validator.permission;
  final TronPermissionBuilder validator;
  final TronTransactionAccountPermissionUpdateContractOperation form;
  @override
  Widget build(BuildContext context) {
    return APPStreamBuilder(
        value: validator.notifier,
        builder: (context, value) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WidgetConstant.height20,
              Text("permission_type".tr, style: context.textTheme.titleMedium),
              WidgetConstant.height8,
              ContainerWithBorder(
                  child: Text(permission.type.name.camelCase,
                      style: context.onPrimaryTextTheme.bodyMedium)),
              WidgetConstant.height20,
              Text("permission_name".tr, style: context.textTheme.titleMedium),
              Text("input_the_permission_name".tr),
              WidgetConstant.height8,
              ContainerWithBorder(
                onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
                onRemove: () {
                  context
                      .openSliverBottomSheet<String>(
                        "update_account_permission".tr,
                        child: StringWriterView(
                            defaultValue: permission.permissionName,
                            title: PageTitleSubtitle(
                                title: "permission_name".tr,
                                body: Text("input_the_permission_name".tr)),
                            buttonText: "setup_input".tr,
                            label: "permission_name".tr),
                      )
                      .then(validator.onUpdatePermissionName);
                },
                child: Text(permission.permissionName ?? "tap_to_input_value".tr,
                    style: context.onPrimaryTextTheme.bodyMedium),
              ),
              WidgetConstant.height20,
              Text("threshold".tr, style: context.textTheme.titleMedium),
              Text("tron_threshhold_desc".tr),
              WidgetConstant.height8,
              ContainerWithBorder(
                  child: NumberTextField(
                      label: "threshold".tr,
                      onChangeValue: validator.onUpdateTheresHold,
                      defaultValue: validator.permission.threshold.toInt(),
                      max: TronUtils.maxPermissionThreshhold,
                      min: 1)),
              if (!permission.isWitnessPermission) ...[
                WidgetConstant.height20,
                Text("operations".tr, style: context.textTheme.titleMedium),
                Text("tron_operations_desc".tr),
                WidgetConstant.height8,
                ContainerWithBorder(
                  onRemove: permission.isActivePermission
                      ? () {
                          context.openDialogPage('',
                              child: (context) =>
                                  _TronSelectPermissionContact(validator));
                        }
                      : null,
                  onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
                  child:
                      ConditionalWidgets(enable: validator.canUpdateOperations, widgets: {
                    false: (context) => Text("all_operations".tr,
                        style: context.onPrimaryTextTheme.bodyMedium),
                    true: (context) => Text(
                        "n_item_selected"
                            .tr
                            .replaceOne(validator.operations.length.toString()),
                        style: context.onPrimaryTextTheme.bodyMedium),
                  }),
                ),
              ],
              WidgetConstant.height20,
              Text("tron_permission_key".tr, style: context.textTheme.titleMedium),
              Text("tron_permission_key_desc".tr),
              WidgetConstant.height8,
              ...List.generate(validator.permission.keys.length, (index) {
                return CustomizedContainer(
                    iconAlginment: CrossAxisAlignment.start,
                    enableTap: false,
                    onTapStackIcon: () {
                      validator.onRemoveSigner(validator.permission.keys[index]);
                    },
                    onStackIcon: Icons.remove_circle,
                    reverseColor: context.onPrimaryContainer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OneLineTextWidget(
                            validator.permission.keys[index].address.toAddress(),
                            style: context.onPrimaryTextTheme.bodyMedium),
                        Divider(color: context.onPrimaryContainer),
                        NumberTextField(
                            label: "weight".tr,
                            onChangeValue: (p0) {
                              validator.updateKeyThereshHold(
                                  validator.permission.keys[index], p0);
                            },
                            max: TronUtils.maxPermissionThreshhold,
                            defaultValue: validator.permission.keys[index].weight.toInt(),
                            min: 1),
                      ],
                    ));
              }),
              if (validator.permission.keys.length < 5)
                ContainerWithBorder(
                  validate: validator.error == null,
                  onRemoveIcon: Icon(Icons.add_box, color: context.onPrimaryContainer),
                  child: Text("tap_to_input_new_signer".tr,
                      style: context.onPrimaryTextTheme.bodyMedium),
                  onRemove: () {
                    context
                        .selectAccount<TronAddress>(
                            account: form.account,
                            title: "signer".tr,
                            onFilterAccount: validator.filterAccount)
                        .then(
                      (value) {
                        validator.onAddNewSigner(value?.firstOrNull);
                      },
                    );
                  },
                ),
              ErrorTextContainer(error: validator.error),
              Padding(
                padding: WidgetConstant.paddingVertical40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FixedElevatedButton.icon(
                      onPressed: form.onSavePermission,
                      activePress: validator.error == null,
                      label: Text("update_permission".tr),
                      icon: const Icon(Icons.save),
                    ),
                    if (permission.isActivePermission) ...[
                      WidgetConstant.width8,
                      FixedElevatedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: Text("remove_permission".tr),
                        onPressed: form.onRemovePermission,
                      )
                    ]
                  ],
                ),
              )
            ],
          );
        });
  }
}

class _TronSelectPermissionContact extends StatefulWidget {
  final TronPermissionBuilder builder;
  const _TronSelectPermissionContact(this.builder);

  @override
  State<_TronSelectPermissionContact> createState() =>
      __TronSelectPermissionContactState();
}

class __TronSelectPermissionContactState extends State<_TronSelectPermissionContact> {
  List<TransactionContractType> get permissions => widget.builder.operations;
  bool get allSelected => permissions.length == TronUtils.supportedOperations.length;
  @override
  Widget build(BuildContext context) {
    return APPStreamBuilder(
        value: widget.builder.notifier,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text("operations".tr),
                actions: [
                  TextButton.icon(
                    onPressed: () {
                      widget.builder.onTogglePermissions();
                    },
                    label: Text("choose_all".tr),
                    icon: ConditionalWidget(
                      enable: widget.builder.allOperationSelected,
                      onActive: (context) => Icon(Icons.check_box),
                      onDeactive: (context) => Icon(Icons.check_box_outline_blank),
                    ),
                  ),
                ],
              ),
              SliverConstraintsBoxView(
                  padding: WidgetConstant.paddingHorizontal10,
                  sliver: SliverList.builder(
                    itemBuilder: (context, index) {
                      final contract = TronUtils.supportedOperations[index];
                      return ContainerWithBorder(
                        onRemove: () {
                          widget.builder.onUpdateOperations(contract);
                        },
                        onRemoveIcon: APPCheckBox(
                          value: permissions.contains(contract),
                          color: context.primaryContainer,
                          backgroundColor: context.onPrimaryContainer,
                          onChanged: (p0) {},
                          ignoring: true,
                        ),
                        child: Text(contract.name,
                            style: context.onPrimaryTextTheme.bodyMedium),
                      );
                    },
                    itemCount: TronUtils.supportedOperations.length,
                  ))
            ],
          );
        });
  }
}
