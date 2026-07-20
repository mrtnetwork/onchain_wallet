import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class EraseWalletView extends StatelessWidget {
  const EraseWalletView({super.key});
  @override
  Widget build(BuildContext context) {
    return AccessWalletView<WalletCredentialResponseVerify, WalletCredentialVerify>(
        request: WalletCredentialVerify(),
        onAccsess: (credential) {
          return _EraseWalletView(credential: credential);
        },
        title: "delete_wallet".tr,
        subtitle: PageTitleSubtitle(
            title: "delete_wallet".tr,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("delete_wallet_desc".tr),
                WidgetConstant.height8,
                Text("enter_wallet_password_to_continue".tr),
              ],
            )));
  }
}

class _EraseWalletView extends StatefulWidget {
  const _EraseWalletView({required this.credential});

  final WalletCredentialResponseVerify credential;

  @override
  State<_EraseWalletView> createState() => _EraseWalletViewState();
}

class _EraseWalletViewState extends State<_EraseWalletView>
    with SafeState<_EraseWalletView>, ProgressMixin<_EraseWalletView> {
  List<_ViewWalletData> wallets = [];

  List<_ViewWalletData> _buildWallets() {
    List<_ViewWalletData> wallets = [];
    final wallet = context.wallet.wallet.wallet;
    wallets.add(_ViewWalletData(
        name: wallet.name, subwalletId: null, createdAt: wallet.created.toOnlyDateStr()));
    for (final i in wallet.subWallets) {
      wallets.add(_ViewWalletData(
          name: i.name, subwalletId: i.id, createdAt: i.created.toOnlyDateStr()));
    }
    return wallets;
  }

  late _ViewWalletData wallet;

  Map<_ViewWalletData, Widget> _buildItems() {
    return {
      for (final i in wallets)
        i: Row(
          children: [
            ConditionalWidget(
              enable: i.subwalletId == null,
              onActive: (context) => Icon(Icons.account_balance_wallet),
              onDeactive: (context) => Icon(Icons.account_balance_wallet_outlined),
            ),
            WidgetConstant.width8,
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(i.name, style: context.textTheme.bodyMedium),
                Text(i.createdAt, style: context.textTheme.bodySmall)
              ]),
            )
          ],
        )
    };
  }

  Map<_ViewWalletData, Widget> items = {};
  void onChangeWallet(final _ViewWalletData? wallet) {
    if (wallet == null) return;
    this.wallet = wallet;
    updateState();
  }

  Future<void> onDelete() async {
    final accept = await context.openSliverDialog<bool>(
        widget: (p0) => DialogTextView(
              widget: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(wallet.subwalletId == null
                    ? "delete_main_wallet_desc".tr
                    : "delete_sub_wallet_desc".tr),
                WidgetConstant.height20,
                AlertTextContainer(message: "delete_wallet_alert".tr, enableTap: false)
              ]),
              buttonWidget: const DialogDoubleButtonView(),
            ),
        label: "erase_wallet".tr);
    if (accept != true) return;
    progressKey.progressText("deleting_wallet".tr);
    final model = context.wallet;
    final result = switch (wallet.subwalletId) {
      null => await model.wallet
          .doAction(WalletActionRemoveWallet(credential: widget.credential)),
      int id => await model.wallet
          .doAction(WalletActionRemoveSubWallet(id: id, credential: widget.credential))
    };
    if (result.isErr) {
      progressKey.errorText(result.unwrapErr().localizationError,
          backToIdle: false, showBackButton: true);
    } else {
      if (wallet.subwalletId == null) {
        progressKey.successText("wallet_deleted_success".tr, backToIdle: false);
        await MethodUtils.delayed();
        navigatorKey?.currentContext?.popToHome();
        return;
      }
      progressKey.successText("wallet_deleted_success".tr, backToIdle: true);
    }
  }

  void init() {
    wallets = _buildWallets();
    wallet = wallets.first;
    items = _buildItems();
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    init();
  }

  @override
  Widget build(BuildContext context) {
    return StreamPageProgress(
      controller: progressKey,
      builder: (c) => Center(
        child: CustomScrollView(
          shrinkWrap: true,
          slivers: [
            SliverConstraintsBoxView(
              padding: WidgetConstant.paddingHorizontal20,
              sliver: SliverToBoxAdapter(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  WidgetConstant.height20,
                  PageTitleSubtitle(
                      title: "delete_wallet".tr,
                      body: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("delete_wallet_desc".tr),
                        ],
                      )),
                  AppDropDownBottom(
                      items: items,
                      isDense: false,
                      isExpanded: true,
                      value: wallet,
                      onChanged: onChangeWallet),
                  WidgetConstant.height8,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FixedElevatedButton(
                        padding: WidgetConstant.paddingVertical40,
                        onPressed: () {
                          onDelete();

                          // .then(onDelete);
                        },
                        child: Text("delete_wallet".tr),
                      )
                    ],
                  )
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewWalletData {
  final String name;
  final int? subwalletId;
  final String createdAt;
  _ViewWalletData(
      {required this.name, required this.subwalletId, required this.createdAt});
}
