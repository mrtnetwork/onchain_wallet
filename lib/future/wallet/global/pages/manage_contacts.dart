import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/account/account.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/add_to_contact_list.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class ManageAccountContactsView extends StatelessWidget {
  const ManageAccountContactsView({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountActionView(
        action: NetworkViewActionContacts(),
        childBulder: (p0) {
          return _ManageAccountContacts(account: p0.chain, contacts: p0.contacts);
        });
  }
}

class _ManageAccountContacts extends StatefulWidget {
  const _ManageAccountContacts({required this.account, required this.contacts});
  final Chain account;
  final List<NetworkContact> contacts;

  @override
  State<_ManageAccountContacts> createState() => _ManageAccountContactsState();
}

class _ManageAccountContactsState extends State<_ManageAccountContacts>
    with SafeState<_ManageAccountContacts> {
  List<NetworkContact> contacts = [];
  StreamSubscription? listener;
  Future<void> onCOntactUpdated(ChainEvent event) async {
    final contacts = await widget.account.getAccountContacts();
    contacts.watch(
      onErr: (error) => context.showAlert(error.localizationError),
      onOk: (value) {
        this.contacts = value;
        updateState();
      },
    );
  }

  Future<void> removeCotntact(NetworkContact contact) async {
    context.openSliverDialog(
        widget: (ctx) => DialogTextView(
            buttonWidget: AsyncDialogDoubleButtonView(
                firstButtonPressed: () async =>
                    await widget.account.removeContact(contact)),
            text: "remove_contact_from_account".tr),
        label: 'remove_contact'.tr);
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    contacts = widget.contacts;
    listener = widget.account.stream
        .where((e) => e.type == DefaultChainNotify.contacts)
        .listen(onCOntactUpdated);
  }

  @override
  void safeDispose() {
    super.safeDispose();
    listener?.cancel();
    listener = null;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Text("contacts".tr),
          actions: [
            IconButton(
                onPressed: () {
                  context.openMaxExtendSliverBottomSheet(
                    "new_contact".tr,
                    child: AddToContactListView(
                        contact: null, chain: widget.account, callBack: (p0) {}),
                  );
                },
                icon: Icon(Icons.add_box))
          ],
        ),
        SliverConstraintsBoxView(
            sliver: EmptyItemSliverWidgetView(
          isEmpty: contacts.isEmpty,
          itemBuilder: (context) {
            return SliverList.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return ContainerWithBorder(
                  onRemove: () {},
                  enableTap: false,
                  onRemoveIcon: IconButton(
                      onPressed: () {
                        context.openSliverDialog(
                            widget: (ctx) => DialogTextView(
                                buttonWidget: AsyncDialogDoubleButtonView(
                                    firstButtonPressed: () async =>
                                        (await widget.account.removeContact(contact))
                                            .unwrap()),
                                text: "remove_contact_from_account".tr),
                            label: 'remove_contact'.tr);
                      },
                      icon: Icon(Icons.delete, color: context.onPrimaryContainer)),
                  child: CopyableTextWidget(
                    text: contact.address,
                    color: context.onPrimaryContainer,
                    widget:
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(contact.name,
                                style: context.onPrimaryTextTheme.labelLarge),
                          ),
                          Text(
                            contact.created.toDateAndTime(),
                            style: context.onPrimaryTextTheme.labelSmall,
                          )
                        ],
                      ),
                      OneLineTextWidget(contact.address,
                          style: context.onPrimaryTextTheme.bodyMedium),
                    ]),
                  ),
                );
              },
            );
          },
          icon: Icons.contacts,
        ))
      ],
    );
  }
}
