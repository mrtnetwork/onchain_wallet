import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/ripple/ripple.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/account/controller/account_controller.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

enum _MultiSigPage { account, info }

enum _MultiSigType { regularKey, signerList }

class SetupRippleMutlisigAddressView extends StatelessWidget {
  const SetupRippleMutlisigAddressView({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<XRPNetworkClient, IXRPAddress, XRPChain>(
      title: "multi_sig_addr".tr,
      addressRequired: true,
      clientRequired: true,
      childBulder: (wallet, account, client, address) {
        return _SetupRippleMutlisigAddressView(account: account, client: client);
      },
    );
  }
}

class _SetupRippleMutlisigAddressView extends StatefulWidget {
  const _SetupRippleMutlisigAddressView({required this.account, required this.client});
  final XRPChain account;
  final XRPNetworkClient client;
  @override
  State<_SetupRippleMutlisigAddressView> createState() =>
      _SetupRippleMutlisigAddressViewState();
}

class _SetupRippleMutlisigAddressViewState extends State<_SetupRippleMutlisigAddressView>
    with SafeState<_SetupRippleMutlisigAddressView> {
  late WalletProvider wallet;
  final Map<AccountObjectSignerEntry, RippleMultiSigSignerDetails?> signers = {};
  int sumOfWeight = 0;
  bool get sigerListIsReady => sumOfWeight >= signerList!.signerQuorum;
  final StreamPageProgressController progressKey = StreamPageProgressController();
  _MultiSigPage page = _MultiSigPage.account;
  bool get inInfoPage => page == _MultiSigPage.info;
  _MultiSigType? addressType;
  ReceiptAddress? address;

  String? regularKey;
  XRPAccountObjectEntry? signerList;
  bool get hasRegularKey => pickedRegular != null;
  RippleMultiSignatureAddress? pickedRegular;
  WalletXRPNetwork get network => widget.account.network;

  Future<void> onAddSigner(AccountObjectSignerEntry signer) async {
    try {
      if (signers[signer] != null) {
        signers[signer] = null;
        return;
      }
      final acc = await context.selectOrSwitchAccount<IXRPAddress>(
          account: widget.account, showMultiSig: false);
      if (acc == null) return;
      if (acc.multiSigAccount) {
        context.showAlert("unavailable_multi_sig_public_key".tr);
        return;
      }
      if (acc.networkAddress.toString() != signer.account) {
        context.showAlert("account_does_not_match_with_signer_account".tr);
        return;
      }
      if (signers[signer] != null) {
        context.showAlert("address_already_exist".tr);
        return;
      }

      final newAcc = RippleMultiSigSignerDetails(
          publicKey: acc.publicKey,
          derivationIndex: acc.derivationIndex.cast(),
          weight: signer.signerWeight);

      signers.addAll({signer: newAcc});
    } finally {
      sumOfWeight = signers.values.fold<int>(
          0, (previousValue, element) => previousValue + (element?.weight ?? 0));
      updateState();
    }
  }

  Future<void> onAccountInformation() async {
    final address = this.address;
    if (address == null || progressKey.inProgress) return;
    progressKey.progressText("retrieving_account_information".tr);
    final result = await IResult.call(() async {
      final account = await widget.client
          .getAccountRegularAndSignerList(RippleUtils.ensureClassicAddress(address.view));
      return account;
    });
    if (result.isErr) {
      progressKey.errorText(result.unwrapErr().localizationError);
    } else if (result.ok() == null) {
      progressKey.errorText("ripple_mutlti_sig_address_not_found".tr);
    } else {
      page = _MultiSigPage.info;
      regularKey = result.unwrap()!.$1;
      signerList = result.unwrap()!.$2;
      if (signerList != null) {
        for (final i in signerList!.signerEntries) {
          signers[i] = null;
        }
      }

      progressKey.success();
    }
  }

  Future<void> onSetRegularKey() async {
    final addr = await context.selectOrSwitchAccount<IXRPAddress>(
        account: widget.account, showMultiSig: false);
    if (addr == null || regularKey == null) return;
    if (addr.multiSigAccount) {
      context.showAlert("unavailable_multi_sig_public_key".tr);
      return;
    }
    if (addr.networkAddress.toString() != regularKey) {
      context.showAlert("account_does_not_match_with_signer_account".tr);
      return;
    }
    pickedRegular = RippleMultiSignatureAddress(
        threshold: 1,
        signers: [
          RippleMultiSigSignerDetails(
              derivationIndex: addr.derivationIndex.cast(),
              publicKey: addr.publicKey,
              weight: 1)
        ],
        isRegularKey: true);
    updateState();
  }

  Future<void> onSetupRegularKey() async {
    final pickedRegular = this.pickedRegular;
    if (!hasRegularKey || pickedRegular == null) return;
    progressKey.progressText("setup_address".tr);
    final rippleAddress = XRPBaseAddress(address!.view);
    final addrParam = RippleMultiSigNewAddressParams(
        coin: network.coins.first,
        masterAddress: rippleAddress,
        multiSigAccount: pickedRegular);
    final result = await wallet.wallet.doAction(
        WalletActionDeriveNewAccount(newAccountParams: addrParam, chain: widget.account));
    if (result.isErr) {
      progressKey.errorText(result.unwrapErr().localizationError,
          showBackButton: true, backToIdle: false);
    } else {
      progressKey.successText("address_added_to_accounts".tr, backToIdle: false);
    }
  }

  Future<void> onSetupSignerList() async {
    progressKey.progressText("setup_address".tr);
    final wallet = context.wallet.wallet;
    final accountParams = await IResult.call(() async {
      final rippleAddress =
          XRPBaseAddress(address!.view, chainType: network.coinParam.chainType);
      final newAccountParams = RippleMultiSigNewAddressParams(
        coin: network.coins.first,
        masterAddress: rippleAddress,
        multiSigAccount: RippleMultiSignatureAddress(
            signers: signers.values.where((element) => element != null).toList().cast(),
            threshold: signerList!.signerQuorum,
            isRegularKey: false),
      );
      return newAccountParams;
    });
    if (accountParams.isErr) {
      progressKey.errorText(accountParams.unwrapErr().localizationError,
          showBackButton: true, backToIdle: false);
    } else {
      final result = await wallet.doAction(WalletActionDeriveNewAccount(
          newAccountParams: accountParams.unwrap(), chain: widget.account));
      if (result.isErr) {
        progressKey.errorText(result.unwrapErr().localizationError,
            showBackButton: true, backToIdle: false);
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
    updateState(() {});
  }

  void onSelectAddress(ReceiptAddress? newAddr) {
    address = newAddr;
    updateState();
  }

  void onChangeType(_MultiSigType? type) {
    addressType = type;
    updateState(() {});
  }

  void onBack() {
    page = _MultiSigPage.account;
    updateState();
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    wallet = context.wallet;
  }

  @override
  void safeDispose() {
    super.safeDispose();
    progressKey.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: progressKey.isSuccess || !inInfoPage,
      onPopInvokedWithResult: (didPop, _) {
        if (inInfoPage) onBack();
      },
      child: StreamPageProgress(
        controller: progressKey,
        builder: (context) => UnfocusableChild(
          child: Center(
            child: CustomScrollView(
              shrinkWrap: true,
              slivers: [
                SliverConstraintsBoxView(
                  padding: WidgetConstant.paddingHorizontal20,
                  sliver: SliverToBoxAdapter(
                      child: AnimatedSwitcher(
                          duration: APPConst.animationDuraion,
                          child: AnimatedSwitcher(
                            duration: APPConst.animationDuraion,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                WidgetConstant.height20,
                                PageTitleSubtitle(
                                    title: "multi_sig_addr".tr,
                                    body: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("ripple_multi_sig_address_desc".tr),
                                        if (inInfoPage) ...[
                                          WidgetConstant.height8,
                                          Text("ripple_multi_sig_address_desc2".tr)
                                        ]
                                      ],
                                    )),
                                ConditionalWidget(
                                  enable: inInfoPage,
                                  onActive: (context) => Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    key: ValueKey(page),
                                    children: [
                                      Text("multi_sig_feature_type".tr,
                                          style: context.textTheme.titleMedium),
                                      WidgetConstant.height8,
                                      RadioGroup<_MultiSigType>(
                                          groupValue: addressType,
                                          onChanged: onChangeType,
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                IgnorePointer(
                                                  ignoring: regularKey == null,
                                                  child: RadioListTile<_MultiSigType>(
                                                    title: Text("regular_key".tr),
                                                    value: _MultiSigType.regularKey,
                                                    subtitle: regularKey == null
                                                        ? Text(
                                                            "account_does_not_support_feature"
                                                                .tr)
                                                        : null,
                                                  ),
                                                ),
                                                RadioListTile<_MultiSigType>(
                                                  value: _MultiSigType.signerList,
                                                  title: Text("signer_list".tr),
                                                  subtitle: signerList == null
                                                      ? Text(
                                                          "account_does_not_support_feature"
                                                              .tr)
                                                      : null,
                                                )
                                              ])),
                                      AnimatedSwitcher(
                                        duration: APPConst.animationDuraion,
                                        child: ConditionalWidgets<
                                            _MultiSigType>(enable: addressType, widgets: {
                                          _MultiSigType.regularKey: (context) =>
                                              _RegularKeyFeatureView(
                                                  regularKey: regularKey!,
                                                  onSetupRegularKey: onSetupRegularKey,
                                                  hasRegularKey: hasRegularKey,
                                                  onTapSetup: onSetRegularKey),
                                          _MultiSigType.signerList: (context) =>
                                              _SignerListFeatureView(
                                                  signerQuorum: signerList!.signerQuorum,
                                                  sumOfWeight: sumOfWeight,
                                                  onTapSetup: onSetupSignerList,
                                                  signers: signers,
                                                  onTapSigner: onAddSigner)
                                        }),
                                      )
                                    ],
                                  ),
                                  onDeactive: (context) => Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ReceiptAddressView(
                                          title: "account".tr,
                                          subtitle: "ripple_multi_sig_account_desc".tr,
                                          onTap: () {
                                            context
                                                .selectAccount<XRPBaseAddress>(
                                                    account: widget.account,
                                                    title: "account".tr)
                                                .then((value) =>
                                                    onSelectAddress(value?.firstOrNull));
                                          },
                                          address: address),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          FixedElevatedButton(
                                              padding: WidgetConstant.paddingVertical20,
                                              onPressed: address == null
                                                  ? null
                                                  : onAccountInformation,
                                              child: Text("get_account_information".tr))
                                        ],
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

typedef _OnTapSigner = void Function(AccountObjectSignerEntry);

class _SignerListFeatureView extends StatelessWidget {
  const _SignerListFeatureView(
      {required this.signerQuorum,
      required this.sumOfWeight,
      required this.signers,
      required this.onTapSigner,
      required this.onTapSetup});
  final int signerQuorum;
  final Map<AccountObjectSignerEntry, RippleMultiSigSignerDetails?> signers;
  final int sumOfWeight;
  final _OnTapSigner onTapSigner;
  final DynamicVoid onTapSetup;
  @override
  Widget build(BuildContext context) {
    final bool hasSigner = signerQuorum == sumOfWeight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WidgetConstant.height20,
        PageTitleSubtitle(
            title: "signer_list".tr,
            body: Text("ripple_multi_sig_addres_signer_list_desc".tr)),
        Text("signerquorum".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("${signerQuorum.toString()}/${sumOfWeight.toString()}"),
            Icon(Icons.check_circle,
                color: hasSigner ? context.colors.green : context.colors.disable)
          ]),
        ),
        WidgetConstant.height20,
        Text("signer_list".tr, style: context.textTheme.titleMedium),
        Text("ripple_multi_sig_addres_signer_list_desc2".tr),
        WidgetConstant.height8,
        ...List.generate(signers.length, (index) {
          final signerEntries = signers.keys.toList();
          return CustomizedContainer(
            onTapStackIcon: () {},
            enableTap: false,
            onStackWidget: APPCheckBox(
                backgroundColor: context.primaryContainer,
                color: context.onPrimaryContainer,
                value: signers[signerEntries[index]] != null,
                onChanged: (value) {
                  onTapSigner(signerEntries[index]);
                }),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ContainerWithBorder(
                    backgroundColor: context.onPrimaryContainer,
                    child: Text(signerEntries[index].account,
                        style: context.primaryTextTheme.bodyMedium)),
                ContainerWithBorder(
                    backgroundColor: context.onPrimaryContainer,
                    child: Text(signerEntries[index].signerWeight.toString(),
                        style: context.primaryTextTheme.bodyMedium)),
              ],
            ),
          );
        }),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(
              padding: WidgetConstant.paddingVertical40,
              onPressed: hasSigner ? onTapSetup : null,
              child: Text("generate_address".tr),
            )
          ],
        )
      ],
    );
  }
}

class _RegularKeyFeatureView extends StatelessWidget {
  const _RegularKeyFeatureView(
      {required this.regularKey,
      required this.onSetupRegularKey,
      required this.hasRegularKey,
      required this.onTapSetup});
  final String regularKey;
  final DynamicVoid onSetupRegularKey;
  final DynamicVoid onTapSetup;
  final bool hasRegularKey;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WidgetConstant.height20,
        PageTitleSubtitle(
            title: "regular_key".tr, body: Text("ripple_multi_sig_regular_key_desc".tr)),
        Text("address".tr, style: context.textTheme.titleMedium),
        Text("ripple_multi_sig_addres_signer_list_desc2".tr),
        WidgetConstant.height8,
        ContainerWithBorder(
          onRemove: onTapSetup,
          onRemoveIcon: IgnorePointer(
            child: Checkbox(
              value: hasRegularKey,
              onChanged: (value) {},
            ),
          ),
          child: Text(regularKey),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(
              padding: WidgetConstant.paddingVertical40,
              onPressed: hasRegularKey ? onSetupRegularKey : null,
              child: Text("generate_address".tr),
            )
          ],
        )
      ],
    );
  }
}
