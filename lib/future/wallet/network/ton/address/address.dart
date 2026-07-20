import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/global/address_derivation/controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/crypto/crypto.dart';
import 'package:ton_dart/ton_dart.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

enum _V5ContectType {
  custom,
  client;

  bool get isCustomWalletId => this == client;
}

enum _TonWorkChain {
  basechain(TonWorkChain.basechain),
  masterchain(TonWorkChain.masterchain);

  final TonWorkChain workchain;
  const _TonWorkChain(this.workchain);
}

class SetupTonAddressView extends StatefulWidget {
  final AddressDerivationController controller;
  const SetupTonAddressView({super.key, required this.controller});
  @override
  State<SetupTonAddressView> createState() => _SetupTonAddressViewState();
}

class _SetupTonAddressViewState extends State<SetupTonAddressView> with SafeState {
  final GlobalKey<NumberTextFieldState> subwalletKey = GlobalKey();
  WalletVersion version = WalletVersion.v5R1;
  _TonWorkChain workchain = _TonWorkChain.basechain;
  _V5ContectType v5Type = _V5ContectType.client;
  bool get hasSubWalletId => version.version > 2;
  WalletTonNetwork get network => widget.controller.network.cast();
  bool bouncable = false;
  int defaultSubWalletId() {
    if (isVersion5) return 0;
    return TonConst.defaultSubWalletId + workchain.workchain.id;
  }

  int? subWalletId;
  bool get isVersion5 => version == WalletVersion.v5R1;

  String subwalletIdLable = "sub_wallet_id";

  late int maximumSubWalletId = getMaximumSubWalletId();

  void onChangeVersion(WalletVersion? onChange) {
    if (onChange == null) return;
    version = onChange;
    maximumSubWalletId = getMaximumSubWalletId();
    updateSubWalletIdLable();
    updateState();
    subwalletKey.currentState?.setValue(defaultSubWalletId());
  }

  void onChangeWorkChain(_TonWorkChain? workchain) {
    if (workchain == null) return;
    final isDefaultSubId = defaultSubWalletId() == subWalletId;
    this.workchain = workchain;
    updateState();
    if (!isVersion5 && isDefaultSubId) {
      final swId = defaultSubWalletId();
      final context = subwalletKey.currentState;
      assert(context != null);
      context?.setValue(swId);
    }
  }

  void updateSubWalletIdLable() {
    if (!isVersion5) {
      v5Type = _V5ContectType.client;
    } else {
      if (v5Type.isCustomWalletId) {
        subwalletIdLable = "wallet_id";
      } else {
        subwalletIdLable = "sub_wallet_id";
      }
    }
  }

  void onChangeV5Type(bool? _) {
    if (v5Type == _V5ContectType.client) {
      v5Type = _V5ContectType.custom;
    } else {
      v5Type = _V5ContectType.client;
    }
    maximumSubWalletId = getMaximumSubWalletId();
    updateSubWalletIdLable();
    updateState();
    subwalletKey.currentState?.setValue(defaultSubWalletId());
  }

  void onChangeBounce(bool? v) {
    bouncable = !bouncable;
    setState(() {});
  }

  int getMaximumSubWalletId() {
    if (isVersion5) {
      switch (v5Type) {
        case _V5ContectType.client:
          return TonConst.maximumV5SubWalletId;
        default:
          return TonConst.maximumWalletId;
      }
    }
    return TonConst.maximumSubWalletId;
  }

  void onChangeSubWalletId(int? id) {
    if (id == null || id < 0 || id > maximumSubWalletId) {
      subWalletId = null;
    } else {
      subWalletId = id;
    }
  }

  String? validateSubWalletId(String? v) {
    if (!hasSubWalletId) return null;
    if (subWalletId == null) {
      return "sub_wallet_id_validator".tr.replaceOne(maximumSubWalletId.toString());
    }
    return null;
  }

  Future<void> generateAddress() async {
    final keyIndex = await widget.controller.getCoin(
        context: context,
        seedGeneration: SeedTypes.bip39,
        selectedCoins: network.coins.first);
    if (keyIndex == null) return;
    final workchain = this.workchain.workchain;
    final chainId = network.coinParam.chainId;
    if (widget.controller.form.ready()) {
      if (hasSubWalletId && subWalletId == null) return;
      TonAccountContext? context;
      switch (version) {
        case WalletVersion.v1R1:
        case WalletVersion.v1R2:
        case WalletVersion.v1R3:
        case WalletVersion.v2R1:
        case WalletVersion.v2R2:
          context = TonAccountLegacyContext(
              version: version,
              bouncable: bouncable,
              chainId: chainId,
              workchain: workchain);
          break;
        case WalletVersion.v3R1:
        case WalletVersion.v3R2:
        case WalletVersion.v4:
          context = TonAccountSubWalletContext(
              version: version,
              bouncable: bouncable,
              subwalletId: subWalletId!,
              chainId: chainId,
              workchain: workchain);
          break;
        case WalletVersion.v5R1:
          context = switch (v5Type) {
            _V5ContectType.client => TonAccountV5SubWalletContext(
                version: version,
                bouncable: bouncable,
                subwalletId: subWalletId!,
                chainId: chainId,
                workchain: workchain),
            _V5ContectType.custom => TonAccountV5CustomContext(
                version: version,
                bouncable: bouncable,
                contextId: subWalletId!,
                chainId: chainId,
                workchain: workchain),
          };
          break;
      }
      final newAccount = TonNewAddressParams(
          deriveIndex: keyIndex, context: context, coin: widget.controller.coin);
      widget.controller.generateAddress(newAccount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("types_of_wallet_contracts".tr, style: context.textTheme.titleMedium),
        TextAndLinkView(
          text: "ton_wallet_contract_desc".tr,
          url: LinkConst.reviewTonWalletContract,
          linkDesc: "read_more".tr,
        ),
        WidgetConstant.height8,
        AppDropDownBottom(
          items: {for (final i in WalletVersion.values) i: Text(i.name)},
          hint: "wallet_type".tr,
          onChanged: onChangeVersion,
          value: version,
        ),
        WidgetConstant.height20,
        Text("workchain".tr, style: context.textTheme.titleMedium),
        Text("ton_workchain_desc".tr),
        WidgetConstant.height8,
        AppDropDownBottom(
          items: {for (final i in _TonWorkChain.values) i: Text(i.name.tr)},
          hint: "workchain".tr,
          onChanged: onChangeWorkChain,
          value: workchain,
        ),
        WidgetConstant.height20,
        WidgetConstant.height20,
        AnimatedSize(
            duration: APPConst.animationDuraion,
            child: hasSubWalletId
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("sub_wallet_id".tr, style: context.textTheme.titleMedium),
                      TextAndLinkView(
                        text: "sub_wallet_id_desc".tr,
                        url: LinkConst.reviewTonSubWalletId,
                        linkDesc: "read_more".tr,
                      ),
                      if (isVersion5) ...[
                        WidgetConstant.height20,
                        AppCheckListTile(
                          contentPadding: EdgeInsets.zero,
                          onChanged: onChangeV5Type,
                          value: v5Type == _V5ContectType.custom,
                          title: Text("use_wallet_id".tr,
                              style: context.textTheme.titleMedium),
                          subtitle: TextAndLinkView(
                            text: "ton_v5_wallet_desc".tr,
                            url: LinkConst.reviewTonV5,
                            linkDesc: "read_more".tr,
                          ),
                        )
                      ],
                      WidgetConstant.height8,
                      NumberTextField(
                          key: subwalletKey,
                          label: subwalletIdLable.tr,
                          onChangeValue: onChangeSubWalletId,
                          validator: validateSubWalletId,
                          defaultValue: subWalletId,
                          max: maximumSubWalletId,
                          min: 0),
                    ],
                  )
                : const SizedBox()),
        WidgetConstant.height20,
        AppCheckListTile(
          contentPadding: EdgeInsets.zero,
          value: bouncable,
          onChanged: onChangeBounce,
          title: Text("bouncable".tr, style: context.textTheme.titleMedium),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ton_address_type_desc".tr),
              TextAndLinkView(
                text: "ton_bounceable_vs_non_bounceable".tr,
                url: LinkConst.tonBounceableAddressReview,
                linkDesc: "read_more".tr,
              )
            ],
          ),
        ),
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
      ],
    );
  }
}
