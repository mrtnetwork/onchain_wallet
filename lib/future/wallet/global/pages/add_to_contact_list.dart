import 'package:blockchain_utils/networks/types/address.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/networks/address/utils.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

typedef CbOnContantImported<NETWORKADDRESS extends IAddress> = void Function(
    NetworkContact<NETWORKADDRESS>);

class AddToContactListView<NETWORKADDRESS extends IAddress> extends StatefulWidget {
  const AddToContactListView(
      {super.key,
      this.contact,
      required this.chain,
      required this.callBack,
      this.address});
  final NetworkContact<NETWORKADDRESS>? contact;
  final String? address;
  final APPCHAINADDRESS<NETWORKADDRESS> chain;
  final CbOnContantImported<NETWORKADDRESS> callBack;

  @override
  State<AddToContactListView<NETWORKADDRESS>> createState() =>
      _AddToContactListViewState<NETWORKADDRESS>();
}

class _AddToContactListViewState<NETWORKADDRESS extends IAddress>
    extends State<AddToContactListView<NETWORKADDRESS>>
    with SafeState<AddToContactListView<NETWORKADDRESS>> {
  final GlobalKey<FormState> formKey = GlobalKey(debugLabel: "AddToContactListView");
  final GlobalKey<AppTextFieldState> textFieldKey =
      GlobalKey(debugLabel: "AddToContactListView_1");
  NetworkContact<NETWORKADDRESS>? contact;
  final StreamPageProgressController progressKey = StreamPageProgressController();
  String address = '';
  late String name = widget.contact?.name ?? "";
  String? err;
  bool lockAddressField = false;
  void clearError() {
    if (err != null) {
      err = null;
      updateState();
    }
  }

  void onChange(String v) {
    name = v;
  }

  void onPaste(String v) {
    textFieldKey.currentState?.updateText(v);
  }

  void onChangeAddress(String v) {
    address = v;
  }

  String? onAddressValidator(String? v) {
    final address = _validate(v);
    if (address == null) {
      return "invalid_network_address".tr.replaceOne(widget.chain.network.networkName);
    }
    return null;
  }

  String? validator(String? v) {
    if (v == null || v.length < 3) {
      return "contact_name_validator".tr;
    }
    return null;
  }

  NetworkContact<NETWORKADDRESS>? getCurrentContact() {
    if (!formKey.ready()) return null;
    if (contact != null) return contact;
    return _validate(address);
  }

  Future<void> onTapAdd() async {
    clearError();
    final contact = getCurrentContact();
    if (contact == null) return;

    progressKey.progress();
    final NetworkContact<NETWORKADDRESS> newContact =
        NetworkContact(addressObject: contact.addressObject, name: name);
    final result = await widget.chain.importContact(newContact);
    result.watch(
      onErr: (error) {
        progressKey.backToIdle();
        err = error.localizationError;
        updateState();
      },
      onOk: (_) {
        progressKey.successText("contact_saved".tr, backToIdle: false);
        updateState();
        widget.callBack(newContact);
      },
    );
  }

  NetworkContact<NETWORKADDRESS>? _validate(String? address) {
    try {
      final addr =
          BlockchainAddressUtils.validateAddress(address, widget.chain.network).ok();
      if (addr == null) return null;
      return NetworkContact(addressObject: addr as NETWORKADDRESS, name: name);
    } catch (_) {
      return null;
    }
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    final addr = widget.contact?.address ?? widget.address;
    if (addr != null) {
      lockAddressField = true;
      address = addr;
    }
  }

  @override
  void safeDispose() {
    super.safeDispose();
    progressKey.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: StreamPageProgress(
        controller: progressKey,
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageTitleSubtitle(
                title: "add_to_contacts".tr,
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("contact_desc_1".tr.replaceOne(widget.chain.network.token.name)),
                    Text("add_new_contact_desc".tr),
                  ],
                )),
            AppTextField(
              key: textFieldKey,
              label: "name_of_contact".tr,
              initialValue: name,
              readOnly: progressKey.inProgress,
              minlines: 1,
              maxLines: 2,
              pasteIcon: true,
              validator: validator,
              onChanged: onChange,
            ),
            WidgetConstant.height20,
            AppTextField(
                readOnly: lockAddressField,
                initialValue: address,
                label: "address".tr,
                pasteIcon: true,
                validator: onAddressValidator,
                onChanged: onChangeAddress),
            ErrorTextContainer(error: err, enableTap: false),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FixedElevatedButton(
                  padding: WidgetConstant.paddingVertical40,
                  onPressed: onTapAdd,
                  child: Text("add_to_contacts".tr),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
