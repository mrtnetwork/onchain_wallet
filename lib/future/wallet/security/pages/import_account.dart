import 'package:blockchain_utils/bip/bip/bip.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/restore_backup.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/crypto/crypto.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

enum _PrivateKeyTypes {
  extendKey("extended_key"),
  privateKey("private_key"),
  orchardSpendKey("orchard_spend_key"),
  saplingExtendedSpandingKey("sapling_extended_spend_key"),
  saplingSpendKey("sapling_spend_key"),
  wif("Wif");

  WalletBackupTypes? get backupType {
    switch (this) {
      case _PrivateKeyTypes.extendKey:
        return WalletBackupTypes.extendedKey;
      case _PrivateKeyTypes.privateKey:
        return WalletBackupTypes.privatekey;
      case _PrivateKeyTypes.wif:
        return WalletBackupTypes.wif;
      case _PrivateKeyTypes.orchardSpendKey:
        return WalletBackupTypes.orchardSpendKey;
      case _PrivateKeyTypes.saplingExtendedSpandingKey:
        return WalletBackupTypes.saplingExtendedSpandingKey;
      case _PrivateKeyTypes.saplingSpendKey:
        return WalletBackupTypes.saplingSpendKey;
    }
  }

  const _PrivateKeyTypes(this.value);
  final String value;
  bool get isExtendedKey => this == _PrivateKeyTypes.extendKey;
  bool get supportedBackup => this != _PrivateKeyTypes.wif;
  CustomKeyType toCustomKeyType() {
    switch (this) {
      case _PrivateKeyTypes.extendKey:
        return CustomKeyType.extendedKey;
      case _PrivateKeyTypes.privateKey:
        return CustomKeyType.privateKey;
      case _PrivateKeyTypes.wif:
        return CustomKeyType.wif;
      case _PrivateKeyTypes.orchardSpendKey:
        return CustomKeyType.orchardSpendKey;
      case _PrivateKeyTypes.saplingExtendedSpandingKey:
        return CustomKeyType.saplingExtendedSpandingKey;
      case _PrivateKeyTypes.saplingSpendKey:
        return CustomKeyType.saplingSpendKey;
    }
  }

  String toKey(Bip32Base key) {
    if (isExtendedKey) return key.privateKey.toExtended;
    return key.privateKey.toHex();
  }

  String get helper {
    switch (this) {
      case _PrivateKeyTypes.extendKey:
      case _PrivateKeyTypes.wif:
        return "enter_key_base58_desc";
      case _PrivateKeyTypes.saplingExtendedSpandingKey:
        return "enter_key_bech32_desc";
      default:
        return "enter_key_hex_desc";
    }
  }
}

class ImportAccountView extends StatelessWidget {
  const ImportAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    final ImportCustomKeys? importKey = context.getNullArgruments();
    return AccessWalletView<WalletCredentialResponseVerify, WalletCredentialVerify>(
        request: WalletCredentialVerify(),
        onAccsess: (credential) {
          return _ImportAccount(credential: credential, customKey: importKey);
        },
        title: "import_account".tr,
        subtitle: PageTitleSubtitle(
            title: "import_account".tr, body: Text("import_account_desc1".tr)));
  }
}

class _ImportAccount extends StatefulWidget {
  const _ImportAccount({required this.credential, required this.customKey});
  final WalletCredentialResponseVerify credential;
  final ImportCustomKeys? customKey;
  @override
  State<_ImportAccount> createState() => _ImportAccountState();
}

class _ImportAccountState extends State<_ImportAccount> with SafeState<_ImportAccount> {
  late final WalletNetwork network;
  final GlobalKey<AppTextFieldState> textFieldState =
      GlobalKey<AppTextFieldState>(debugLabel: "_ImportAccountState");
  final StreamPageProgressController controller =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  final GlobalKey<FormState> form = GlobalKey(debugLabel: "_ImportAccountState_2");
  Map<_PrivateKeyTypes, Widget> keyTypes = {};
  List<CryptoCoins> get coins => network.coins;
  CryptoCoins? coin;
  bool get needSelectCoins => coins.length > 1;
  String? _error;
  _PrivateKeyTypes selected = _PrivateKeyTypes.privateKey;
  String keyName = "";
  String _key = "";
  final int maxNameLength = 20;
  final int minNameLength = 3;

  String? validateKeyName(String? name) {
    final length = name?.trim().length ?? 0;
    if (length > maxNameLength || length < minNameLength) {
      return "import_key_name_validator".tr;
    }
    return null;
  }

  void onChangeKeyName(String name) {
    keyName = name;
  }

  Map<CryptoCoins, Widget> coinItems = {};

  Map<_PrivateKeyTypes, Widget> _buildKeyTypes() {
    final Map<_PrivateKeyTypes, Widget> types = {};
    final coin = this.coin;

    if (coin == null) return {};
    final conf = coin.conf;
    for (final i in _PrivateKeyTypes.values) {
      switch (i) {
        case _PrivateKeyTypes.extendKey when coin.proposal.isBip && conf.hasExtendedKeys:
          types[i] = OneLineTextWidget(i.value.tr);
          break;
        case _PrivateKeyTypes.privateKey when !coin.proposal.isZip:
          types[i] = OneLineTextWidget(i.value.tr);
          break;
        case _PrivateKeyTypes.orchardSpendKey
            when coin.proposal.isZip && conf.type == EllipticCurveTypes.redPallas:
          types[i] = OneLineTextWidget(i.value.tr);
          break;
        case _PrivateKeyTypes.saplingSpendKey:
        case _PrivateKeyTypes.saplingExtendedSpandingKey:
          if (coin.proposal.isZip && conf.type == EllipticCurveTypes.redJubJub) {
            types[i] = OneLineTextWidget(i.value.tr);
          }
          break;
        case _PrivateKeyTypes.wif when conf.hasWif:
          types[i] = OneLineTextWidget(i.value.tr);
          break;
        default:
          break;
      }
    }
    return types;
  }

  void onSelectKeyType(_PrivateKeyTypes? s) {
    selected = s ?? selected;
    _error = null;
    updateState(() {});
  }

  void onChangeKeyAlogrithm(CryptoCoins? mewCoin) {
    if (mewCoin == null) return;
    coin = mewCoin;
    keyTypes = _buildKeyTypes();
    if (!keyTypes.containsKey(selected)) {
      selected = keyTypes.keys.first;
    }
    updateState(() {});
  }

  void onPaste(String v) {
    textFieldState.currentState?.updateText(v);
  }

  String? validate(String? v) {
    if (v == null || v.length < BlockchainConst.minimumKeysLength) {
      return "invalid_key_length".tr;
    }
    final bool isValid = switch (selected) {
      _PrivateKeyTypes.privateKey ||
      _PrivateKeyTypes.saplingSpendKey ||
      _PrivateKeyTypes.orchardSpendKey =>
        StringUtils.isHexBytes(v),
      _PrivateKeyTypes.wif || _PrivateKeyTypes.extendKey => StringUtils.isBase58(v),
      _PrivateKeyTypes.saplingExtendedSpandingKey => true,
    };
    if (isValid) return null;
    return "invalid_key_encoding_format".tr;
  }

  void onChangeKey(String key) {
    _key = key;
    if (_error != null) {
      _error = null;
      updateState(() {});
    }
  }

  void _init() {
    network = context.wallet.wallet.network;
    coinItems = {
      for (final i in coins)
        i: RichText(
            text: TextSpan(style: context.textTheme.bodyMedium, children: [
          TextSpan(text: i.coinName.camelCase),
          TextSpan(
              text: " (${i.conf.type.name.camelCase}/${i.proposal.name.camelCase}) ",
              style: context.textTheme.labelSmall)
        ]))
    };
    if (!needSelectCoins) {
      coin = coins.first;
      keyTypes = _buildKeyTypes();
    }
    final ImportCustomKeys? customKey = widget.customKey;
    if (customKey != null) {
      if (!coins.contains(customKey.coin)) {
        controller.errorText("wrong_network_key_error".tr.replaceOne(network.token.name),
            backToIdle: false);
        return;
      }
      selected = _PrivateKeyTypes.privateKey;
      coin = customKey.coin;
      keyTypes = _buildKeyTypes();
      _key = customKey.privateKey;
    }
    controller.success();
  }

  void onRestoreBackup(String? v) {
    if (v == null) return;
    textFieldState.currentState?.updateText(v);
  }

  Future<void> onSetup({bool custumKey = false}) async {
    if (!custumKey) {
      if (!form.ready()) return;
    }
    final coin = this.coin;
    final keyStr = _key;
    final keyName = this.keyName;
    final keyType = selected.toCustomKeyType();
    if (coin == null) return;

    controller.progressText("importing_key_pls_wait".tr);
    final model = context.wallet;

    final createKey = await context.wallet.wallet.doAction(WalletActionCryptoRequest(
        request: CryptoRequestGenerateImportedKey(
            key: keyStr, coin: coin, keyType: keyType, keyName: keyName)));

    if (createKey.isErr) {
      _error = createKey.unwrapErr().localizationError;
      controller.errorText(createKey.unwrapErr().localizationError,
          backToIdle: false, showBackButton: true);
      return;
    }
    final params = WalletActionImportSecretKey(
        secretKey: createKey.unwrap(), credential: widget.credential);
    final result = await model.wallet.doAction(params);
    if (result.isErr) {
      _error = result.unwrapErr().localizationError;
      controller.errorText(_error ?? '', backToIdle: false, showBackButton: true);
    } else {
      controller.successText("address_imported_desc1".tr, backToIdle: false);
    }
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    _init();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    _key = "";
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SensitiveContent(
      sensitivity: ContentSensitivity.sensitive,
      child: StreamPageProgress(
        controller: controller,
        initialWidget: ProgressWithTextView(text: "retrieving_resources".tr),
        builder: (c) => UnfocusableChild(
          child: CustomScrollView(
            // shrinkWrap: true,
            slivers: [
              SliverConstraintsBoxView(
                padding: WidgetConstant.paddingHorizontal20,
                sliver: SliverToBoxAdapter(
                  child: Form(
                    key: form,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PageTitleSubtitle(
                              title: "import_account".tr,
                              body: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("import_account_desc2".tr),
                                  WidgetConstant.height8,
                                  Text("import_account_desc1".tr)
                                ],
                              )),
                          if (needSelectCoins) ...[
                            Text("coin_type".tr, style: context.textTheme.titleMedium),
                            Text("choose_key_coin_desc".tr),
                            WidgetConstant.height8,
                            AppDropDownBottom(
                                items: coinItems,
                                value: coin,
                                hint: "coin_type".tr,
                                onChanged: onChangeKeyAlogrithm),
                            WidgetConstant.height20,
                          ],
                          APPAnimatedSize(
                              isActive: coin != null,
                              onActive: (c) => _ImportAccountStateKeyType(this),
                              onDeactive: (c) => WidgetConstant.sizedBox)
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportAccountStateKeyType extends StatelessWidget {
  const _ImportAccountStateKeyType(this.state);
  final _ImportAccountState state;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("key_type".tr, style: context.textTheme.titleMedium),
      Text("inidicate_type_of_key".tr),
      WidgetConstant.height8,
      AppDropDownBottom(
          items: state.keyTypes,
          value: state.selected,
          hint: "key_type".tr,
          onChanged: state.onSelectKeyType),
      WidgetConstant.height20,
      _ImportAccountStateKey(state: state)
    ]);
  }
}

class _ImportAccountStateKey extends StatelessWidget {
  const _ImportAccountStateKey({required this.state});
  final _ImportAccountState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(state.selected.value.tr, style: context.textTheme.titleMedium),
        Text(state.selected.helper.tr),
        WidgetConstant.height8,
        AppTextField(
            key: state.textFieldState,
            label: state.selected.value.tr,
            onChanged: state.onChangeKey,
            initialValue: state._key,
            validator: state.validate,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BarcodeScannerIconView(state.onPaste, isSensitive: true),
                PasteTextIcon(onPaste: state.onPaste, isSensitive: true),
                IconButton(
                    onPressed: () {
                      context
                          .openSliverBottomSheet<String>("restore_backup".tr,
                              child:
                                  RestoreBackupView(accepted: state.selected.backupType))
                          .then(state.onRestoreBackup);
                    },
                    icon: Icon(Icons.settings_backup_restore_outlined))
              ],
            ),
            error: state._error,
            obscureText: true),
        WidgetConstant.height20,
        Text("key_name".tr, style: context.textTheme.titleMedium),
        Text("import_private_key_key_name_desc".tr),
        WidgetConstant.height8,
        AppTextField(
          label: "key_name".tr,
          validator: state.validateKeyName,
          onChanged: state.onChangeKeyName,
          initialValue: state.keyName,
          maxLines: 1,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(
                padding: WidgetConstant.paddingVertical40,
                onPressed: state.onSetup,
                child: Text("import_account".tr)),
          ],
        )
      ],
    );
  }
}
