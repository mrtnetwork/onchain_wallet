import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/ton/ton.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/transaction/types/transfer.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/transaction/widgets/token_list.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/constant/networks/ton.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/jetton.dart';
import 'package:ton_dart/ton_dart.dart';
import 'fee.dart';

class TonTransactionTransferWidget extends StatelessWidget {
  final TonTransactionTransferOperation form;
  const TonTransactionTransferWidget({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      LiveFormWidgetList(
        field: form.recipients,
        onCreate: (context, field) {
          if (!form.allowAddTransfer) return null;
          return ContainerWithBorder(
            validate: field.hasValue,
            onRemove: () {
              context
                  .selectAccount<TonAddress>(
                      account: form.account,
                      multipleSelect: true,
                      onFilterAccount: form.filterAccount)
                  .then(
                    (value) =>
                        form.onUpdateRecipients(value, (err) => context.showAlert(err)),
                  );
            },
            onRemoveIcon: Icon(Icons.add_box, color: context.onPrimaryContainer),
            child: Text("tap_to_add_new_receipment".tr,
                style: context.onPrimaryTextTheme.bodyMedium),
          );
        },
        builder: (context, field, receiver) {
          return APPStreamBuilder(
            value: receiver.notifier,
            builder: (context, value) {
              return ContainerWithBorder(
                iconAlginment: CrossAxisAlignment.start,
                onRemoveIcon:
                    Icon(Icons.remove_circle, color: context.onPrimaryContainer),
                validate: receiver.isReady,
                onRemove: () {},
                enableTap: false,
                onRemoveWidget: IconButton(
                    onPressed: () {
                      context
                          .openSliverDialog<bool>(
                              widget: (p0) => DialogTextView(
                                    text: "remove_recipient_desc".tr,
                                    buttonWidget: const DialogDoubleButtonView(),
                                  ),
                              label: "remove_recipient".tr)
                          .then((remove) {
                        if (remove != true) return;
                        form.onRemoveRecipients(receiver);
                      });
                    },
                    icon: Icon(Icons.remove_circle, color: context.onPrimaryContainer)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ContainerWithBorder(
                        backgroundColor: context.onPrimaryContainer,
                        child: ReceiptAddressDetailsView(
                            address: receiver.recipient,
                            color: context.colors.primaryContainer)),
                    ContainerWithBorder(
                        onRemove: () {
                          context
                              .setupAmount(
                                  token: receiver.networkToken,
                                  max: form.getMaxInput(receiver))
                              .then((amount) {
                            form.onUpdateBalance(receiver, amount);
                          });
                        },
                        validate: receiver.hasAmount,
                        onRemoveIcon: Icon(Icons.edit, color: context.primaryContainer),
                        backgroundColor: context.colors.onPrimaryContainer,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CoinAndMarketPriceView(
                                balance: receiver.amount,
                                style: context.primaryTextTheme.titleMedium,
                                symbolColor: context.colors.primaryContainer,
                                showTokenImage: true),
                            APPAnimated(
                                isActive: receiver.hasToken,
                                onActive: (context) => AlertTextContainer(
                                    message: "ton_jetton_transfer_ton_amount_desc".tr)),
                          ],
                        )),
                    APPAnimated(
                      isActive: true,
                      onActive: (context) => ConditionalWidget(
                          key: ValueKey(receiver.hasToken),
                          enable: receiver.hasToken,
                          onDeactive: (context) => ContainerWithBorder(
                                backgroundColor: context.onPrimaryContainer,
                                onRemove: () {
                                  context
                                      .openSliverBottomSheet<TonJettonToken>(
                                          child: TonTransactionSelectTokenList(
                                            account: form.address,
                                            tokens: form.addressTokens,
                                          ),
                                          "select_token".tr)
                                      .then((jetton) {
                                    form.onUpdateToken(receiver, jetton);
                                  });
                                },
                                onRemoveIcon:
                                    Icon(Icons.add_box, color: context.primaryContainer),
                                child: Text("add_jetton_to_transfer".tr,
                                    style: context.primaryTextTheme.bodyMedium),
                              ),
                          onActive: (context) => ContainerWithBorder(
                                onRemove: () {},
                                enableTap: false,
                                onRemoveIcon: IconButton(
                                    onPressed: () {
                                      form.onRemoveToken(receiver);
                                    },
                                    icon: Icon(Icons.remove_circle,
                                        color: context.primaryContainer)),
                                iconAlginment: CrossAxisAlignment.start,
                                backgroundColor: context.onPrimaryContainer,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ContainerWithBorder(
                                      onRemove: () {
                                        context
                                            .setupAmount(
                                                token: receiver.jetton!.token,
                                                max: form.getTokenMaxInput(receiver))
                                            .then((amount) {
                                          form.onUpdateJettonBalance(receiver, amount);
                                        });
                                      },
                                      validate: receiver.hasTokenAmount,
                                      onRemoveIcon: Icon(Icons.edit,
                                          color: context.onPrimaryContainer),
                                      backgroundColor: context.primaryContainer,
                                      child: CoinAndMarketPriceView(
                                          balance: receiver.tokenBalance,
                                          style: context.onPrimaryTextTheme.titleMedium,
                                          symbolColor: context.onPrimaryContainer,
                                          showTokenImage: true),
                                    ),
                                    APPExpansionListTile(
                                      margin: WidgetConstant.padding5,
                                      color: context.primaryContainer,
                                      reverse: context.onPrimaryContainer,
                                      title: Text("jetton_transfer_options".tr,
                                          style: context.onPrimaryTextTheme.bodyMedium),
                                      children: [
                                        ContainerWithBorder(
                                          backgroundColor: context.onPrimaryContainer,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text("forward_amount".tr,
                                                        style: context.primaryTextTheme
                                                            .titleMedium),
                                                  ),
                                                  WidgetConstant.width8,
                                                  TooltipHelper(
                                                      "ton_total_amount_desc_2".tr,
                                                      iconColor: context.primaryContainer)
                                                ],
                                              ),
                                              WidgetConstant.height8,
                                              ContainerWithBorder(
                                                onRemove: () {
                                                  context
                                                      .setupAmount(
                                                          token: receiver.networkToken,
                                                          max: form.getMaxInput(receiver))
                                                      .then((amount) {
                                                    form.onUpdateForwardBalance(
                                                        receiver, amount);
                                                  });
                                                },
                                                onRemoveIcon: Icon(Icons.edit,
                                                    color: context.onPrimaryContainer),
                                                backgroundColor: context.primaryContainer,
                                                child: CoinAndMarketPriceView(
                                                    balance: receiver.forwardBalance,
                                                    style: context
                                                        .onPrimaryTextTheme.titleMedium,
                                                    symbolColor:
                                                        context.onPrimaryContainer,
                                                    showTokenImage: true),
                                              ),
                                              WidgetConstant.height20,
                                              Text("query_id".tr,
                                                  style: context
                                                      .primaryTextTheme.titleMedium),
                                              WidgetConstant.height8,
                                              ContainerWithBorder(
                                                  backgroundColor:
                                                      context.colors.primaryContainer,
                                                  onRemoveIcon: Icon(Icons.edit,
                                                      color: context
                                                          .colors.onPrimaryContainer),
                                                  onRemove: () {
                                                    context
                                                        .openSliverBottomSheet<
                                                            BigRational>(
                                                      "jetton_transfer_fields".tr,
                                                      child: NumberWriteView(
                                                        defaultValue: BigRational.zero,
                                                        allowDecimal: false,
                                                        customForm: form.queryIdValidator,
                                                        max: TonConst.maxTransferQueryId,
                                                        allowSign: false,
                                                        title: PageTitleSubtitle(
                                                            title: "query_id".tr,
                                                            body: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                TextAndLinkView(
                                                                    text:
                                                                        "arbitrary_request_number"
                                                                            .tr,
                                                                    url: LinkConst
                                                                        .reviewJettonQueryId),
                                                              ],
                                                            )),
                                                        buttonText: "setup_input".tr,
                                                        label: "query_id".tr,
                                                      ),
                                                    )
                                                        .then(
                                                      (value) {
                                                        form.onUpdateQueryId(
                                                            receiver, value);
                                                      },
                                                    );
                                                  },
                                                  child: Text(receiver.queryId.toString(),
                                                      style: context.onPrimaryTextTheme
                                                          .bodyMedium)),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              )),
                    ),

                    // WidgetConstant.height20,
                    APPExpansionListTile(
                      margin: WidgetConstant.padding5,
                      title: Text("message_options".tr,
                          style: context.primaryTextTheme.bodyMedium),
                      color: context.colors.onPrimaryContainer,
                      reverse: context.colors.primaryContainer,
                      children: [
                        ContainerWithBorder(
                          child: TonTransactionMessageSettingsView(
                            receiver: receiver,
                            controller: form,
                            onSubmit: (ctx) {
                              ExpansibleController.of(ctx).collapse();
                              context.showAlert("message_setting_updated".tr);
                            },
                          ),
                        )
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
      WidgetConstant.height20,
      TonTransactionFeeDataView(controller: form),
      TransactionStateSendTransaction(controller: form)
    ]);
  }
}

class TonTransactionMessageSettingsView extends StatefulWidget {
  const TonTransactionMessageSettingsView(
      {required this.receiver,
      required this.controller,
      required this.onSubmit,
      super.key});
  final TonTransferDetails receiver;
  final VoidContext onSubmit;
  final TonTransactionTransferOperation controller;

  @override
  State<TonTransactionMessageSettingsView> createState() =>
      _TonTransactionMessageSettingsViewState();
}

class _TonTransactionMessageSettingsViewState
    extends State<TonTransactionMessageSettingsView>
    with SafeState<TonTransactionMessageSettingsView> {
  late bool isBounce = widget.receiver.bounce;
  late TonMessageBodyType bodyType = widget.receiver.bodyType;
  final GlobalKey<AppTextFieldState> bodyTextController =
      GlobalKey(debugLabel: "_TonTransactionMessageSettingsViewState");
  final GlobalKey<FormState> formKey =
      GlobalKey(debugLabel: "_TonTransactionMessageSettingsViewState_1");
  void toggleBounce() {
    updateState(() {
      isBounce = !isBounce;
    });
  }

  void onChageBodyType(TonMessageBodyType? type) {
    if (type == TonMessageBodyType.encryptedMessage) return;
    updateState(() {
      bodyType = type ?? bodyType;
    });
  }

  String? bodyForm(String? v) {
    if (bodyType == TonMessageBodyType.none) return null;
    if (bodyType.isValid(v)) return null;
    switch (bodyType) {
      case TonMessageBodyType.binaryComment:
        return "invalid_hex_bytes_string".tr;
      case TonMessageBodyType.comment:
        return "ton_message_body_comment_validator".tr;
      default:
        return "ton_invalid_cell_string_data".tr;
    }
  }

  void onPaste(String text) {
    bodyTextController.currentState?.updateText(text);
  }

  void submit() {
    if (formKey.ready()) {
      final body = bodyTextController.currentState?.getValue();
      widget.controller.onUpdateMessageBody(widget.receiver, bodyType, body);
      widget.controller.onUpdateAddressBounce(widget.receiver, isBounce);
      widget.onSubmit(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstraintsBoxView(
      padding: WidgetConstant.paddingHorizontal20,
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: context.primaryContainer,
              child: AppSwitchListTile(
                title: Text("bounce".tr, style: context.onPrimaryTextTheme.titleMedium),
                contentPadding: EdgeInsets.zero,
                subtitle: Text("ton_bounce_desc2".tr,
                    style: context.onPrimaryTextTheme.bodyMedium),
                value: isBounce,
                onChanged: (p0) => toggleBounce(),
              ),
            ),
            WidgetConstant.height20,
            Text("type_of_message_body".tr,
                style: context.onPrimaryTextTheme.titleMedium),
            WidgetConstant.height8,
            AppDropDownBottom(
              items: {
                for (final i in TonMessageBodyType.supportValues) i: Text(i.name.tr)
              },
              hint: "choose_the_type".tr,
              onChanged: onChageBodyType,
              value: bodyType,
            ),
            APPAnimatedSize(
                isActive: bodyType.hasBody,
                onActive: (c) =>
                    _TonBodyBuilderView(state: this, initialValue: widget.receiver.body),
                onDeactive: (c) => WidgetConstant.sizedBox),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FixedElevatedButton(
                    padding: WidgetConstant.paddingVertical40,
                    onPressed: submit,
                    child: Text("update_messsage".tr))
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// The body of the message

class _TonBodyBuilderView extends StatelessWidget {
  const _TonBodyBuilderView({required this.state, this.initialValue});
  final _TonTransactionMessageSettingsViewState state;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WidgetConstant.height20,
        Text(state.bodyType.name.tr, style: context.onPrimaryTextTheme.titleMedium),
        Text(state.bodyType.helperText.tr, style: context.onPrimaryTextTheme.bodyMedium),
        WidgetConstant.height8,
        AppTextField(
            key: state.bodyTextController,
            validator: state.bodyForm,
            label: "message_body".tr,
            minlines: 2,
            maxLines: 8,
            initialValue: initialValue,
            pasteIcon: true,
            helperText: state.bodyType.helperText.tr)
      ],
    );
  }
}
