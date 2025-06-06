import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';

import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/wallet/network/forms/forms.dart';
import 'package:xrpl_dart/xrpl_dart.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class RippleSetSignerListFieldsView extends StatelessWidget {
  const RippleSetSignerListFieldsView(
      {required this.account,
      required this.address,
      required this.validator,
      super.key});
  final ChainAccount address;
  final RippleChain account;
  final RippleSignerListForm validator;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: APPConst.animationDuraion,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        key: ValueKey(validator.signerEntries.value?.length),
        children: [
          ...List.generate(validator.signerEntries.value?.length ?? 0, (index) {
            final signer = validator.signerEntries.value![index];
            return ContainerWithBorder(
                onRemove: () {
                  validator.removeIndex(validator.signerEntries, index);
                },
                onRemoveIcon: Icon(
                  Icons.remove_circle,
                  color: context.onPrimaryContainer,
                ),
                child: _SignerEntryView(signer: signer));
          }),
          ReceiptAddressView(
            address: null,
            validate: (validator.signerEntries.value?.isNotEmpty ?? false),
            title: null,
            onTap: () {
              context
                  .openSliverBottomSheet<XRPSignerEntries>(
                    validator.validatorName.tr,
                    child: _SetupRippleSignerEntries(account: account),
                  )
                  .then((value) =>
                      validator.setListValue(validator.signerEntries, value));
            },
          ),
          WidgetConstant.height20,
          Text(validator.signerQuorum.name.tr,
              style: context.textTheme.titleMedium),
          Text(validator.signerQuorum.subject!.tr),
          WidgetConstant.height8,
          ContainerWithBorder(
            validate: validator.signerQuorum.isCompleted,
            onRemoveIcon: AddOrEditIconWidget(validator.signerQuorum.hasValue),
            onRemove: () {
              context
                  .openSliverBottomSheet<BigRational>(
                    validator.validatorName.tr,
                    child: NumberWriteView(
                      defaultValue: validator.signerQuorum.value,
                      min: BigRational.zero,
                      max: RippleConst.max32UnsignedRational,
                      allowDecimal: false,
                      allowSign: false,
                      title: PageTitleSubtitle(
                          title: validator.signerQuorum.name.tr,
                          body: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextAndLinkView(
                                  text: validator.signerQuorum.subject!.tr,
                                  url: validator.helperUri),
                            ],
                          )),
                      buttonText: "setup_input".tr,
                      label: validator.signerQuorum.name.tr,
                    ),
                  )
                  .then(
                    (value) =>
                        validator.setValue(validator.signerQuorum, value),
                  );
            },
            child: Text(
                validator.signerQuorum.value?.toString().to3Digits ??
                    "tap_to_input_value".tr,
                style: context.onPrimaryTextTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _SignerEntryView extends StatelessWidget {
  const _SignerEntryView({required this.signer});
  final XRPSignerEntries signer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("account".tr, style: context.onPrimaryTextTheme.labelLarge),
        OneLineTextWidget(signer.address.view,
            style: context.onPrimaryTextTheme.bodyMedium),
        WidgetConstant.height8,
        Text("ripple_signer_weight".tr,
            style: context.onPrimaryTextTheme.labelLarge),
        Text(signer.weight.toString(),
            style: context.onPrimaryTextTheme.bodyMedium)
      ],
    );
  }
}

class _SetupRippleSignerEntries extends StatefulWidget {
  const _SetupRippleSignerEntries({required this.account});
  final RippleChain account;

  @override
  State<_SetupRippleSignerEntries> createState() =>
      _SetupRippleSignerEntriesState();
}

class _SetupRippleSignerEntriesState extends State<_SetupRippleSignerEntries>
    with SafeState {
  ReceiptAddress<XRPAddress>? address;
  BigRational? signerWegith;
  String? walletLocator;

  bool isReady = false;

  void _isReady() {
    isReady = address != null && signerWegith != null;
    setState(() {});
  }

  void onSelectAddress(ReceiptAddress<XRPAddress>? newAddress) {
    address = newAddress;
    _isReady();
  }

  void onSelectWeight(BigRational? sw) {
    if (sw == null ||
        sw.isNegative ||
        sw.isDecimal ||
        sw.isZero ||
        sw > RippleConst.max32UnsignedRational) {
      signerWegith = null;
    } else {
      signerWegith = sw;
    }
    _isReady();
  }

  String? validatorLocator(String? v) {
    final isHash256 = QuickBytesUtils.ensureIsHash256(v);
    if (isHash256 == null) {
      return "hash256_validator".tr;
    }
    return null;
  }

  void onSetLocator(String? locator) {
    walletLocator = QuickBytesUtils.ensureIsHash256(locator);
    _isReady();
  }

  void onSetup() {
    _isReady();
    if (!isReady) return;
    final signer = XRPSignerEntries(
        address: address!, weight: signerWegith!, walletLocator: walletLocator);
    context.pop(signer);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitleSubtitle(
            title: "ripple_signer_entery".tr,
            body: Text(
              "ripple_signer_entery_desc".tr,
            )),
        ReceiptAddressView(
          address: address,
          validate: address != null,
          title: null,
          onTap: () {
            context
                .selectAccount<XRPAddress>(
                    account: widget.account, title: "account".tr)
                .then((v) => onSelectAddress(v?.firstOrNull));
          },
        ),
        WidgetConstant.height20,
        Text("ripple_signer_weight".tr, style: context.textTheme.titleMedium),
        Text("ripple_signer_weight_desc".tr),
        WidgetConstant.height8,
        ContainerWithBorder(
          validate: signerWegith != null,
          onRemoveIcon: AddOrEditIconWidget(signerWegith != null),
          onRemove: () {
            context
                .openSliverBottomSheet<BigRational>(
                  "ripple_signer_enteris_fields".tr,
                  child: NumberWriteView(
                    defaultValue: signerWegith ?? BigRational.one,
                    min: BigRational.one,
                    max: RippleConst.max32UnsignedRational,
                    allowDecimal: false,
                    allowSign: false,
                    title: PageTitleSubtitle(
                        title: "ripple_signer_weight".tr,
                        body: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("ripple_signer_weight_desc".tr),
                          ],
                        )),
                    buttonText: "setup_input".tr,
                    label: "ripple_signer_weight".tr,
                  ),
                )
                .then(onSelectWeight);
          },
          child: Text(
            signerWegith?.toString().to3Digits ?? "tap_to_input_value".tr,
            style: context.onPrimaryTextTheme.bodyMedium,
          ),
        ),
        WidgetConstant.height20,
        Text("ripple_wallet_locator".tr, style: context.textTheme.titleMedium),
        Text("ripple_signer_entry_wallet_locator_desc".tr),
        WidgetConstant.height8,
        ContainerWithBorder(
          onRemove: () {
            context
                .openSliverBottomSheet<String>(
                  "ripple_signer_enteris_fields".tr,
                  child: StringWriterView(
                    defaultValue: walletLocator,
                    maxLength: RippleConst.maxWalletLocatorLength,
                    customForm: validatorLocator,
                    title: PageTitleSubtitle(
                        title: "ripple_wallet_locator".tr,
                        body: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("ripple_signer_entry_wallet_locator_desc".tr),
                          ],
                        )),
                    buttonText: "setup_input".tr,
                    label: "ripple_wallet_locator".tr,
                  ),
                )
                .then(onSetLocator);
          },
          onRemoveIcon: AddOrEditIconWidget(walletLocator != null),
          child: Text(
            walletLocator ?? "tap_to_input_value".tr,
            maxLines: 3,
            style: context.onPrimaryTextTheme.bodyMedium,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FixedElevatedButton(
                  padding: WidgetConstant.paddingVertical40,
                  onPressed: isReady ? onSetup : null,
                  child: Text("setup_signer".tr),
                ),
              ],
            )
          ],
        )
      ],
    );
  }
}
