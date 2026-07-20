import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/others/models/receipt_address.dart';

class ReceiptAddressView extends StatelessWidget {
  const ReceiptAddressView(
      {this.address,
      this.onTap,
      this.title = "recipient",
      super.key,
      this.subtitle,
      this.validate,
      this.onEditIcon,
      this.onEditWidget,
      this.enableTap = true});
  final ReceiptAddress? address;
  final DynamicVoid? onTap;
  final String? title;
  final String? subtitle;
  final bool? validate;
  final Icon? onEditIcon;
  final Widget? onEditWidget;
  // final String? errorText;
  final bool enableTap;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(title?.tr ?? "recipient".tr, style: context.textTheme.titleMedium),
          if (subtitle != null) LargeTextView([subtitle!], maxLine: 2),
          WidgetConstant.height8,
        ],
        ContainerWithBorder(
          validate: validate ?? (address != null),
          onRemove: onTap,
          enableTap: enableTap,
          onRemoveWidget: onEditWidget,
          onRemoveIcon: address == null
              ? Icon(Icons.add_box, color: context.onPrimaryContainer)
              : onEditIcon ?? Icon(Icons.edit, color: context.onPrimaryContainer),
          child: APPAnimated(
            isActive: true,
            onActive: (context) => ConditionalWidget(
              key: ValueKey(address),
              enable: address != null,
              onDeactive: (context) => FullWidthWrapper(
                child: Text("tap_to_choose_address".tr,
                    style: context.onPrimaryTextTheme.bodyMedium),
              ),
              onActive: (context) => CopyableTextWidget(
                  text: address?.view ?? "",
                  widget: ReceiptAddressDetailsView(
                      address: address!, color: context.onPrimaryContainer),
                  color: context.onPrimaryContainer),
            ),
          ),
        )
      ],
    );
  }
}

class ReceiptAddressDetailsView extends StatelessWidget {
  const ReceiptAddressDetailsView(
      {required this.address, super.key, required this.color, this.accountLable});
  final ReceiptAddress address;
  final Color color;
  // final bool focus;
  final InlineSpan? accountLable;

  @override
  Widget build(BuildContext context) {
    final lable = accountLable;
    final contact = address.contact;
    final type = address.type;
    final accountName = address.account?.accountName;
    final account = address.account;
    final bool hasLable =
        lable != null || contact != null || type != null || accountName != null;

    final labelStyle = context.textTheme.labelLarge?.copyWith(color: color);
    final bodyStyle = context.textTheme.bodyMedium?.copyWith(color: color);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConditionalWidget(
            enable: hasLable,
            onActive: (context) => RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(style: labelStyle, children: [
                  if (lable != null) ...[
                    lable,
                    TextSpan(text: " "),
                  ],
                  if (accountName != null)
                    TextSpan(text: accountName, style: labelStyle)
                  else if (contact != null)
                    TextSpan(children: [
                      WidgetSpan(
                          child: Icon(
                        Icons.contacts,
                        size: labelStyle?.fontSize ?? APPConst.smallIconSize,
                        color: color,
                      )),
                      TextSpan(text: " "),
                      TextSpan(text: contact.name, style: labelStyle)
                    ])
                  else if (type != null)
                    TextSpan(text: type.tr, style: labelStyle)
                ]))),
        RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(style: bodyStyle, children: [
              if (account != null) ...[
                WidgetSpan(
                    child: AddressDerivationKeyIcon(
                  account.derivationIndex,
                  color: color,
                  size: context.textTheme.bodyMedium?.fontSize ?? APPConst.smallIconSize,
                )),
                TextSpan(text: " ")
              ],
              TextSpan(text: address.view, style: bodyStyle)
            ])),
      ],
    );
  }
}
