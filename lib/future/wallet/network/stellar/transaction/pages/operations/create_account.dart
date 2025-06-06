import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/constant/global/app.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/models/models.dart';
import 'package:stellar_dart/stellar_dart.dart';
import 'operation_destination_tracker.dart';

class CreateAccountOperationView extends StatefulWidget {
  final StellarTransactionStateController controller;
  final StellarCreateAccountOperation? operation;
  const CreateAccountOperationView(
      {required this.controller, this.operation, super.key});

  @override
  State<CreateAccountOperationView> createState() =>
      _CreateAccountOperationViewState();
}

class _CreateAccountOperationViewState extends State<CreateAccountOperationView>
    with SafeState, StellarOperationDestinationTracker {
  StellarTransactionStateController get controller => widget.controller;
  StellarChain get chain => controller.account;
  @override
  late final StellarPickedIssueAsset asset = StellarPickedIssueAsset(
      asset: StellarAssetNative(), network: chain.network, issueToken: null);
  late final IntegerBalance remindAmount = IntegerBalance.zero(asset.token);
  late IntegerBalance amount = IntegerBalance.zero(chain.network.token);
  bool isReady = false;
  bool showLimit = false;

  @override
  StellarClient get client => controller.apiProvider;
  BigInt maximumAmount = BigInt.zero;
  String? balanceError;

  void calculateMaximumAmount() {
    final sameOperations = controller.customOperations.where((e) =>
        (e.asset?.asset.type.isNative ?? false) && e != widget.operation);
    final totalStroop = sameOperations.fold(BigInt.zero, (p, c) => p + c.value);
    maximumAmount = chain.address.address.currencyBalance -
        (totalStroop + (controller.fee?.balance ?? BigInt.zero));
  }

  void calculateRemindAmount() {
    final remind = maximumAmount - amount.balance;
    remindAmount.updateBalance(remind);
  }

  void setupAmount(BigInt? amount) {
    if (amount == null) return;
    this.amount.updateBalance(amount);
    if (this.amount.balance <
        controller.noneActiveAccountRequiredAmount.balance) {
      balanceError = "stellar_starting_balance_desc"
          .tr
          .replaceOne(controller.noneActiveAccountRequiredAmount.price);
    } else {
      balanceError = null;
    }
    calculateRemindAmount();
    checkIsReady();
    updateState();
  }

  void setupOperation() {
    if (!isReady) return;
    final operation = StellarCreateAccountOperation(
      startingBalance: amount,
      asset: StellarPickedIssueAsset(
          asset: StellarAssetNative(),
          network: chain.network,
          issueToken: null),
      destination: receiver!,
    );
    context.pop(operation);
  }

  void checkIsReady() {
    isReady = receiver != null &&
        !amount.isNegative &&
        !remindAmount.isNegative &&
        balanceError == null &&
        destinationInactiveError == null;
  }

  @override
  void onAccountActivityUpdated() {
    if (receiver?.status.isActive ?? false) {
      destinationInactiveError = "account_is_active".tr;
    } else {
      destinationInactiveError = null;
    }
    checkIsReady();
    updateState();
  }

  void init() {
    try {
      final operation = widget.operation;
      if (operation == null) return;
      receiver = operation.destination;
      trackActivity(receiver!);
      amount = operation.startingBalance.clone();
    } finally {
      calculateMaximumAmount();
      calculateRemindAmount();
      checkIsReady();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    init();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitleSubtitle(
            title: "create_an_account".tr,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("stellar_create_account_operation_desc".tr),
                if (widget.operation != null) ...[
                  WidgetConstant.height8,
                  Text("remove_operation_close_page_desc".tr)
                ]
              ],
            )),
        ReceiptAddressView(
          enableTap: receiver == null,
          address: receiver?.address,
          onEditWidget: receiver == null
              ? null
              : Row(
                  children: [
                    IconButton(
                        onPressed: () {
                          context
                              .selectAccount<StellarAddress>(account: chain)
                              .then((value) => setReceiver(value?.firstOrNull));
                        },
                        icon: Icon(Icons.edit,
                            color: context.onPrimaryContainer)),
                    IconButton(
                        tooltip: receiver!.status.message?.tr,
                        onPressed: () {
                          trackActivity(receiver!);
                        },
                        icon: StatusIconWidget(
                          status: receiver!.status.toProgressStatus,
                          size: APPConst.iconSize,
                          onSuccessIcon: receiver!.status.isInactive
                              ? Icon(Icons.no_accounts_rounded,
                                  color: context.onPrimaryContainer)
                              : Icon(Icons.account_circle,
                                  color: context.onPrimaryContainer),
                        ))
                  ],
                ),
          onTap: () {
            context
                .selectAccount<StellarAddress>(account: chain)
                .then((v) => setReceiver(v?.firstOrNull));
          },
        ),
        WidgetConstant.height20,
        TransactionAmountView(
          amount: amount,
          token: asset.token,
          title: "starting_balance".tr,
          subtitle: "stellar_create_account_starting_balance_desc".tr,
          onTap: () {
            context
                .setupAmount(token: asset.token, max: maximumAmount)
                .then(setupAmount);
          },
        ),
        InsufficientBalanceErrorView(
            verticalMargin: WidgetConstant.paddingVertical10,
            balance: remindAmount),
        ErrorTextContainer(
            error: balanceError ?? destinationInactiveError,
            verticalMargin: WidgetConstant.paddingVertical10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          FixedElevatedButton(
              padding: WidgetConstant.paddingVertical40,
              onPressed: isReady ? setupOperation : null,
              child: Text("setup_operation".tr))
        ])
      ],
    );
  }
}
