import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/next_derivation.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart' show Chain;
import 'package:on_chain_wallet/crypto/crypto.dart';

typedef CHANGEDERIVATIONCALLBACK<DERIVABLEINDEX extends DerivableIndex>
    = Future<DERIVABLEINDEX?> Function();

class SetupAddressDerivationIndex<DERIVABLEINDEX extends DerivableIndex,
    DERIVATION extends NetDerivation<DERIVABLEINDEX>> extends StatefulWidget {
  final NetDerivationBuilder<DERIVABLEINDEX, DERIVATION, CryptoCoins,
      AddressDerivedIndex<DERIVABLEINDEX>> derivationBuilder;
  final DERIVABLEINDEX? defaultDerivation;
  final ScrollController controller;
  final Bip44Levels? fixedLevel;
  final String? buttonText;
  final Chain account;
  const SetupAddressDerivationIndex(
      {super.key,
      required this.derivationBuilder,
      required this.account,
      this.defaultDerivation,
      required this.controller,
      this.fixedLevel,
      this.buttonText});

  @override
  State<SetupAddressDerivationIndex<DERIVABLEINDEX, DERIVATION>> createState() =>
      _SetupAddressDerivationIndex2State<DERIVABLEINDEX, DERIVATION>();
}

abstract class SetupAddressDerivationState<
    T extends StatefulWidget,
    DERIVABLEINDEX extends DerivableIndex,
    DERIVATION extends NetDerivation<DERIVABLEINDEX>> extends State<T> with SafeState<T> {
  Chain get account;
  final StreamPageProgressController controller =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  NetDerivationBuilder<DERIVABLEINDEX, DERIVATION, CryptoCoins,
      AddressDerivedIndex<DERIVABLEINDEX>> get derivationBuilder;
  DERIVABLEINDEX? get defaultDerivation;
  ScrollController get scrollController;
  List<ViewDerivationKeyModel<DERIVABLEINDEX, DERIVATION>> derivationKeys = [];
  late ViewDerivationKeyModel<DERIVABLEINDEX, DERIVATION> derivationKey;
  late DERIVATION nextKeyIndex;

  late final bool useByronLegacyDeriavation =
      derivationBuilder.coin.proposal == CoinProposal.cip0019;
  List<ViewImportedSecretKey> customKeys = [];
  Map<ViewDerivationKeyModel<DERIVABLEINDEX, DERIVATION>, Widget> items = {};

  final generateAddressKey = GlobalKey();

  void onChangeDerivationKey(ViewDerivationKeyModel<DERIVABLEINDEX, DERIVATION>? key) {
    if (key == null || key == derivationKey) return;
    derivationKey = key;
    final index =
        derivationKey.onCustomDerivation(nextKeyIndex, derivationKeyChanged: true);
    nextKeyIndex = index ?? derivationKey.next();
    updateState();
  }

  Future<void> onChangeDerivation(
      CHANGEDERIVATIONCALLBACK<DERIVABLEINDEX> onGenerateDerivation) async {
    assert(derivationKey.allowDerivation);
    if (!derivationKey.allowDerivation) return;
    final index = await onGenerateDerivation();
    if (index == null) return;
    final derivationIndex =
        derivationKey.onCustomDerivation(nextKeyIndex.copyWith(nextIndex: index).cast());
    if (derivationIndex == null) {
      context.showAlert("invalid_key_derivation".tr);
      return;
    }
    nextKeyIndex = derivationIndex;
    updateState();
  }

  void onSubmit() {
    final derivationIndex = derivationKey.isValidDeration(nextKeyIndex);
    if (derivationIndex == null) {
      context.showAlert("invalid_key_derivation".tr);
      return;
    }
    context.pop(derivationIndex);
  }

  void buildKeys() {
    final wallet = context.wallet.wallet.wallet;
    final mainWalletDerivation = ViewDerivationKeyModel<DERIVABLEINDEX, DERIVATION>(
        name: wallet.name,
        created: wallet.created,
        allowDerivation: true,
        derivationBuilder: derivationBuilder,
        icon: Icon(Icons.account_balance_wallet_rounded));
    final List<ViewDerivationKeyModel<DERIVABLEINDEX, DERIVATION>> keys = [
      mainWalletDerivation
    ];
    final sWIcon = Icon(Icons.account_balance_wallet_outlined);
    for (final i in wallet.subWallets) {
      switch (i.type) {
        case SubWalletType.bip39:
          break;
        case SubWalletType.monero:
          if (account.network.type == NetworkType.monero) break;
          continue;
        case SubWalletType.ton:
          if (account.network.type == NetworkType.ton) break;
          continue;
      }
      keys.add(ViewDerivationKeyModel<DERIVABLEINDEX, DERIVATION>(
          name: i.name,
          created: i.created,
          derivationBuilder: derivationBuilder,
          subId: i,
          allowDerivation: i.type.allowDerivation,
          icon: sWIcon));
    }

    for (final i in customKeys) {
      keys.add(ViewDerivationKeyModel<DERIVABLEINDEX, DERIVATION>(
          name: i.name,
          created: i.created,
          derivationBuilder: derivationBuilder,
          importedKey: i,
          allowDerivation: i.allowDerivation(derivationBuilder.coin),
          icon: Icon(Icons.key)));
    }

    derivationKeys = keys;
    DERIVABLEINDEX? defaultIndex = defaultDerivation;
    if (defaultIndex == null ||
        (defaultIndex.subId == null && defaultIndex.importedKeyId == null)) {
      derivationKey = mainWalletDerivation;
    } else {
      final currentDerivationKey = keys.firstWhereOrNull((e) =>
          e.subId?.id == defaultIndex?.subId &&
          e.importedKey?.id == defaultIndex?.importedKeyId);
      assert(currentDerivationKey != null, "default index derivation key not found.");
      if (currentDerivationKey == null) {
        defaultIndex = null;
      }
      derivationKey = currentDerivationKey ?? mainWalletDerivation;
    }
    nextKeyIndex = derivationKey.next(derivationIndex: defaultIndex);
  }

  Map<ViewDerivationKeyModel<DERIVABLEINDEX, DERIVATION>, Widget> buildKeysItems() {
    return {for (final i in derivationKeys) i: ViewDerivationKeyModelWidget(i)};
  }

  Future<void> init() async {
    final customKeys =
        await context.wallet.wallet.doAction(WalletActionViewImportedAccounts());
    assert(customKeys.isOk, "failed to get imported accounts.");
    this.customKeys =
        customKeys.ok()?.where((e) => e.canUseFor(derivationBuilder.coin)).toList() ?? [];
    buildKeys();
    items = buildKeysItems();

    controller.backToIdle();
    MethodUtils.executeAfterDelay(() async {
      generateAddressKey.ensureKeyVisible();
    }, duration: APPConst.animationDuraion);
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    init();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("setup_derivation".tr)),
      body: StreamPageProgress(
        controller: controller,
        builder: (context) => CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverConstraintsBoxView(
              padding: WidgetConstant.padding20,
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AlertTextContainer(
                        message: "custom_key_derivation_desc".tr, enableTap: false),
                    WidgetConstant.height20,
                    Text("derivation_path".tr, style: context.textTheme.titleMedium),
                    WidgetConstant.height8,
                    ContainerWithBorder(
                        onRemove: derivationKey.allowDerivation
                            ? () {
                                onChangeDerivation(
                                  () async {
                                    if (useByronLegacyDeriavation) {
                                      return context.openSliverBottomSheet<
                                              DERIVABLEINDEX>("key_derivation".tr,
                                          child: ByronLegacyKeyDerivationView(
                                              coin: derivationBuilder.coin,
                                              curve: derivationBuilder.coin.conf.type));
                                    }
                                    return context.openMaxExtendSliverBottomSheet<
                                            DERIVABLEINDEX>("key_derivation".tr,
                                        child: Bip32KeyDerivationView(
                                            coin: derivationBuilder.coin,
                                            defaultPath: nextKeyIndex.nextIndex.hdPath,
                                            seedGeneration:
                                                derivationBuilder.seedGenerationType),
                                        centerContent: false);
                                  },
                                );
                              }
                            : null,
                        onRemoveIcon:
                            Icon(Icons.edit, color: context.colors.onPrimaryContainer),
                        child: APPAnimated(
                          isActive: derivationKey.allowDerivation,
                          onActive: (context) => FullWidthWrapper(
                            key: ValueKey(nextKeyIndex),
                            child: AddressDrivationInfo(
                              nextKeyIndex.nextIndex,
                              style: context.onPrimaryTextTheme.bodyLarge,
                            ),
                          ),
                          onDeactive: (context) => FullWidthWrapper(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("non_derivation".tr,
                                    style: context.textTheme.labelLarge),
                                ErrorTextContainer(
                                    error: "key_derivation_disabled_desc".tr,
                                    showErrorIcon: false)
                              ],
                            ),
                          ),
                        )),
                    WidgetConstant.height20,
                    Text("select_creation_type".tr, style: context.textTheme.titleMedium),
                    Text("generate_from_hd_wallet".tr),
                    WidgetConstant.height8,
                    AppDropDownBottom(
                        items: items,
                        value: derivationKey,
                        onChanged: onChangeDerivationKey,
                        isDense: false,
                        isExpanded: true),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FixedElevatedButton(
                            key: generateAddressKey,
                            padding: WidgetConstant.paddingVertical40,
                            onPressed: onSubmit,
                            child: Text("setup_derivation".tr))
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupAddressDerivationIndex2State<DERIVABLEINDEX extends DerivableIndex,
        DERIVATION extends NetDerivation<DERIVABLEINDEX>>
    extends SetupAddressDerivationState<
        SetupAddressDerivationIndex<DERIVABLEINDEX, DERIVATION>,
        DERIVABLEINDEX,
        DERIVATION> {
  @override
  Chain get account => widget.account;
  @override
  NetDerivationBuilder<DERIVABLEINDEX, DERIVATION, CryptoCoins,
          AddressDerivedIndex<DERIVABLEINDEX>>
      get derivationBuilder => widget.derivationBuilder;
  @override
  DERIVABLEINDEX? get defaultDerivation => widget.defaultDerivation;

  @override
  ScrollController get scrollController => widget.controller;
}

class ViewDerivationKeyModelWidget extends StatelessWidget {
  final ViewDerivationKeyModel derivationKey;
  const ViewDerivationKeyModelWidget(this.derivationKey, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      derivationKey.icon,
      WidgetConstant.width8,
      Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(derivationKey.name, style: context.textTheme.bodyMedium),
        Text(derivationKey.createdAt, style: context.textTheme.bodySmall)
      ]))
    ]);
  }
}

class ViewDerivationKeyModel<DERIVABLEINDEX extends DerivableIndex,
    DERIVATION extends NetDerivation<DERIVABLEINDEX>> {
  final String name;
  final String createdAt;
  final ViewImportedSecretKey? importedKey;
  final ViewSubWalletKey? subId;
  final bool allowDerivation;
  final Icon icon;
  final ViewImportedSecretKey? customKey;
  final NetDerivationBuilder<DERIVABLEINDEX, DERIVATION, CryptoCoins,
      AddressDerivedIndex<DERIVABLEINDEX>> derivationBuilder;
  bool get isMainWallet => subId == null && importedKey == null;
  bool get isSubWallet => subId != null;
  bool get isImportedKey => importedKey != null;

  DERIVATION? isValidDeration(DERIVATION derivation) {
    if (derivationBuilder.isValidIndex(derivation.nextIndex,
        importedKey: importedKey, subId: subId)) {
      return derivation;
    }
    return null;
  }

  DERIVATION next({DERIVATION? defaultIndex, DERIVABLEINDEX? derivationIndex}) {
    assert(defaultIndex == null || derivationIndex == null);
    DERIVATION? currentIndex = defaultIndex;
    if (currentIndex == null && derivationIndex != null) {
      currentIndex = derivationBuilder
          .getDefaultDerivation(subId: subId, importedKey: importedKey)
          .copyWith(nextIndex: derivationIndex)
          .cast();
    }
    return derivationBuilder.next(
        currentIndex: defaultIndex, importedKey: importedKey, subId: subId);
  }

  DERIVATION? onCustomDerivation(DERIVATION derivation,
      {bool derivationKeyChanged = false}) {
    DERIVABLEINDEX index = derivation.nextIndex.asMainWallet().cast<DERIVABLEINDEX>();
    final subId = this.subId;
    final importedKey = this.importedKey;
    if (subId != null) {
      index = index.asSubWalletKey(subId.id).cast<DERIVABLEINDEX>();
    }
    if (importedKey != null) {
      index = index.asImportedKey(importedKey.id).cast<DERIVABLEINDEX>();
    }
    if (derivationKeyChanged && index.isMaster && allowDerivation) {
      return next();
    }

    if (derivationBuilder.isValidIndex(index, subId: subId, importedKey: importedKey)) {
      return next(defaultIndex: derivation.copyWith(nextIndex: index).cast());
    }
    return null;
  }

  ViewDerivationKeyModel(
      {required this.name,
      required this.derivationBuilder,
      required DateTime created,
      required this.allowDerivation,
      this.customKey,
      required this.icon,
      this.importedKey,
      this.subId})
      : createdAt = created.toDateAndTime();
}
