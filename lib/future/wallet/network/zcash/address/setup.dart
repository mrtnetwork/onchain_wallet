import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/bip/bip.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/types/next_derivation.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/global/address_derivation/public_key_generations.dart';
import 'package:on_chain_wallet/future/wallet/global/address_derivation/setup_address_derivation_mode.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/address_details.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/extension.dart';
import 'package:on_chain_wallet/future/wallet/global/types/types.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:zcash_dart/zcash.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/constant/networks/bitcoin.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/account.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/creation_params.dart';
import 'package:on_chain_wallet/wallet/models/others/models/receipt_address.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';

class SetupZcashAddressView extends StatefulWidget {
  final ZcashChain account;
  const SetupZcashAddressView(this.account, {super.key});

  @override
  State<SetupZcashAddressView> createState() => _SetupZcashAddressViewState();
}

class _SetupZcashAddressViewState extends State<SetupZcashAddressView>
    with SafeState<SetupZcashAddressView> {
  late _ZcashAddressGeneratorController controller = _ZcashAddressGeneratorController(
      account: widget.account,
      walletProvider: context.wallet,
      supportedProtocols: widget.account.supportedProtocols());

  @override
  void safeDispose() {
    super.safeDispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return APPStreamBuilder(
      value: controller.notifier,
      builder: (context, _) {
        return PopScope(
          onPopInvokedWithResult: controller.onBackButton,
          canPop: controller.canPop,
          child: StreamPageProgress(
            controller: controller.progressController,
            builder: (context) => Form(
              key: controller.form,
              child: CustomScrollView(
                shrinkWrap: true,
                slivers: [
                  SliverConstraintsBoxView(
                      padding: WidgetConstant.padding20,
                      sliver:
                          APPSliverAnimatedSwitcher(enable: controller.page, widgets: {
                        _Pages.mode: (context) => _SelectMode(controller),
                        _Pages.protocol: (context) => _SelectProtocols(controller),
                        _Pages.sapling: (context) => _BuildSheild(
                              controller: controller,
                              currentDerivation: controller.saplingDerivation,
                            ),
                        _Pages.orchard: (context) => _BuildSheild(
                              controller: controller,
                              currentDerivation: controller.orchardDerivation,
                            ),
                        _Pages.transparent: (context) => APPSliverAnimated(
                              onActive: (context) => _BuildTransparentMultisig(
                                  currentDerivation: controller.transparentMSigDerivation,
                                  controller: controller),
                              onDeactive: (context) => _BuildTransparent(
                                controller: controller,
                                currentDerivation: controller.transparentDerivation,
                              ),
                              isActive: controller.transparentMultisigDerivation,
                            ),
                      }))
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SelectMode extends StatelessWidget {
  final _ZcashAddressGeneratorController controller;
  const _SelectMode(this.controller);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("select_zcash_protocol".tr, style: context.textTheme.titleMedium),
          Text("select_zcash_protocol_desc".tr, style: context.textTheme.bodyMedium),
          WidgetConstant.height8,
          DisabledWidget(
            disabled: !controller.protocolSupported(ZcashProtocol.orchard),
            onActive: (p0, p1) {
              return AppListTile(
                onTap: () => controller.onChangeMode(
                    ZCashNewAddressDerivationMode.unified,
                    (err) => context.showAlert(err)),
                title: Text("orchard_upgrade".tr, style: context.textTheme.titleMedium),
                subtitle: Text("derive_new_unified_address".tr),
                trailing: Icon(Icons.arrow_forward),
              );
            },
          ),
          DisabledWidget(
            disabled: !controller.protocolSupported(ZcashProtocol.sapling),
            onActive: (p0, p1) {
              return AppListTile(
                onTap: () => controller.onChangeMode(
                    ZCashNewAddressDerivationMode.sapling,
                    (err) => context.showAlert(err)),
                title: Text("sapling_upgrade".tr, style: context.textTheme.titleMedium),
                subtitle: Text("derive_new_sapling_payment_address".tr),
                trailing: Icon(Icons.arrow_forward),
              );
            },
          ),
          DisabledWidget(
            disabled: !controller.protocolSupported(ZcashProtocol.transparent),
            onActive: (p0, p1) {
              return AppListTile(
                onTap: () => controller.onChangeMode(
                    ZCashNewAddressDerivationMode.transparent,
                    (err) => context.showAlert(err)),
                title: Text("transparent".tr, style: context.textTheme.titleMedium),
                subtitle: Text("zcash_transparent_derivation_desc".tr),
                trailing: Icon(Icons.arrow_forward),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SelectProtocols extends StatelessWidget {
  final _ZcashAddressGeneratorController controller;
  const _SelectProtocols(this.controller);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("unified_address".tr, style: context.textTheme.titleMedium),
      Text("zcash_select_address_protocols_desc".tr),
      WidgetConstant.height20,
      DisabledWidget(
        disabled: !controller.protocolSupported(ZcashProtocol.orchard),
        onActive: (p0, p1) {
          return AppCheckListTile(
            title: Text("orchard".tr, style: context.textTheme.titleMedium),
            subtitle: Text("orchard_desc".tr),
            value: controller.protocolSelected(ZcashProtocol.orchard),
            onChanged: (_) => controller.addProtocol(
                ZcashProtocol.orchard, (err) => context.showAlert(err)),
          );
        },
      ),
      DisabledWidget(
        disabled: !controller.protocolSupported(ZcashProtocol.sapling),
        onActive: (p0, p1) {
          return AppCheckListTile(
            title: Text("sapling".tr, style: context.textTheme.titleMedium),
            subtitle: Text("sapling_desc".tr),
            value: controller.protocolSelected(ZcashProtocol.sapling),
            onChanged: (_) => controller.addProtocol(
                ZcashProtocol.sapling, (err) => context.showAlert(err)),
          );
        },
      ),
      DisabledWidget(
        disabled: !controller.protocolSupported(ZcashProtocol.transparent),
        onActive: (p0, p1) {
          return AppCheckListTile(
            title: Text("transparent".tr, style: context.textTheme.titleMedium),
            subtitle: Text("transparent_desc".tr),
            value: controller.protocolSelected(ZcashProtocol.transparent),
            onChanged: (_) => controller.addProtocol(
                ZcashProtocol.transparent, (err) => context.showAlert(err)),
          );
        },
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FixedElevatedButton(
            onPressed: () => controller.nextPage((err) => context.showAlert(err)),
            activePress: controller.stateReady,
            padding: WidgetConstant.paddingVertical40,
            child: Text(controller.latestPage ? "setup_address".tr : "continue".tr),
          ),
        ],
      ),
    ]));
  }
}

class _BuildSheild extends StatelessWidget {
  final _ZcashAddressGeneratorController controller;
  final _ShieldedDerivation currentDerivation;
  const _BuildSheild({required this.controller, required this.currentDerivation});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageTitleSubtitle(
            title: "n_address_configuration"
                .tr
                .replaceOne(currentDerivation.protocol.name.tr),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("address_configuration_desc"
                    .tr
                    .replaceOne(currentDerivation.protocol.name.tr))
              ],
            )),
        WidgetConstant.height20,
        Text("zip32_derivation_path".tr, style: context.textTheme.titleMedium),
        Text("custom_zip32_path_desc".tr),
        WidgetConstant.height8,
        ContainerWithBorder(
          onRemove: () {
            controller.setupDerivationPath(context, controller.account);
          },
          onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
          child: AddressDrivationInfo(currentDerivation.nextIndex,
              style: context.onPrimaryTextTheme.titleMedium),
        ),
        ConditionalWidget(
          enable: currentDerivation.protocol.isOrchard,
          onActive: (context) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WidgetConstant.height20,
                APPAnimated(onActive: (context) {
                  bool enableSaplingRole = currentDerivation.enableSaplingRole;
                  return ConditionalWidget(
                      enable: enableSaplingRole,
                      onActive: (context) {
                        final fs = currentDerivation.followingSapling;
                        return Column(
                          children: [
                            AppCheckListTile(
                              contentPadding: EdgeInsets.zero,
                              onChanged: (p0) => controller.onChangeFollowingSaplingRole(
                                (err) => context.showAlert(err),
                              ),
                              value: fs,
                              title: Text("followng_sapling_diversifier_role".tr,
                                  style: context.textTheme.titleMedium),
                              subtitle: Text("followng_sapling_diversifier_role_desc".tr),
                            ),
                          ],
                        );
                      });
                }),
              ],
            );
          },
        ),
        APPAnimated(
            isActive: currentDerivation.enableDiversifierIndex,
            onActive: (context) =>
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  WidgetConstant.height20,
                  Text("scope".tr, style: context.textTheme.titleMedium),
                  Text("zcash_derivation_scope_desc".tr),
                  WidgetConstant.height8,
                  AppGroupRadioBuilder<Bip44Changes>(
                    groupValue: currentDerivation.scope,
                    onChanged: (e) => controller.onChangeScope(e),
                    builder: (context) {
                      return Column(
                        children: [
                          AppRadioListTile<Bip44Changes>(
                            value: Bip44Changes.chainExt,
                            title:
                                Text("external".tr, style: context.textTheme.titleMedium),
                          ),
                          AppRadioListTile<Bip44Changes>(
                            value: Bip44Changes.chainInt,
                            title:
                                Text("internal".tr, style: context.textTheme.titleMedium),
                          ),
                        ],
                      );
                    },
                  ),
                  WidgetConstant.height20,
                  Text("diversifier_index".tr, style: context.textTheme.titleMedium),
                  Text("diversifier_index_of_address".tr),
                  ConditionalWidget(
                      enable: currentDerivation.protocol.isSapling,
                      onActive: (context) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("diversifier_index_sapling_desc".tr),
                              WidgetConstant.height8,
                              AppSwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                onChanged: (p0) => controller.onChangeAutoDiversifier(),
                                value: currentDerivation.diversifier.autoDiversifier,
                                title: Text("auto_diversifier_index".tr,
                                    style: context.textTheme.titleMedium),
                                subtitle: Text("auto_diversifier_index_desc".tr),
                              ),
                            ],
                          )),
                  WidgetConstant.height8,
                  ConstraintsBoxView(
                      maxWidth: APPConst.numberFieldsWidth,
                      child: BigRationalTextField(
                          label: 'index'.tr,
                          onChange: currentDerivation.diversifier.onChangeDerivationIndex,
                          max: currentDerivation.diversifier.maxDiversifier,
                          defaultValue: currentDerivation.diversifier.diversifierIndex,
                          validator: currentDerivation.diversifier.diversifierValidator,
                          min: controller.minDiversifier)),
                ])),
        WidgetConstant.height20,
        AppSwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: currentDerivation.newAccount,
          title: Text("new_account".tr),
          subtitle: Text("enable_activation_height_desc".tr),
          onChanged: (p0) {
            controller.onChangeNewAccount();
          },
        ),
        APPAnimated(
            isActive: !currentDerivation.newAccount,
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
                            onChange: currentDerivation.onChangeActivationHeight,
                            max: null,
                            defaultValue: currentDerivation.activationHeight,
                            validator: (p0) => controller.onValidateActivationHeight(
                                p0, currentDerivation),
                            min: BigRational.zero)),
                  ],
                )),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(
              onPressed: () => controller.nextPage(
                (err) => context.showAlert(err),
              ),
              activePress: controller.stateReady,
              padding: WidgetConstant.paddingVertical40,
              child: Text(controller.latestPage ? "setup_address".tr : "continue".tr),
            ),
          ],
        ),
      ]),
    );
  }
}

class _BuildTransparent extends StatelessWidget {
  final _ZcashAddressGeneratorController controller;
  final _TransparentSingleKeyDerivation currentDerivation;
  const _BuildTransparent({required this.controller, required this.currentDerivation});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageTitleSubtitle(
            title: "n_address_configuration"
                .tr
                .replaceOne(ZcashProtocol.transparent.name.tr),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("address_configuration_desc"
                    .tr
                    .replaceOne(ZcashProtocol.transparent.name.tr))
              ],
            )),
        AppCheckListTile(
          contentPadding: EdgeInsets.zero,
          value: controller.transparentMultisigDerivation,
          onChanged: (_) => controller.onChangeTransparentMultisignature(),
          title: Text("multi_sig_addr".tr, style: context.textTheme.titleMedium),
          subtitle: Text('generate_multisignature_address_desc'.tr),
        ),
        WidgetConstant.height20,
        Text("bip32_derivation_path".tr, style: context.textTheme.titleMedium),
        Text("custom_bip32_path_desc".tr),
        WidgetConstant.height8,
        ContainerWithBorder(
          onRemove: () {
            controller.setupDerivationPath(context, controller.account);
          },
          onRemoveIcon: Icon(
            Icons.edit,
            color: context.onPrimaryContainer,
          ),
          child: APPAnimated(
            onActive: (context) {
              return FullWidthWrapper(
                key: ValueKey(
                    (currentDerivation.nextIndex, currentDerivation.overridePath)),
                child: AddressDrivationInfo(
                  currentDerivation.nextIndex,
                  style: context.textTheme.titleMedium,
                  overridePath: currentDerivation.overridePath,
                ),
              );
            },
          ),
        ),
        ConditionalWidget(
            enable: currentDerivation.canFollowSaplingStrategy,
            onActive: (context) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WidgetConstant.height20,
                  APPAnimated(onActive: (context) {
                    return AppCheckListTile(
                      contentPadding: EdgeInsets.zero,
                      onChanged: (p0) => controller.onChangeFollowingSaplingRole(
                        (err) => context.showAlert(err),
                      ),
                      value: currentDerivation.followSaplingStrategy,
                      title: Text("followng_sapling_diversifier_role".tr,
                          style: context.textTheme.titleMedium),
                      subtitle: Text("followng_sapling_diversifier_role_desc".tr),
                    );
                  }),
                ],
              );
            }),
        WidgetConstant.height20,
        Text(
          "transparent_address_type".tr,
          style: context.textTheme.titleMedium,
        ),
        WidgetConstant.height8,
        AppGroupRadioBuilder<BitcoinAddressType>(
          groupValue: currentDerivation.type,
          onChanged: (e) => controller.onChangeTransparentAddressType(e),
          builder: (context) {
            return Column(
              children: currentDerivation.supportTypes
                  .map((e) => AppRadioListTile<BitcoinAddressType>(
                        value: e,
                        title: Text(e.name, style: context.textTheme.titleMedium),
                      ))
                  .toList(),
            );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(
              onPressed: () => controller.nextPage(
                (err) => context.showAlert(err),
              ),
              activePress: controller.stateReady,
              padding: WidgetConstant.paddingVertical40,
              child: Text(controller.latestPage ? "setup_address".tr : "continue".tr),
            ),
          ],
        ),
      ]),
    );
  }
}

class _BuildTransparentMultisig extends StatelessWidget {
  final _TransparentMultisignatureDerivation currentDerivation;
  final _ZcashAddressGeneratorController controller;
  const _BuildTransparentMultisig(
      {required this.currentDerivation, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitleSubtitle(
              title: "n_address_configuration"
                  .tr
                  .replaceOne(ZcashProtocol.transparent.name.tr),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("address_configuration_desc"
                      .tr
                      .replaceOne(ZcashProtocol.transparent.name.tr))
                ],
              )),
          AppCheckListTile(
            contentPadding: EdgeInsets.zero,
            value: controller.transparentMultisigDerivation,
            onChanged: (_) => controller.onChangeTransparentMultisignature(),
            title: Text("multi_sig_addr".tr, style: context.textTheme.titleMedium),
            subtitle: Text('generate_multisignature_address_desc'.tr),
          ),
          WidgetConstant.height20,
          Text("threshold".tr, style: context.textTheme.titleMedium),
          Text("threshhold_desc3".tr),
          WidgetConstant.height8,
          ContainerWithBorder(
              onRemoveIcon: AddOrEditIconWidget(true),
              onRemove: () {
                context
                    .openMaxExtendSliverBottomSheet<BigRational>(
                      "threshold".tr,
                      child: NumberWriteView(
                          defaultValue: BtcConst.minMultiSigThresholdRational,
                          min: BtcConst.minMultiSigThresholdRational,
                          max: BtcConst.maxMultiSigThresholdRational,
                          allowDecimal: false,
                          allowSign: false,
                          title: PageTitleSubtitle(
                              title: "threshold".tr,
                              body: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [Text("threshhold_desc3".tr)])),
                          buttonText: "setup_input".tr,
                          label: "threshold".tr),
                    )
                    .then(controller.onChangeThreshHold);
              },
              child: Text(currentDerivation.threshold.toString(),
                  style: context.onPrimaryTextTheme.bodyMedium)),
          WidgetConstant.height20,
          Text("list_of_public_keys".tr, style: context.textTheme.titleMedium),
          Text("choose_public_key_or_generate_new_on".tr),
          WidgetConstant.height8,
          AnimatedSize(
            duration: APPConst.animationDuraion,
            child: Column(
              key: ValueKey<int>(currentDerivation.signers.length),
              children: List.generate(currentDerivation.signers.length, (index) {
                final signer = currentDerivation.signers[index];
                return CustomizedContainer(
                    enableTap: false,
                    onTapStackIcon: () => controller.onRemovePublicKey(signer),
                    onStackIcon: Icons.remove_circle,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OneLineTextWidget(signer.publicKey,
                            style: context.onPrimaryTextTheme.bodyMedium),
                        AddressDrivationInfo(signer.keyIndex,
                            color: context.onPrimaryContainer),
                        Divider(color: context.onPrimaryContainer),
                        ContainerWithBorder(
                          backgroundColor: context.colors.surface,
                          child: NumberTextField(
                              iconColor: context.colors.onSurface,
                              label: "weight".tr,
                              maxWidth: double.infinity,
                              defaultValue: signer.weight,
                              readOnly: true,
                              onChangeValue: (p0) {
                                controller.onChangeSignerWeight(signer, p0);
                              },
                              max: currentDerivation.threshold,
                              min: 1),
                        )
                      ],
                    ));
              }),
            ),
          ),
          ShimmerActionView(
            action: controller.onAddSignerAction,
            ignoring: true,
            onActive: (enable, context) {
              return ContainerWithBorder(
                  onRemove: () {},
                  enableTap: false,
                  validate: currentDerivation.signers.isNotEmpty,
                  onRemoveWidget: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                          tooltip: 'accounts'.tr,
                          onPressed: () {
                            context
                                .selectOrSwitchAccount<IZcashAddress>(
                                    account: controller.account,
                                    filter: controller.onFilterTransparentAccounts,
                                    showMultiSig: false)
                                .then(
                              (value) {
                                controller.onAddSigner(
                                    (err) => context.showAlert(err), value);
                              },
                            );
                          },
                          icon: Icon(Icons.supervisor_account_rounded)),
                      IconButton(
                          tooltip: 'generate_public_key'.tr,
                          onPressed: () {
                            context
                                .openMaxExtendSliverBottomSheet<
                                        PublicKeyDerivationWithMode>('',
                                    bodyBuilder: (c) => PublicKeyDerivationView(
                                        controller: c,
                                        pubKeyMode: PubKeyModes.compressed,
                                        coins: controller.transparentCoins()))
                                .then(
                              (value) async {
                                controller.onAddPublicKey(
                                    (err) => context.showAlert(err), value);
                              },
                            );
                          },
                          icon: Icon(Icons.add_box)),
                    ],
                  ),
                  child: Text("tap_to_chose_or_create_public_key".tr));
            },
          ),
          APPAnimated(
              isActive: !currentDerivation.isReady,
              onActive: (context) => ErrorTextContainer(
                  error: currentDerivation.signersReady ? "threshhold_desc3".tr : null,
                  showErrorIcon: true,
                  enableTap: false)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                onPressed: () => controller.nextPage(
                  (err) => context.showAlert(err),
                ),
                activePress: controller.stateReady,
                padding: WidgetConstant.paddingVertical40,
                child: Text(controller.latestPage ? "setup_address".tr : "continue".tr),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _Pages {
  mode,
  protocol,
  sapling,
  orchard,
  transparent;
}

class _ZcashAddressGeneratorController with DisposableMixin, StreamStateController {
  final ZcashChain account;
  final WalletProvider walletProvider;
  final GlobalKey<FormState> form = GlobalKey();
  StreamPageProgressController progressController = StreamPageProgressController();
  _ShieldedDerivation? _saplingDerivation;
  _ShieldedDerivation get saplingDerivation => _saplingDerivation!;
  _ShieldedDerivation? _orchardDerivation;
  _ShieldedDerivation get orchardDerivation => _orchardDerivation!;
  _TransparentSingleKeyDerivation? _transparentDerivation;
  _TransparentSingleKeyDerivation get transparentDerivation => _transparentDerivation!;
  _TransparentMultisignatureDerivation? _transparentMSigDerivation;
  _TransparentMultisignatureDerivation get transparentMSigDerivation =>
      _transparentMSigDerivation!;
  final List<ZcashProtocol> supportedProtocols;
  bool showNewAccountAlert = false;
  List<ZcashProtocol> selectdProtocols = [];

  ZCashNewAddressDerivationMode mode = ZCashNewAddressDerivationMode.unified;
  _ZcashAddressGeneratorController(
      {required this.account,
      required this.walletProvider,
      required this.supportedProtocols}) {
    account.client().then((e) {
      e.mapCatchAsync((e) async {
        final height = await e.getLatestBlockHeight();
        currentHeight = BigRational.from(height);
        currentHeightBig = BigInt.from(height);
        notify();
      });
    });
  }
  _Pages page = _Pages.mode;

  bool protocolSupported(ZcashProtocol protocol) => supportedProtocols.contains(protocol);
  bool protocolSelected(ZcashProtocol protocol) => selectdProtocols.contains(protocol);
  bool transparentMultisigDerivation = false;
  BigRational? currentHeight;
  BigInt? currentHeightBig;
  bool hasSapling = false;
  bool hasOrchard = false;
  bool hasTransparent = false;
  bool stateReady = false;
  bool latestPage = false;
  bool get canPop =>
      page == _Pages.mode || progressController.isSuccess || progressController.hasError;

  void onBackButton(bool _, Object? __) {
    if (page == _Pages.mode) return;
    if (page == _Pages.protocol || !mode.isUnifiedAddress) {
      page = _Pages.mode;
    } else {
      page = _Pages.protocol;
    }
    latestPage = false;

    updateState();
  }

  void updateState() {
    latestPage = false;
    switch (page) {
      case _Pages.mode:
        break;
      case _Pages.protocol:
        switch (mode) {
          case ZCashNewAddressDerivationMode.unified:
          case ZCashNewAddressDerivationMode.sapling:
            stateReady = selectdProtocols.any((e) => e.sheilded);
            break;
          default:
            break;
        }
        break;

      case _Pages.sapling:
        stateReady = saplingDerivation.isOk();
        latestPage = !(hasTransparent || hasOrchard);
        break;
      case _Pages.orchard:
        stateReady = orchardDerivation.isOk();
        latestPage = !hasTransparent;
        break;
      case _Pages.transparent:
        stateReady = switch (transparentMultisigDerivation) {
          true => transparentMSigDerivation.isOk(),
          false => transparentDerivation.isOk(),
        };
        latestPage = true;
        break;
    }

    notify();
  }

  ///
  final BigRational minDiversifier = BigRational.zero;

  ({Bip32DerivationIndex index, BigRational diversifierIndex}) getNextDerivation(
      {required CryptoCoins coin}) {
    final index =
        account.nextDerive(coin: coin, seedGeneration: SeedTypes.bip39, subId: null);
    switch (index) {
      case NextDerivationDefault():
        return (index: index.nextIndex.cast(), diversifierIndex: BigRational.zero);
      case NextDerivationZip32():
        return (
          index: index.nextIndex.cast(),
          diversifierIndex: BigRational(index.nextDiversifier.toU128())
        );
      default:
        throw AppCryptoExceptionConst.invalidDerivationKey;
    }
  }

  _ShieldedDerivation _buildShieldedDerivaton(EllipticCurveTypes type,
      {_ShieldedDerivation? sapling}) {
    final coin =
        account.network.coins.firstWhere((e) => e.conf.type == type) as ZIP32Coins;
    final nextIndex = getNextDerivation(coin: coin);
    return _ShieldedDerivation(
        sapling: sapling,
        nextIndex: nextIndex.index,
        diversifier: nextIndex.diversifierIndex,
        account: account,
        coin: coin);
  }

  _TransparentSingleKeyDerivation _buildTransparentDerivaton() {
    final coin = account.network.coins.firstWhere((e) {
      return e.proposal == CoinProposal.bip44 &&
          e.conf.type == EllipticCurveTypes.secp256k1;
    }) as BipCoins;
    final sapling = _saplingDerivation;
    return _TransparentSingleKeyDerivation(
        nextIndex: getNextDerivation(coin: coin).index,
        account: account,
        coin: coin,
        sapling: sapling);
  }

  _TransparentMultisignatureDerivation _buildTransparentMultisigDerivation() =>
      _TransparentMultisignatureDerivation();

  void addProtocol(ZcashProtocol protocol, StringVoid onErr) {
    if (!supportedProtocols.contains(protocol)) {
      onErr("protocol_not_supported".tr);
      return;
    }
    if (supportedProtocols.contains(protocol)) {
      final remove = selectdProtocols.remove(protocol);
      if (remove) resetState();
      if (!remove) {
        selectdProtocols.add(protocol);
      }
      updateState();
    }
  }

  void resetState() {
    _saplingDerivation = null;
    _transparentDerivation = null;
    _transparentMSigDerivation = null;
    _orchardDerivation = null;
    transparentMultisigDerivation = false;
  }

  void onChangeMode(ZCashNewAddressDerivationMode mode, StringVoid onErr) {
    if (!supportedProtocols.contains(mode.protocol)) {
      onErr("protocol_not_supported".tr);
      return;
    }
    bool changed = this.mode != mode;
    this.mode = mode;
    if (changed) {
      resetState();
    }
    stateReady = true;
    nextPage(
      (p0) {
        assert(false, p0);
      },
    );
  }

  bool toOrchard() {
    if (hasOrchard) {
      _orchardDerivation ??= _buildShieldedDerivaton(EllipticCurveTypes.redPallas,
          sapling: _saplingDerivation);
      return true;
    }
    _orchardDerivation = null;
    return false;
  }

  String? onValidateActivationHeight(BigRational v, _ShieldedDerivation derivation) {
    if (currentHeight != null && v > currentHeight!) {
      return "activation_height_grather_than_network_height_desc"
          .tr
          .replaceOne(currentHeightBig.toString());
    }

    return derivation.onValidateActivationHeight(v);
  }

  bool toTransport() {
    if (hasTransparent) {
      if (transparentMultisigDerivation) {
        _transparentMSigDerivation ??= _buildTransparentMultisigDerivation();
        _transparentDerivation = null;
      } else {
        _transparentDerivation ??= _buildTransparentDerivaton();
        _transparentMSigDerivation = null;
      }
      return true;
    }
    _transparentDerivation = null;
    _transparentMSigDerivation = null;
    return false;
  }

  bool toSapling() {
    if (hasSapling) {
      _saplingDerivation ??= _buildShieldedDerivaton(EllipticCurveTypes.redJubJub);
      return true;
    }
    _saplingDerivation = null;
    return false;
  }

  void nextPage(StringVoid onError) {
    if (!stateReady) {
      if (page == _Pages.protocol) {
        onError("at_least_one_sapling_orchard_required".tr);
      }
      return;
    }
    if (!form.ready()) return;
    if (latestPage) {
      generateStandardParams();
      return;
    }
    switch (page) {
      case _Pages.mode:
        switch (mode) {
          case ZCashNewAddressDerivationMode.unified:
            page = _Pages.protocol;
            break;
          case ZCashNewAddressDerivationMode.sapling:
            hasSapling = true;
            hasOrchard = false;
            hasTransparent = false;
            if (toSapling()) {
              page = _Pages.sapling;
            }
            break;
          case ZCashNewAddressDerivationMode.transparent:
          case ZCashNewAddressDerivationMode.transparentMultisig:
            hasSapling = false;
            hasOrchard = false;
            hasTransparent = true;
            if (toTransport()) {
              page = _Pages.transparent;
            }
            break;
        }
        break;
      case _Pages.protocol:
        hasSapling = selectdProtocols.contains(ZcashProtocol.sapling);
        hasOrchard = selectdProtocols.contains(ZcashProtocol.orchard);
        hasTransparent = selectdProtocols.contains(ZcashProtocol.transparent);
        // maxDiversifier = getMaxDiversifier();
        if (toSapling()) {
          _transparentDerivation = null;
          page = _Pages.sapling;
        } else if (toOrchard()) {
          page = _Pages.orchard;
        } else if (toTransport()) {
          page = _Pages.transparent;
        }
        break;

      case _Pages.sapling:
        if (toOrchard()) {
          page = _Pages.orchard;
        } else if (toTransport()) {
          page = _Pages.transparent;
        }
        break;
      case _Pages.orchard:
        if (toTransport()) {
          page = _Pages.transparent;
        }
        break;
      case _Pages.transparent:
        break;
    }
    updateState();
  }

  Future<void> setupDerivationPath(BuildContext context, ZcashChain account) async {
    final updated = switch (page) {
      _Pages.sapling => await saplingDerivation.setupDerivation(context, account),
      _Pages.orchard => await orchardDerivation.setupDerivation(context, account),
      _Pages.transparent => await transparentDerivation.setupDerivation(context, account),
      _ => false
    };
    if (updated) updateState();
  }

  void onChangeAutoDiversifier() {
    if (page != _Pages.sapling) return;
    saplingDerivation.onChangeAutoDiversifier();
    _orchardDerivation = null;
    _transparentDerivation = null;

    updateState();
  }

  void onChangeFollowingSaplingRole(StringVoid onErr) {
    switch (page) {
      case _Pages.orchard:
        orchardDerivation.onChangeFollowingSaplingRole();
        break;
      case _Pages.transparent:
        transparentDerivation.onChangeFollowingSaplingRole(onErr);
        break;
      default:
        break;
    }
    updateState();
  }

  void onChangeScope(Bip44Changes? scope) {
    if (scope == null) return;
    switch (page) {
      case _Pages.sapling:
        saplingDerivation.onChangeScope(scope);
        break;
      case _Pages.orchard:
        orchardDerivation.onChangeScope(scope);
        break;

      default:
        break;
    }
    updateState();
  }

  void onChangeTransparentAddressType(BitcoinAddressType? type) {
    if (type == null) return;
    transparentDerivation.onChangeAddressType(type);
    updateState();
  }

  void onChangeTransparentMultisignature() {
    transparentMultisigDerivation = !transparentMultisigDerivation;
    switch (transparentMultisigDerivation) {
      case true:
        _transparentMSigDerivation = _buildTransparentMultisigDerivation();
        _transparentDerivation = null;
        break;
      case false:
        _transparentMSigDerivation = null;
        _transparentDerivation = _buildTransparentDerivaton();
    }
    updateState();
  }

  Future<void> onChangeNewAccount() async {
    switch (page) {
      case _Pages.sapling:
        saplingDerivation.onToggleNewAccount();
        break;
      case _Pages.orchard:
        orchardDerivation.onToggleNewAccount();
        break;

      default:
        break;
    }
    updateState();
  }

  Future<void> generateStandardParams() async {
    if (!stateReady || !form.ready()) return;
    progressController.progressText("generating_new_addr".tr);
    final result = await IResult.block(() async {
      final client = await account.client();
      final height = await client.mapAsync((e) async {
        return await e.getLatestBlockHeight();
      });
      return height.mapErr((_) {
        return AppException("failed_to_retrieve_block_height");
      }).andThenAsync(
        (currentHeight) async {
          final orchard = _orchardDerivation?.toUnifiedParams(currentHeight);
          final sapling = _saplingDerivation?.toUnifiedParams(currentHeight);
          final transparent = _transparentDerivation?.toUnifiedParams(currentHeight);
          final msig = _transparentMSigDerivation?.toUnifiedParams(currentHeight);
          if (transparent != null && msig != null) {
            throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
          }
          List<BigInt> existsIndexes = [];
          bool isAutoDerivation =
              _saplingDerivation?.diversifier.autoDiversifier ?? false;
          if (isAutoDerivation) {
            existsIndexes = account.saplingAccountsDiversifierIndexsSync();
          }
          final newAccountParams = switch (mode) {
            ZCashNewAddressDerivationMode.unified => await () async {
                return ZcashNewAddressParamsUnified(
                    network: account.network.coinParam.network,
                    coin: account.network.coins.first,
                    existsIndexes: existsIndexes,
                    currentHeight: currentHeight,
                    params: [orchard, sapling, transparent, msig]
                        .whereType<ZcashAccountCreationParams>()
                        .toList());
              }(),
            ZCashNewAddressDerivationMode.sapling => () {
                if (sapling == null || sapling is! ZcashAccountCreationParamsSapling) {
                  throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
                }
                return ZcashNewAddressParamsSapling(
                    network: account.network.coinParam.network,
                    coin: sapling.index.currencyCoin,
                    existsIndexes: existsIndexes,
                    currentHeight: currentHeight,
                    param: sapling);
              }(),
            ZCashNewAddressDerivationMode.transparent => switch (
                  transparentMultisigDerivation) {
                true => () {
                    if (msig == null) {
                      throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
                    }
                    return ZcashNewAddressParamsTransparentMultisignature(
                        network: account.network.coinParam.network,
                        param: msig,
                        coin: account.network.coins.firstWhere((e) =>
                            e.proposal == CoinProposal.bip49 &&
                            e.conf.type == EllipticCurveTypes.secp256k1));
                  }(),
                false => () {
                    if (transparent == null) {
                      throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
                    }
                    return ZcashNewAddressParamsTransparent(
                        network: account.network.coinParam.network,
                        param: transparent,
                        coin: transparent.index.currencyCoin);
                  }(),
              },
            ZCashNewAddressDerivationMode.transparentMultisig =>
              throw AppCryptoExceptionConst.invalidNeweAddressConfiguration
          };
          final List<int> activationHeights = newAccountParams.params
                  ?.map((e) => e.activationHeight)
                  .whereType<int>()
                  .toList() ??
              [];
          if (activationHeights.any((e) => e > currentHeight)) {
            throw AppException("invalid_activation_height");
          }
          return await walletProvider.wallet.doAction(WalletActionDeriveNewAccount(
              newAccountParams: newAccountParams, chain: account));
        },
      );
    });
    if (result.isErr) {
      progressController.errorText(result.unwrapErr().localizationError,
          backToIdle: false, showBackButton: true);
    } else {
      progressController.success(
          backToIdle: false,
          progressWidget: SuccessWithButtonView(
              buttonText: "generate_new_address".tr,
              buttonWidget: ContainerWithBorder(
                  margin: WidgetConstant.paddingVertical8,
                  child: AddressDetailsView(address: result.unwrap())),
              onPressed: () {
                resetState();
                page = _Pages.mode;
                progressController.backToIdle();
                updateState();
              },
              text: "address_added_success".tr));
    }
  }

  List<BipCoins> transparentCoins() {
    return account.network.coins
        .whereType<BipCoins>()
        .where((e) => e.conf.type == EllipticCurveTypes.secp256k1)
        .toList();
  }

  String? onFilterTransparentAccounts(IZcashAddress addr) {
    if (addr.multiSigAccount) {
      return "unavailable_multi_sig_public_key".tr;
    }
    final transparent =
        addr.account.receivers.firstWhereOrNull((e) => e.type.isTransparent);
    if (transparent == null) {
      return "address_does_not_contains_any_transparent_addr".tr;
    }
    if (transparent is ZcsahAccountInfoP2shMultisig) {
      return "unavailable_multi_sig_public_key".tr;
    }
    return null;
  }

  void onChangeThreshHold(BigRational? v) {
    transparentMSigDerivation.onChangeThreshHold(v);
    updateState();
  }

  ShimmerAction<void> onAddSignerAction = ShimmerAction(object: null);

  Future<void> onAddSigner(StringVoid onError, IZcashAddress? addr) async {
    try {
      onAddSignerAction.setAction(true);
      updateState();
      await transparentMSigDerivation.onAddSigner(
          onError: onError, account: account, addr: addr, provider: walletProvider);
    } finally {
      onAddSignerAction.setAction(false);
      updateState();
    }
  }

  void onAddPublicKey(StringVoid onError, PublicKeyDerivationWithMode? pubKey) {
    transparentMSigDerivation.onAddPublicKey(onError: onError, pubKey: pubKey);
    updateState();
  }

  /// add threshold validator for text field
  void onChangeSignerWeight(_TransparentMultisigSigner address, int? weight) {
    transparentMSigDerivation.onChangeSignerWeight(address, weight ?? 1);
    updateState();
  }

  void onRemovePublicKey(_TransparentMultisigSigner signer) {
    transparentMSigDerivation.onRemovePublicKey(signer);
    updateState();
  }

  @override
  void dispose() {
    super.dispose();
    progressController.dispose();
  }
}

abstract mixin class _AddressDerivation {
  ZcashAccountCreationParams toUnifiedParams(int currentHeight);
  bool isOk();
}

class _ShieldedDerivation implements _AddressDerivation {
  Bip32DerivationIndex nextIndex;
  final ZIP32Coins coin;
  final _ShieldedDerivation? sapling;
  final _Diversifier diversifier = _Diversifier();
  final ZcashProtocol protocol;
  final ZcashChain account;
  late final BigRational defaultActiviationHeight;
  late final BigInt defaultActiviationHeightBig;
  BigRational activationHeight = BigRational.zero;
  bool newAccount = true;
  bool get enableSaplingRole => sapling != null;
  bool followingSapling = false;
  bool get enableDiversifierIndex => protocol.isSapling || !followingSapling;

  @override
  bool isOk() => true;
  _ShieldedDerivation({
    required this.nextIndex,
    required this.coin,
    required this.account,
    // required ZcashNetwork network,
    required BigRational diversifier,
    this.sapling,
  }) : protocol = switch (coin.conf.type) {
          EllipticCurveTypes.redJubJub => ZcashProtocol.sapling,
          EllipticCurveTypes.redPallas => ZcashProtocol.orchard,
          _ => throw AppInternalError.internalError("Invalid zip32 coin.")
        } {
    final network = account.network.coinParam.network;
    final activationProvider = DefaultUpgradeActivationProvider();
    defaultActiviationHeight = BigRational.from(switch (protocol) {
      ZcashProtocol.orchard =>
        activationProvider.activationHeight(ZcashNetworkProtocol.nu5, network) + 1,
      ZcashProtocol.sapling =>
        activationProvider.activationHeight(ZcashNetworkProtocol.sapling, network) + 1,
      ZcashProtocol.transparent => 0,
    });
    defaultActiviationHeightBig = defaultActiviationHeight.toBigInt();
    activationHeight = defaultActiviationHeight;
    final sapling = this.sapling;
    if (sapling != null) {
      followingSapling = true;
      scope = sapling.scope;
    }
    if (protocol.isSapling) {
      this.diversifier.onChangeAutoDiversifier(enable: true);
      this.diversifier.onChangeDerivationIndex(diversifier);
    } else if (sapling == null) {
      this.diversifier.onChangeDerivationIndex(diversifier);
    }
  }

  Future<bool> setupDerivation(BuildContext context, ZcashChain account) async {
    final path = await context.openMaxExtendSliverBottomSheet<Bip32DerivationIndex>(
        "setup_derivation".tr,
        bodyBuilder: (controller) => SetupDerivationModeView(
              coin: coin,
              chainAccout: account,
              seedGenerationType: SeedTypes.bip39,
              defaultDerivation: nextIndex,
              buttonText: "setup_derivation".tr,
              controller: controller,
            ));
    nextIndex = path ?? nextIndex;
    return path != null;
  }

  Bip44Changes scope = Bip44Changes.chainExt;

  void onChangeScope(Bip44Changes scope) {
    this.scope = scope;
  }

  void onChangeAutoDiversifier() {
    diversifier.onChangeAutoDiversifier();
  }

  void onChangeFollowingSaplingRole() {
    followingSapling = !followingSapling;
    if (!followingSapling) {
      final nextIndex = account.nextDerive(
          coin: coin, seedGeneration: SeedTypes.bip39, subId: this.nextIndex.subId);
      if (nextIndex
          case NextDerivationZip32(nextDiversifier: DiversifierIndex nextDiversifier)) {
        diversifier.onChangeDerivationIndex(BigRational(nextDiversifier.toU128()));
      }
    }
  }

  void onChangeActivationHeight(BigRational height) {
    activationHeight = height;
  }

  void onToggleNewAccount() {
    newAccount = !newAccount;
    if (!newAccount) {
      activationHeight = defaultActiviationHeight;
    }
  }

  String? onValidateActivationHeight(BigRational v) {
    if (v < defaultActiviationHeight) {
      return "address_protocol_activiation_height_validator"
          .tr
          .replaceOne(defaultActiviationHeightBig.toString());
    }

    return null;
  }

  @override
  ZcashAccountCreationParams<DerivationIndex> toUnifiedParams(int currentHeight) {
    final activationHeight =
        newAccount ? currentHeight : this.activationHeight.toBigInt().toIntOrThrow;
    switch (protocol) {
      case ZcashProtocol.sapling:
        return ZcashAccountCreationParamsSapling(
            index: nextIndex.withName(protocol.name),
            exactDiversifier: !diversifier.autoDiversifier,
            diversifierIndex:
                DiversifierIndex.fromBigInt(diversifier.diversifierIndex.toBigInt()),
            change: scope,
            activationHeight: activationHeight);
      case ZcashProtocol.orchard:
        final sapling = this.sapling;
        if (followingSapling) {
          if (sapling == null) {
            throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
          }
          return ZcashAccountCreationParamsUnified(
              index: nextIndex,
              diversifierIndex: null,
              change: sapling.scope,
              activationHeight: activationHeight);
        }
        return ZcashAccountCreationParamsUnified(
            index: nextIndex.withName(protocol.name),
            activationHeight: activationHeight,
            diversifierIndex:
                DiversifierIndex.fromBigInt(diversifier.diversifierIndex.toBigInt()),
            change: scope);
      default:
        throw AppCryptoExceptionConst.invalidCoin;
    }
  }
}

class _TransparentSingleKeyDerivation implements _AddressDerivation {
  Bip32DerivationIndex nextIndex;
  final BipCoins coin;
  final ZcashChain account;
  _ShieldedDerivation? sapling;
  String? overridePath;
  bool get canFollowSaplingStrategy => sapling != null;
  bool followSaplingStrategy = false;
  bool isCustomDerivation = false;

  @override
  bool isOk() => true;
  BitcoinAddressType type = P2pkhAddressType.p2pkh;
  List<BitcoinAddressType> supportTypes = [
    P2pkhAddressType.p2pkh,
    P2shAddressType.p2pkInP2sh,
    P2shAddressType.p2pkhInP2sh
  ];
  _TransparentSingleKeyDerivation({
    required this.nextIndex,
    required this.coin,
    required this.account,
    _ShieldedDerivation? sapling,
  }) {
    if (sapling != null) {
      int? bip32Index;
      final bool canFollowSaplingStrategy = () {
        bip32Index = sapling.diversifier.asBip32KeyIndex;
        return bip32Index != null;
      }();
      if (canFollowSaplingStrategy) {
        this.sapling = sapling;
        setSaplingRole();
      }
    }
  }
  void setSaplingRole() {
    final sapling = this.sapling;
    if (sapling == null) return;
    followSaplingStrategy = true;
    final bip32Index = switch (sapling.diversifier.autoDiversifier) {
      false => () {
          return sapling.diversifier.asBip32KeyIndex;
        }(),
      true => null,
    };
    nextIndex = nextIndex.copyWith(
        changeLevel: sapling.scope.value, addressIndex: bip32Index ?? 0);
    final path = nextIndex.toString();
    int index = path.lastIndexOf("/");
    if (index.isNegative || nextIndex.level() != Bip44Levels.addressIndex) {
      throw AppInternalError.internalError("Unexpected hd path string.");
    }

    if (bip32Index == null) {
      overridePath = "${path.substring(0, index)}/[SaplingRole]";
    } else {
      overridePath = null;
    }
  }

  Future<bool> setupDerivation(BuildContext context, ZcashChain account) async {
    if (followSaplingStrategy) {
      final accept = await context.openSliverDialog<bool>(
          widget: (ctx) => DialogTextView(
              buttonWidget: DialogSingleButtonView(
                buttonLabel: "got_it".tr,
              ),
              text: "custom_derivation_with_following_sapling_role_desc".tr),
          label: 'customize_key_derivation'.tr);
      if (accept != true) return false;
    }
    Bip32DerivationIndex? path = await context
        .openMaxExtendSliverBottomSheet<Bip32DerivationIndex>("setup_derivation".tr,
            bodyBuilder: (controller) => SetupDerivationModeView(
                  coin: coin,
                  chainAccout: account,
                  seedGenerationType: SeedTypes.bip39,
                  defaultDerivation:
                      followSaplingStrategy ? nextIndex.take(Bip44Levels.account) : null,
                  buttonText: "setup_derivation".tr,
                  fixedLevel: followSaplingStrategy ? Bip44Levels.account : null,
                  nextAddressDerivationBuilder: (
                          {required coin, required seedGeneration, required subId}) =>
                      NextDerivationDefault(nextIndex),
                  controller: controller,
                ));
    if (path == null || path == nextIndex) return false;
    nextIndex = path;
    if (followSaplingStrategy) {
      setSaplingRole();
    } else {
      isCustomDerivation = true;
    }
    return true;
  }

  void onChangeAddressType(BitcoinAddressType type) {
    this.type = type;
    if (isCustomDerivation) return;
    final CoinProposal proposal = switch (type) {
      P2pkhAddressType.p2pkh => CoinProposal.bip44,
      P2shAddressType.p2pkInP2sh => CoinProposal.bip49,
      P2shAddressType.p2pkhInP2sh => CoinProposal.bip49,
      _ => CoinProposal.bip44
    };
    final coin = account.network.coins.firstWhere((e) {
      return e.proposal == proposal && e.conf.type == EllipticCurveTypes.secp256k1;
    }) as BipCoins;
    final index = account.nextDerive(
        coin: coin, seedGeneration: SeedTypes.bip39, subId: nextIndex.subId);
    nextIndex = index.nextIndex.cast();
    if (followSaplingStrategy) {
      setSaplingRole();
    }
  }

  bool canUseSaplingRole() {
    final level = nextIndex.level();
    return level == Bip44Levels.account || level == Bip44Levels.addressIndex;
  }

  void onChangeFollowingSaplingRole(StringVoid onErr) {
    if (!followSaplingStrategy && !canUseSaplingRole()) {
      onErr("sapling_role_can_only_applied_on_account_level_path".tr);
      return;
    }
    followSaplingStrategy = !followSaplingStrategy;
    if (followSaplingStrategy) {
      isCustomDerivation = false;
      setSaplingRole();
    } else {
      nextIndex = account
          .nextDerive(coin: coin, seedGeneration: SeedTypes.bip39, subId: nextIndex.subId)
          .nextIndex
          .cast();
      overridePath = null;
    }
  }

  @override
  ZcashAccountCreationParamsTransparent<Bip32DerivationIndex> toUnifiedParams(
      int currentHeight) {
    if (followSaplingStrategy) {
      final sapling = this.sapling;
      if (sapling == null) {
        throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
      }
      if (nextIndex.changeLevel != sapling.scope.value) {
        throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
      }
      final autoDiversifier = sapling.diversifier.autoDiversifier;
      if (!autoDiversifier) {
        if (sapling.diversifier.asBip32KeyIndex != nextIndex.addressIndex) {
          throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
        }
      } else {
        if (nextIndex.addressIndex != null && nextIndex.addressIndex != 0) {
          throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
        }
      }
    }
    switch (type) {
      case P2pkhAddressType.p2pkh:
        return ZcashAccountCreationParamsP2pkh(
            index: nextIndex.withName(type.name),
            followingSaplingRole: followSaplingStrategy);
      case P2shAddressType.p2pkInP2sh:
      case P2shAddressType.p2pkhInP2sh:
        return ZcashAccountCreationParamsP2shStandard(
            p2shType: type.cast<P2shAddressType>(),
            index: nextIndex.withName(type.name),
            followingSaplingRole: followSaplingStrategy);
      default:
        throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
    }
  }
}

class _TransparentMultisignatureDerivation implements _AddressDerivation {
  final Map<String, _TransparentMultisigSigner> _signers = {};
  List<_TransparentMultisigSigner> get signers => _signers.values.toList();
  int threshold = BtcConst.minMultiSigThreshold;

  bool isReady = false;
  bool signersReady = false;
  @override
  bool isOk() => isReady;
  int? signerWeight() {
    if (_signers.isEmpty) return null;
    int sum = 0;
    for (final i in _signers.values) {
      if (i.weight > threshold) {
        return null;
      } else if (i.weight < 1) {
        return null;
      }
      sum += i.weight;
    }
    return sum;
  }

  void onStateUpdated() {
    final signerWeight = this.signerWeight();
    signersReady = signerWeight != null;
    isReady = signersReady && signerWeight! >= threshold;
  }

  void onChangeThreshHold(BigRational? v) {
    if (v == null || v.isDecimal || v.isNegative) return;
    final threshold = v.toBigInt().toInt();
    if (threshold > BtcConst.maxMultiSigThreshold ||
        threshold < BtcConst.minMultiSigThreshold) {
      return;
    }
    this.threshold = threshold;
    onStateUpdated();
  }

  Future<void> onAddSigner(
      {required StringVoid onError,
      required WalletProvider provider,
      required IZcashAddress? addr,
      required ZcashChain account}) async {
    if (addr == null) return;
    if (addr.multiSigAccount) {
      onError("unavailable_multi_sig_public_key".tr);
      return;
    }
    final transparent =
        addr.account.receivers.firstWhereOrNull((e) => e.type.isTransparent);
    if (transparent == null) {
      onError("address_does_not_contains_any_transparent_addr".tr);
      return;
    }
    if (transparent is ZcsahAccountInfoP2shMultisig) {
      onError("unavailable_multi_sig_public_key".tr);
      return;
    }
    final pk = await provider.wallet.doAction(
        WalletActionDerivableIndexPublicKey(index: transparent.index.cast()),
        delay: null);
    if (pk.isErr) {
      onError(pk.unwrapErr().localizationError);
      return;
    }
    final transparentAddr = addr.networkAddress.tryToTransparentAddreses();
    ReceiptAddress<ZcashAddress>? addrInfo;
    if (transparentAddr != null) {
      addrInfo = ReceiptAddress<ZcashAddress>(
          networkAddress: transparentAddr, account: addr, view: transparentAddr.address);
    }
    onAddPublicKey(
        onError: onError,
        pubKey: PublicKeyDerivationWithMode(
            derivation: pk.unwrap(), mode: PubKeyModes.compressed),
        transparentAddr: addrInfo);
  }

  void onAddPublicKey(
      {required StringVoid onError,
      required PublicKeyDerivationWithMode? pubKey,
      ReceiptAddress<ZcashAddress>? transparentAddr}) {
    if (pubKey == null) return;
    final key = pubKey.selectedKey();
    if (_signers.containsKey(key)) {
      onError("public_key_already_exist".tr);
      return;
    }
    final newAcc = _TransparentMultisigSigner(
        publicKey: key, keyIndex: pubKey.derivation.index, account: transparentAddr);
    _signers.addAll({newAcc.publicKey: newAcc});
    onStateUpdated();
  }

  void onChangeSignerWeight(_TransparentMultisigSigner address, int weight) {
    address.onUpdateWight(weight);
    onStateUpdated();
  }

  void onRemovePublicKey(_TransparentMultisigSigner signer) {
    _signers.remove(signer.publicKey);
    onStateUpdated();
  }

  @override
  ZcashAccountCreationParamsP2shMultisig toUnifiedParams(int currentHeight) {
    return ZcashAccountCreationParamsP2shMultisig(
        multisig: TransparentMultiSignatureAddressDetails(
            threshold: threshold, signers: signers.map((e) => e.toParams()).toList()));
  }
}

class _TransparentMultisigSigner {
  final String publicKey;
  final ReceiptAddress<ZcashAddress>? account;
  final DerivableIndex keyIndex;
  _TransparentMultisigSigner(
      {required this.publicKey, required this.account, required this.keyIndex});
  int weight = 1;
  bool isValid(int threshold) {
    return weight >= 1 && weight <= threshold;
  }

  void onUpdateWight(final int weight) {
    this.weight = weight;
  }

  TransparentMultiSignatureSignerDefaultWithDerivationIndex toParams() {
    return TransparentMultiSignatureSignerDefaultWithDerivationIndex(
      index: keyIndex,
      signer:
          TransparentMultiSignatureSignerDefault(publicKey: publicKey, weight: weight),
    );
  }
}

class _Diversifier {
  final BigRational maxDiversifier = BigRational(DiversifierIndex.maxIndex);
  BigRational diversifierIndex = BigRational.zero;
  bool _authoDiversifier = true;
  int? asBip32KeyIndex;
  void onChangeDerivationIndexBigInt(BigInt index) {
    onChangeDerivationIndex(BigRational(index));
  }

  void onChangeDerivationIndex(BigRational index) {
    diversifierIndex = index;
    final toBig = index.toBigInt();
    if (toBig.isValidInt) {
      final index = toBig.toInt();
      if (Bip32KeyIndex.isValidBip32Index(index)) {
        asBip32KeyIndex = index;
        return;
      }
    }
    asBip32KeyIndex = null;
  }

  bool get autoDiversifier => _authoDiversifier;

  void onChangeAutoDiversifier({bool? enable}) {
    _authoDiversifier = enable ?? !_authoDiversifier;
    diversifierIndex = BigRational.zero;
    asBip32KeyIndex = 0;
  }

  String? diversifierValidator(BigRational v) {
    final n = v.toBigInt();
    if (v.isNegative || v.isDecimal || n.isNegative) {
      return "diversifier_index_validator_desc".tr;
    }
    final rational = BigRational(n);
    if (rational > maxDiversifier) {
      return "diversifier_index_validator_desc2".tr;
    }
    return null;
  }
}
