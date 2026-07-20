import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/next_derivation.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart' show Chain, WalletNetwork;
import 'package:on_chain_wallet/crypto/crypto.dart';

typedef _OnGenerateDerivation = Future<DerivableIndex?> Function();
typedef ADDRESSDNEXTDERIVATION = NetDerivation Function(
    {required CryptoCoins coin, required SeedTypes seedGeneration, required int? subId});

/// TODO
@Deprecated("Merge to SetupAddressDerivationIndex")
class SetupDerivationModeView extends StatefulWidget {
  final CryptoCoins coin;
  final Chain chainAccout;
  final DerivableIndex? defaultDerivation;
  final SeedTypes seedGenerationType;
  final ScrollController controller;
  final ADDRESSDNEXTDERIVATION? nextAddressDerivationBuilder;
  final Bip44Levels? fixedLevel;
  final String? buttonText;
  const SetupDerivationModeView(
      {super.key,
      required this.coin,
      required this.chainAccout,
      this.defaultDerivation,
      required this.seedGenerationType,
      required this.controller,
      this.fixedLevel,
      this.nextAddressDerivationBuilder,
      this.buttonText});

  @override
  State<SetupDerivationModeView> createState() => _SetupDerivationModeView2State();
}

class _SetupDerivationModeView2State extends State<SetupDerivationModeView>
    with SafeState<SetupDerivationModeView> {
  final StreamPageProgressController controller =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  List<ViewDerivationKeyModel> derivationKeys = [];
  late ViewDerivationKeyModel derivationKey;
  late DerivableIndex nextKeyIndex;
  DerivableIndex? customKeyIndex;
  WalletNetwork get network => chainAccount.network;
  Chain get chainAccount => widget.chainAccout;
  CryptoCoins get coin => widget.coin;
  late final bool useByronLegacyDeriavation = coin.proposal == CoinProposal.cip0019;
  List<ViewImportedSecretKey> customKeys = [];
  bool get derivationStandard => customKeyIndex == null;

  Map<ViewDerivationKeyModel, Widget> items = {};

  DerivableIndex _getNextDerivation() {
    // final defaultP = widget.defaultDerivation;
    // if (defaultP != null && defaultP.subId == derivationKey.subId) {
    //   return defaultP;
    // }
    final builder = widget.nextAddressDerivationBuilder ?? chainAccount.nextDerive;
    return builder(
            coin: coin,
            seedGeneration: widget.seedGenerationType,
            subId: derivationKey.subId)
        .nextIndex;
  }

  DerivableIndex getNextDerivation() {
    if (derivationKey.isImportedKey) {
      return derivationKey.master(coin, widget.seedGenerationType);
    }
    DerivableIndex nextDerivation = _getNextDerivation();
    return derivationKey.toCurrentKeyDerivation(nextDerivation);
  }

  final generateAddressKey = GlobalKey();

  void onChangeDerivationKey(ViewDerivationKeyModel? key) {
    if (key == null || key == derivationKey) return;
    customKeyIndex = null;
    derivationKey = key;

    if (key.allowDerivation) {
      nextKeyIndex = getNextDerivation();
    }
    updateState();
  }

  Future<void> onChangeDerivation(_OnGenerateDerivation onGenerateDerivation) async {
    assert(derivationKey.allowDerivation);
    if (derivationStandard) {
      final index = customKeyIndex = await onGenerateDerivation();
      if (index != null) {
        customKeyIndex = derivationKey.toCurrentKeyDerivation(index);
      }
    } else {
      customKeyIndex = null;
    }
    updateState();
  }

  void onSubmit() {
    final key = derivationKey.toDerivationIndex(
        coin: coin,
        customKeyIndex: customKeyIndex,
        defaultKeyIndex: nextKeyIndex,
        seedGeneration: widget.seedGenerationType);
    assert(derivationKey.importedKey == key.importedKeyId,
        "imported key ${derivationKey.importedKey} ${key.importedKeyId}");
    assert(derivationKey.subId == key.subId);
    assert(widget.seedGenerationType == key.seedGeneration);
    context.pop(key);
  }

  void buildKeys() {
    final wallet = context.wallet.wallet.wallet;
    final mainWalletDerivation = ViewDerivationKeyModel(
        name: wallet.name,
        created: wallet.created,
        allowDerivation: true,
        icon: Icon(Icons.account_balance_wallet_rounded));
    final List<ViewDerivationKeyModel> keys = [mainWalletDerivation];
    final sWIcon = Icon(Icons.account_balance_wallet_outlined);
    for (final i in wallet.subWallets) {
      switch (i.type) {
        case SubWalletType.bip39:
          break;
        case SubWalletType.monero:
          if (network.type == NetworkType.monero) break;
          continue;
        case SubWalletType.ton:
          if (network.type == NetworkType.ton) break;
          continue;
      }
      keys.add(ViewDerivationKeyModel(
          name: i.name,
          created: i.created,
          subId: i.id,
          allowDerivation: i.type.allowDerivation,
          icon: sWIcon));
    }

    for (final i in customKeys) {
      keys.add(ViewDerivationKeyModel(
          name: i.name,
          created: i.created,
          importedKey: i.id,
          allowDerivation: i.allowDerivation(coin),
          icon: Icon(Icons.key)));
    }

    ViewDerivationKeyModel? findKey(int? subId, int? importedKeyId) {
      if (subId != null) {
        return keys.firstWhereNullable((e) => e.subId == subId);
      }
      if (importedKeyId != null) {
        return keys.firstWhereNullable((e) => e.importedKey == importedKeyId);
      }
      return mainWalletDerivation;
    }

    derivationKeys = keys;
    final defaultDerivation = widget.defaultDerivation;
    ViewDerivationKeyModel? currentDerivation;
    DerivableIndex? currentIndex;
    if (defaultDerivation != null) {
      final key = findKey(defaultDerivation.subId, defaultDerivation.importedKeyId);
      if (key != null) {
        currentDerivation = key;
        currentIndex = defaultDerivation;
      }
    }
    derivationKey = currentDerivation ?? mainWalletDerivation;
    nextKeyIndex = currentIndex ?? getNextDerivation();
  }

  Map<ViewDerivationKeyModel, Widget> buildKeysItems() {
    return {for (final i in derivationKeys) i: ViewDerivationKeyModelWidget(i)};
  }

  Future<void> init() async {
    final customKeys =
        await context.wallet.wallet.doAction(WalletActionViewImportedAccounts());
    assert(customKeys.isOk, "failed to get imported accounts.");
    this.customKeys = customKeys.ok()?.where((e) => e.canUseFor(coin)).toList() ?? [];
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
          controller: widget.controller,
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
                                      return context
                                          .openSliverBottomSheet<Bip32DerivationIndex>(
                                              "key_derivation".tr,
                                              child: ByronLegacyKeyDerivationView(
                                                  coin: coin, curve: coin.conf.type));
                                    }
                                    return context.openMaxExtendSliverBottomSheet<
                                            DerivableIndex>("key_derivation".tr,
                                        child: Bip32KeyDerivationView(
                                            coin: coin,
                                            fixedLevel: widget.fixedLevel,
                                            defaultPath: nextKeyIndex.hdPath,
                                            seedGeneration: widget.seedGenerationType),
                                        centerContent: false);
                                  },
                                );
                              }
                            : null,
                        onRemoveIcon: ConditionalWidgets<bool>(
                            enable: derivationStandard,
                            widgets: {
                              true: (e) => Icon(Icons.edit,
                                  color: context.colors.onPrimaryContainer),
                              false: (e) => Icon(Icons.remove_circle,
                                  color: context.colors.onPrimaryContainer)
                            }),
                        child: APPAnimated(
                          isActive: derivationKey.allowDerivation,
                          onActive: (context) => FullWidthWrapper(
                            key: ValueKey(customKeyIndex ?? nextKeyIndex),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    derivationStandard
                                        ? "standard_derivation".tr
                                        : "custom_derivation".tr,
                                    style: context.textTheme.labelLarge),
                                AddressDrivationInfo(customKeyIndex ?? nextKeyIndex)
                              ],
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
                            child: Text(widget.buttonText ?? "generate_address".tr))
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

class ViewDerivationKeyModel {
  final String name;
  final String createdAt;
  final int? importedKey;
  final int? subId;
  final bool allowDerivation;
  final Icon icon;
  final ViewImportedSecretKey? customKey;
  bool get isMainWallet => subId == null && importedKey == null;
  bool get isSubWallet => subId != null;
  bool get isImportedKey => importedKey != null;
  DerivableIndex master(CryptoCoins coin, SeedTypes seedGenerationType) {
    DerivableIndex index = switch (coin) {
      SubstrateCoins coin => SubstrateDerivationIndex(currencyCoin: coin),
      _ => Bip32DerivationIndex(currencyCoin: coin, seedGeneration: seedGenerationType)
    };
    final subId = this.subId;
    final importedKey = this.importedKey;
    if (subId != null) {
      index = index.asSubWalletKey(subId);
    }
    if (importedKey != null) {
      index = index.asImportedKey(importedKey);
    }
    return index;
  }

  DerivableIndex defaultIndex(CryptoCoins coin, SeedTypes seedGenerationType) {
    DerivableIndex index = switch (coin) {
      BipCoins coin when allowDerivation =>
        Bip32DerivationIndex.defaultBip(coin: coin, seedGeneration: seedGenerationType),
      ZIP32Coins coin when allowDerivation =>
        Bip32DerivationIndex.defaultZip(coin: coin, seedGeneration: seedGenerationType),
      SubstrateCoins coin => SubstrateDerivationIndex(currencyCoin: coin),
      _ => Bip32DerivationIndex(currencyCoin: coin, seedGeneration: seedGenerationType)
    };
    final subId = this.subId;
    final importedKey = this.importedKey;
    if (subId != null) {
      index = index.asSubWalletKey(subId);
    }
    if (importedKey != null) {
      index = index.asImportedKey(importedKey);
    }
    return index;
  }

  DerivableIndex toCurrentKeyDerivation(DerivableIndex index) {
    assert(index.isMaster || allowDerivation);
    if (!index.isMaster && !allowDerivation) {
      return defaultIndex(index.currencyCoin, index.seedGeneration);
    }
    final subId = this.subId;
    final importedKey = this.importedKey;
    if (subId != null) {
      index = index.asSubWalletKey(subId);
    }
    if (importedKey != null) {
      index = index.asImportedKey(importedKey);
    }
    assert(index.subId == subId && index.importedKeyId == importedKey);
    if (index.subId == subId && index.importedKeyId == importedKey) {
      return index;
    }
    return defaultIndex(index.currencyCoin, index.seedGeneration);
  }

  DerivableIndex toDerivationIndex(
      {required DerivableIndex defaultKeyIndex,
      required DerivableIndex? customKeyIndex,
      required CryptoCoins coin,
      required SeedTypes seedGeneration}) {
    final importedKey = this.importedKey;
    final subId = this.subId;
    if (!allowDerivation) {
      final keyIndex = switch (coin.proposal) {
        CoinProposal.substrate =>
          SubstrateDerivationIndex(currencyCoin: coin as SubstrateCoins),
        _ => Bip32DerivationIndex(currencyCoin: coin, seedGeneration: seedGeneration)
      };
      if (importedKey != null) {
        return keyIndex.asImportedKey(importedKey);
      }
      if (subId != null) return keyIndex.asSubWalletKey(subId);
      return keyIndex;
    }
    DerivableIndex keyIndex = customKeyIndex ?? defaultKeyIndex;
    if (subId != null) return keyIndex.asSubWalletKey(subId);
    if (importedKey != null) return keyIndex.asImportedKey(importedKey);
    return keyIndex;
  }

  ViewDerivationKeyModel(
      {required this.name,
      required DateTime created,
      required this.allowDerivation,
      this.customKey,
      required this.icon,
      this.importedKey,
      this.subId})
      : createdAt = created.toDateAndTime();
}
