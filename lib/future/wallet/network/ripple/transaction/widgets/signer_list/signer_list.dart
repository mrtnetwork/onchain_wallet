import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/operations/signer_list/signer_list.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:xrpl_dart/xrpl_dart.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class RippleTransactionSignerListSetWidget extends StatelessWidget {
  final RippleTransactionSignerListSetOperation form;
  const RippleTransactionSignerListSetWidget({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      LiveFormWidgetList(
        field: form.signerEntries,
        onCreate: (context, field) {
          return ContainerWithBorder(
            onRemoveIcon: Icon(Icons.add_box),
            child: Text("tap_to_input_value".tr,
                style: context.onPrimaryTextTheme.bodyMedium),
            onRemove: () {
              context
                  .openSliverBottomSheet<XRPSignerEntries>(
                    "ripple_signer_list_fields".tr,
                    child: _SetupRippleSignerEntries(account: form.account),
                  )
                  .then((e) => form.onUpdateSignerEntries(e));
            },
          );
        },
        builder: (context, field, value) {
          return ContainerWithBorder(
              onRemove: () {
                form.onRemoveSignerEntries(value);
              },
              onRemoveIcon: Icon(Icons.remove_circle, color: context.onPrimaryContainer),
              child: _SignerEntryView(signer: value));
        },
      ),
      WidgetConstant.height20,
      LiveFormWidget(
        field: form.signerQuorum,
        builder: (context, field, value) {
          return ContainerWithBorder(
              validate: value != null,
              onRemoveIcon: AddOrEditIconWidget(value != null),
              onRemove: () {
                context
                    .openSliverBottomSheet<BigRational>(
                      "ripple_signer_list_fields".tr,
                      child: NumberWriteView(
                        defaultValue: value,
                        min: BigRational.zero,
                        max: RippleConst.max32UnsignedRational,
                        allowDecimal: false,
                        allowSign: false,
                        title: PageTitleSubtitle(
                            title: form.signerQuorum.title,
                            body: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextAndLinkView(
                                    text: form.signerQuorum.subtitle ?? '',
                                    url: RippleConst.aboutSignerList),
                              ],
                            )),
                        buttonText: "setup_input".tr,
                        label: form.signerQuorum.title,
                      ),
                    )
                    .then(form.onUpdateSignerQuorum);
              },
              child: Text(value?.toString().to3Digits ?? "tap_to_input_value".tr,
                  style: context.onPrimaryTextTheme.bodyMedium));
        },
      ),
      WidgetConstant.height20,
      TransactionFeeView(controller: form, onRetryFeeEstimate: form.estimateFee),
      TransactionStateSendTransaction(controller: form)
    ]);
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
        Text("account".tr, style: context.onPrimaryTextTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            backgroundColor: context.onPrimaryContainer,
            child: ReceiptAddressDetailsView(
                address: signer.address, color: context.colors.primaryContainer)),
        WidgetConstant.height20,
        Text("ripple_signer_weight".tr, style: context.onPrimaryTextTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
          backgroundColor: context.onPrimaryContainer,
          child:
              Text(signer.weight.toString(), style: context.primaryTextTheme.bodyMedium),
        )
      ],
    );
  }
}

class _SetupRippleSignerEntries extends StatefulWidget {
  const _SetupRippleSignerEntries({required this.account});
  final XRPChain account;

  @override
  State<_SetupRippleSignerEntries> createState() => _SetupRippleSignerEntriesState();
}

class _SetupRippleSignerEntriesState extends State<_SetupRippleSignerEntries>
    with SafeState<_SetupRippleSignerEntries> {
  ReceiptAddress<XRPBaseAddress>? address;
  BigRational? signerWegith;
  String? walletLocator;

  bool isReady = false;

  void _isReady() {
    isReady = address != null && signerWegith != null;
    updateState();
  }

  void onSelectAddress(ReceiptAddress<XRPBaseAddress>? newAddress) {
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
                .selectAccount<XRPBaseAddress>(
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
                .openMaxExtendSliverBottomSheet<BigRational>(
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
            if (walletLocator != null) {
              onSetLocator(null);
              return;
            }
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
          onRemoveIcon: AddOrRemoveIconWidget(walletLocator != null),
          child: APPAnimated(
              onActive: (context) => FullWidthWrapper(
                  key: ValueKey(walletLocator?.length),
                  child: Text(
                    walletLocator ?? "tap_to_input_value".tr,
                    maxLines: 3,
                    style: context.onPrimaryTextTheme.bodyMedium,
                  ))),
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
