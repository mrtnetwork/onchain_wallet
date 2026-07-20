import 'package:flutter/material.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/account/controller/account_controller.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class SetupTronMultiSigAddressView extends StatelessWidget {
  const SetupTronMultiSigAddressView({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<TronClient, ITronAddress, TronChain>(
      title: "multi_sig_addr".tr,
      addressRequired: true,
      clientRequired: true,
      childBulder: (wallet, account, client, address) {
        return _SetupTronMultisigAddressView(account: account, client: client);
      },
    );
  }
}

class _SetupTronMultisigAddressView extends StatefulWidget {
  const _SetupTronMultisigAddressView({required this.account, required this.client});
  final TronChain account;
  final TronClient client;
  @override
  State<_SetupTronMultisigAddressView> createState() =>
      __SetupTronMultisigAddressViewState();
}

class __SetupTronMultisigAddressViewState extends State<_SetupTronMultisigAddressView>
    with SafeState<_SetupTronMultisigAddressView> {
  final StreamPageProgressController progressKey = StreamPageProgressController();
  ReceiptAddress<TronAddress>? address;
  WalletTronNetwork get network => widget.account.network;
  TronAccountInfo? account;
  List<AccountPermission> get permissions => account!.permissions;
  AccountPermission? permission;
  List<TransactionContractType>? operations;
  bool get isReady => permission != null && sumOfWeight >= permission!.threshold;
  BigInt sumOfWeight = BigInt.zero;
  final Map<PermissionKeys, TronMultiSigSignerDetais?> signers = {};

  void onSelectAddress(ReceiptAddress<TronAddress>? multiSigAddr) {
    address = multiSigAddr;
    updateState();
  }

  void onSelectPermission(AccountPermission? select) {
    if (select == null) return;
    permission = select;
    if (permission!.operations == null) {
      operations = null;
    } else {
      operations = TronHelper.decodePermissionOperation(permission!.operations!);
    }
    signers.clear();
    sumOfWeight = BigInt.zero;
    for (final i in permission!.keys) {
      signers[i] = null;
    }
    updateState();
  }

  void onRemoveSigner(PermissionKeys signer) {
    signers[signer] = null;
    updateState();
  }

  Future<void> onAddSigner(PermissionKeys signer) async {
    try {
      if (signers[signer] != null) {
        signers[signer] = null;
        return;
      }
      final acc = await context.selectOrSwitchAccount<ITronAddress>(
          account: widget.account, showMultiSig: false);
      if (acc == null) return;
      if (acc.multiSigAccount) {
        context.showAlert("unavailable_multi_sig_public_key".tr);
        return;
      }
      if (acc.networkAddress.toAddress() != signer.address.toAddress()) {
        context.showAlert("account_does_not_match_with_signer_account".tr);
        return;
      }
      if (signers[signer] != null) {
        context.showAlert("address_already_exist".tr);
        return;
      }

      final newAcc = TronMultiSigSignerDetais(
          publicKey: acc.publicKey,
          derivationIndex: acc.derivationIndex.cast(),
          weight: signer.weight);

      signers.addAll({signer: newAcc});
    } finally {
      sumOfWeight = signers.values.fold<BigInt>(BigInt.zero,
          (previousValue, element) => previousValue + (element?.weight ?? BigInt.zero));
      setState(() {});
    }
  }

  Future<void> onAccountInformation() async {
    if (address == null) return;
    progressKey.progressText("retrieving_account_information".tr);
    final result = await IResult.call(() async {
      return await widget.client.getAccount(address!.networkAddress);
    });
    if (result.isErr) {
      progressKey.errorText(result.unwrapErr().localizationError);
    } else {
      account = result.unwrap();
      if (account == null) {
        progressKey.errorText("account_not_found".tr);
      } else {
        progressKey.backToIdle();
      }
    }
  }

  Future<void> onGenerateAddress() async {
    progressKey.progressText("setup_address".tr);
    final wallet = context.wallet.wallet;

    final accountParams = await IResult.call(() async {
      final newAccountParams = TronMultisigNewAddressParams(
        coin: network.coins.first,
        masterAddress: address!.networkAddress,
        multiSigAccount: TronMultiSignatureAddress(
            signers: signers.values.where((element) => element != null).toList().cast(),
            threshold: permission!.threshold,
            permissionID: permission!.id),
      );
      return newAccountParams;
    });
    if (accountParams.isErr) {
      progressKey.errorText(accountParams.unwrapErr().localizationError);
    } else {
      final result = await wallet.doAction(WalletActionDeriveNewAccount(
          newAccountParams: accountParams.unwrap(), chain: widget.account));
      if (result.isErr) {
        progressKey.errorText(result.unwrapErr().localizationError);
      } else {
        progressKey.success(
            backToIdle: false,
            progressWidget: SuccessWithButtonView(
              buttonWidget: ContainerWithBorder(
                  margin: WidgetConstant.paddingVertical8,
                  child: AddressDetailsView(address: result.unwrap())),
              buttonText: "close".tr,
              onPressed: () {
                if (mounted) {
                  context.pop();
                }
              },
            ));
      }
    }
    setState(() {});
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
      builder: (context) => UnfocusableChild(
        child: Center(
          child: CustomScrollView(
            shrinkWrap: true,
            slivers: [
              SliverToBoxAdapter(
                  child: ConstraintsBoxView(
                      padding: WidgetConstant.paddingHorizontal20,
                      child: AnimatedSwitcher(
                          duration: APPConst.animationDuraion,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PageTitleSubtitle(
                                  title: "multi_sig_addr".tr,
                                  body: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("tron_multi_sig_desc".tr),
                                    ],
                                  )),
                              APPAnimatedSwitcher(
                                duration: APPConst.animationDuraion,
                                enable: account != null,
                                width: context.mediaQuery.size.width,
                                widgets: {
                                  true: (context) => Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        key: const ValueKey<bool>(true),
                                        children: [
                                          Text("permissions".tr,
                                              style: context.textTheme.titleMedium),
                                          Text("tron_multi_sig_select_permission".tr),
                                          WidgetConstant.height8,
                                          AppDropDownBottom(
                                              items: {
                                                for (final i in permissions)
                                                  i: RichText(
                                                      text: TextSpan(
                                                          style: context
                                                              .textTheme.bodyMedium,
                                                          text: i.type.name.camelCase,
                                                          children: [
                                                        if (i.permissionName != null)
                                                          TextSpan(
                                                              text:
                                                                  " (${i.permissionName}) ",
                                                              style: context
                                                                  .textTheme.bodySmall)
                                                      ]))
                                              },
                                              hint: "permissions".tr,
                                              onChanged: onSelectPermission),
                                          APPAnimatedSize(
                                            duration: APPConst.animationDuraion,
                                            isActive: permission != null,
                                            onDeactive: (context) =>
                                                WidgetConstant.sizedBox,
                                            onActive: (context) => Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                WidgetConstant.height20,
                                                Text("threshold".tr,
                                                    style: context.textTheme.titleMedium),
                                                WidgetConstant.height8,
                                                ContainerWithBorder(
                                                    child: Text(
                                                        permission!.threshold.toString(),
                                                        style: context.onPrimaryTextTheme
                                                            .bodyMedium)),
                                                WidgetConstant.height20,
                                                Text("operations".tr,
                                                    style: context.textTheme.titleMedium),
                                                WidgetConstant.height8,
                                                ContainerWithBorder(
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                            permission?.operations ??
                                                                "all_operations".tr,
                                                            style: context
                                                                .onPrimaryTextTheme
                                                                .bodyMedium),
                                                      ),
                                                      if (operations != null) ...[
                                                        WidgetConstant.width8,
                                                        ToolTipView(
                                                            waitDuration: null,
                                                            tooltipWidget: (c) =>
                                                                TooltipConstrainsWidget(
                                                                    child: Wrap(
                                                                  alignment: WrapAlignment
                                                                      .spaceBetween,
                                                                  runSpacing: 2.5,
                                                                  spacing: 2.5,
                                                                  children: List.generate(
                                                                      operations!.length,
                                                                      (index) =>
                                                                          Container(
                                                                            padding:
                                                                                WidgetConstant
                                                                                    .padding5,
                                                                            decoration: BoxDecoration(
                                                                                color: context
                                                                                    .colors
                                                                                    .surface,
                                                                                borderRadius:
                                                                                    WidgetConstant
                                                                                        .border8),
                                                                            width: 120,
                                                                            child: OneLineTextWidget(
                                                                                TransactionContractType
                                                                                    .values[
                                                                                        index]
                                                                                    .name,
                                                                                style: context
                                                                                    .textTheme
                                                                                    .bodySmall),
                                                                          )),
                                                                )),
                                                            child: Icon(Icons.help,
                                                                color: context
                                                                    .onPrimaryContainer))
                                                      ]
                                                    ],
                                                  ),
                                                ),
                                                WidgetConstant.height20,
                                                Text("tron_permission_key".tr,
                                                    style: context.textTheme.titleMedium),
                                                Text("tron_multi_sig_addres_threshhold"
                                                    .tr),
                                                WidgetConstant.height8,
                                                ...List.generate(permission!.keys.length,
                                                    (index) {
                                                  final signerEntries =
                                                      permission!.keys.toList();
                                                  final key = signerEntries[index];
                                                  final signerAccount = signers[key];
                                                  return CustomizedContainer(
                                                    onTapStackIcon: () {
                                                      onAddSigner(key);
                                                    },
                                                    enableTap: false,
                                                    onStackWidget: APPCheckBox(
                                                        backgroundColor:
                                                            context.primaryContainer,
                                                        color: context.onPrimaryContainer,
                                                        value: signerAccount != null,
                                                        onChanged: (value) {
                                                          onAddSigner(key);
                                                        }),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        ContainerWithBorder(
                                                          backgroundColor:
                                                              context.onPrimaryContainer,
                                                          child: Text(
                                                              key.address.toAddress(),
                                                              style: context
                                                                  .primaryTextTheme
                                                                  .bodyMedium),
                                                        ),
                                                        ContainerWithBorder(
                                                          backgroundColor:
                                                              context.onPrimaryContainer,
                                                          child: Text(
                                                              key.weight.toString(),
                                                              style: context
                                                                  .primaryTextTheme
                                                                  .bodyMedium),
                                                        )
                                                      ],
                                                    ),
                                                  );
                                                }),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              FixedElevatedButton(
                                                padding: WidgetConstant.paddingVertical40,
                                                onPressed:
                                                    isReady ? onGenerateAddress : null,
                                                child: Text("generate_address".tr),
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                                  false: (context) => Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ReceiptAddressView(
                                            title: "account".tr,
                                            subtitle: "tron_multi_sig_desc2".tr,
                                            onTap: () {
                                              context
                                                  .selectAccount<TronAddress>(
                                                      account: widget.account,
                                                      title: "account".tr)
                                                  .then((v) =>
                                                      onSelectAddress(v?.firstOrNull));
                                            },
                                            address: address,
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              FixedElevatedButton(
                                                  padding:
                                                      WidgetConstant.paddingVertical20,
                                                  onPressed: address == null
                                                      ? null
                                                      : onAccountInformation,
                                                  child:
                                                      Text("get_account_information".tr))
                                            ],
                                          )
                                        ],
                                      )
                                },
                              ),
                            ],
                          )))),
            ],
          ),
        ),
      ),
    );
  }
}
