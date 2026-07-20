import 'package:blockchain_utils/networks/types/address.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';

typedef HASPERMISSION<ACCOUNT> = bool Function(ACCOUNT);
typedef OnChangeCurrentChain<CHAIN> = void Function(CHAIN?);
typedef ADDPERMISSIONACCOUNT<ACCOUNT> = void Function(ACCOUNT);
typedef ONCHANGEDEFAULTACCOUNT<ACCOUNT> = void Function(ACCOUNT);

class UpdateChainPermissionWidget<
    NETWORKADDRESS extends IAddress,
    ADDRESS extends ACCOUNTADDRESS<NETWORKADDRESS>,
    CHAIN extends APPCHAINACCOUNT<ADDRESS>> extends StatefulWidget {
  const UpdateChainPermissionWidget(
      {required this.chain,
      required this.chains,
      required this.onUpdateState,
      required this.hasPermission,
      required this.addAccount,
      required this.onChangeChain,
      required this.onChangeDefaultAccount,
      required this.activities,
      required this.menuItems,
      required this.isDefaultAddress,
      required this.addresses,
      this.extraPages = const {},
      super.key});
  final HASPERMISSION<ADDRESS> isDefaultAddress;
  final CHAIN chain;
  final List<CHAIN> chains;
  final List<ADDRESS> addresses;
  final DynamicVoid onUpdateState;
  final HASPERMISSION<ADDRESS> hasPermission;
  final OnChangeCurrentChain<CHAIN> onChangeChain;
  final ADDPERMISSIONACCOUNT<ADDRESS> addAccount;
  final ONCHANGEDEFAULTACCOUNT<ADDRESS> onChangeDefaultAccount;
  final List<Web3ActivityViewItem> activities;
  final List<DropdownMenuItem<CHAIN>> menuItems;
  final Map<String, WidgetContext> extraPages;

  @override
  State<UpdateChainPermissionWidget> createState() =>
      _UpdateChainPermissionWidget2State<NETWORKADDRESS, ADDRESS, CHAIN>();
}

class _UpdateChainPermissionWidget2State<
        NETWORKADDRESS extends IAddress,
        ADDRESS extends ACCOUNTADDRESS<NETWORKADDRESS>,
        CHAIN extends APPCHAINACCOUNT<ADDRESS>>
    extends State<UpdateChainPermissionWidget<NETWORKADDRESS, ADDRESS, CHAIN>>
    with
        AutomaticKeepAliveClientMixin,
        SafeState<UpdateChainPermissionWidget<NETWORKADDRESS, ADDRESS, CHAIN>> {
  List<_ChainPermissionPages> pages = [];
//  late _ChainPermissionPages page;
  String? page;

  void onChangeTab(int tab) {
    page = pages.elementAt(tab).name;
    updateState();
  }

  Chain? chain;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.chain != chain) {
      page = pages.elementAtOrNull(0)?.name;
      MethodUtils.executeAfterDelay(
          () async => DefaultTabController.of(context).animateTo(0));
    }
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    final allPages = [
      "accounts".tr,
      ...widget.extraPages.entries.map((e) => e.key),
      "histories".tr
    ];
    assert(allPages.toSet().length == allPages.length, "duplicate page name");
    pages = allPages.indexed.map((e) => _ChainPermissionPages(e.$2, e.$1)).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MultiSliver(children: [
      SliverAppBar(
          leading: WidgetConstant.sizedBox,
          surfaceTintColor: context.colors.transparent,
          centerTitle: false,
          backgroundColor: context.colors.surface,
          leadingWidth: 0,
          actions: [],
          title: AppDropDownBottom(
              focusColor: context.colors.surface,
              fillColor: context.colors.surface,
              label: null,
              isExpanded: true,
              menuItems: widget.menuItems,
              onChanged: widget.onChangeChain,
              value: widget.chain),
          pinned: false,
          floating: true,
          snap: true,
          bottom: TabBar(
              onTap: onChangeTab, tabs: pages.map((e) => Tab(text: e.name)).toList())),
      SliverConstraintsBoxView(
          sliver: APPSliverAnimatedSwitcher<String>(enable: page, widgets: {
        "Accounts": (context) {
          return SelectWeb3PermissionAccountView<NETWORKADDRESS, ADDRESS, CHAIN>(
              isDefaultAddress: widget.isDefaultAddress,
              chain: widget.chain,
              addresses: widget.addresses,
              hasPermission: widget.hasPermission,
              addAccount: widget.addAccount,
              onChangeDefaultAccount: widget.onChangeDefaultAccount,
              addressWidget: (p0, p1) => AddressDetailsView(
                    address: p1,
                    color: context.onPrimaryContainer,
                    chain: widget.chain,
                  ));
        },
        "Histories": (context) {
          return _Web3ActivitiesView(widget.activities);
        },
        ...widget.extraPages
      }))
    ]);
  }

  @override
  bool get wantKeepAlive => true;
}

class _Web3ActivitiesView extends StatelessWidget {
  const _Web3ActivitiesView(this.activities);
  final List<Web3ActivityViewItem> activities;
  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      ConditionalWidget(
          onActive: (context) {
            return SliverToBoxAdapter();
          },
          onDeactive: (context) => SliverToBoxAdapter(
                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Padding(padding: WidgetConstant.paddingVertical40),
                  Icon(Icons.hourglass_empty, size: APPConst.double40),
                  WidgetConstant.height8,
                  Text("no_web3_activities".tr)
                ]),
              ),
          enable: activities.isNotEmpty),
      SliverList.separated(
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final activity = activities[index];
          return ContainerWithBorder(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(activity.activity.method.camelCase),
              Text(activity.activity.date.toDateAndTime(),
                  style: context.onPrimaryTextTheme.bodySmall),
              if (activity.address != null)
                ContainerWithBorder(
                  backgroundColor: context.onPrimaryContainer,
                  child: CopyableTextWidget(
                      text: activity.address!.view,
                      color: context.primaryContainer,
                      widget: ReceiptAddressDetailsView(
                          address: activity.address!, color: context.primaryContainer)),
                ),
              if (activity.url != null)
                ContainerWithBorder(
                  backgroundColor: context.onPrimaryContainer,
                  onRemove: () {},
                  onRemoveIcon: LaunchBrowserIcon(
                      url: activity.url, color: context.primaryContainer),
                  child: OneLineTextWidget(activity.activity.path ?? activity.url!,
                      style: context.primaryTextTheme.bodyMedium),
                )
            ]),
          );
        },
        separatorBuilder: (context, index) => WidgetConstant.divider,
      ),
    ]);
  }
}

class _ChainPermissionPages {
  final String name;
  final int index;
  const _ChainPermissionPages(this.name, this.index);
}

typedef WEB3PERMISSIONADDRESSWIDGET<ADDRESS> = Widget Function(BuildContext, ADDRESS);

class SelectWeb3PermissionAccountView<
    NETWORKADDRESS extends IAddress,
    ADDRESS extends ACCOUNTADDRESS<NETWORKADDRESS>,
    CHAIN extends APPCHAINACCOUNT<ADDRESS>> extends StatelessWidget {
  final HASPERMISSION<ADDRESS>? isDefaultAddress;
  final CHAIN chain;
  final List<ADDRESS> addresses;
  final HASPERMISSION<ADDRESS> hasPermission;
  final ADDPERMISSIONACCOUNT<ADDRESS> addAccount;
  final ONCHANGEDEFAULTACCOUNT<ADDRESS>? onChangeDefaultAccount;
  final WEB3PERMISSIONADDRESSWIDGET<ADDRESS> addressWidget;
  const SelectWeb3PermissionAccountView(
      {this.isDefaultAddress,
      required this.chain,
      required this.addresses,
      required this.hasPermission,
      required this.addAccount,
      required this.addressWidget,
      this.onChangeDefaultAccount,
      super.key});

  @override
  Widget build(BuildContext context) {
    return APPSliverAnimatedSwitcher(enable: addresses.isNotEmpty, widgets: {
      true: (context) => SliverList.builder(
          addAutomaticKeepAlives: false,
          itemBuilder: (c, index) {
            final addr = addresses[index];
            final hasPermission = this.hasPermission(addr);
            return ContainerWithBorder(
              enableTap: false,
              onRemove: () {
                addAccount(addr);
              },
              onRemoveWidget: Column(
                children: [
                  IconButton(
                    onPressed: () => addAccount(addr),
                    icon: IgnorePointer(
                      child: Checkbox(value: hasPermission, onChanged: (e) {}),
                    ),
                  ),
                  ConditionalWidget(
                      enable: onChangeDefaultAccount != null && isDefaultAddress != null,
                      onActive: (context) => APPAnimatedSize(
                          isActive: hasPermission,
                          onActive: (context) => IconButton(
                              tooltip: "default_address".tr,
                              onPressed: () => onChangeDefaultAccount!(addr),
                              icon: IgnorePointer(
                                child: RadioGroup(
                                  groupValue: true,
                                  onChanged: (e) {},
                                  child: Radio<bool>(
                                      toggleable: true, value: isDefaultAddress!(addr)),
                                ),
                              )),
                          onDeactive: (context) => WidgetConstant.sizedBox))
                ],
              ),
              child: addressWidget(context, addr),
            );
          },
          itemCount: addresses.length),
      false: (context) => SliverFillRemaining(
          hasScrollBody: false, child: NoAccountFoundInChainWidget(chain))
    });
  }
}
