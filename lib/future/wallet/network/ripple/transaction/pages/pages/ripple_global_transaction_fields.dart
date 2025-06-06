import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';

import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/pages/pages/build_currency_amount.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:xrpl_dart/xrpl_dart.dart';
import 'package:on_chain_wallet/future/wallet/network/forms/forms.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class RippleGlobalTransactionFieldsView extends StatelessWidget {
  const RippleGlobalTransactionFieldsView(
      {required this.field,
      required this.account,
      required this.address,
      required this.validator,
      super.key});
  final TransactionFormField field;
  final ChainAccount address;
  final RippleChain account;
  final RippleTransactionForm validator;
  @override
  Widget build(BuildContext context) {
    switch (field.id) {
      case "burn_token_id":
      case "offer_token_id":
      case "accept_offer_sell_offer":
      case "accept_offer_buy_offer":
        return ContainerWithBorder(
          validate: field.isCompleted,
          onRemove: () {
            context
                .openSliverBottomSheet<String>(
                  validator.validatorName.tr,
                  child: StringWriterView(
                    defaultValue: field.value,
                    maxLength: RippleConst.rippleTranactionHashLength,
                    minLength: RippleConst.rippleTranactionHashLength,
                    title: PageTitleSubtitle(
                        title: field.name.tr,
                        body: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(field.subject!.tr),
                          ],
                        )),
                    buttonText: "setup_input".tr,
                    label: field.name.tr,
                  ),
                )
                .then(
                  (value) => validator.setValue(field, value),
                );
          },
          onRemoveIcon: AddOrEditIconWidget(field.hasValue),
          child: Text(
            field.value ?? "tap_to_input_value".tr,
            maxLines: 3,
            style: context.onPrimaryTextTheme.bodyMedium,
          ),
        );
      case "burn_owner":
      case "offer_owner":
      case "offer_destination":
      case "mint_issuer":
      case "escrow_create_destination":
      case "escrow_finish_owner":
      case "regular_key":
        return ReceiptAddressView(
          address: field.value,
          validate: field.isCompleted,
          title: null,
          onTap: () {
            context
                .selectAccount<XRPAddress>(
                    account: account, title: field.name.tr)
                .then((value) => validator.setValue(field, value?.firstOrNull));
          },
        );
      case "mint_nftokentaxon":
        return ContainerWithBorder(
          validate: field.isCompleted,
          onRemoveIcon: AddOrEditIconWidget(field.hasValue),
          onRemove: () {
            context
                .openSliverBottomSheet<BigRational>(
                  validator.validatorName.tr,
                  child: NumberWriteView(
                    defaultValue: field.value,
                    max: RippleConst.max32UnsignedRational,
                    allowDecimal: false,
                    allowSign: false,
                    title: PageTitleSubtitle(
                        title: field.name.tr,
                        body: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(field.subject!.tr),
                          ],
                        )),
                    buttonText: "setup_input".tr,
                    label: field.name.tr,
                  ),
                )
                .then((value) => validator.setValue(field, value));
          },
          child: Text(
            field.value?.toString().to3Digits ?? "tap_to_input_value".tr,
            style: context.onPrimaryTextTheme.bodyMedium,
          ),
        );
      case "mint_transfer_fee":
      case "escrow_create_destination_tag":
      case "escrow_finish_sequence":
      case "trust_set_quality_in":
      case "trust_set_quality_out":
        return ContainerWithBorder(
          onRemoveIcon: AddOrEditIconWidget(field.hasValue),
          validate: field.isCompleted,
          onRemove: () {
            BigRational? max;
            switch (field.id) {
              case "mint_transfer_fee":
                max = RippleConst.maxNftTokenTransferRate;
              case "escrow_create_destination_tag":
              case "trust_set_quality_in":
              case "trust_set_quality_out":
                max = RippleConst.max32UnsignedRational;
                break;
              default:
            }
            context
                .openSliverBottomSheet<BigRational>(
                  validator.validatorName.tr,
                  child: NumberWriteView(
                    defaultValue: field.value,
                    max: max,
                    allowDecimal: false,
                    allowSign: false,
                    title: PageTitleSubtitle(
                        title: field.name.tr,
                        body: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(field.subject!.tr),
                          ],
                        )),
                    buttonText: "setup_input".tr,
                    label: field.name.tr,
                  ),
                )
                .then((value) => validator.setValue(field, value));
          },
          child: Text(
            field.value?.toString().to3Digits ?? "tap_to_input_value".tr,
            style: context.onPrimaryTextTheme.bodyMedium,
          ),
        );
      case "mint_uri":
      case "escrow_create_condition":
      case "escrow_finish_fulfillment":
        return ContainerWithBorder(
          onRemove: () {
            int? maxLength;
            if (field.id == "mint_uri") {
              maxLength = RippleConst.maxDomainLength;
            }
            context
                .openSliverBottomSheet<String>(
                  validator.validatorName.tr,
                  child: StringWriterView(
                    defaultValue: field.value,
                    maxLength: maxLength,
                    title: PageTitleSubtitle(
                        title: field.name.tr,
                        body: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(field.subject!.tr),
                          ],
                        )),
                    buttonText: "setup_input".tr,
                    label: field.name.tr,
                  ),
                )
                .then(
                  (value) => validator.setValue(field, value),
                );
          },
          onRemoveIcon: AddOrEditIconWidget(field.hasValue),
          child: validator.transactionType != XRPLTransactionType.escrowCreate
              ? Text(
                  field.value ?? "tap_to_input_value".tr,
                  maxLines: 3,
                  style: context.onPrimaryTextTheme.bodyMedium,
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                      Expanded(
                          child: Text(
                        field.value ?? "tap_to_input_value".tr,
                        maxLines: 3,
                        style: context.onPrimaryTextTheme.bodyMedium,
                      )),
                      if (!field.hasValue) ...[
                        WidgetConstant.width8,
                        FilledButton(
                          onPressed: () {
                            context
                                .openSliverDialog<String>(
                                    (p0) => const _GenerateFulFillmentView(),
                                    "fulfillment".tr)
                                .then((value) {
                              validator.setValue(field, value);
                            });
                          },
                          child: Text("generate".tr),
                        )
                      ],
                    ]),
        );
      case "mint_flag":
        return AppDropDownBottom(
          items: <NFTokenMintFlag, Widget>{
            for (final i in NFTokenMintFlag.values) i: Text(i.name)
          },
          value: field.value,
          key: ValueKey<String>("set_${field.value}"),
          onChanged: (p0) => validator.setValue(field, p0),
          hint: "none".tr,
          icon: field.hasValue
              ? InkWell(
                  onTap: () {
                    validator.setValue(field, null);
                  },
                  child: const Icon(Icons.remove_circle))
              : null,
        );
      case "offer_expiration":
      case "escrow_create_cancel_after":
        return ContainerWithBorder(
          onRemove: () {
            showAdaptiveDialog<DateTime>(
              context: context,
              useRootNavigator: false,
              builder: (context) {
                return DatePickerDialog(
                  firstDate: DateTime.now(),
                  lastDate: DateTime(3000),
                  fieldLabelText: field.name.tr,
                );
              },
            ).then((date) {
              if (date == null) {
                validator.setValue(field, null);
                return;
              }
              showAdaptiveDialog<TimeOfDay>(
                context: context,
                useRootNavigator: false,
                builder: (context) {
                  return TimePickerDialog(
                    initialTime: TimeOfDay.now(),
                    helpText: date.toOnlyDateStr(),
                  );
                },
              ).then((time) {
                if (time == null) {
                  validator.setValue(field, null);
                  return;
                }
                final DateTime picked = DateTime(
                    date.year, date.month, date.day, time.hour, time.minute);
                validator.setValue(field, picked);
              });
            });
          },
          onRemoveIcon: AddOrEditIconWidget(field.hasValue),
          child: Text(
            (field.value as DateTime?)?.toDateAndTime() ??
                "tap_to_input_value".tr,
            style: context.onPrimaryTextTheme.bodyMedium,
          ),
        );

      case "offer_amount":
      case "accept_nft_broker_fee":
      case "trust_set_limit_amount":
        final XRPCurrencyAmount? value = field.value;
        return ContainerWithBorder(
          validate: field.isCompleted,
          onRemoveIcon: AddOrEditIconWidget(field.hasValue),
          onRemove: () {
            context
                .openSliverBottomSheet<XRPCurrencyAmount>(
                  "setup_currency_amount".tr,
                  bodyBuilder: (controller) => BuildRippleCurrencyAmountView(
                    account: account,
                    scrollController: controller,
                    title: validator.validatorName.tr,
                    acceptZero: true,
                    supportXRP: field.id != "trust_set_limit_amount",
                  ),
                )
                .then((value) => validator.setValue(field, value));
          },
          child: value == null
              ? Text("tap_to_input_value".tr,
                  style: context.onPrimaryTextTheme.bodyMedium)
              : CoinAndMarketPriceView(
                  balance: value.price,
                  style: context.onPrimaryTextTheme.titleMedium,
                  symbolColor: context.onPrimaryContainer,
                ),
        );
      case "nft_offer_flag":
        return AppDropDownBottom(
          items: <NftTokenCreateOfferFlag, Widget>{
            for (final i in NftTokenCreateOfferFlag.values) i: Text(i.name)
          },
          value: field.value,
          key: ValueKey<String>("set_${field.value}"),
          onChanged: (p0) => validator.setValue(field, p0),
          hint: "none".tr,
          icon: field.hasValue
              ? InkWell(
                  onTap: () {
                    validator.setValue(field, null);
                  },
                  child: const Icon(Icons.remove_circle))
              : null,
        );
      case "trust_set_flags":
        return AppDropDownBottom(
          items: <TrustSetFlag, Widget>{
            for (final i in TrustSetFlag.values) i: Text(i.name)
          },
          value: field.value,
          key: ValueKey(field.value),
          onChanged: (v) {
            validator.setValue(field, v);
          },
          hint: "none".tr,
          icon: field.hasValue
              ? InkWell(
                  onTap: () {
                    validator.setValue(field, null);
                  },
                  child: const Icon(Icons.remove_circle))
              : null,
        );
      case "cancel_nft_nft_token_offers":
        final TransactionFormField<List<String>> f =
            field as TransactionFormField<List<String>>;

        return AnimatedSize(
          duration: APPConst.animationDuraion,
          child: Column(
            key: ValueKey<int?>(f.value?.length),
            children: [
              ...List.generate(f.value?.length ?? 0, (index) {
                final v = f.value![index];
                return ContainerWithBorder(
                  validate: field.isCompleted,
                  onRemove: () {
                    validator.removeIndex(
                        field as TransactionFormField<List<String>>, index);
                  },
                  onRemoveIcon: Icon(Icons.remove_circle,
                      color: context.onPrimaryContainer),
                  child: OneLineTextWidget(v,
                      style: context.onPrimaryTextTheme.bodyMedium),
                );
              }),
              ContainerWithBorder(
                validate: field.isCompleted,
                onRemove: () {
                  context
                      .openSliverBottomSheet<String>(
                        validator.validatorName.tr,
                        child: StringWriterView(
                          defaultValue: null,
                          maxLength: RippleConst.rippleTranactionHashLength,
                          minLength: RippleConst.rippleTranactionHashLength,
                          title: PageTitleSubtitle(
                              title: field.name.tr,
                              body: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(field.subject!.tr),
                                ],
                              )),
                          buttonText: "setup_input".tr,
                          label: field.name.tr,
                        ),
                      )
                      .then((value) => validator.setListValue(
                          field as TransactionFormField<List<String>>, value));
                },
                onRemoveIcon: Icon(
                  Icons.add,
                  color: context.onPrimaryContainer,
                ),
                child: Text("tap_to_input_value".tr,
                    maxLines: 3, style: context.onPrimaryTextTheme.bodyMedium),
              )
            ],
          ),
        );
      case "escrow_create_amount":
        return ContainerWithBorder(
            validate: field.isCompleted,
            onRemove: () {
              context
                  .setupAmount(
                      title: validator.validatorName.tr,
                      token: account.network.coinParam.token,
                      max: account.address.address.currencyBalance)
                  .then(
                (value) {
                  if (value == null) {
                    validator.setValue(field, null);
                  } else {
                    validator.setValue(field,
                        IntegerBalance.token(value, account.network.token));
                  }
                },
              );
            },
            onRemoveIcon: AddOrEditIconWidget(field.hasValue),
            child: !field.hasValue
                ? Text("tap_to_enter_amount".tr,
                    style: context.onPrimaryTextTheme.bodyMedium)
                : CoinAndMarketPriceView(
                    balance: field.value,
                    style: context.onPrimaryTextTheme.titleMedium,
                    symbolColor: context.onPrimaryContainer,
                  ));

      default:
        return const Text(
          "unsuported field",
          style: TextStyle(fontSize: 25, color: Colors.red),
        );
    }
  }
}

class _GenerateFulFillmentView extends StatefulWidget {
  const _GenerateFulFillmentView();

  @override
  State<_GenerateFulFillmentView> createState() =>
      _GenerateFulFillmentViewState();
}

class _GenerateFulFillmentViewState extends State<_GenerateFulFillmentView>
    with SafeState {
  final GlobalKey<StreamWidgetState> progressKey = GlobalKey();
  FulfillmentPreimageSha256? fulFillment;
  void generateFulFillment() async {
    if (progressKey.inProgress) return;
    if (fulFillment != null) {
      fulFillment = null;
      setState(() {});
      await MethodUtils.wait(duration: Duration(milliseconds: 400));
    }
    progressKey.process();

    final result = await MethodUtils.call(() async {
      final rand = QuickCrypto.generateRandom();
      final fullFillment = FulfillmentPreimageSha256.generate(rand);
      return fullFillment;
    }, delay: APPConst.oneSecoundDuration);
    if (result.hasError) {
      progressKey.error();
    } else {
      fulFillment = result.result;
      progressKey.success();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitleSubtitle(
            title: "create_random_fulfillment".tr,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("fulfillment_desc".tr),
                WidgetConstant.height8,
                Text("fulfillment_desc2".tr)
              ],
            )),
        APPAnimatedSize(
          duration: APPConst.animationDuraion,
          isActive: fulFillment == null,
          onActive: (context) => WidgetConstant.sizedBox,
          onDeactive: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("fulfillment".tr, style: context.textTheme.titleMedium),
              WidgetConstant.height8,
              ContainerWithBorder(
                  child: CopyableTextWidget(
                      text: fulFillment!.fulfillment,
                      isSensitive: true,
                      color: context.onPrimaryContainer)),
              WidgetConstant.height20,
              Text("condition".tr, style: context.textTheme.titleMedium),
              WidgetConstant.height8,
              ContainerWithBorder(
                  child: CopyableTextWidget(
                      text: fulFillment!.condition,
                      isSensitive: true,
                      color: context.onPrimaryContainer))
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: APPConst.animationDuraion,
              child: Padding(
                padding: WidgetConstant.paddingVertical20,
                child: fulFillment == null
                    ? ButtonProgress(
                        key: progressKey,
                        child: (context) => FilledButton(
                            onPressed: generateFulFillment,
                            child: Text("generate".tr)))
                    : Row(children: [
                        FilledButton(
                            onPressed: () {
                              context
                                  .openSliverDialog<bool>(
                                      (p0) => DialogTextView(
                                            text: "saved_fulfillment_desc".tr,
                                            buttonWidget:
                                                const DialogDoubleButtonView(),
                                          ),
                                      "fulfillment".tr)
                                  .then((value) {
                                if (value == true && context.mounted) {
                                  context.pop(fulFillment?.condition);
                                }
                              });
                            },
                            child: Text("apply_for_condition".tr)),
                        WidgetConstant.width8,
                        IconButton(
                            onPressed: generateFulFillment,
                            icon: const Icon(Icons.refresh))
                      ]),
              ),
            )
          ],
        )
      ],
    );
  }
}
