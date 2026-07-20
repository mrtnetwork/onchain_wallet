import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:flutter/widgets.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'animated/widgets/animated_size.dart';
import 'button.dart';
import 'container_with_border.dart';
import 'copy_icon_widget.dart';
import 'drop_down_button.dart';
import 'error_text_container.dart';
import 'paste_icon_widget.dart';
import 'text_field.dart';
import 'widget_constant.dart';

enum _BytesTools {
  ethereum("Ethereum"),
  substrate("Substrate"),
  solana("Solana"),
  cosmos("Cosmos"),
  ripple("Ripple"),
  sha256("SHA/256"),
  sha512("SHA/512"),
  md5("MD5"),
  keccack256Hash("Keccack/256"),
  blacke2b128("Blake2b/128"),
  blake2b256Hash("Blake2b/256"),
  twoX128("TWOX/128"),
  twoX256("TWOX/256"),
  twoX64("TWOX/64"),
  utf8("UTF-8"),
  base64("Base64"),
  base58("Base58"),
  sha3("SHA3"),
  sha3224("SHA3/224"),
  sha3256("SHA3/256"),
  sha3384("SHA3/384"),
  sha3512("SHA3/256"),
  ripemd160("RIPEMD-160");

  final String name;
  String? get additionalData {
    return switch (this) {
      _BytesTools.substrate => 'ss58'.tr,
      _BytesTools.cosmos => 'hrp'.tr,
      _ => null,
    };
  }

  const _BytesTools(this.name);
}

class BytesToolsView extends StatefulWidget {
  final String? value;
  const BytesToolsView({this.value, super.key});

  @override
  State<BytesToolsView> createState() => _StringWriterViewState();
}

class _StringWriterViewState extends State<BytesToolsView>
    with SafeState<BytesToolsView> {
  Map<_BytesTools, Widget> addresses = {};
  _BytesTools address = _BytesTools.substrate;
  final GlobalKey<AppTextFieldState> textFieldKey =
      GlobalKey(debugLabel: "_StringWriterViewState");
  final GlobalKey<FormState> formKey = GlobalKey(debugLabel: "_StringWriterViewState_1");
  late String text = widget.value ?? '';
  late String additionalFeild = address.additionalData ?? '';
  String? error;

  void clear() {
    if (error != null || inHex != null) {
      error = null;
      inHex = null;
      updateState();
    }
  }

  void onChangeAdditionalField(String v) {
    additionalFeild = v;
    clear();
  }

  String? inHex;

  void onChangeAddress(_BytesTools? address) {
    if (address == null) return;
    this.address = address;
    clear();
    updateState();
  }

  void onChange(String v) {
    text = v;
    clear();
  }

  String encode(String v) {
    List<int> bytes = BytesUtils.fromHexString(v);
    String data;
    switch (address) {
      case _BytesTools.ethereum:
        data = EthAddrUtils.addressBytesToChecksumAddress(bytes);
        break;
      case _BytesTools.cosmos:
        data = AtomAddressUtils.encodeAddressBytes(
            addressBytes: bytes, hrp: additionalFeild);
        break;
      case _BytesTools.substrate:
        final ss58Format = int.tryParse(additionalFeild);
        if (ss58Format == null) {
          throw const AppException('invalid_ssh_58_format');
        }
        data = SS58Encoder.encode(bytes, ss58Format);
        break;
      case _BytesTools.solana:
        data = SolAddrEncoder().encodeKey(bytes);
        break;
      case _BytesTools.ripple:
        data = XRPAddressUtils.hashToAddress(bytes);
        break;
      case _BytesTools.sha256:
        return BytesUtils.toHexString(QuickCrypto.sha256Hash(bytes));
      case _BytesTools.sha512:
        return BytesUtils.toHexString(QuickCrypto.sha512Hash(bytes));
      case _BytesTools.blacke2b128:
        return BytesUtils.toHexString(QuickCrypto.blake2b128Hash(bytes));
      case _BytesTools.keccack256Hash:
        return BytesUtils.toHexString(QuickCrypto.keccack256Hash(bytes));
      case _BytesTools.blake2b256Hash:
        return BytesUtils.toHexString(QuickCrypto.blake2b256Hash(bytes));
      case _BytesTools.twoX128:
        return BytesUtils.toHexString(QuickCrypto.twoX128(bytes));
      case _BytesTools.ripemd160:
        return BytesUtils.toHexString(QuickCrypto.ripemd160Hash(bytes));
      case _BytesTools.twoX256:
        return BytesUtils.toHexString(QuickCrypto.twoX256(bytes));
      case _BytesTools.twoX64:
        return BytesUtils.toHexString(QuickCrypto.twoX64(bytes));
      case _BytesTools.md5:
        return BytesUtils.toHexString(MD5.hash(bytes));
      case _BytesTools.utf8:
        return StringUtils.decode(bytes);
      case _BytesTools.base64:
        return StringUtils.decode(bytes, encoding: StringEncoding.base64);
      case _BytesTools.sha3:
        return BytesUtils.toHexString(SHA3.hash(bytes));
      case _BytesTools.sha3224:
        return BytesUtils.toHexString(SHA3224.hash(bytes));
      case _BytesTools.sha3256:
        return BytesUtils.toHexString(SHA3256.hash(bytes));
      case _BytesTools.sha3384:
        return BytesUtils.toHexString(SHA3384.hash(bytes));
      case _BytesTools.sha3512:
        return BytesUtils.toHexString(SHA3512.hash(bytes));
      case _BytesTools.base58:
        return Base58Encoder.encode(bytes);
    }
    return data;
  }

  String? validator(String? v) {
    if (!StringUtils.isHexBytes(v ?? '')) {
      return "invalid_hex_validator".tr;
    }
    return null;
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    addresses = {for (final i in _BytesTools.values) i: Text(i.name)};
  }

  void onPaste(String v) {
    textFieldKey.currentState?.updateText(v);
  }

  void onPressed() async {
    if (!formKey.ready()) return;
    final r = await IResult.call(() async => encode(text));
    if (r.isErr) {
      error = r.unwrapErr().localizationError;
    } else {
      inHex = r.unwrap();
    }
    updateState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("bytes_tools".tr, style: context.textTheme.titleMedium),
          Text("bytes_tools_desc".tr),
          WidgetConstant.height20,
          AppDropDownBottom(items: addresses, value: address, onChanged: onChangeAddress),
          AppTextField(
            label: "bytes".tr,
            initialValue: text,
            validator: validator,
            suffixIcon: PasteTextIcon(onPaste: onPaste, isSensitive: false),
            onChanged: onChange,
            key: textFieldKey,
          ),
          APPAnimatedSize(
              isActive: address.additionalData != null,
              onActive: (context) {
                return AppTextField(
                  label: address.additionalData,
                  initialValue: null,
                  suffixIcon: PasteTextIcon(onPaste: onPaste, isSensitive: false),
                  onChanged: onChangeAdditionalField,
                );
              },
              onDeactive: (context) => WidgetConstant.sizedBox),
          APPAnimatedSize(
              isActive: inHex != null,
              onActive: (context) => ContainerWithBorder(
                    child: CopyableTextWidget(
                        text: inHex!, color: context.onPrimaryContainer),
                  ),
              onDeactive: (context) => WidgetConstant.sizedBox),
          APPAnimatedSize(
              isActive: error != null,
              onActive: (context) => ErrorTextContainer(error: error),
              onDeactive: (context) => WidgetConstant.sizedBox),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                  padding: WidgetConstant.paddingVertical40,
                  onPressed: onPressed,
                  child: Text('convert'.tr))
            ],
          )
        ],
      ),
    );
  }
}
