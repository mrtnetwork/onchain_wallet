import 'package:blockchain_utils/bip/bip/bip.dart';
import 'package:blockchain_utils/bip/cardano/cip0019/conf/cip0019_coins.dart';
import 'package:blockchain_utils/blockchain_utils.dart'
    show ADAAddressType, Bip32PathParser, Bip44Coins, BytesUtils, Cip1852Coins;
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';

import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/crypto/crypto.dart';

typedef _OnChangeShellyAddrType = void Function(ADAAddressType? addrType);

enum _AdaEra {
  shelly("shelly"),
  byron("byron");

  final String name;
  const _AdaEra(this.name);
  bool get isShelly => this == _AdaEra.shelly;
  CryptoCoins getRelatedIcarusCardanoCoin(WalletCardanoNetwork network) {
    if (isShelly) {
      if (network.coinParam.mainnet) {
        return Cip1852Coins.cardanoIcarus;
      } else {
        return Cip1852Coins.cardanoIcarusTestnet;
      }
    } else {
      if (network.coinParam.mainnet) {
        return Bip44Coins.cardanoByronIcarus;
      } else {
        return Bip44Coins.cardanoByronIcarusTestnet;
      }
    }
  }

  CryptoCoins getRelatedLedgerCardanoCoin(WalletCardanoNetwork network) {
    if (isShelly) {
      if (network.coinParam.mainnet) {
        return Cip1852Coins.cardanoLedger;
      } else {
        return Cip1852Coins.cardanoLedgerTestnet;
      }
    } else {
      if (network.coinParam.mainnet) {
        return Bip44Coins.cardanoByronLedger;
      } else {
        return Bip44Coins.cardanoByronLedgerTestnet;
      }
    }
  }

  CryptoCoins getRelatedByronLegacy(WalletCardanoNetwork network) {
    if (isShelly) {
      throw AppInternalError.internalError("getRelatedByronLegacy");
    }
    if (network.coinParam.mainnet) {
      return Cip0019Coins.byronLegacy;
    } else {
      return Cip0019Coins.byronLegacyTestnet;
    }
  }
}

enum _CardanoMasterKeyGenerationType {
  ledger("ledger"),
  icarus("icarus"),
  byronLegacy("byronLegacy");

  final String name;
  const _CardanoMasterKeyGenerationType(this.name);
  bool get isLegacy => this == _CardanoMasterKeyGenerationType.byronLegacy;
}

enum _GenerateAddressPage { seedGeneration, era, masterKeyGeneration, generateAddress }

class SetupCardanoAddressView extends StatefulWidget {
  const SetupCardanoAddressView(this.chain, {super.key});
  final ADAChain chain;

  @override
  State<SetupCardanoAddressView> createState() => _SetupCardanoAddressViewState();
}

class _SetupCardanoAddressViewState extends State<SetupCardanoAddressView>
    with SafeState {
  final StreamPageProgressController pageProgressKey = StreamPageProgressController();
  final GlobalKey visibleGenerateAddress =
      GlobalKey(debugLabel: "_SetupCardanoAddressViewState_visibleContinue");
  final GlobalKey visibleXAddressDetails =
      GlobalKey(debugLabel: "_SetupCardanoAddressViewState_visibleContinue");
  final GlobalKey<FormState> form = GlobalKey<FormState>();
  final GlobalKey<AppTextFieldState> hdPathKeyKey =
      GlobalKey<AppTextFieldState>(debugLabel: "_SetupCardanoAddressViewState_hdPathKey");
  final GlobalKey<AppTextFieldState> hdPathKey =
      GlobalKey<AppTextFieldState>(debugLabel: "_SetupCardanoAddressViewState_hdPath");

  bool customDervation = false;
  late final ADAChain chainAccount = widget.chain;
  WalletCardanoNetwork get network => chainAccount.network;
  List<CryptoCoins> get coins => network.coins;
  late CryptoCoins coin = coins.first;
  bool inited = false;
  _AdaEra era = _AdaEra.shelly;
  _GenerateAddressPage page = _GenerateAddressPage.seedGeneration;
  _CardanoMasterKeyGenerationType keyGenerationType =
      _CardanoMasterKeyGenerationType.icarus;
  SeedTypes seedGenerationType = SeedTypes.icarus;
  ADAAddressType addrType = ADAAddressType.base;

  String? manuallyHdPath;
  String? manuallyHdPathKey;
  bool manuallySetLegacyHdPathKey = false;

  void onChageCustomDerivation() {
    customDervation = !customDervation;
    updateState();
  }

  void backToDefault() {
    era = _AdaEra.shelly;
    page = _GenerateAddressPage.seedGeneration;
    keyGenerationType = _CardanoMasterKeyGenerationType.icarus;
    seedGenerationType = SeedTypes.icarus;
    addrType = ADAAddressType.base;
    coin = era.getRelatedIcarusCardanoCoin(network);
    customDervation = false;
    updateState();
  }

  void onChangeManuallySetHdPathKey() {
    manuallySetLegacyHdPathKey = !manuallySetLegacyHdPathKey;
    if (!manuallySetLegacyHdPathKey) {
      manuallyHdPath = null;
      manuallyHdPathKey = null;
    }
    setState(() {});
  }

  void onChageHdPath(String path) {
    manuallyHdPath = path;
  }

  void onChangeHdPathKey(String v) {
    manuallyHdPathKey = v;
  }

  String? onValidateHdPath(String? v) {
    try {
      final parse = Bip32PathParser.parse(manuallyHdPath!);
      if (parse.elems.length != BlockchainConst.maxByronLegacyBip32LevelIndex) {
        return "byron_legacy_hd_wallet_length_desc".tr;
      }
    } catch (e) {
      return "invalid_byron_legacy_hd_path_key".tr;
    }
    return null;
  }

  String? onValidateHdPathKey(String? v) {
    try {
      final inBytes = BytesUtils.tryFromHexString(manuallyHdPathKey);
      if (inBytes == null) {
        return "byron_legacy_hd_path_key_desc".tr;
      }
      if (inBytes.length != CardanoUtils.byronAddressHdPathKeyLengthBytes) {
        return "byron_legacy_hd_path_key_length_desc".tr;
      }
    } catch (e) {
      return "byron_legacy_hd_path_key_desc".tr;
    }
    return null;
  }

  void onChangeEra(_AdaEra? e) {
    era = e ?? era;
    updateState();
  }

  void onContinueFromSeedGeneration() {
    if (!customDervation) {
      seedGenerationType = SeedTypes.icarus;
      era = _AdaEra.shelly;
      addrType = ADAAddressType.base;
      keyGenerationType = _CardanoMasterKeyGenerationType.icarus;
      onContinueFromMasterkeyGeneration();
      return;
    }

    page = _GenerateAddressPage.era;
    setState(() {});
  }

  void onContinueFromEra() {
    page = _GenerateAddressPage.masterKeyGeneration;
    if (era == _AdaEra.byron) {
      addrType = ADAAddressType.byron;
    } else {
      addrType = ADAAddressType.base;
      keyGenerationType = _CardanoMasterKeyGenerationType.icarus;
    }
    updateState();
  }

  bool get showLegacy => !era.isShelly && seedGenerationType == SeedTypes.byronLegacySeed;
  void onChangeMasterKeyGeneration(_CardanoMasterKeyGenerationType? masterKeyGeneration) {
    if (masterKeyGeneration == null) return;
    if (era.isShelly && masterKeyGeneration.isLegacy) return;
    keyGenerationType = masterKeyGeneration;
    updateState();
  }

  void onChangeSeedGeneration(SeedTypes? seedType) {
    seedGenerationType = seedType ?? seedGenerationType;
    updateState();
  }

  void onContinueFromMasterkeyGeneration() {
    switch (keyGenerationType) {
      case _CardanoMasterKeyGenerationType.icarus:
        coin = era.getRelatedIcarusCardanoCoin(network);
        break;
      case _CardanoMasterKeyGenerationType.byronLegacy:
        coin = era.getRelatedByronLegacy(network);
        break;
      default:
        coin = era.getRelatedLedgerCardanoCoin(network);
        break;
    }
    page = _GenerateAddressPage.generateAddress;
    updateState();
  }

  void onChangeShellyddrType(ADAAddressType? type) {
    if (type == null) return;
    if (era == _AdaEra.byron) return;
    if (type == ADAAddressType.pointer) return;
    addrType = type;
    updateState();
  }

  void generateAddress() async {
    if (!form.ready()) return;
    final result = await IResult.call(() async {
      pageProgressKey.progressText("generating_new_addr".tr);
      final model = context.wallet;
      Bip32DerivationIndex? keyIndex = await context
          .openMaxExtendSliverBottomSheet<Bip32DerivationIndex>("setup_derivation".tr,
              bodyBuilder: (controller) => SetupDerivationModeView(
                  coin: coin,
                  chainAccout: chainAccount,
                  seedGenerationType: seedGenerationType,
                  controller: controller));
      if (keyIndex == null) {
        return null;
      }
      keyIndex = keyIndex.copyWith(keyName: "base_key");
      Bip32DerivationIndex? stakeDerivation;
      if (addrType == ADAAddressType.base) {
        final defaultStakeKey = keyIndex.copyWith(
            changeLevel: CardanoUtils.bip32StakeChangeLevel,
            addressIndex: CardanoUtils.bip32StakeAddressLevel);
        // ignore: use_build_context_synchronously
        stakeDerivation = await context
            .openMaxExtendSliverBottomSheet<Bip32DerivationIndex>("setup_derivation".tr,
                bodyBuilder: (controller) => SetupDerivationModeView(
                      coin: coin,
                      chainAccout: chainAccount,
                      seedGenerationType: seedGenerationType,
                      defaultDerivation: defaultStakeKey,
                      controller: controller,
                    ));
        if (stakeDerivation == null) return null;
        stakeDerivation = stakeDerivation.copyWith(keyName: "stake_key");
      }
      if (addrType == ADAAddressType.base && keyIndex == stakeDerivation) {
        throw AppException("ada_base_stake_key_same_error");
      }
      String? hdPath;
      List<int>? hdPathKey;
      if (keyGenerationType.isLegacy) {
        if (manuallySetLegacyHdPathKey) {
          hdPath = CryptoKeyUtils.validateHdPathKey(manuallyHdPath!,
              maxIndex: BlockchainConst.maxByronLegacyBip32LevelIndex);
          if (hdPath == null) {
            throw AppException("invalid_hd_wallet_derivation_path");
          }
          hdPathKey = BytesUtils.tryFromHexString(manuallyHdPathKey!);
        } else {
          if (keyIndex.hdPath == null) {
            hdPath = "";
            hdPathKey = List<int>.filled(32, 0);
          }
        }
      }

      final newAccount = CardanoNewAddressParams(
          deriveIndex: keyIndex,
          addressType: addrType,
          rewardKeyIndex: stakeDerivation,
          customHdPath: hdPath,
          customHdPathKey: hdPathKey,
          coin: coin);
      final result = await model.wallet.doAction(WalletActionDeriveNewAccount(
          newAccountParams: newAccount, chain: chainAccount));
      return result.unwrap();
    });

    if (result.isErr) {
      pageProgressKey.errorText(result.unwrapErr().localizationError);
    }
    if (result.ok() == null) {
      pageProgressKey.backToIdle();
    } else {
      pageProgressKey.success(
          backToIdle: false,
          progressWidget: SuccessWithButtonView(
            buttonWidget: ContainerWithBorder(
                margin: WidgetConstant.paddingVertical8,
                child: AddressDetailsView(address: result.unwrap()!)),
            buttonText: "generate_new_address".tr,
            onPressed: () {
              backToDefault();
              pageProgressKey.backToIdle();
            },
          ));
    }
    updateState();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    pageProgressKey.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: form,
      canPop: pageProgressKey.isSuccess || page == _GenerateAddressPage.seedGeneration,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) backToDefault();
      },
      child: StreamPageProgress(
        controller: pageProgressKey,
        builder: (context) => Center(
          child: CustomScrollView(
            shrinkWrap: true,
            slivers: [
              SliverToBoxAdapter(
                  child: ConstraintsBoxView(
                padding: WidgetConstant.paddingHorizontal20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  key: const ValueKey<bool>(true),
                  children: [
                    AnimatedSwitcher(
                      duration: APPConst.animationDuraion,
                      child: page == _GenerateAddressPage.seedGeneration
                          ? _SelectSeedGenerationType(
                              seedGenerationType: seedGenerationType,
                              onChageSeedGeneration: onChangeSeedGeneration,
                              onContinue: onContinueFromSeedGeneration,
                              custom: customDervation,
                              onCustom: onChageCustomDerivation,
                            )
                          : page == _GenerateAddressPage.era
                              ? _SelectEra(
                                  era: era,
                                  onChangeEra: onChangeEra,
                                  onContinue: onContinueFromEra)
                              : page == _GenerateAddressPage.masterKeyGeneration
                                  ? _SelectMasterKeyGeneration(
                                      keyGenerationType: keyGenerationType,
                                      era: era,
                                      onChangeKeyGeneration: onChangeMasterKeyGeneration,
                                      onContinue: onContinueFromMasterkeyGeneration,
                                      seedGeneration: seedGenerationType,
                                    )
                                  : _GenerateAddress(
                                      network: network,
                                      addrType: addrType,
                                      generateAddress: generateAddress,
                                      coin: coin,
                                      era: era,
                                      hdPathKeyKey: hdPathKeyKey,
                                      keyGeneratorType: keyGenerationType,
                                      hdpathKey: hdPathKey,
                                      onChangedHdPath: onChageHdPath,
                                      onChangedHdPathKey: onChangeHdPathKey,
                                      validatorHdPath: onValidateHdPath,
                                      validatorHdPathKey: onValidateHdPathKey,
                                      onChangeShellyddrType: onChangeShellyddrType,
                                      hdPath: manuallyHdPath,
                                      hdPathKey: manuallyHdPathKey,
                                      manuallySetHdPathKey: manuallySetLegacyHdPathKey,
                                      onChangeManuallySetHdPathKey:
                                          onChangeManuallySetHdPathKey,
                                    ),
                    ),
                  ],
                ),
              ))
            ],
          ),
        ),
      ),
    );
  }
}

typedef _OnChangeEra = void Function(_AdaEra? era);

class _SelectEra extends StatelessWidget {
  const _SelectEra(
      {required this.era, required this.onChangeEra, required this.onContinue});
  final _AdaEra era;
  final _OnChangeEra onChangeEra;
  final DynamicVoid onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitleSubtitle(
            title: "cardano_era".tr,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("select_era_for_generate_addr".tr),
                WidgetConstant.height8,
                Text("recommended_address_type".tr)
              ],
            )),
        AppGroupRadioBuilder<_AdaEra>(
          groupValue: era,
          onChanged: onChangeEra,
          builder: (context) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppRadioListTile<_AdaEra>(
              title: Text("shelly".tr),
              value: _AdaEra.shelly,
            ),
            AppRadioListTile<_AdaEra>(
              value: _AdaEra.byron,
              title: Text("byron".tr),
            ),
          ]),
        ),
        WidgetConstant.height20,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(onPressed: onContinue, child: Text("continue".tr)),
          ],
        )
      ],
    );
  }
}

typedef _OnChangeMasterKeyGeneration = void Function(
    _CardanoMasterKeyGenerationType? era);

class _SelectMasterKeyGeneration extends StatelessWidget {
  const _SelectMasterKeyGeneration(
      {required this.keyGenerationType,
      required this.onChangeKeyGeneration,
      required this.onContinue,
      required this.era,
      required this.seedGeneration});
  final _CardanoMasterKeyGenerationType keyGenerationType;
  final _OnChangeMasterKeyGeneration onChangeKeyGeneration;
  final DynamicVoid onContinue;
  final _AdaEra era;
  final SeedTypes seedGeneration;
  bool get showLegacy => !era.isShelly && seedGeneration == SeedTypes.byronLegacySeed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitleSubtitle(
            title: "master_key_generation".tr,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("cardano_bip32_master_key".tr),
                WidgetConstant.height8,
                Text("choose_master_key_gen".tr)
              ],
            )),
        AppGroupRadioBuilder<_CardanoMasterKeyGenerationType>(
          groupValue: keyGenerationType,
          onChanged: onChangeKeyGeneration,
          builder: (context) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppRadioListTile<_CardanoMasterKeyGenerationType>(
              title: Text("ledger".tr),
              value: _CardanoMasterKeyGenerationType.ledger,
            ),
            AppRadioListTile<_CardanoMasterKeyGenerationType>(
              value: _CardanoMasterKeyGenerationType.icarus,
              title: Text("icarus".tr),
            ),
            if (showLegacy)
              AppRadioListTile<_CardanoMasterKeyGenerationType>(
                  value: _CardanoMasterKeyGenerationType.byronLegacy,
                  title: Text("byron_legacy".tr)),
          ]),
        ),
        WidgetConstant.height20,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(onPressed: onContinue, child: Text("continue".tr)),
          ],
        )
      ],
    );
  }
}

typedef _OnChangeSeedGeneration = void Function(SeedTypes? era);

class _SelectSeedGenerationType extends StatelessWidget {
  const _SelectSeedGenerationType(
      {required this.seedGenerationType,
      required this.onChageSeedGeneration,
      required this.onContinue,
      required this.custom,
      required this.onCustom});
  final SeedTypes seedGenerationType;
  final _OnChangeSeedGeneration onChageSeedGeneration;
  final DynamicVoid onContinue;
  final bool custom;
  final DynamicVoid onCustom;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCheckListTile(
          contentPadding: EdgeInsets.zero,
          value: custom,
          title:
              Text("customize_key_derivation".tr, style: context.textTheme.titleMedium),
          subtitle: Text("ada_customize_derivation_desc".tr),
          onChanged: (p0) => onCustom(),
        ),
        WidgetConstant.height20,
        APPAnimatedSize(
            isActive: custom,
            onActive: (p0) => AppGroupRadioBuilder(
                  onChanged: onChageSeedGeneration,
                  groupValue: seedGenerationType,
                  builder: (context) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("seed_generation".tr, style: context.textTheme.titleMedium),
                      Text("seed_generation_type".tr),
                      WidgetConstant.height8,
                      AppRadioListTile(value: SeedTypes.icarus, title: Text("icarus".tr)),
                      AppRadioListTile(
                          title: Text("byron_legacy_seed".tr),
                          value: SeedTypes.byronLegacySeed),
                      AppRadioListTile(
                          title: Text("bip39_seed".tr), value: SeedTypes.bip39),
                    ],
                  ),
                ),
            onDeactive: (p0) => WidgetConstant.sizedBox),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(
                padding: WidgetConstant.paddingVertical40,
                onPressed: onContinue,
                child: Text("continue".tr)),
          ],
        )
      ],
    );
  }
}

class _GenerateAddress extends StatelessWidget {
  const _GenerateAddress(
      {required this.network,
      required this.addrType,
      required this.generateAddress,
      required this.coin,
      required this.era,
      required this.onChangeShellyddrType,
      required this.hdpathKey,
      required this.hdPathKeyKey,
      required this.onChangedHdPath,
      required this.validatorHdPath,
      required this.onChangedHdPathKey,
      required this.validatorHdPathKey,
      required this.keyGeneratorType,
      required this.hdPath,
      required this.hdPathKey,
      required this.manuallySetHdPathKey,
      required this.onChangeManuallySetHdPathKey});
  final WalletCardanoNetwork network;
  final _AdaEra era;
  final ADAAddressType addrType;
  final CryptoCoins coin;
  final _OnChangeShellyAddrType onChangeShellyddrType;
  final DynamicVoid generateAddress;
  final GlobalKey<AppTextFieldState> hdpathKey;
  final GlobalKey<AppTextFieldState> hdPathKeyKey;
  final StringVoid onChangedHdPath;
  final NullStringString validatorHdPath;
  final StringVoid onChangedHdPathKey;
  final NullStringString validatorHdPathKey;
  final _CardanoMasterKeyGenerationType keyGeneratorType;
  final String? hdPath;
  final String? hdPathKey;
  final bool manuallySetHdPathKey;
  final DynamicVoid onChangeManuallySetHdPathKey;
  bool get isBaseAddress => addrType == ADAAddressType.base;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (era.isShelly) ...[
          WidgetConstant.height20,
          Text("shelley_address_format".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          AppDropDownBottom(
              items: {
                ADAAddressType.base: Text("base".tr),
                ADAAddressType.reward: Text("reward".tr),
                ADAAddressType.enterprise: Text("enterprise".tr),
              },
              value: addrType,
              onChanged: onChangeShellyddrType,
              hint: "shelley_address_format".tr),
          WidgetConstant.height20,
        ] else if (keyGeneratorType.isLegacy) ...[
          AppSwitchListTile(
            value: manuallySetHdPathKey,
            title: Text("manually_set_hd_path".tr),
            subtitle: Text("byron_legacy_hd_path_generate_from_master_key_desc".tr),
            onChanged: (p0) => onChangeManuallySetHdPathKey(),
          ),
          AnimatedSize(
            duration: APPConst.animationDuraion,
            alignment: Alignment.topCenter,
            child: manuallySetHdPathKey
                ? Column(
                    children: [
                      WidgetConstant.height8,
                      AppTextField(
                        label: "hd_path".tr,
                        key: hdpathKey,
                        onChanged: onChangedHdPath,
                        validator: validatorHdPath,
                        hint: CardanoUtils.hdPathHint,
                        initialValue: hdPath,
                      ),
                      AppTextField(
                        label: "hd_path_key".tr,
                        key: hdPathKeyKey,
                        onChanged: onChangedHdPathKey,
                        validator: validatorHdPathKey,
                        helperText: "byron_legacy_hd_path_key_desc2".tr,
                        hint: "0x950163...",
                        initialValue: hdPathKey,
                      ),
                    ],
                  )
                : WidgetConstant.sizedBox,
          )
        ],
        WidgetConstant.height20,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(
              padding: WidgetConstant.paddingVertical20,
              onPressed: generateAddress,
              child: Text("setup_derivation".tr),
            ),
          ],
        )
      ],
    );
  }
}
