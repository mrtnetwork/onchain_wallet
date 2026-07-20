import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/operations/transfer.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/widgets/pick_token.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/constant/networks/cosmos.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/cw20.dart';

class CosmosTransactionTransferWidget extends StatelessWidget {
  final CosmosTransactionTransferOperation form;
  const CosmosTransactionTransferWidget({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      LiveFormWidgetList(
        field: form.recipients,
        onCreate: (context, field) => LiveWidgetAddNewTransferDetails<CosmosBaseAddress>(
            onUpdateAddresses: form.onUpdateRecipients,
            account: form.account,
            isReady: field.hasValue,
            multipleSelect: true),
        builder: (context, field, value) => APPStreamBuilder(
          value: value.notifier,
          builder: (context, _) {
            return CustomizedContainer(
              iconAlginment: CrossAxisAlignment.start,
              validate: value.isReady,
              enableTap: false,
              onStackIcon: Icons.remove_circle,
              onTapStackIcon: () => form.onRemoveRecipients(value),
              reverseColor: context.colors.onPrimaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ContainerWithBorder(
                      backgroundColor: context.onPrimaryContainer,
                      child: ReceiptAddressDetailsView(
                        address: value.recipient,
                        color: context.primaryContainer,
                      )),
                  ContainerWithBorder(
                      backgroundColor: context.onPrimaryContainer,
                      onRemove: () {
                        context
                            .openMaxExtendSliverBottomSheet<CW20Token>(
                              "transfer".tr,
                              centerContent: false,
                              bodyBuilder: (sc) => CosmosTransactionPickTokenView(
                                  tokens: form.tokens, controller: sc),
                            )
                            .then((e) =>
                                form.onUpdateRecipientToken(receipt: value, token: e));
                      },
                      onRemoveIcon:
                          Icon(Icons.edit, color: context.colors.primaryContainer),
                      child: AccountTokenDetailsWidget(
                        token: value.token.token,
                        liveBalance: value.token.streamBalance,
                        radius: APPConst.circleRadius25,
                        color: context.colors.primaryContainer,
                      )),
                  ContainerWithBorder(
                      onRemove: () {
                        final max = form.getMaxInput(value);
                        context
                            .setupAmount(token: value.amount.token, max: max)
                            .then((amount) {
                          if (amount == null) return;
                          form.onUpdateAmount(value, amount, amount == max);
                        });
                      },
                      validate: value.hasAmount,
                      onRemoveIcon: Icon(Icons.edit, color: context.primaryContainer),
                      backgroundColor: context.onPrimaryContainer,
                      child: CoinAndMarketPriceView(
                        balance: value.amount,
                        style: context.primaryTextTheme.titleMedium,
                        symbolColor: context.primaryContainer,
                        showTokenImage: true,
                      )),
                ],
              ),
            );
          },
        ),
      ),
      WidgetConstant.height20,
      LiveFormWidgetMemo(
        field: form.memo,
        onUpdateMemo: form.onUpdateMemo,
        onRemoveMemo: form.onRemoveMemo,
      ),
      WidgetConstant.height20,
      TransactionFeeView(
          controller: form,
          onRetryFeeEstimate: form.estimateFee,
          onTapManual: () {
            context
                .openSliverBottomSheet<CosmosTransactionFee>("setup_custom_fee".tr,
                    child: CosmosSetTransferFeeView(
                      currentFee: form.txFee.fee,
                      feeTokens: form.transactionRequirment.feeTokens,
                      max: form.getMaxFeeInput(),
                    ))
                .then(form.setManualFee);
          }),
      TransactionStateSendTransaction(controller: form)
    ]);
  }
}

class CosmosSetTransferFeeView extends StatefulWidget {
  final CosmosTransactionFee currentFee;
  final List<CW20Token> feeTokens;
  final BigInt? max;
  const CosmosSetTransferFeeView(
      {required this.feeTokens, required this.currentFee, super.key, required this.max});
  // final CosmosTransactionFeeController form;

  @override
  State<CosmosSetTransferFeeView> createState() => _CosmosSetTransferFeeViewState();
}

class _CosmosSetTransferFeeViewState extends State<CosmosSetTransferFeeView>
    with SafeState<CosmosSetTransferFeeView> {
  BigInt gasLimit = BigInt.zero;
  CosmosTransactionFee get feeData => widget.currentFee;
  late String denom;
  late Token feeToken = feeData.token;
  BigInt? get max => widget.max;
  late IntegerBalance fee;
  bool isReady = true;

  void setFeeToken(CW20Token? token) {
    if (token == null || token.denom == denom) return;
    denom = token.denom;
    feeToken = token.token;
    fee = IntegerBalance.zero(feeToken);
    checkIsReady();
  }

  void checkIsReady() {
    isReady = fee.largerThanZero && !gasLimit.isNegative;
    updateState();
  }

  void onChangeMaxLimit(BigInt gasLimit) {
    this.gasLimit = gasLimit;
    checkIsReady();
  }

  void setFee(BigInt? fee) {
    if (fee == null) return;
    this.fee.updateBalance(fee);
    checkIsReady();
  }

  void setupFee() {
    if (!isReady) return;
    final fee = CosmosTransactionFee(
        token: feeToken,
        gasLimit: gasLimit,
        fee: this.fee.balance,
        denom: denom,
        type: TxFeeTypes.manually);
    context.pop(fee);
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    gasLimit = feeData.gasLimit;
    feeToken = feeData.token;
    denom = feeData.denom;
    fee = IntegerBalance.token(feeData.fee.balance, feeData.token);
    checkIsReady();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("fee_token".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            onRemove: () {
              context
                  .openMaxExtendSliverBottomSheet<CW20Token>(
                    "fee_token".tr,
                    centerContent: false,
                    bodyBuilder: (sc) => CosmosTransactionPickTokenView(
                        controller: sc, tokens: widget.feeTokens),
                  )
                  .then(setFeeToken);
            },
            onRemoveIcon: Icon(Icons.edit, color: context.colors.onPrimaryContainer),
            child: AccountTokenDetailsWidget(
              token: feeToken,
              radius: APPConst.circleRadius25,
              color: context.colors.onPrimaryContainer,
            )),
        WidgetConstant.height20,
        Text("gas_limit".tr, style: context.textTheme.titleMedium),
        Text("cosmis_fee_limit_desc".tr),
        WidgetConstant.height8,
        BigNumberTextField(
          defaultValue: gasLimit,
          label: "gas_limit".tr,
          min: BigInt.zero,
          max: CosmosConst.maxGasLimit,
          onChange: onChangeMaxLimit,
        ),
        WidgetConstant.height20,
        Text("transaction_fee".tr, style: context.textTheme.titleMedium),
        Text("cost_for_transaction".tr),
        WidgetConstant.height8,
        ContainerWithBorder(
          validate: fee.largerThanZero,
          onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
          onRemove: () {
            context
                .setupAmount(token: feeToken, max: max, title: "transaction_fee".tr)
                .then(setFee);
          },
          child: CoinAndMarketPriceView(
              balance: fee,
              style: context.onPrimaryTextTheme.titleMedium,
              symbolColor: context.onPrimaryContainer),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(
                activePress: isReady,
                padding: WidgetConstant.paddingVertical40,
                onPressed: setupFee,
                child: Text("setup_custom_fee".tr)),
          ],
        )
      ],
    );
  }
}
