import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/receipt_address_view.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/constant/networks/ripple.dart';
import 'package:on_chain_wallet/wallet/models/models.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class RippleGenerateXAddressView extends StatefulWidget {
  final XRPChain account;
  final ScrollController controller;
  const RippleGenerateXAddressView(
      {required this.account, required this.controller, super.key});

  @override
  State<RippleGenerateXAddressView> createState() => _RippleGenerateXAddressViewState();
}

class _RippleGenerateXAddressViewState extends State<RippleGenerateXAddressView>
    with SafeState<RippleGenerateXAddressView> {
  String view = "";
  GlobalKey<FormState> formKey = GlobalKey();
  GlobalKey<AppTextFieldState> textFieldKey = GlobalKey();
  int? tag = 0;
  XRPBaseAddress? addr;
  StreamValue<ReceiptAddress<XRPBaseAddress>?> xAddress =
      StreamValue(null, name: "_RippleGenerateXAddressViewState");

  void onStateUpdated() {
    xAddress.value = MethodUtils.fallbackOnException(() {
      final addr = this.addr;
      final tag = this.tag;
      if (addr == null || tag == null) return null;
      final xAddr = addr.toXAddress(
          chainType: widget.account.network.coinParam.chainType, tag: tag);

      return ReceiptAddress(
          view: xAddr.address, networkAddress: xAddr, type: "x_address".tr);
    }, logOnDebug: false);
  }

  void onChangeTag(int? v) {
    tag = v;
    onStateUpdated();
  }

  String? validatorTag(String? v) {
    try {
      final tag = int.tryParse(v ?? "");
      if (tag == null) {
        return "ripple_address_validator_desc".tr;
      }
      return null;
    } finally {
      onStateUpdated();
    }
  }

  String? onAddressValidator(String? v) {
    if (addr == null) {
      return "enter_a_valid_ripple_classic_address".tr;
    }
    return null;
  }

  void onChange(String v) {
    view = v;
    addr = MethodUtils.fallbackOnException(() => XRPClassicAddress(v), logOnDebug: false);
    onStateUpdated();
  }

  void onPasteAddress(String v) {
    textFieldKey.currentState?.updateText(v);
  }

  void onSetup() {
    if (!formKey.ready()) return;
    final addr = xAddress.value?.networkAddress.address;
    if (addr == null) return;
    context.pop(addr);
  }

  @override
  void safeDispose() {
    super.safeDispose();
    xAddress.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("x_address".tr),
      ),
      body: CustomScrollView(
        controller: widget.controller,
        slivers: [
          SliverConstraintsBoxView(
            padding: WidgetConstant.padding20,
            sliver: SliverToBoxAdapter(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PageTitleSubtitle(
                        title: "generate_ripple_x_addreess".tr,
                        body: Text("generate_ripple_x_addreess_desc".tr)),
                    AppTextField(
                      key: textFieldKey,
                      label: "address".tr,
                      minlines: 1,
                      initialValue: view,
                      maxLines: 2,
                      suffixIcon:
                          PasteTextIcon(onPaste: onPasteAddress, isSensitive: false),
                      validator: onAddressValidator,
                      onChanged: onChange,
                    ),
                    WidgetConstant.height20,
                    NumberTextField(
                        label: "tag".tr,
                        onChangeValue: onChangeTag,
                        max: RippleConst.maxRippleTag,
                        defaultValue: tag,
                        validator: validatorTag,
                        min: 0),
                    WidgetConstant.height20,
                    APPStreamBuilder(
                      value: xAddress,
                      builder: (context, value) => APPAnimated(
                          isActive: xAddress.value != null,
                          onActive: (context) => Column(
                                children: [
                                  ReceiptAddressView(
                                    address: xAddress.value,
                                    subtitle: null,
                                    title: null,
                                  ),
                                  FixedElevatedButton(
                                      padding: WidgetConstant.paddingVertical40,
                                      onPressed: onSetup,
                                      child: Text("setup_address".tr))
                                ],
                              )),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
