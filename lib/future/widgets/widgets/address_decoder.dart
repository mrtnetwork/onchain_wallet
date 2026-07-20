import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/widgets/animated/widgets/animated_size.dart';
import 'package:on_chain_wallet/future/widgets/widgets/paste_icon_widget.dart';
import 'button.dart';
import 'container_with_border.dart';
import 'copy_icon_widget.dart';
import 'drop_down_button.dart';
import 'text_field.dart';
import 'widget_constant.dart';

enum _SupportAddresses {
  ethereum("Ethereum"),
  substrate("Substrate"),
  tron("Tron"),
  solana("Solana"),
  cosmos("Cosmos"),
  ripple("Ripple");

  final String name;
  const _SupportAddresses(this.name);
}

class AddressDecoderView extends StatefulWidget {
  const AddressDecoderView({super.key});

  @override
  State<AddressDecoderView> createState() => _StringWriterViewState();
}

class _StringWriterViewState extends State<AddressDecoderView>
    with SafeState<AddressDecoderView> {
  Map<_SupportAddresses, Widget> addresses = {};
  _SupportAddresses address = _SupportAddresses.substrate;

  String? inHex;

  void onChangeAddress(_SupportAddresses? address) {
    if (address == null) return;
    this.address = address;
    onChange(text);
    updateState();
  }

  final GlobalKey<AppTextFieldState> textFieldKey =
      GlobalKey(debugLabel: "_StringWriterViewState");
  final GlobalKey<FormState> formKey = GlobalKey(debugLabel: "_StringWriterViewState_1");
  late String text = "";
  void onChange(String v) {
    text = v;
    final decode =
        MethodUtils.fallbackOnException(() => this.decode(v), logOnDebug: false);
    if (decode != inHex) {
      inHex = decode;
      updateState();
    }
  }

  String decode(String v) {
    List<int> bytes;
    switch (address) {
      case _SupportAddresses.ethereum:
        bytes = EthAddrDecoder().decodeAddr(v);
        break;
      case _SupportAddresses.tron:
        bytes = TrxAddrDecoder().decodeAddr(v);
        break;
      case _SupportAddresses.cosmos:
        bytes = AtomAddressUtils.decode(v).bytes;
        break;
      case _SupportAddresses.substrate:
        bytes = SubstrateGenericAddrDecoder().decodeAddr(v);
        break;
      case _SupportAddresses.solana:
        bytes = SolAddrDecoder().decodeAddr(v);
        break;
      case _SupportAddresses.ripple:
        bytes = XRPAddressUtils.decodeAddress(v).hash;
        break;
    }
    return BytesUtils.toHexString(bytes);
  }

  String? validator(String? v) {
    if (v == null || v.trim().isEmpty) {
      return "enter_valid_address_validator".tr.replaceOne(address.name);
    }
    if (inHex == null) {
      return "enter_valid_address_validator".tr.replaceOne(address.name);
    }
    return null;
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    addresses = {for (final i in _SupportAddresses.values) i: Text(i.name)};
  }

  void onPaste(String v) {
    textFieldKey.currentState?.updateText(v);
  }

  void onPressed() {
    if (!formKey.ready()) return;
    if (context.mounted) {
      context.pop(inHex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("address_decoder".tr, style: context.textTheme.titleMedium),
          Text("convert_address_to_bytes".tr),
          WidgetConstant.height20,
          AppDropDownBottom(items: addresses, value: address, onChanged: onChangeAddress),
          AppTextField(
            label: "address".tr,
            initialValue: text,
            validator: validator,
            suffixIcon: PasteTextIcon(onPaste: onPaste, isSensitive: false),
            onChanged: onChange,
            key: textFieldKey,
          ),
          APPAnimatedSize(
              isActive: inHex != null,
              onActive: (context) => ContainerWithBorder(
                    child: CopyableTextWidget(
                        text: inHex!, color: context.onPrimaryContainer),
                  ),
              onDeactive: (context) => WidgetConstant.sizedBox),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                  padding: WidgetConstant.paddingVertical40,
                  onPressed: onPressed,
                  child: Text('setup'.tr))
            ],
          )
        ],
      ),
    );
  }
}
