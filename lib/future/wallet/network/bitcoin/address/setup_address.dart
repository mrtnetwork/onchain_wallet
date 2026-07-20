import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/crypto/networks/bitcoin/bitcoin.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class SetupBitcoinAddressView extends StatefulWidget {
  const SetupBitcoinAddressView(this.chain, {super.key});
  final BitcoinChain chain;

  @override
  State<SetupBitcoinAddressView> createState() => _SetupBitcoinAddressViewState();
}

class _SetupBitcoinAddressViewState extends State<SetupBitcoinAddressView>
    with SafeState<SetupBitcoinAddressView> {
  final StreamPageProgressController pageProgressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  late final BitcoinChain chainAccount = widget.chain;
  final GlobalKey visibleGenerateAddress =
      GlobalKey(debugLabel: "_SetupBitcoinAddressViewState_visibleContinue");

  WalletBitcoinNetwork get network => chainAccount.network;
  List<CryptoCoins> get coins => network.coins;
  bool inited = false;
  late final List<P2shAddressType> p2shTypes;
  late final List<P2pkhAddressType> p2pkhTypes;
  late final List<BitcoinAddressType> supportAddressTypes;
  late P2shAddressType p2shType;
  P2pkhAddressType p2pkhType = P2pkhAddressType.p2pkh;
  PubKeyModes keyType = PubKeyModes.compressed;
  bool supportUncompressedKey = true;
  late BitcoinAddressType selected;
  late final bool isSupportSegwit;
  late final bool isSupportP2tr;
  late final Map<BitcoinAddressType, String> typesToSelect;
  late final Map<BitcoinAddressType, Widget> typesWidget;
  String? recomendedTypeDescription;

  void onChangeKeyType() {
    if (!supportUncompressedKey) return;
    if (keyType.isCompressed) {
      keyType = PubKeyModes.uncompressed;
    } else {
      keyType = PubKeyModes.compressed;
    }
    updateState();
  }

  void canUseUncompressedPubKey() {
    final selectedType = correctAddressType();
    supportUncompressedKey = !selectedType.isSegwit &&
        (selectedType != P2shAddressType.p2wpkhInP2sh &&
            selectedType != P2shAddressType.p2wshInP2sh);
    if (!supportUncompressedKey) {
      keyType = PubKeyModes.compressed;
    }
  }

  void buildTypes() {
    typesToSelect = {
      P2pkhAddressType.p2pkh: P2pkhAddressType.p2pkh.name,
      if (supportAddressTypes.contains(P2shAddressType.p2pkhInP2sh))
        _defaultP2sh(): "P2SH",
      if (supportAddressTypes.contains(SegwitAddressType.p2wpkh))
        SegwitAddressType.p2wpkh: SegwitAddressType.p2wpkh.name,
      if (supportAddressTypes.contains(SegwitAddressType.p2wsh))
        SegwitAddressType.p2wsh: SegwitAddressType.p2wsh.name,
      if (supportAddressTypes.contains(SegwitAddressType.p2tr))
        SegwitAddressType.p2tr: SegwitAddressType.p2tr.name,
    };
    typesWidget = {for (final i in typesToSelect.entries) i.key: Text(i.value)};
    recomendedTypeDescription = typesToSelect[SegwitAddressType.p2tr] ??
        typesToSelect[SegwitAddressType.p2wpkh] ??
        typesToSelect[P2shAddressType.p2wpkhInP2sh] ??
        typesToSelect[P2shAddressType.p2pkInP2sh];
  }

  CryptoCoins findCoin() {
    return network.findCoinFromBitcoinAddressType(selected);
  }

  void _init() {
    if (inited) return;
    inited = true;
    supportAddressTypes = network.coinParam.transacationNetwork.supportedAddress;
    p2shTypes = supportAddressTypes.whereType<P2shAddressType>().toList();
    p2pkhTypes = supportAddressTypes.whereType<P2pkhAddressType>().toList();
    p2shType = _defaultP2sh();
    isSupportP2tr = supportAddressTypes.contains(SegwitAddressType.p2tr);
    isSupportSegwit = supportAddressTypes.contains(SegwitAddressType.p2wpkh);
    if (isSupportP2tr) {
      selected = SegwitAddressType.p2tr;
    } else if (isSupportSegwit) {
      selected = SegwitAddressType.p2wpkh;
    } else {
      selected = P2pkhAddressType.p2pkh;
    }
    buildTypes();
    canUseUncompressedPubKey();

    pageProgressKey.backToIdle();
  }

  P2shAddressType _defaultP2sh() {
    if (p2shTypes.contains(P2shAddressType.p2wpkhInP2sh)) {
      return P2shAddressType.p2wpkhInP2sh;
    }
    return P2shAddressType.p2pkInP2sh;
  }

  void onChangeSelected(BitcoinAddressType? value) {
    selected = value ?? selected;
    p2shType = _defaultP2sh();
    p2pkhType = P2pkhAddressType.p2pkh;
    canUseUncompressedPubKey();
    updateState();
  }

  void onChageSegwit(P2shAddressType? val) {
    if (!p2shTypes.contains(val)) return;
    p2shType = val ?? p2shType;
    canUseUncompressedPubKey();
    updateState();
  }

  void onChangeP2pkh(P2pkhAddressType? val) {
    if (!p2pkhTypes.contains(val)) return;
    p2pkhType = val ?? p2pkhType;
    canUseUncompressedPubKey();
    updateState();
  }

  BitcoinAddressType correctAddressType() {
    if (selected == _defaultP2sh()) {
      return p2shType;
    } else if (selected == P2pkhAddressType.p2pkh) {
      return p2pkhType;
    } else {
      return selected;
    }
  }

  Future<void> generateAddress() async {
    final wallet = context.wallet;
    final coin = findCoin();
    final BitcoinAddressType selectedType = correctAddressType();

    final Bip32DerivationIndex? keyIndex = await context
        .openMaxExtendSliverBottomSheet<Bip32DerivationIndex>("setup_derivation".tr,
            bodyBuilder: (controller) => SetupDerivationModeView(
                coin: coin,
                chainAccout: chainAccount,
                seedGenerationType: SeedTypes.bip39,
                controller: controller));

    if (keyIndex == null) return;

    pageProgressKey.progressText("generating_new_addr".tr);
    NewAccountParams newAccount;
    if (network.type == NetworkType.bitcoinCash) {
      newAccount = BitcoinCashNewAddressParams(
          deriveIndex: keyIndex,
          bitcoinAddressType: selectedType,
          coin: coin,
          keyType: keyType);
    } else {
      newAccount = BitcoinNewAddressParams(
          deriveIndex: keyIndex,
          bitcoinAddressType: selectedType,
          coin: coin,
          keyType: keyType);
    }

    final result = await wallet.wallet.doAction(
        WalletActionDeriveNewAccount(newAccountParams: newAccount, chain: chainAccount));
    if (result.isErr) {
      pageProgressKey.errorText(result.unwrapErr().localizationError);
    } else {
      pageProgressKey.success(
          backToIdle: false,
          progressWidget: SuccessWithButtonView(
              buttonText: "generate_new_address".tr,
              buttonWidget: ContainerWithBorder(
                  margin: WidgetConstant.paddingVertical8,
                  child: AddressDetailsView(address: result.unwrap())),
              onPressed: () {
                pageProgressKey.backToIdle();
              },
              text: "address_added_success".tr));
    }
    updateState();
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    _init();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    pageProgressKey.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamPageProgress(
      controller: pageProgressKey,
      // backToIdle: APPConst.oneSecoundDuration,
      // initialStatus: PageProgressStatus.progress,
      builder: (c) => Center(
        child: CustomScrollView(
          shrinkWrap: true,
          slivers: [
            SliverToBoxAdapter(
                child: ConstraintsBoxView(
              padding: WidgetConstant.paddingHorizontal20,
              child: Column(
                key: const ValueKey<bool>(true),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DriveFromHdWallet(
                      onVisibleGenerateAddress: visibleGenerateAddress,
                      typesToSelect: typesToSelect,
                      generateAddress: generateAddress,
                      p2shTypes: p2shTypes,
                      p2pkhTypes: p2pkhTypes,
                      onChageSegwit: onChageSegwit,
                      onChangeSelected: onChangeSelected,
                      selected: selected,
                      selectedP2shType: p2shType,
                      onChangeP2pkh: onChangeP2pkh,
                      selectedP2pkhType: p2pkhType,
                      recommendedTypeDescription: recomendedTypeDescription,
                      typesWidget: typesWidget,
                      supportUncompressedKey: supportUncompressedKey,
                      keyType: keyType,
                      onChangeKeyType: onChangeKeyType),
                ],
              ),
            ))
          ],
        ),
      ),
    );
  }
}

typedef _OnChangeBitcoinAddrType = void Function(BitcoinAddressType?);

class _DriveFromHdWallet extends StatelessWidget {
  const _DriveFromHdWallet(
      {required this.selected,
      required this.generateAddress,
      required this.p2shTypes,
      required this.onChageSegwit,
      required this.onChangeSelected,
      required this.selectedP2shType,
      required this.onVisibleGenerateAddress,
      required this.typesToSelect,
      required this.p2pkhTypes,
      required this.onChangeP2pkh,
      required this.selectedP2pkhType,
      required this.recommendedTypeDescription,
      required this.typesWidget,
      required this.supportUncompressedKey,
      required this.keyType,
      required this.onChangeKeyType});

  final BitcoinAddressType selected;
  final _OnChangeP2shType onChageSegwit;
  final DynamicVoid generateAddress;
  final _OnChangeBitcoinAddrType onChangeSelected;
  final List<P2shAddressType> p2shTypes;
  final List<P2pkhAddressType> p2pkhTypes;
  final P2shAddressType selectedP2shType;
  final P2pkhAddressType selectedP2pkhType;
  final _OnChangeP2pkhTypes onChangeP2pkh;
  final GlobalKey onVisibleGenerateAddress;
  final Map<BitcoinAddressType, String> typesToSelect;
  final String? recommendedTypeDescription;
  final Map<BitcoinAddressType, Widget> typesWidget;
  final bool supportUncompressedKey;
  final PubKeyModes keyType;
  final DynamicVoid onChangeKeyType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("choose_bitcoin_address_type".tr, style: context.textTheme.titleMedium),
        if (recommendedTypeDescription != null)
          Text("bitcoin_type_recomended".tr.replaceOne(recommendedTypeDescription ?? "")),
        WidgetConstant.height8,
        AppDropDownBottom(
            isExpanded: true,
            hint: "address_type".tr,
            items: typesWidget,
            onChanged: onChangeSelected,
            value: selected),
        WidgetConstant.height20,
        AppCheckListTile(
          value: keyType.isCompressed,
          onChanged: supportUncompressedKey
              ? (v) {
                  onChangeKeyType();
                }
              : null,
          title: Text(
            "compressed_public_key".tr,
            style: context.textTheme.titleMedium,
          ),
          subtitle: Text("generatare_from_compressed_public_key".tr),
          // contentPadding: EdgeInsets.zero,
        ),
        WidgetConstant.height20,
        _AddressTypeOPtion(
          select: selected,
          p2shTypes: p2shTypes,
          selectedP2shType: selectedP2shType,
          onChangeP2shSegwit: onChageSegwit,
          p2pkhTypes: p2pkhTypes,
          onChangeP2pkhAddress: onChangeP2pkh,
          selectP2pkhType: selectedP2pkhType,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(
              padding: WidgetConstant.paddingVertical40,
              onPressed: generateAddress,
              key: onVisibleGenerateAddress,
              child: Text("setup_derivation".tr),
            ),
          ],
        )
      ],
    );
  }
}

typedef _OnChangeP2shType = void Function(P2shAddressType?);
typedef _OnChangeP2pkhTypes = void Function(P2pkhAddressType?);

class _AddressTypeOPtion extends StatelessWidget {
  const _AddressTypeOPtion(
      {required this.select,
      required this.p2pkhTypes,
      required this.selectedP2shType,
      required this.onChangeP2shSegwit,
      required this.p2shTypes,
      required this.onChangeP2pkhAddress,
      required this.selectP2pkhType});
  final List<P2shAddressType> p2shTypes;
  final List<P2pkhAddressType> p2pkhTypes;
  final BitcoinAddressType select;
  final P2shAddressType selectedP2shType;
  final P2pkhAddressType selectP2pkhType;
  final _OnChangeP2shType onChangeP2shSegwit;
  final _OnChangeP2pkhTypes onChangeP2pkhAddress;

  @override
  Widget build(BuildContext context) {
    return APPAnimatedSwitcher<BitcoinAddressType>(
      enable: select,
      widgets: {
        SegwitAddressType.p2wsh: (context) =>
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("p2wsh_one_of_one_desc".tr, textAlign: TextAlign.center),
            ]),
        P2pkhAddressType.p2pkh: (context) => AppGroupRadioBuilder<P2pkhAddressType>(
              groupValue: selectP2pkhType,
              onChanged: onChangeP2pkhAddress,
              builder: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                      p2pkhTypes.length,
                      (index) => AppRadioListTile<P2pkhAddressType>(
                          title: Text(p2pkhTypes[index].name),
                          value: p2pkhTypes[index],
                          subtitle:
                              Text(BTCUtils.getAddressDetails(p2pkhTypes[index]))))),
            ),
        SegwitAddressType.p2tr: (context) => WidgetConstant.sizedBox,
        SegwitAddressType.p2wpkh: (context) => WidgetConstant.sizedBox,
      },
      defaultBuilder: (context) => AppGroupRadioBuilder<P2shAddressType>(
        groupValue: selectedP2shType,
        onChanged: onChangeP2shSegwit,
        builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(p2shTypes.length, (index) {
              return AppRadioListTile<P2shAddressType>(
                title: Text(p2shTypes[index].name),
                value: p2shTypes[index],
                subtitle: Text(BTCUtils.getAddressDetails(p2shTypes[index])),
              );
            })),
      ),
    );
  }
}
