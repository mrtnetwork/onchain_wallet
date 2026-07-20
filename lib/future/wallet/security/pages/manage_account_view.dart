import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class ManageImportedKeysView extends StatelessWidget {
  const ManageImportedKeysView({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessWalletView<WalletCredentialResponseVerify, WalletCredentialVerify>(
        request: WalletCredentialVerify(),
        onAccsess: (credential) {
          return _ImportAccount(credential: credential);
        },
        title: "imported_key".tr,
        subtitle: PageTitleSubtitle(
            title: "manage_imported_key".tr, body: Text("manage_key_desc1".tr)));
  }
}

class _ImportAccount extends StatefulWidget {
  const _ImportAccount({required this.credential});
  final WalletCredentialResponseVerify credential;
  @override
  State<_ImportAccount> createState() => _ImportAccountState();
}

class _ImportAccountState extends State<_ImportAccount> with SafeState<_ImportAccount> {
  final GlobalKey<AppTextFieldState> textFieldState =
      GlobalKey<AppTextFieldState>(debugLabel: "_ImportAccountState");

  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  final GlobalKey<FormState> form = GlobalKey(debugLabel: "_ImportAccountState_2");
  final Set<ViewImportedSecretKey> importedKeys = {};
  Future<void> getAccounts() async {
    final wallet = context.wallet;
    final result = await wallet.wallet.doAction(WalletActionViewImportedAccounts());
    if (result.isErr) {
      progressKey.errorText(result.unwrapErr().localizationError, backToIdle: false);
    } else {
      if (result.unwrap().isEmpty) {
        progressKey.success(
          backToIdle: false,
          progressWidget: SuccessWithTextView(
              text: "no_imported_key_found".tr, icon: Icons.hourglass_empty),
        );
      } else {
        importedKeys.addAll(result.unwrap());
        progressKey.success();
      }
    }
  }

  Future<void> removeKey(ViewImportedSecretKey key) async {
    progressKey.progressText("deleting_key".tr);
    final wallet = context.wallet;
    final result = await wallet.wallet.doAction(
        WalletActionRemoveImportedKey(secretKey: key, credential: widget.credential));
    if (result.isErr) {
      progressKey.errorText(result.unwrapErr().localizationError);
      return;
    }
    importedKeys.clear();
    progressKey.progressText("retrieving_imported_keys_wait".tr);
    getAccounts();
  }

  bool inited = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!inited) {
      inited = true;
      getAccounts();
    }
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
      initialWidget: ProgressWithTextView(text: "retrieving_imported_keys_wait".tr),
      builder: (c) => UnfocusableChild(
        child: CustomScrollView(
          slivers: [
            SliverConstraintsBoxView(
              padding: WidgetConstant.paddingHorizontal20,
              sliver: SliverToBoxAdapter(
                child: Form(
                  key: form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WidgetConstant.height20,
                      PageTitleSubtitle(
                          title: "manage_imported_key".tr,
                          body: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("manage_key_desc1".tr),
                              WidgetConstant.height8,
                              Text("manage_key_desc2".tr)
                            ],
                          )),
                      RichText(
                          text: TextSpan(children: [
                        TextSpan(
                            text: "inventory_keys".tr,
                            style: context.textTheme.titleMedium),
                        TextSpan(
                            text: " (${"public_key".tr}) ",
                            style: context.textTheme.bodySmall)
                      ])),
                      WidgetConstant.height8,
                      ...List.generate(importedKeys.length, (index) {
                        final ViewImportedSecretKey key = importedKeys.elementAt(index);
                        final time = key.created.toDateAndTime();
                        return ContainerWithBorder(
                          onRemove: () {},
                          enableTap: false,
                          onRemoveWidget: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                                onPressed: () {
                                  context
                                      .openSliverDialog<bool>(
                                    widget: (p0) => DialogTextView(
                                        buttonWidget: DialogDoubleButtonView(
                                          firstButtonLabel: "remove".tr,
                                          secoundButtonLabel: "cancel".tr,
                                        ),
                                        widget: Column(
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text("manage_key_desc1".tr),
                                                WidgetConstant.height8,
                                                Text("manage_key_desc2".tr)
                                              ],
                                            )
                                          ],
                                        )),
                                    label: "remove_account".tr,
                                  )
                                      .then((value) {
                                    if (value == true && context.mounted) {
                                      removeKey(key);
                                    }
                                  });
                                },
                                icon: Icon(Icons.delete,
                                    color: context.onPrimaryContainer)),
                            IconButton(
                              onPressed: () {
                                context.to(PageRouter.exportPrivateKey, argruments: key);
                              },
                              icon: Icon(Icons.open_in_new,
                                  color: context.onPrimaryContainer),
                            )
                          ]),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(key.name,
                                        style: context.onPrimaryTextTheme.labelLarge),
                                  ),
                                  Text(time, style: context.onPrimaryTextTheme.bodySmall)
                                ],
                              ),
                              Text(key.id.toString(),
                                  style: context.onPrimaryTextTheme.bodySmall),
                            ],
                          ),
                        );
                      }),
                      WidgetConstant.height20,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
