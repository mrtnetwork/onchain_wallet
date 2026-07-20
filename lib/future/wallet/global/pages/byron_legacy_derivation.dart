import 'package:blockchain_utils/bip/bip/bip.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/crypto/crypto.dart' show Bip32DerivationIndex;

class ByronLegacyKeyDerivationView extends StatefulWidget {
  const ByronLegacyKeyDerivationView(
      {super.key, required this.coin, required this.curve});
  final CryptoCoins coin;
  final EllipticCurveTypes curve;

  @override
  State<ByronLegacyKeyDerivationView> createState() =>
      _ByronLegacyKeyDerivationViewState();
}

class _ByronLegacyKeyDerivationViewState extends State<ByronLegacyKeyDerivationView>
    with SafeState<ByronLegacyKeyDerivationView> {
  final GlobalKey<FormState> form =
      GlobalKey<FormState>(debugLabel: "_ByronLegacyKeyDerivationViewState");
  final Map<Bip44Levels, GlobalKey<NumberTextFieldState>> levelStateKeys = {
    Bip44Levels.change: GlobalKey<NumberTextFieldState>(
        debugLabel: "_ByronLegacyKeyDerivationViewState_1"),
    Bip44Levels.addressIndex: GlobalKey<NumberTextFieldState>(
        debugLabel: "_ByronLegacyKeyDerivationViewState_2"),
  };

  late final bool isSupportNoneHardend;
  late final int minIndex;
  String path = "";
  final Map<Bip44Levels, Bip44LevelsDetails?> levels = {
    Bip44Levels.change: null,
    Bip44Levels.addressIndex: null,
  };

  String? validate(String? v, Bip44Levels level) {
    if (levels[level] == null) {
      return "bip32_key_index_validate".tr;
    }
    return null;
  }

  void onChangedValue(int? v, Bip44Levels level) {
    try {
      if (v == null) {
        levels[level] = null;
      } else {
        final index = Bip44LevelsDetails.fromIntIndex(v, level);
        if (!index.isHardened && !isSupportNoneHardend) return;
        levels[level] = Bip44LevelsDetails.fromIntIndex(v, level);
      }
    } catch (_) {
      levels[level] = null;
    } finally {
      path = calculatePath();
      updateState(() {});
    }
  }

  String? helperText(Bip44Levels level) {
    if (levels[level]?.isHardened ?? false) {
      return "hardened_index".tr.replaceOne(levels[level]!.unHardendValue.toString());
    }
    return null;
  }

  Color? hardenedColor(Bip44Levels level) {
    return (levels[level]?.isHardened ?? false) ? context.theme.iconTheme.color : null;
  }

  bool isHardened(Bip44Levels level) {
    return (levels[level]?.isHardened ?? false);
  }

  void onSubmit() {
    if (!form.ready()) return;
    final keyIndex = Bip32DerivationIndex.byronLegacy(
      firstIndex: levels[Bip44Levels.change]!.index,
      secoundIndex: levels[Bip44Levels.addressIndex]!.index,
      currencyCoin: widget.coin,
    );
    context.pop(keyIndex);
  }

  void onTapHardened(Bip44Levels level) {
    if (levels[level]?.isHardened ?? true) return;
    stateKey(level)
        .currentState
        ?.changeIndex(Bip32KeyIndex.hardenIndex(levels[level]!.index).index);
  }

  GlobalKey<NumberTextFieldState> stateKey(Bip44Levels level) {
    return levelStateKeys[level]!;
  }

  String calculatePath() {
    String p = "m";
    for (final i in levels.values) {
      if (i == null) {
        p += "/***";
      } else {
        p += "/${i.path}";
      }
    }
    return p;
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    isSupportNoneHardend = widget.curve != EllipticCurveTypes.ed25519;
    minIndex = isSupportNoneHardend ? 0 : Bip32KeyDataConst.hardenKeyIndexMinValue;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("path".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          ContainerWithBorder(
              child: Text(
            path,
            style: context.textTheme.bodyLarge,
          )),
          WidgetConstant.height20,
          NumberTextField(
            label: "first_index".tr,
            max: Bip32KeyDataConst.keyIndexMaxVal,
            helperText: helperText(Bip44Levels.change),
            key: stateKey(Bip44Levels.change),
            min: minIndex,
            onChangeValue: (v) {
              onChangedValue(v, Bip44Levels.change);
            },
            validator: (v) => validate(v, Bip44Levels.change),
          ),
          NumberTextField(
            label: "second_index".tr,
            max: Bip32KeyDataConst.keyIndexMaxVal,
            helperText: helperText(Bip44Levels.addressIndex),
            key: stateKey(Bip44Levels.addressIndex),
            min: minIndex,
            onChangeValue: (v) {
              onChangedValue(v, Bip44Levels.addressIndex);
            },
            validator: (v) => validate(v, Bip44Levels.addressIndex),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                padding: WidgetConstant.paddingVertical20,
                onPressed: onSubmit,
                child: Text("setup_derivation_path".tr),
              ),
            ],
          )
        ],
      ),
    );
  }
}
