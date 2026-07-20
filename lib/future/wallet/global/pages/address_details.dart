import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class AddressDetailsView extends StatelessWidget {
  const AddressDetailsView(
      {required this.address,
      this.chain,
      super.key,
      this.showBalance = true,
      this.color,
      this.title});
  final ChainAccount address;
  final Chain? chain;
  final bool showBalance;
  final Color? color;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final accountName = title ?? address.accountName;
    final accountType = address.type?.tr;
    final labelStyle = context.textTheme.labelLarge?.copyWith(color: color);
    final currentAccount = chain?.addressSyncOrNull == address;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(style: labelStyle, children: [
              if (currentAccount) ...[
                WidgetSpan(
                    child: ToolTipView(
                        message: "current_account_address".tr,
                        child: Icon(
                          Icons.circle,
                          size: context.textTheme.bodyMedium?.fontSize ??
                              APPConst.smallIconSize,
                          color: color,
                        ))),
                TextSpan(text: " "),
              ],
              WidgetSpan(
                  child: AddressDerivationKeyIcon(
                address.derivationIndex,
                color: color,
                size: context.textTheme.bodyMedium?.fontSize ?? APPConst.smallIconSize,
              )),
              TextSpan(text: " "),
              if (accountName != null)
                TextSpan(text: accountName, style: labelStyle)
              else if (accountType != null)
                TextSpan(text: accountType, style: labelStyle)
              else
                TextSpan(text: address.derivationIndex.typName(), style: labelStyle)
            ])),
        OneLineTextWidget(
          address.address,
          style: context.textTheme.bodyMedium?.copyWith(color: color),
        ),
        ConditionalWidget(
            enable: showBalance,
            onActive: (context) => Column(children: [
                  WidgetConstant.height8,
                  CoinAndMarketLivePriceView(
                      liveBalance: address.addressData.balance,
                      style: context.textTheme.titleMedium?.copyWith(color: color),
                      showTokenImage: true,
                      symbolColor: color),
                ]))
      ],
    );
  }
}

class ContactAddressView extends StatelessWidget {
  const ContactAddressView({super.key, required this.contact, this.color});
  final NetworkContact contact;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OneLineTextWidget(contact.name,
            style: context.textTheme.labelLarge?.copyWith(color: color)),
        if (contact.type != null)
          Text(contact.type!.tr,
              style: context.textTheme.bodySmall?.copyWith(color: color)),
        OneLineTextWidget(contact.address,
            style: context.textTheme.bodyMedium?.copyWith(color: color)),
      ],
    );
  }
}

class AddressDrivationInfo extends StatelessWidget {
  const AddressDrivationInfo(this.keyIndex,
      {this.overridePath, this.color, this.style, super.key});
  final DerivationIndex keyIndex;
  final Color? color;
  final TextStyle? style;
  final String? overridePath;
  @override
  Widget build(BuildContext context) {
    final keyStr = overridePath ?? keyIndex.toString().tr;

    if (keyIndex.isImportedKey) {
      return RichText(
        text: TextSpan(children: [
          WidgetSpan(
              child: AddressDerivationKeyIcon(keyIndex,
                  size: style?.fontSize ?? APPConst.smallIconSize, color: color)),
          TextSpan(
              text: "imported_".tr.replaceOne(keyStr),
              style: style ?? context.textTheme.bodySmall?.copyWith(color: color))
        ]),
      );
    }
    return RichText(
      text: TextSpan(children: [
        WidgetSpan(
            child: AddressDerivationKeyIcon(
          keyIndex,
          size: style?.fontSize ?? APPConst.smallIconSize,
          color: color,
        )),
        TextSpan(
            text: " ${keyStr.tr}",
            style: style ?? context.textTheme.bodySmall?.copyWith(color: color))
      ]),
    );
  }
}

class AddressDerivationKeyIcon extends StatelessWidget {
  const AddressDerivationKeyIcon(this.keyIndex, {this.size, this.color, super.key});
  final DerivationIndex keyIndex;
  final Color? color;
  final double? size;
  @override
  Widget build(BuildContext context) {
    final typeName = keyIndex.typName();
    return ToolTipView(
        message: typeName,
        child: switch (keyIndex) {
          MultiSigAddressIndex() =>
            Icon(Icons.switch_account_rounded, color: color, size: size),
          DerivableIndex index when index.isImportedKey =>
            Icon(Icons.key, color: color, size: size),
          DerivableIndex index when index.subId != null =>
            Icon(Icons.account_balance_wallet_outlined, color: color, size: size),
          _ => Icon(Icons.account_balance_wallet_rounded, color: color, size: size)
        });
  }
}

extension ExtDerivationIndexTranslate on DerivationIndex {
  String typName() {
    switch (this) {
      case MultiSigAddressIndex _:
        return "multisig_address".tr;
      case DerivableIndex keyIndex:
        if (keyIndex.isImportedKey) {
          return "imported_key".tr;
        }
        if (keyIndex.subId != null) {
          return "subwallet".tr;
        }
        return "mainwallet".tr;
    }
  }
}
