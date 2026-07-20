import 'package:blockchain_utils/bip/bip/conf/bip/bip_coins.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/next_derivation.dart';
import 'package:on_chain_wallet/future/wallet/global/address_derivation/setup_address_derivation.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class SetupMoneroAddressView extends StatefulWidget {
  final MoneroChain account;
  const SetupMoneroAddressView(this.account, {super.key});
  @override
  State<SetupMoneroAddressView> createState() => _SetupMoneroAddressViewState();
}

enum _MoneroAddressDerivationPage { bip32, subIndex }

class _SetupMoneroAddressViewState extends State<SetupMoneroAddressView>
    with SafeState<SetupMoneroAddressView> {
  late MoneroNextDerivationBuilder derivationBuilder;
  _MoneroAddressDerivationPage page = _MoneroAddressDerivationPage.bip32;
  MoneroChain get account => widget.account;
  final StreamPageProgressController pageProgressKey = StreamPageProgressController();
  late NextDerivationMonero currentDerivation;
  GlobalKey<FormState> formKey = GlobalKey();
  BigRational currentHeight = BigRational.from(BinaryOps.safeUint);
  BipCoins get coin => account.network.coins.first;
  int major = MoneroConst.minSubAddressIndex;
  int minor = MoneroConst.minSubAddressIndex;
  bool newAccount = true;
  BigRational activationHeight = BigRational.zero;
  BigRational defaultActiviationHeight = BigRational.zero;

  void onChangeMajor(int? major) {
    this.major = major ?? MoneroConst.minSubAddressIndex;
    updateState();
  }

  void onChangeMinor(int? minor) {
    this.minor = minor ?? MoneroConst.minSubAddressIndex;
    updateState();
  }

  void onChangeDerivationPage(_MoneroAddressDerivationPage page) {
    this.page = page;
    minor = currentDerivation.index.minor;
    major = currentDerivation.index.major;
    updateState();
  }

  void onChangeActivationHeight(BigRational height) {
    activationHeight = height;
  }

  void onToggleNewAccount() {
    newAccount = !newAccount;
    if (!newAccount) {
      activationHeight = defaultActiviationHeight;
    }
    updateState();
  }

  String? onValidateActivationHeight(BigRational v) {
    if (v < defaultActiviationHeight) {
      return "monero_rct_block_validator"
          .tr
          .replaceOne(defaultActiviationHeight.toString());
    }
    final height = currentHeight;
    if (v.isNegative || v > height) {
      return "invalid_activation_height".tr;
    }
    return null;
  }

  Future<void> setupDerivation() async {
    final index = await context.openMaxExtendSliverBottomSheet<NextDerivationMonero>(
        "setup_derivation".tr,
        bodyBuilder: (controller) => SetupAddressDerivationIndex(
              controller: controller,
              account: account,
              derivationBuilder: derivationBuilder,
            ));
    if (index == null || index == currentDerivation) return;
    currentDerivation = index;
    updateState();
  }

  Future<void> generateAddress() async {
    if (!formKey.ready()) return;
    final heightInt = this.activationHeight.toBigInt().toIntOrNull;
    if (heightInt == null) return;
    pageProgressKey.progressText("generating_new_addr".tr);
    final activationHeight = switch (newAccount) {
      true => null,
      false => heightInt,
    };
    final params = MoneroNewAddressParams(
        deriveIndex: currentDerivation.nextIndex,
        major: major,
        minor: minor,
        coin: coin,
        network: account.network.coinParam.network,
        activeHeight: activationHeight);
    final result = await context.wallet.wallet
        .doAction(WalletActionDeriveNewAccount(newAccountParams: params, chain: account));
    if (result.isErr) {
      pageProgressKey.errorText(result.unwrapErr().localizationError);
    } else {
      pageProgressKey.success(
          backToIdle: false,
          progressWidget: SuccessWithButtonView(
              buttonText: "generate_new_address".tr,
              buttonWidget: ContainerWithBorder(
                  margin: WidgetConstant.paddingVertical8,
                  child: AddressDetailsView(address: result.unwrap(), chain: account)),
              onPressed: () {
                pageProgressKey.backToIdle();
                onPopInvokedWithResult(null, null);
              },
              text: "address_added_success".tr));
      updateState();
    }
    // widget.controller.generateAddress(newAccount);
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    derivationBuilder = MoneroNextDerivationBuilder(
        indexes: account.addresses.map((e) => MoneroAddressDeivedIndex(e.index)).toList(),
        coin: coin);
    currentDerivation = derivationBuilder.next();
    defaultActiviationHeight = BigRational.from(account.network.coinParam.rctHeight);
    account.client().then((e) => e.mapCatchAsync((client) async {
          final height = await client.getHeight();
          currentHeight = BigRational.from(height);
          updateState();
        }));
  }

  void onPopInvokedWithResult(__, _) {
    if (pageProgressKey.inProgress) return;
    if (!pageProgressKey.isIdle) {
      pageProgressKey.backToIdle();
    }
    page = _MoneroAddressDerivationPage.bip32;
    newAccount = true;
    derivationBuilder = MoneroNextDerivationBuilder(
        indexes: account.addresses.map((e) => MoneroAddressDeivedIndex(e.index)).toList(),
        coin: coin);
    currentDerivation = derivationBuilder.next();
    updateState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: UnfocusableChild(
        child: Form(
          key: formKey,
          canPop:
              !pageProgressKey.inProgress && page == _MoneroAddressDerivationPage.bip32,
          onPopInvokedWithResult: onPopInvokedWithResult,
          child: StreamPageProgress(
              controller: pageProgressKey,
              builder: (context) {
                return Center(
                  child: CustomScrollView(
                    shrinkWrap: true,
                    slivers: [
                      SliverConstraintsBoxView(
                          padding: WidgetConstant.padding20,
                          sliver: SliverToBoxAdapter(
                              child: APPAnimated(
                            alignment: Alignment.center,
                            onActive: (context) => ConditionalWidget(
                              key: ValueKey(page),
                              enable: page == _MoneroAddressDerivationPage.bip32,
                              onDeactive: (context) => Column(children: [
                                AppListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text("sub_address".tr,
                                      style: context.textTheme.titleMedium),
                                  subtitle: Text("xmr_sub_address_desc".tr),
                                ),
                                WidgetConstant.height20,
                                NumberTextField(
                                  label: "major_index".tr,
                                  onChangeValue: onChangeMajor,
                                  max: MoneroConst.maxSubAddressIndex,
                                  min: MoneroConst.minSubAddressIndex,
                                  defaultValue: major,
                                ),
                                WidgetConstant.height20,
                                NumberTextField(
                                  label: "minor_index".tr,
                                  onChangeValue: onChangeMinor,
                                  max: MoneroConst.maxSubAddressIndex,
                                  min: MoneroConst.minSubAddressIndex,
                                  defaultValue: minor,
                                ),
                                AppSwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: newAccount,
                                  title: Text("new_account".tr),
                                  subtitle: Text("enable_activation_height_desc".tr),
                                  onChanged: (p0) {
                                    onToggleNewAccount();
                                  },
                                ),
                                APPAnimated(
                                    isActive: !newAccount,
                                    onActive: (context) => Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            WidgetConstant.height8,
                                            AlertTextContainer(
                                              message: "setup_activation_height_desc".tr,
                                              enableTap: false,
                                            ),
                                            ConstraintsBoxView(
                                                maxWidth: APPConst.numberFieldsWidth,
                                                child: BigRationalTextField(
                                                    label: 'block_height'.tr,
                                                    onChange: onChangeActivationHeight,
                                                    defaultValue: activationHeight,
                                                    validator: onValidateActivationHeight,
                                                    min: defaultActiviationHeight)),
                                          ],
                                        )),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FixedElevatedButton(
                                      padding: WidgetConstant.paddingVertical40,
                                      onPressed: generateAddress,
                                      child: Text("generate_address".tr),
                                    ),
                                  ],
                                )
                              ]),
                              onActive: (context) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("bip32_derivation_path".tr,
                                      style: context.textTheme.titleMedium),
                                  Text("custom_bip32_path_desc".tr),
                                  WidgetConstant.height8,
                                  ContainerWithBorder(
                                    onRemove: () {
                                      setupDerivation();
                                      // controller.setupDerivationPath(context, controller.account);
                                    },
                                    onRemoveIcon: Icon(Icons.edit,
                                        color: context.onPrimaryContainer),
                                    child: AddressDrivationInfo(
                                        currentDerivation.nextIndex,
                                        style: context.onPrimaryTextTheme.titleMedium),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      FixedElevatedButton(
                                        padding: WidgetConstant.paddingVertical40,
                                        onPressed: () => onChangeDerivationPage(
                                            _MoneroAddressDerivationPage.subIndex),
                                        child: Text("continue".tr),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ))),
                    ],
                  ),
                );
              }),
        ),
      ),
    );
  }
}
