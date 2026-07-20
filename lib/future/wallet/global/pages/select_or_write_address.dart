import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/crypto/networks/address/utils.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/account/account.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/add_to_contact_list.dart';
import 'package:on_chain_wallet/wallet/chain/chain/typedef/types.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/address/pages/generate_xaddress.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/models/models.dart';
import 'receipt_address_view.dart';

typedef RECIPIENTFILTER<NETWORKADDRESS extends IAddress> = String? Function(
    NETWORKADDRESS address);

class SelectOrWriteAddressView<NETWORKADDRESS extends IAddress> extends StatelessWidget {
  const SelectOrWriteAddressView(
      {super.key,
      required this.account,
      required this.scrollController,
      this.title,
      this.multipleSelect = false,
      this.onFilterAccount});
  final APPCHAINADDRESS<NETWORKADDRESS> account;
  final ScrollController scrollController;
  final String? title;
  final bool multipleSelect;
  final RECIPIENTFILTER<NETWORKADDRESS>? onFilterAccount;

  @override
  Widget build(BuildContext context) {
    return NetworkAccountActionView(
        childBulder: (p0) {
          return _SelectOrWriteAddressView<NETWORKADDRESS>(
            account: account,
            scrollController: scrollController,
            contacts: p0.contacts,
            multipleSelect: multipleSelect,
            onFilterAccount: onFilterAccount,
            title: title,
          );
        },
        action: NetworkViewActionContacts<
            NETWORKADDRESS,
            WalletNetwork,
            ACCOUNADDRESSNETWORK<NETWORKADDRESS, WalletNetwork>,
            CLIENTNADDRESSNETWORK<NETWORKADDRESS, WalletNetwork>,
            APPCHAINADDRESSNETWORKACCOUNTCLIENT<
                NETWORKADDRESS,
                WalletNetwork,
                ACCOUNADDRESSNETWORK<NETWORKADDRESS, WalletNetwork>,
                CLIENTNADDRESSNETWORK<NETWORKADDRESS, WalletNetwork>>>(chain: account));
  }
}

class _SelectOrWriteAddressView<NETWORKADDRESS extends IAddress> extends StatefulWidget {
  const _SelectOrWriteAddressView(
      {super.key,
      required this.account,
      required this.scrollController,
      this.title,
      this.multipleSelect = false,
      this.onFilterAccount,
      this.contacts = const []});
  final APPCHAINADDRESS<NETWORKADDRESS> account;
  final ScrollController scrollController;
  final String? title;
  final bool multipleSelect;
  final RECIPIENTFILTER<NETWORKADDRESS>? onFilterAccount;
  final List<NetworkContact<NETWORKADDRESS>> contacts;

  @override
  State<_SelectOrWriteAddressView<NETWORKADDRESS>> createState() =>
      __SelectOrWriteAddressViewState<NETWORKADDRESS>();
}

class __SelectOrWriteAddressViewState<NETWORKADDRESS extends IAddress>
    extends State<_SelectOrWriteAddressView<NETWORKADDRESS>>
    with
        SafeState<_SelectOrWriteAddressView<NETWORKADDRESS>>,
        SelectOrWriteAddressState<_SelectOrWriteAddressView<NETWORKADDRESS>,
            NETWORKADDRESS> {
  @override
  APPCHAINADDRESS<NETWORKADDRESS> get account => widget.account;

  @override
  List<NetworkContact<NETWORKADDRESS>> get contacts => widget.contacts;

  @override
  bool get multipleSelect => widget.multipleSelect;

  @override
  String? onSelectAddress(NETWORKADDRESS address) {
    final supportByPlatform = account.addressSupportedByWalletPlatform(address);
    if (!supportByPlatform) {
      return "address_not_supported_on_this_platform".tr;
    }
    final onFilter = widget.onFilterAccount;
    if (onFilter == null) return null;
    return onFilter(address);
  }

  @override
  ScrollController get scrollController => widget.scrollController;

  @override
  String? get title => widget.title;
}

mixin SelectOrWriteAddressState<W extends StatefulWidget, NETWORKADDRESS extends IAddress>
    on SafeState<W> {
  APPCHAINADDRESS<NETWORKADDRESS> get account;
  String? onSelectAddress(NETWORKADDRESS address);
  bool get multipleSelect;
  ScrollController get scrollController;
  WalletNetwork get network => account.network;
  List<NetworkContact<NETWORKADDRESS>> get contacts;
  String? get title;
  GlobalKey<FormState> formKey = GlobalKey();
  GlobalKey<AppTextFieldState> textFieldKey = GlobalKey();
  late SelectedAddressbuilder<NETWORKADDRESS> builder;

  Future<void> generateRippleXAddress() async {
    final addr = await context.openSliverBottomSheet<String>(
      "",
      initiaalExtend: 1,
      bodyBuilder: (c) =>
          RippleGenerateXAddressView(account: account.cast(), controller: c),
    );
    if (addr == null) return;
    onPaste(addr);
  }

  void onPaste(String v) {
    textFieldKey.currentState?.updateText(v);
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    final addresses = account.addresses.map((e) {
      final error = onSelectAddress(e.networkAddress);
      return SelectedAddressDefault<NETWORKADDRESS>(
          address: e.networkAddress,
          view: e.address,
          isCurrentAccountAddress: e == account.addressSync,
          account: e,
          disabled: error != null,
          error: error);
    }).toList();
    final c = contacts.map((contact) {
      final error = onSelectAddress(contact.addressObject);
      return SelectedAddressDefault<NETWORKADDRESS>(
          address: contact.addressObject,
          view: contact.address,
          account: null,
          contact: contact,
          disabled: error != null,
          error: error);
    }).toList();
    builder = SelectedAddressbuilder(
        mulipleSelect: multipleSelect,
        existAddressees: [...addresses, ...c],
        network: network,
        onFilterAccount: onSelectAddress);
  }

  @override
  void safeDispose() {
    super.safeDispose();
    builder.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: APPStreamWidget(
          builder: (context, value) {
            return APPAnimated(
                isActive: builder.selectedAddresses.isNotEmpty,
                onActive: (context) => Badge.count(
                      count: builder.selectedAddresses.length,
                      child: FloatingActionButton(
                        onPressed: () {
                          final addresses = builder.pickAddress();
                          if (addresses != null) context.pop(addresses);
                        },
                        child: Icon(Icons.check_circle),
                      ),
                    ));
          },
          stream: builder.notifier),
      appBar: AppBar(
        title: Text(title?.tr ?? "recipient".tr),
        actions: [
          CircleTokenImageView(network.token, radius: APPConst.circleRadius12),
          WidgetConstant.width8,
        ],
      ),
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverConstraintsBoxView(
              padding: WidgetConstant.padding20,
              sliver: MultiSliver(children: [
                SliverToBoxAdapter(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          key: textFieldKey,
                          label: "address".tr,
                          minlines: 1,
                          initialValue: builder.view,
                          maxLines: 2,
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              BarcodeScannerIconView(onPaste),
                              PasteTextIcon(onPaste: onPaste, isSensitive: false)
                            ],
                          ),
                          validator: builder.onValidateAddress,
                          onChanged: builder.onChangeAddress,
                        ),
                        ConditionalWidget(
                            enable: network.type == NetworkType.xrpl,
                            onActive: (context) => Column(
                                  children: [
                                    AppListTile(
                                      onTap: generateRippleXAddress,
                                      trailing: Icon(Icons.open_in_new),
                                      title: Text("x_address".tr),
                                      subtitle:
                                          Text("generate_ripple_x_addreess_desc".tr),
                                    ),
                                    WidgetConstant.height20,
                                  ],
                                )),
                      ],
                    ),
                  ),
                ),
                APPStreamBuilder(
                  value: builder.notifier,
                  builder: (context, _) {
                    return SliverList.builder(
                        itemCount: builder.fillteredAddress.length,
                        itemBuilder: (context, index) {
                          final addr = builder.fillteredAddress[index];
                          bool selected = builder.isSelected(addr);
                          return APPStreamBuilder(
                            value: addr.notifier,
                            builder: (context, _) => DisabledWidget(
                                disabled: addr.disabled,
                                onActive: (context, disabled) {
                                  return ContainerWithBorder(
                                    onRemove: () {},
                                    enableTap: false,
                                    onRemoveWidget: Row(
                                      children: [
                                        Checkbox(
                                            value: selected,
                                            onChanged: (v) => builder.onChangeSelected(
                                                addr, (err) => context.showAlert(err))),
                                        ConditionalWidget(
                                            enable: addr.contact == null &&
                                                addr.account == null,
                                            onActive: (context) => IconButton(
                                                tooltip: "add_a_new_contact".tr,
                                                onPressed: () {
                                                  addr.addNewContact(account, context);
                                                },
                                                icon: Icon(Icons.person_add,
                                                    color: context.onPrimaryContainer)))
                                      ],
                                    ),

                                    /// s
                                    child: ReceiptAddressDetailsView(
                                        accountLable: switch (
                                            addr.isCurrentAccountAddress) {
                                          true => WidgetSpan(
                                              child: ToolTipView(
                                                  message: "current_account_address".tr,
                                                  child: Icon(
                                                    Icons.circle,
                                                    size: context.textTheme.bodyMedium
                                                            ?.fontSize ??
                                                        APPConst.smallIconSize,
                                                    color: context.onPrimaryContainer,
                                                  ))),
                                          _ => null,
                                        },
                                        address: addr.rAddress,
                                        color: context.onPrimaryContainer),
                                  );
                                }),
                          );
                        });
                  },
                ),
              ])),
          WidgetConstant.sliverPaddingVertial40
        ],
      ),
    );
    // return ;
  }
}

abstract class ISelectedAddress<NETWORKADDRESS extends IAddress>
    with DisposableMixin, StreamStateController {
  bool get disabled;
  String get view;
  String? get error;
  ACCOUNTADDRESS<NETWORKADDRESS>? get account;
  NetworkContact<NETWORKADDRESS>? get contact;
  NETWORKADDRESS? get address;
}

class SelectedAddressbuilder<NETWORKADDRESS extends IAddress>
    with DisposableMixin, StreamStateController {
  final WalletNetwork network;
  final RECIPIENTFILTER<NETWORKADDRESS> onFilterAccount;
  final bool mulipleSelect;
  List<SelectedAddressDefault<NETWORKADDRESS>> selectedAddresses = [];

  List<SelectedAddressDefault<NETWORKADDRESS>> existAddressees;
  ReceiptAddress<NETWORKADDRESS>? rAddress;
  List<SelectedAddressDefault<NETWORKADDRESS>> fillteredAddress;
  SelectedAddressbuilder(
      {required List<SelectedAddressDefault<NETWORKADDRESS>> existAddressees,
      required this.network,
      required this.onFilterAccount,
      this.mulipleSelect = false})
      : fillteredAddress = existAddressees.clone(),
        existAddressees = existAddressees.clone();
  bool get isReady => selectedAddresses.isNotEmpty;
  String view = "";

  bool isSelected(SelectedAddressDefault addr) => selectedAddresses.contains(addr);

  void onChangeFilter() {
    fillteredAddress = existAddressees
        .where((e) => e.view.toLowerCase().startsWith(view.toLowerCase()))
        .toList();
    notify();
  }

  void onChangeAddress(String v) {
    view = v;
    onChangeFilter();
  }

  String? onValidateAddress(String? v) {
    if (v == null || v.isEmpty) return null;
    final addr = BlockchainAddressUtils.validateAddress(v, network);
    if (addr.isErr) {
      return addr.unwrapErr()?.message.tr ??
          "invalid_network_address".tr.replaceOne(network.networkName);
    }
    final address = MethodUtils.fallbackOnException(() => addr.unwrap() as NETWORKADDRESS,
        logOnDebug: false);
    if (address == null) {
      return "invalid_network_address".tr.replaceOne(network.networkName);
    }
    if (existAddressees.any((e) => e.address == address)) {
      onChangeFilter();
      return null;
    }
    final filter = onFilterAccount(address);
    final newAddr = SelectedAddressDefault(
        disabled: filter != null,
        view: v,
        address: address,
        error: filter,
        account: null,
        contact: null);
    existAddressees = [newAddr, ...existAddressees];
    onChangeFilter();
    onChangeSelected(newAddr, (p0) {});
    return null;
  }

  void onChangeSelected(SelectedAddressDefault<NETWORKADDRESS> addr, StringVoid onErr) {
    final err = addr.error;
    if (err != null) {
      onErr(err);
      return;
    }
    if (mulipleSelect) {
      if (!selectedAddresses.remove(addr)) {
        selectedAddresses.add(addr);
      }
    } else {
      if (selectedAddresses.contains(addr)) {
        selectedAddresses.clear();
      } else {
        selectedAddresses.clear();
        selectedAddresses.add(addr);
      }
    }
    notify();
  }

  List<ReceiptAddress<NETWORKADDRESS>>? pickAddress() {
    final addresses = selectedAddresses;
    if (addresses.isEmpty) return null;
    if (mulipleSelect) return addresses.map((e) => e.rAddress).toList();
    return [addresses[0].rAddress];
  }

  @override
  void dispose() {
    for (final i in selectedAddresses) {
      i.dispose();
    }
    selectedAddresses = [];
    fillteredAddress = [];
    super.dispose();
  }
}

class SelectedAddressDefault<NETWORKADDRESS extends IAddress>
    extends ISelectedAddress<NETWORKADDRESS> {
  ReceiptAddress<NETWORKADDRESS> _rAddress;
  ReceiptAddress<NETWORKADDRESS> get rAddress => _rAddress;
  @override
  final bool disabled;
  @override
  final String view;
  @override
  final String? error;
  @override
  final ACCOUNTADDRESS<NETWORKADDRESS>? account;
  NetworkContact<NETWORKADDRESS>? _contact;
  @override
  NetworkContact<NETWORKADDRESS>? get contact => _contact;
  @override
  final NETWORKADDRESS address;
  final bool isCurrentAccountAddress;

  SelectedAddressDefault({
    required this.disabled,
    required this.view,
    this.isCurrentAccountAddress = false,
    this.error,
    this.account,
    NetworkContact<NETWORKADDRESS>? contact,
    required this.address,
  })  : _rAddress = ReceiptAddress<NETWORKADDRESS>(
          networkAddress: address,
          view: view,
          type: account?.type ?? contact?.type,
          contact: contact,
          account: account,
        ),
        _contact = contact;

  Future<void> addNewContact(
      APPCHAINADDRESS<NETWORKADDRESS> account, BuildContext context) async {
    await context.openSliverBottomSheet(
      "new_contact".tr,
      child: AddToContactListView<NETWORKADDRESS>(
        chain: account,
        address: view,
        callBack: (contact) {
          _contact = contact;
          _rAddress = ReceiptAddress<NETWORKADDRESS>(
              view: view,
              networkAddress: address,
              account: rAddress.account,
              contact: contact);
          notify();
        },
      ),
    );
  }
}
