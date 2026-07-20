import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/substrate/substrate.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/networks/substrate/models/multisig.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

enum _SubstrateMultisigData {
  hash("hash"),
  call("call");

  final String tr;
  const _SubstrateMultisigData(this.tr);
}

class SubstrateMultisigCallDataField extends StatefulWidget {
  final MetadataApi api;
  const SubstrateMultisigCallDataField({
    super.key,
    required this.method,
    required this.api,
    this.defaultValue,
  });
  final MultisigCallPalletMethod method;
  final SubstrateMultisigCallData? defaultValue;

  @override
  State<SubstrateMultisigCallDataField> createState() => _StringWriterViewState();
}

class _StringWriterViewState extends State<SubstrateMultisigCallDataField>
    with SafeState {
  AutovalidateMode autovalidateMode = AutovalidateMode.disabled;
  bool allowHash = false;
  final GlobalKey<FormState> formKey = GlobalKey(debugLabel: "_StringWriterViewState_1");

  _SubstrateMultisigData data = _SubstrateMultisigData.call;

  Map<_SubstrateMultisigData, Widget> items = {};

  late String text = "";

  void onChangeData(_SubstrateMultisigData? data) {
    this.data = data ?? this.data;
    autovalidateMode = switch (this.data) {
      _SubstrateMultisigData.call => AutovalidateMode.disabled,
      _SubstrateMultisigData.hash => AutovalidateMode.onUserInteraction
    };
    updateState();
  }

  void onChange(String v) {
    text = v;
  }

  String? validateCallOrHash(String? v) {
    // final data=
    if (v == null || !StringUtils.isHexBytes(v)) {
      return "invalid_hex_validator".tr;
    }
    final value = StringUtils.normalizeHex(v);
    switch (data) {
      case _SubstrateMultisigData.call:
        final content = MethodUtils.fallbackOnException(
            () => widget.api.decodeCall(BytesUtils.fromHexString(value)),
            logOnDebug: false);
        if (content == null) {
          return "failed_to_decode_call_data".tr;
        }
        return null;
      default:
        final hexLengh = QuickCrypto.blake2b256DigestSize * 2;
        if (value.length == hexLengh) return null;
        return "invalid_hex_length"
            .tr
            .replaceOne(hexLengh.toString())
            .replaceTwo(QuickCrypto.blake2b256DigestSize.toString());
    }
  }

  void onPressed() {
    if (!formKey.ready()) return;
    final dataBytes = BytesUtils.fromHexString(text);
    final data = MethodUtils.fallbackOnException(() => SubstrateMultisigCallData(
        multisig: null,
        weight: null,
        call: switch (this.data) {
          _SubstrateMultisigData.call => SubstrateMultisigCall(
              callData: dataBytes, callHash: SubstrateUtils.callHash(dataBytes)),
          _SubstrateMultisigData.hash => SubstrateMultisigCall(callHash: dataBytes),
        },
        content: switch (this.data) {
          _SubstrateMultisigData.call => widget.api.decodeCall(dataBytes).toJson(),
          _SubstrateMultisigData.hash => null,
        }));
    if (data == null) return;
    context.pop(data);
  }

  String get title {
    switch (data) {
      case _SubstrateMultisigData.call:
        return "multisig_call_data".tr;
      default:
        return "multisig_call_hash".tr;
    }
  }

  String get subtitle {
    switch (data) {
      case _SubstrateMultisigData.hash:
        return "multisig_call_data_desc".tr;
      default:
        return "multisig_call_hash_desc".tr;
    }
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    allowHash = widget.method != MultisigCallPalletMethod.asMulti;
    items = {
      _SubstrateMultisigData.call: Text(_SubstrateMultisigData.call.tr.tr),
      if (allowHash) _SubstrateMultisigData.hash: Text(_SubstrateMultisigData.hash.tr.tr)
    };
    final callData = widget.defaultValue;
    if (callData == null) return;
    if (callData.call.callData != null) {
      text = callData.call.callDataHex ?? '';
      data = _SubstrateMultisigData.call;
      return;
    }
    if (!allowHash) return;
    text = callData.call.callHashHex;
    data = _SubstrateMultisigData.hash;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitleSubtitle(
              title: "call_data".tr,
              body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text("call_data_desc".tr)])),
          WidgetConstant.height20,
          Text("type_of_call_data".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          AppDropDownBottom(items: items, value: data, onChanged: onChangeData),
          WidgetConstant.height20,
          // widget.title,
          // WidgetConstant.height20,
          AppTextField(
              key: ValueKey(data),
              label: title,
              initialValue: text,
              authoValidateMode: autovalidateMode,
              validator: validateCallOrHash,
              pasteIcon: true,
              onChanged: onChange),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                padding: WidgetConstant.paddingVertical40,
                onPressed: onPressed,
                child: Text("setup_input".tr),
              )
            ],
          )
        ],
      ),
    );
  }
}
