import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/wallet/models/access/wallet_access.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/crypto/crypto.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';

class PublicKeyDerivationView extends StatelessWidget {
  const PublicKeyDerivationView(
      {required this.controller,
      this.pubKeyMode = PubKeyModes.compressed,
      required this.coins,
      this.exclude = const [],
      super.key});
  final ScrollController controller;
  final List<CryptoCoins> coins;
  final PubKeyModes? pubKeyMode;
  final List<DerivableIndex> exclude;
  @override
  Widget build(BuildContext context) {
    return AccessWalletView<WalletCredentialResponseLogin, WalletCredentialLogin>(
      request: WalletCredentialLogin.instance,
      controller: controller,
      title: "generate_public_key".tr,
      onAccsess: (credential) {
        return _PublicKeyDerivationView(
          coins: coins,
          controller: controller,
          pubKeyMode: pubKeyMode,
          exclude: exclude,
        );
      },
    );
  }
}

typedef _OnGenerateDerivation = Future<DerivableIndex?> Function();

class _PublicKeyDerivationView extends StatefulWidget {
  final ScrollController controller;
  final List<CryptoCoins> coins;
  final PubKeyModes? pubKeyMode;
  final List<DerivableIndex> exclude;
  const _PublicKeyDerivationView(
      {required this.coins,
      required this.controller,
      this.pubKeyMode,
      required this.exclude});

  @override
  State<_PublicKeyDerivationView> createState() => __PublicKeyDerivationView2State();
}

class __PublicKeyDerivationView2State extends State<_PublicKeyDerivationView>
    with SafeState<_PublicKeyDerivationView> {
  late WalletProvider walletProvider;
  final StreamPageProgressController controller =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  List<ViewDerivationKeyModel> derivationKeys = [];
  late ViewDerivationKeyModel derivationKey;
  late DerivableIndex nextKeyIndex;
  List<CryptoCoins> get coins => widget.coins;
  CryptoPublicKeyDataWithInfo? generatedKey;
  late CryptoCoins coin;
  bool useByronLegacyDeriavation = false;
  bool get showKeyMode => widget.pubKeyMode == null;
  List<ViewImportedSecretKey> importedKeys = [];
  SeedTypes seedType = SeedTypes.bip39;
  List<ViewImportedSecretKey> customKeys = [];
  bool get derivationStandard => customKeyIndex == null;
  DerivableIndex? customKeyIndex;
  Map<CryptoCoins, Widget> coinItems = {};
  final generateAddressKey = GlobalKey();
  Map<ViewDerivationKeyModel, Widget> items = {};
  List<PubKeyModes> keyModes = [PubKeyModes.compressed, PubKeyModes.uncompressed];
  PubKeyModes keyMode = PubKeyModes.compressed;

  void onChangeKeyMode(PubKeyModes? mode) {
    if (mode == null || !showKeyMode) return;
    keyMode = mode;
    updateState();
  }

  List<PubKeyModes> builKeyModes(CryptoPublicKeyDataWithInfo key) {
    return [
      PubKeyModes.compressed,
      if (key.key.uncomprossed != null) PubKeyModes.uncompressed,
    ];
  }

  Map<ViewDerivationKeyModel, Widget> buildKeysItems() {
    return {for (final i in derivationKeys) i: ViewDerivationKeyModelWidget(i)};
  }

  void onChangeDerivationKey(ViewDerivationKeyModel? key) {
    if (key == null || key == derivationKey) return;
    customKeyIndex = null;
    derivationKey = key;
    if (key.allowDerivation) {
      nextKeyIndex = getNextDerivation();
    }
    updateState();
  }

  void onChangeDerivation(_OnGenerateDerivation onGenerateDerivation) async {
    if (derivationStandard) {
      customKeyIndex = await onGenerateDerivation();
    } else {
      customKeyIndex = null;
    }
    updateState();
  }

  SeedTypes _findSeedType(CryptoCoins coin) {
    if (coin is SubstrateCoins) {
      return SeedTypes.bip39Entropy;
    }
    if (coin == Cip0019Coins.byronLegacy || coin == Cip0019Coins.byronLegacyTestnet) {
      return SeedTypes.byronLegacySeed;
    }
    switch (coin) {
      case Bip44Coins.cardanoByronIcarus:
      case Bip44Coins.cardanoByronIcarusTestnet:
      case Cip1852Coins.cardanoIcarus:
      case Cip1852Coins.cardanoIcarusTestnet:
        return SeedTypes.icarus;
      default:
        return SeedTypes.bip39;
    }
  }

  void onChangeCoin(CryptoCoins? coin) {
    if (coin == null) return;
    this.coin = coin;
    useByronLegacyDeriavation = coin.proposal == CoinProposal.cip0019;
    customKeys = importedKeys.where((e) => e.canUseFor(coin)).toList();
    seedType = _findSeedType(coin);
    customKeyIndex = null;
    buildKeys(coin);
    items = buildKeysItems();

    updateState();
  }

  DerivableIndex getNextDerivation() {
    final index = BipDerivationUtils.generateAccountNextKeyIndex(
            coin: coin, seedGenerationType: seedType, exclude: widget.exclude)
        .nextIndex;
    return derivationKey.toCurrentKeyDerivation(index);
  }

  void buildKeys(CryptoCoins coin) {
    final wallet = walletProvider.wallet.wallet;
    final mainWalletDerivation = ViewDerivationKeyModel(
        name: wallet.name,
        created: wallet.created,
        allowDerivation: true,
        icon: Icon(Icons.account_balance_wallet_rounded));
    final List<ViewDerivationKeyModel> keys = [mainWalletDerivation];
    final sWIcon = Icon(Icons.account_balance_wallet_outlined);
    final type = coin.conf.type;
    for (final i in wallet.subWallets) {
      if (i.type.allowUsFor(type)) {
        keys.add(ViewDerivationKeyModel(
            name: i.name,
            created: i.created,
            subId: i.id,
            allowDerivation: i.type.allowDerivation,
            icon: sWIcon));
      }
    }

    for (final i in customKeys) {
      keys.add(ViewDerivationKeyModel(
          name: i.name,
          created: i.created,
          importedKey: i.id,
          customKey: i,
          allowDerivation: i.allowDerivation(coin),
          icon: Icon(Icons.key)));
    }
    derivationKeys = keys;
    derivationKey = mainWalletDerivation;
    nextKeyIndex = getNextDerivation();
  }

  Future<void> init() async {
    final importedKeys =
        await context.wallet.wallet.doAction(WalletActionViewImportedAccounts());
    assert(importedKeys.isOk);
    this.importedKeys = importedKeys.ok() ?? [];
    coinItems = {
      for (final i in coins)
        i: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          OneLineTextWidget(i.coinName.camelCaseToSpaced),
          Text(i.proposal.name.camelCase, style: context.textTheme.bodySmall)
        ])
    };
    onChangeCoin(coins.first);
    controller.backToIdle();
  }

  void onBackButton() {
    if (generatedKey == null) return;
    generatedKey = null;
    updateState();
  }

  Future<void> onGenerateKey() async {
    controller.progressText("generating_public_key_please_wait".tr);
    final index = derivationKey.toDerivationIndex(
        coin: coin,
        customKeyIndex: customKeyIndex,
        defaultKeyIndex: nextKeyIndex,
        seedGeneration: seedType);
    final publicKey = await context.wallet.wallet
        .doAction(WalletActionDerivableIndexPublicKey(index: index));
    if (publicKey.isErr) {
      controller.errorText(publicKey.unwrapErr().localizationError,
          backToIdle: false, showBackButton: true);
      return;
    }
    if (showKeyMode) {
      keyModes = builKeyModes(publicKey.unwrap());
      keyMode = keyModes.first;
    }

    generatedKey = publicKey.unwrap();
    controller.backToIdle();
  }

  void onSubmit() {
    final key = generatedKey;
    if (key == null) return;
    context.pop(PublicKeyDerivationWithMode(derivation: key, mode: keyMode));
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    keyMode = widget.pubKeyMode ?? PubKeyModes.compressed;
    walletProvider = context.wallet;
    init();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) => onBackButton(),
      child: StreamPageProgress(
          controller: controller,
          builder: (context) {
            return CustomScrollView(
              controller: widget.controller,
              slivers: [
                SliverConstraintsBoxView(
                    padding: WidgetConstant.paddingHorizontal20,
                    sliver: SliverToBoxAdapter(
                      child: APPAnimated(
                        isActive: generatedKey == null,
                        onActive: (context) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppDropDownBottom<CryptoCoins>(
                                items: coinItems,
                                value: coin,
                                isExpanded: true,
                                isDense: false,
                                onChanged: onChangeCoin,
                                hint: "shelley_address_format".tr),
                            WidgetConstant.height20,
                            Text("derivation_path".tr,
                                style: context.textTheme.titleMedium),
                            WidgetConstant.height8,
                            ContainerWithBorder(
                                onRemove: derivationKey.allowDerivation ? () {} : null,
                                enableTap: false,
                                onRemoveWidget: IconButton(
                                    onPressed: () {
                                      onChangeDerivation(
                                        () async {
                                          if (useByronLegacyDeriavation) {
                                            return context.openSliverBottomSheet<
                                                    Bip32DerivationIndex>(
                                                "key_derivation".tr,
                                                child: ByronLegacyKeyDerivationView(
                                                    coin: coin, curve: coin.conf.type));
                                          }
                                          return context.openMaxExtendSliverBottomSheet<
                                                  DerivableIndex>("key_derivation".tr,
                                              child: Bip32KeyDerivationView(
                                                  coin: coin,
                                                  defaultPath: nextKeyIndex.hdPath,
                                                  seedGeneration: seedType),
                                              centerContent: false);
                                        },
                                      );
                                    },
                                    icon: ConditionalWidgets<bool>(
                                        enable: derivationStandard,
                                        widgets: {
                                          true: (e) => Icon(Icons.edit,
                                              color: context.colors.onPrimaryContainer),
                                          false: (e) => Icon(Icons.remove_circle,
                                              color: context.colors.onPrimaryContainer)
                                        })),
                                // onRemoveIcon:,
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
                                              AddressDrivationInfo(
                                                  customKeyIndex ?? nextKeyIndex)
                                            ],
                                          ),
                                        ),
                                    onDeactive: (context) => Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("non_derivation".tr,
                                                style: context.textTheme.labelLarge),
                                            ErrorTextContainer(
                                                error: "key_derivation_disabled_desc".tr,
                                                showErrorIcon: false)
                                          ],
                                        ))),
                            WidgetConstant.height20,
                            Text("select_creation_type".tr,
                                style: context.textTheme.titleMedium),
                            Text("generate_from_hd_wallet".tr),
                            WidgetConstant.height8,
                            AppDropDownBottom(
                                key: ValueKey(coin),
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
                                    onPressed: onGenerateKey,
                                    child: Text("generate_public_key".tr))
                              ],
                            )
                          ],
                        ),
                        onDeactive: (context) => Column(children: [
                          PublicKeysDataView(publicKey: generatedKey!),
                          ConditionalWidget(
                              enable: showKeyMode,
                              onActive: (context) => Column(children: [
                                    Divider(),
                                    AppGroupRadioBuilder<PubKeyModes>(
                                      groupValue: keyMode,
                                      onChanged: onChangeKeyMode,
                                      builder: (context) {
                                        return Column(
                                            children: List.generate(keyModes.length, (i) {
                                          return AppRadioListTile<PubKeyModes>(
                                              title: Text(keyModes[i].name.camelCase),
                                              value: keyModes[i]);
                                        }));
                                      },
                                    ),
                                  ])),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FixedElevatedButton(
                                  padding: WidgetConstant.paddingVertical40,
                                  onPressed: onSubmit,
                                  child: Text('submit'.tr))
                            ],
                          )
                        ]),
                      ),
                    ))
              ],
            );
          }),
    );
  }
}
