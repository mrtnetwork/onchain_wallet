import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/address_details.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class DeleteAccountView extends StatelessWidget {
  const DeleteAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    final Chain account = context.getArgruments();
    return AccessWalletView<WalletCredentialResponseVerify, WalletCredentialVerify>(
        request: WalletCredentialVerify(),
        onAccsess: (credential) {
          return _DeleteAccountView(account: account);
        },
        title: "remove_account".tr,
        subtitle: PageTitleSubtitle(
            title: "remove_account".tr, body: Text("remove_account_desc".tr)));
  }
}

class _DeleteAccountView extends StatefulWidget {
  const _DeleteAccountView({required this.account});
  final Chain account;

  @override
  State<_DeleteAccountView> createState() => __DeleteAccountViewState();
}

class __DeleteAccountViewState extends State<_DeleteAccountView>
    with SafeState<_DeleteAccountView> {
  final StreamPageProgressController progressKey = StreamPageProgressController();
  bool deleted = false;

  void deleteAccount(bool? accept) async {
    if (accept != true) return;
    progressKey.progressText("remove_account_pls_wait".tr);
    final result = await widget.account.removeAccount(widget.account.addressSync);
    result.watch(
      onErr: (error) => progressKey.errorText(error.localizationError),
      onOk: (value) => progressKey.successText("account_deleted".tr, backToIdle: false),
    );
  }

  @override
  void safeDispose() {
    super.safeDispose();
    progressKey.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamPageProgress(
      controller: progressKey,
      builder: (c) => ConstraintsBoxView(
        padding: WidgetConstant.padding20,
        child: AnimatedSwitcher(
          duration: APPConst.animationDuraion,
          child: SingleChildScrollView(
            child: deleted || !widget.account.haveAddress
                ? Column(
                    key: const ValueKey<bool>(true),
                    children: [
                      PageTitleSubtitle(
                          title: "b_using_web3_secret_defination".tr,
                          body: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextAndLinkView(
                                text: "about_web3_secret_defination".tr,
                                url: LinkConst.aboutWeb3StorageDefination,
                              ),
                              WidgetConstant.height8,
                              Text("about_web3_defination_desc1".tr),
                              WidgetConstant.height8,
                              Text("backup_desc1".tr),
                              WidgetConstant.height8,
                              Text("backup_desc2".tr)
                            ],
                          )),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PageTitleSubtitle(
                          title: "remove_account".tr,
                          body: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("remove_account_desc".tr),
                              WidgetConstant.height8,
                              Text("remove_accounts_desc1".tr),
                              WidgetConstant.height8,
                              Text("backup_private_key_desc".tr)
                            ],
                          )),
                      Text("address_details".tr, style: context.textTheme.titleMedium),
                      WidgetConstant.height8,
                      ContainerWithBorder(
                          child: AddressDetailsView(
                        address: widget.account.addressSync,
                        chain: widget.account,
                      )),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: WidgetConstant.paddingVertical20,
                            child: FixedElevatedButton.icon(
                                label: Text("remove_account".tr),
                                onPressed: () {
                                  context
                                      .openSliverDialog<bool>(
                                        widget: (p0) => DialogTextView(
                                            buttonWidget: DialogDoubleButtonView(
                                              firstButtonLabel: "remove".tr,
                                              secoundButtonLabel: "cancel".tr,
                                            ),
                                            widget: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text("remove_account_desc".tr),
                                              ],
                                            )),
                                        label: "remove_account".tr,
                                      )
                                      .then(deleteAccount);
                                },
                                icon: Icon(Icons.delete, color: context.colors.error)),
                          )
                        ],
                      )
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
