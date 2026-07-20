import 'package:blockchain_utils/bip/bip/bip.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/substrate/substrate.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/crypto/networks/utils.dart';
import 'package:on_chain_wallet/wallet/wallet.dart' show BlockchainConst;
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

class Bip32KeyDerivationView extends StatefulWidget {
  const Bip32KeyDerivationView(
      {super.key,
      required this.coin,
      required this.defaultPath,
      required this.seedGeneration,
      this.fixedLevel});
  final CryptoCoins coin;
  final SeedTypes seedGeneration;
  final String? defaultPath;
  final Bip44Levels? fixedLevel;

  @override
  State<Bip32KeyDerivationView> createState() => _Bip32KeyDerivationViewState();
}

class _Bip32KeyDerivationViewState extends State<Bip32KeyDerivationView>
    with SafeState<Bip32KeyDerivationView> {
  String path = "";
  // Bip44Changes s
  final GlobalKey<FormState> form =
      GlobalKey<FormState>(debugLabel: "_Bip32KeyDerivationViewState_form");
  final GlobalKey<AppTextFieldState> pathTextFieldKey = GlobalKey<AppTextFieldState>(
      debugLabel: "_Bip32KeyDerivationViewState_pathTextFieldKey");
  bool allowNoneHardend = true;
  late final bool isSubstrate;

  void onSubmit() {
    if (!form.ready()) return;
    DerivableIndex keyIndex;
    if (isSubstrate) {
      keyIndex = SubstrateDerivationIndex.fromPath(
          currencyCoin: widget.coin as SubstrateCoins, substratePath: path);
    } else {
      keyIndex = Bip32DerivationIndex.fromPath(
          path: path, currencyCoin: widget.coin, seedGeneration: widget.seedGeneration);
    }

    context.pop(keyIndex);
  }

  void onChangePath(String v) {
    path = v;
  }

  String? _validatorBip32(String? v) {
    if (path.trim().isEmpty) return null;
    try {
      final fixedLevel = widget.fixedLevel;
      final parse = BlockchainAddressUtils.praseBip32Path(path);
      if (fixedLevel != null && parse.length != fixedLevel.value) {
        return "path_must_exactly_at_n_level".tr.replaceOne(fixedLevel.name);
      }
      if (parse.isEmpty) return null;
      if (!allowNoneHardend && parse.any((element) => !element.isHardened)) {
        return "coin_support_derivation_desc".tr;
      }
      if (parse.length > BlockchainConst.maxBip32LevelIndex) {
        return "invalid_hd_wallet_derivation_path".tr;
      }
    } catch (_) {
      return "invalid_hd_wallet_derivation_path".tr;
    }
    return null;
  }

  String? _validatorSubstrate(String? v) {
    if (path.trim().isEmpty) return null;
    try {
      BlockchainAddressUtils.praseSubstratePath(path);
      return null;
    } catch (e) {
      return "invalid_substrate_path".tr;
    }
  }

  String? validator(String? v) {
    if (isSubstrate) {
      return _validatorSubstrate(v);
    }
    return _validatorBip32(v);
  }

  void onPaste(String v) {
    pathTextFieldKey.currentState?.updateText(v);
  }

  late final EllipticCurveTypes curve = widget.coin.conf.type;

  @override
  void onInitOnce() {
    super.onInitOnce();
    final defaultPath = widget.defaultPath;
    path = widget.defaultPath ?? "";
    isSubstrate = widget.coin.proposal == CoinProposal.substrate;
    final fixedLevel = widget.fixedLevel;
    if (fixedLevel != null && defaultPath != null) {
      try {
        final parse = BlockchainAddressUtils.praseBip32Path(defaultPath)
            .take(fixedLevel.value)
            .toList();
        assert(parse.length >= fixedLevel.value,
            "Fixed Level is grather than default path.");
        final bip32Path = Bip32Path(elems: parse);
        path = bip32Path.toPath();
      } catch (e) {
        assert(false, "Invalid default path $e");
      }
    }
    assert(widget.fixedLevel == null || !isSubstrate,
        "Fixed level not  worked with substrate derivation.");
    switch (curve) {
      case EllipticCurveTypes.ed25519:
      case EllipticCurveTypes.redJubJub:
      case EllipticCurveTypes.redPallas:
        allowNoneHardend = false;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlertTextContainer(message: "custom_key_derivation_desc".tr, enableTap: false),
          WidgetConstant.height20,
          Text("derivation_path".tr, style: context.textTheme.titleMedium),
          if (isSubstrate)
            Text("hd_wallet_substrate_hardened_desc".tr)
          else
            Text("hd_wallet_hardened_desc".tr),
          WidgetConstant.height8,
          AppTextField(
            onChanged: onChangePath,
            initialValue: path,
            suffixIcon: PasteTextIcon(onPaste: onPaste, isSensitive: false),
            validator: validator,
            key: pathTextFieldKey,
            label: "derivation_path".tr,
            hint: "derivation_path".tr,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                padding: WidgetConstant.paddingVertical40,
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
