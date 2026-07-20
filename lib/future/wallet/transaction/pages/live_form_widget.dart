import 'package:blockchain_utils/networks/types/address.dart';
import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/select_or_write_address.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/others/models/receipt_address.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/transaction/types/types.dart';

typedef STREAMBUILERWITHFIELD<T, E> = Widget Function(
    BuildContext context, LiveFormField<T, E> field, T value);

class LiveFormWidget<T extends Object?, E extends Object?> extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final LiveFormField<T, E> field;
  final STREAMBUILERWITHFIELD<T, E> builder;
  final Color? color;
  final bool showFieldTitle;
  const LiveFormWidget(
      {required this.field,
      required this.builder,
      this.showFieldTitle = true,
      this.title,
      this.subtitle,
      this.color,
      super.key});

  @override
  Widget build(BuildContext context) {
    final s = subtitle ?? field.subtitle;
    return ConditionalWidget(
        enable: showFieldTitle,
        onDeactive: (context) => FullWidthWrapper(
            child: APPStreamBuilder(
                value: field.live,
                builder: (context, value) => builder(context, field, value))),
        onActive: (context) =>
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title ?? field.title,
                  style: context.textTheme.titleMedium?.copyWith(color: color)),
              if (s != null)
                Text(s, style: context.textTheme.bodyMedium?.copyWith(color: color)),
              WidgetConstant.height8,
              APPStreamBuilder(
                  value: field.live,
                  builder: (context, value) => builder(context, field, value))
            ]));
  }
}

typedef ONUPDATEAMOUNT = void Function(BigInt amount, bool max);
typedef ONUPDATEAMOUNTMAX = BigInt? Function();
typedef ONUPDATEAMOUNTMIN = BigInt? Function();

class LiveFormWidgetAmount extends StatelessWidget {
  final LiveFormField<IntegerBalance, IntegerBalance> field;
  final ONUPDATEAMOUNT? onUpdateAmount;
  final ONUPDATEAMOUNTMAX? onUpdateAmountMax;
  final ONUPDATEAMOUNTMAX? onUpdateAmountMin;
  final DynamicVoid? onTap;
  final Color? color;
  final Color? reverse;
  final bool showZero;
  const LiveFormWidgetAmount(
      {this.onUpdateAmount,
      this.onTap,
      this.onUpdateAmountMax,
      this.onUpdateAmountMin,
      required this.field,
      this.color,
      this.reverse,
      this.showZero = false,
      super.key});

  @override
  Widget build(BuildContext context) {
    final subtitle = field.subtitle;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(field.title, style: context.textTheme.titleMedium?.copyWith(color: color)),
      if (subtitle != null)
        Text(subtitle, style: context.textTheme.bodyMedium?.copyWith(color: color)),
      WidgetConstant.height8,
      APPStreamBuilder(
        value: field.live,
        builder: (context, value) {
          final bool hasAmount = showZero || field.value.largerThanZero;
          final bool hasCallBack = onTap != null || onUpdateAmount != null;
          return ContainerWithBorder(
              validate: hasAmount && !field.hasError,
              backgroundColor: color,
              onRemove: hasCallBack
                  ? () {
                      final onTap = this.onTap;
                      final onUpdateAmount = this.onUpdateAmount;
                      if (onTap != null) {
                        onTap();
                        return;
                      }
                      if (onUpdateAmount == null) return;
                      final max = onUpdateAmountMax?.call();
                      final min = onUpdateAmountMin?.call();
                      context
                          .setupAmount(token: field.value.token, max: max, min: min)
                          .then((v) {
                        if (v == null) return;
                        onUpdateAmount(v, v == max);
                      });
                    }
                  : null,
              onRemoveIcon: AddOrEditIconWidget(field.hasValue, color: reverse),
              child: ConditionalWidget(
                  enable: hasAmount,
                  onActive: (context) => CoinAndMarketPriceView(
                      balance: field.value,
                      style: context.onPrimaryTextTheme.titleMedium
                          ?.copyWith(color: reverse),
                      showTokenImage: true,
                      symbolColor: reverse ?? context.onPrimaryContainer),
                  onDeactive: (context) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("tap_to_enter_amount".tr,
                              style: context.onPrimaryTextTheme.bodyMedium
                                  ?.copyWith(color: reverse))
                        ],
                      )));
        },
      )
    ]);
  }
}

typedef ONUPDATEDECIMALAMOUNTMAX<T> = T? Function();
typedef ONUPDATEDECIMALAMOUNT<T> = void Function(T amount, bool max);

class LiveFormWidgetBalanceCore<T> extends StatelessWidget {
  final LiveFormField<BalanceCore<T, APPToken>?, BalanceCore<T, APPToken>?> field;
  final ONUPDATEDECIMALAMOUNT<T> onUpdateAmount;
  final ONUPDATEDECIMALAMOUNTMAX<T>? onUpdateAmountMax;
  final ONUPDATEDECIMALAMOUNTMAX<T>? onUpdateAmountMin;
  final DynamicVoid? onTap;
  final bool acceptZero;
  const LiveFormWidgetBalanceCore(
      {required this.onUpdateAmount,
      this.onTap,
      this.onUpdateAmountMax,
      this.onUpdateAmountMin,
      required this.field,
      this.acceptZero = false,
      super.key});

  @override
  Widget build(BuildContext context) {
    final subtitle = field.subtitle;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(field.title, style: context.textTheme.titleMedium),
      if (subtitle != null) Text(subtitle),
      WidgetConstant.height8,
      APPStreamBuilder(
        value: field.live,
        builder: (context, value) {
          if (value == null) return WidgetConstant.sizedBox;
          final bool hasAmount = acceptZero || value.largerThanZero;
          return ContainerWithBorder(
              validate: hasAmount && !field.hasError,
              onRemove: () {
                final onTap = this.onTap;
                if (onTap != null) {
                  onTap();
                  return;
                }

                if (field.value is DecimalBalance) {
                  final T? max = onUpdateAmountMax?.call();
                  final T? min = onUpdateAmountMin?.call();
                  context
                      .openSliverBottomSheet<T>("setup_amount".tr,
                          child: SetupDecimalTokenAmountView(
                              token: value.token as NonDecimalToken,
                              max: max as BigRational?,
                              min: (min ?? BigRational.zero) as BigRational),
                          initiaalExtend: 0.9)
                      .then((v) {
                    if (v == null) return;
                    onUpdateAmount(v, v == max);
                  });
                } else if (field.value is IntegerBalance) {
                  final max = onUpdateAmountMax?.call();
                  final min = onUpdateAmountMin?.call();
                  context
                      .setupAmount(
                          token: value.token as Token,
                          max: max as BigInt?,
                          min: min as BigInt?)
                      .then((v) {
                    if (v == null) return;
                    onUpdateAmount(v as T, v == max);
                  });
                }
              },
              onRemoveIcon: AddOrEditIconWidget(field.hasValue),
              child: ConditionalWidget(
                  enable: hasAmount,
                  onActive: (context) => CoinAndMarketPriceView(
                      balance: value,
                      style: context.onPrimaryTextTheme.titleMedium,
                      showTokenImage: true,
                      symbolColor: context.onPrimaryContainer),
                  onDeactive: (context) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("tap_to_enter_amount".tr,
                              style: context.onPrimaryTextTheme.bodyMedium)
                        ],
                      )));
        },
      )
    ]);
  }
}

typedef ONUPDATEADDRESS<NETWORKADDRESS extends IAddress> = void Function(
    ReceiptAddress<NETWORKADDRESS>? address);
typedef ONUPDATEADDRESSES<NETWORKADDRESS extends IAddress> = void Function(
    List<ReceiptAddress<NETWORKADDRESS>> addresses);

class LiveFormWidgetReceiverAddress<NETWORKADDRESS extends IAddress>
    extends StatelessWidget {
  final bool visibleOnNull;
  final bool removable;
  final LiveFormField<ReceiptAddress<NETWORKADDRESS>?, ReceiptAddress<NETWORKADDRESS>>
      field;
  final APPCHAINADDRESS<NETWORKADDRESS> account;
  final ONUPDATEADDRESS<NETWORKADDRESS>? onUpdateAddress;
  final RECIPIENTFILTER<NETWORKADDRESS>? onFilterAccount;
  const LiveFormWidgetReceiverAddress({
    this.onUpdateAddress,
    required this.field,
    required this.account,
    this.onFilterAccount,
    this.visibleOnNull = true,
    this.removable = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = field.subtitle;
    return APPStreamBuilder(
      value: field.live,
      builder: (context, value) {
        if (!visibleOnNull && value == null) return WidgetConstant.sizedBox;
        final address = value;
        bool hasAddress = address != null;
        final onUpdateAddress = this.onUpdateAddress;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(field.title, style: context.textTheme.titleMedium),
          if (subtitle != null) Text(subtitle),
          WidgetConstant.height8,
          ContainerWithBorder(
            validate: !field.hasError,
            onRemove: onUpdateAddress == null
                ? null
                : () {
                    if (removable && value != null) {
                      onUpdateAddress(null);
                      return;
                    }
                    context
                        .selectAccountNew<NETWORKADDRESS>(
                            account: account, onFilterAccount: onFilterAccount)
                        .then(
                      (value) {
                        final address = value?.firstOrNull;
                        onUpdateAddress(address);
                      },
                    );
                  },
            onRemoveIcon: ConditionalWidget(
                enable: removable,
                onActive: (context) => AddOrRemoveIconWidget(hasAddress),
                onDeactive: (context) => AddOrEditIconWidget(hasAddress)),
            child: APPAnimated(
              isActive: true,
              onActive: (context) => ConditionalWidget(
                  key: ValueKey(address),
                  enable: hasAddress,
                  onDeactive: (context) => FullWidthWrapper(
                        child: Text("tap_to_choose_address".tr,
                            style: context.onPrimaryTextTheme.bodyMedium),
                      ),
                  onActive: (context) => Row(
                        children: [
                          Expanded(
                              child: ReceiptAddressDetailsView(
                            address: address!,
                            color: context.onPrimaryContainer,
                          )),
                          CopyTextIcon(
                              dataToCopy: address.view,
                              color: context.onPrimaryContainer,
                              isSensitive: false)
                        ],
                      )),
            ),
          )
        ]);
      },
    );
  }
}

typedef ONUPDATEMEMO = void Function(String? memo);

class LiveFormWidgetMemo extends StatelessWidget {
  final LiveFormField<String?, String?> field;
  final ONUPDATEMEMO onUpdateMemo;
  final DynamicVoid? onRemoveMemo;
  final NullStringString? validate;

  const LiveFormWidgetMemo(
      {required this.field,
      required this.onUpdateMemo,
      this.onRemoveMemo,
      this.validate,
      super.key});

  @override
  Widget build(BuildContext context) {
    final subtitle = field.subtitle;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(field.title, style: context.textTheme.titleMedium),
      if (subtitle != null) Text(subtitle),
      WidgetConstant.height8,
      APPStreamBuilder(
        value: field.live,
        builder: (context, value) {
          return ContainerWithBorder(
            validate: !field.hasError,
            enableTap: !field.hasValue || onRemoveMemo == null,
            onRemove: () {
              context
                  .openSliverBottomSheet<String>(
                    "transaction_memo".tr,
                    child: StringWriterView(
                        customForm: validate,
                        defaultValue: field.value,
                        title: PageTitleSubtitle(
                            title: "setup_memo".tr,
                            body: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [Text("memo_desc1".tr)],
                            )),
                        buttonText: "setup_memo".tr,
                        label: "memo".tr),
                  )
                  .then(onUpdateMemo);
            },
            onRemoveWidget: ConditionalWidget(
                enable: onRemoveMemo == null,
                onDeactive: (context) {
                  if (field.hasValue) {
                    return IconButton(
                        onPressed: () => onRemoveMemo!(),
                        icon: Icon(Icons.remove_circle,
                            color: context.colors.onPrimaryContainer));
                  }
                  return IgnorePointer(
                    child: IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.add_box,
                            color: context.colors.onPrimaryContainer)),
                  );
                },
                onActive: (context) => AddOrEditIconWidget(value != null)),
            child: APPAnimated(
                onActive: (context) => FullWidthWrapper(
                    key: ValueKey(value?.length),
                    child: Text(value ?? "tap_to_add_memo".tr))),
          );
        },
      )
    ]);
  }
}

typedef LIVEFORMLISTENTRYBUILDER<T extends Object> = Widget Function(
    BuildContext context, LiveFormFields<T> field, T value);
typedef FORMLISTENTRYBUILDER<T extends Object> = Widget Function(
    BuildContext context, T value);
typedef ONCREATENEWLIVEFIELDWIDGET<T extends Object> = Widget? Function(
    BuildContext context, LiveFormFields<T> field);
typedef ONCREATENEWFIELDWIDGET<T extends Object> = Widget? Function(BuildContext context);

class LiveFormWidgetList<T extends Object> extends StatelessWidget {
  final LiveFormFields<T> field;
  final LIVEFORMLISTENTRYBUILDER<T> builder;
  final ONCREATENEWLIVEFIELDWIDGET<T>? onCreate;

  const LiveFormWidgetList(
      {required this.field, required this.builder, this.onCreate, super.key});

  @override
  Widget build(BuildContext context) {
    final subtitle = field.subtitle;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(field.title, style: context.textTheme.titleMedium),
      if (subtitle != null) Text(subtitle),
      WidgetConstant.height8,
      APPStreamBuilder(
        value: field.live,
        builder: (context, value) {
          final onCreateWidget = onCreate?.call(context, field);
          return APPAnimatedSize(
              isActive: true,
              onActive: (context) => ListView(
                    shrinkWrap: true,
                    physics: WidgetConstant.noScrollPhysics,
                    children: [
                      ...List.generate(value.length, (index) {
                        return builder(context, field, value[index]);
                      }),
                      if (onCreateWidget != null) onCreateWidget
                    ],
                  ),
              onDeactive: (context) => WidgetConstant.sizedBox);
        },
      )
    ]);
  }
}

class FormWidgetList<T extends Object> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<T> values;
  final FORMLISTENTRYBUILDER<T> builder;
  final ONCREATENEWFIELDWIDGET<T>? onCreate;

  const FormWidgetList({
    required this.title,
    this.subtitle,
    required this.values,
    required this.builder,
    this.onCreate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final onCreateWidget = onCreate?.call(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: context.textTheme.titleMedium),
      if (subtitle != null) Text(subtitle!),
      WidgetConstant.height8,
      APPAnimatedSize(
          isActive: true,
          onActive: (context) => ListView(
                shrinkWrap: true,
                physics: WidgetConstant.noScrollPhysics,
                children: [
                  ...List.generate(values.length, (index) {
                    return builder(context, values[index]);
                  }),
                  if (onCreateWidget != null) onCreateWidget
                ],
              ),
          onDeactive: (context) => WidgetConstant.sizedBox)
    ]);
  }
}

typedef ONUPDATETRANSFERDETAILSAMOUNT<T extends TransferOutputDetails> = void Function(
    T output, BigInt amount, bool max);
typedef ONUPDATETETRANSFERDETAILSAMOUNTMAX<T extends TransferOutputDetails> = BigInt?
    Function(T output);
typedef ONREMOVETRANSFERDETAILS<T extends TransferOutputDetails> = void Function(
    T output);
typedef ONVALIDATETRANSFER<T> = bool Function(T);

class LiveWidgetTransferDetails<T extends TransferOutputDetails> extends StatelessWidget {
  final T transfer;
  final ONUPDATETRANSFERDETAILSAMOUNT<T> onUpdateAmount;
  final ONUPDATETETRANSFERDETAILSAMOUNTMAX<T>? onUpdateAmountMax;
  final ONREMOVETRANSFERDETAILS<T>? onRemove;
  final ONVALIDATETRANSFER<T>? onValidateTransfer;
  const LiveWidgetTransferDetails(
      {required this.transfer,
      required this.onUpdateAmount,
      required this.onUpdateAmountMax,
      this.onValidateTransfer,
      this.onRemove,
      super.key});

  @override
  Widget build(BuildContext context) {
    return APPStreamBuilder(
      value: transfer.notifier,
      builder: (context, value) {
        final isValid = onValidateTransfer?.call(transfer) ?? true;
        return CustomizedContainer(
          onTapStackIcon: onRemove == null ? null : () => onRemove?.call(transfer),
          onStackIcon: Icons.remove_circle,
          reverseColor: context.colors.onPrimaryContainer,
          validate: transfer.isReady && isValid,
          enableTap: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ContainerWithBorder(
                  backgroundColor: context.onPrimaryContainer,
                  child: ReceiptAddressDetailsView(
                      address: transfer.recipient, color: context.primaryContainer)),
              ContainerWithBorder(
                  onRemove: () {
                    final max = onUpdateAmountMax?.call(transfer);
                    context
                        .setupAmount(token: transfer.amount.token, max: max)
                        .then((amount) {
                      if (amount == null) return;
                      onUpdateAmount(transfer, amount, amount == max);
                    });
                  },
                  validate: transfer.hasAmount,
                  onRemoveIcon: Icon(Icons.edit, color: context.primaryContainer),
                  backgroundColor: context.onPrimaryContainer,
                  child: CoinAndMarketPriceView(
                      balance: transfer.amount,
                      style: context.primaryTextTheme.titleMedium,
                      showTokenImage: true,
                      symbolColor: context.primaryContainer)),
            ],
          ),
        );
      },
    );
  }
}

class LiveWidgetAddNewTransferDetails<NETWORKADDRESS extends IAddress>
    extends StatelessWidget {
  final ONUPDATEADDRESSES<NETWORKADDRESS> onUpdateAddresses;
  final RECIPIENTFILTER<NETWORKADDRESS>? onFilterAccount;
  final APPCHAINADDRESS<NETWORKADDRESS> account;
  final bool multipleSelect;
  final bool isReady;

  const LiveWidgetAddNewTransferDetails(
      {required this.onUpdateAddresses,
      required this.account,
      this.multipleSelect = false,
      this.onFilterAccount,
      this.isReady = true,
      super.key});

  @override
  Widget build(BuildContext context) {
    return ContainerWithBorder(
        validate: isReady,
        onRemove: () {
          context
              .selectAccount<NETWORKADDRESS>(
                  account: account,
                  onFilterAccount: onFilterAccount,
                  multipleSelect: multipleSelect)
              .then((value) {
            if (value == null || value.isEmpty) return;
            onUpdateAddresses(value);
          });
        },
        onRemoveIcon: const Icon(Icons.add_box),
        child: Text("tap_to_add_new_receipment".tr));
  }
}

typedef ONUPDATESTRING = void Function(String?);

class LiveFormWidgetString extends StatelessWidget {
  final LiveFormField<String?, String> field;
  final String fieldName;
  final Widget? title;
  final String? fieldTitle;
  final String? fieldSubtitle;
  final int? minLength;
  final int? maxLength;
  final ONUPDATESTRING onUpdateValue;
  final bool removable;
  final NullStringString? validator;
  const LiveFormWidgetString(
      {required this.onUpdateValue,
      this.removable = false,
      required this.field,
      super.key,
      required this.fieldName,
      this.validator,
      this.title,
      this.minLength,
      this.maxLength,
      this.fieldTitle,
      this.fieldSubtitle});

  @override
  Widget build(BuildContext context) {
    final fTitle = fieldTitle ?? field.title.tr;
    final fSubtitle = fieldSubtitle ?? field.subtitle?.tr;
    return LiveFormWidget(
      field: field,
      title: fieldTitle,
      subtitle: fieldSubtitle,
      builder: (context, field, value) {
        return ContainerWithBorder(
          validate: field.complete,
          onRemove: () {
            if (removable && value != null) {
              onUpdateValue(null);
              return;
            }
            context
                .openSliverBottomSheet<String>(
                  fieldName,
                  child: StringWriterView(
                    defaultValue: field.value,
                    maxLength: maxLength,
                    minLength: minLength,
                    customForm: validator,
                    title: title ??
                        PageTitleSubtitle(
                            title: fTitle,
                            body: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (fSubtitle != null) Text(fSubtitle),
                              ],
                            )),
                    buttonText: "setup_input".tr,
                    label: fTitle,
                  ),
                )
                .then(onUpdateValue);
          },
          onRemoveIcon: ConditionalWidget(
            enable: !removable,
            onDeactive: (context) => AddOrRemoveIconWidget(field.hasValue),
            onActive: (context) => AddOrEditIconWidget(field.hasValue),
          ),
          child: APPAnimated(
              onActive: (context) => FullWidthWrapper(
                  key: ValueKey(value?.length),
                  child: Text(field.value ?? "tap_to_input_value".tr,
                      maxLines: 3, style: context.onPrimaryTextTheme.bodyMedium))),
        );
      },
    );
  }
}

typedef ONUPDATEACCOUNT<ACCOUNT extends ChainAccount> = void Function(ACCOUNT? address);

class LiveFormWidgetAccount<ACCOUNT extends ChainAccount> extends StatelessWidget {
  final bool visibleOnNull;
  final bool removable;
  final bool showMultisigAccount;
  final LiveFormField<ACCOUNT?, ACCOUNT> field;
  final APPCHAINACCOUNT<ACCOUNT> account;
  final ONUPDATEACCOUNT<ACCOUNT>? onUpdateAddress;
  final OnSelectAccountFilter<ACCOUNT>? onFilterAccount;
  const LiveFormWidgetAccount({
    this.onUpdateAddress,
    required this.field,
    required this.account,
    this.onFilterAccount,
    this.visibleOnNull = true,
    this.removable = false,
    this.showMultisigAccount = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = field.subtitle;
    return APPStreamBuilder(
      value: field.live,
      builder: (context, value) {
        if (!visibleOnNull && value == null) return WidgetConstant.sizedBox;
        final address = value;
        bool hasAddress = address != null;
        final onUpdateAddress = this.onUpdateAddress;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(field.title, style: context.textTheme.titleMedium),
          if (subtitle != null) Text(subtitle),
          WidgetConstant.height8,
          CustomizedContainer(
            validate: !field.hasError,
            onRemove: onUpdateAddress == null
                ? null
                : () {
                    if (removable && value != null) {
                      onUpdateAddress(null);
                      return;
                    }
                    context
                        .selectOrSwitchAccount<ACCOUNT>(
                            account: account,
                            filter: onFilterAccount,
                            showMultiSig: showMultisigAccount)
                        .then(
                      (value) {
                        onUpdateAddress(value);
                      },
                    );
                  },
            onRemoveIcon: ConditionalWidget(
                enable: removable,
                onActive: (context) => AddOrRemoveIconWidget(hasAddress),
                onDeactive: (context) => AddOrEditIconWidget(hasAddress)),
            child: APPAnimated(
              isActive: true,
              onActive: (context) => ConditionalWidget(
                  key: ValueKey(address),
                  enable: hasAddress,
                  onDeactive: (context) => FullWidthWrapper(
                        child: Text("tap_to_choose_address".tr,
                            style: context.onPrimaryTextTheme.bodyMedium),
                      ),
                  onActive: (context) => FullWidthWrapper(
                        child: AddressDetailsView(
                          address: address!,
                          color: context.onPrimaryContainer,
                          chain: account,
                        ),
                      )),
            ),
          )
        ]);
      },
    );
  }
}
