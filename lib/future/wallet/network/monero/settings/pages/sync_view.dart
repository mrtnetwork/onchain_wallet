import 'dart:async';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/account/state.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/extension/extensions.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/settings/pages/status.dart';
import 'package:on_chain_wallet/wallet/models/block/block.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class MoneroAccountSyncView extends StatelessWidget {
  const MoneroAccountSyncView({super.key});
  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<MoneroNetworkClient, IMoneroAddress, MoneroChain>(
      title: "sync_information".tr,
      addressRequired: true,
      clientRequired: true,
      childBulder: (wallet, account, client, address) =>
          _MoneroAccountSyncView(wallet: wallet, chain: account, client: client),
    );
  }
}

class _MoneroAccountSyncView extends StatefulWidget {
  const _MoneroAccountSyncView(
      {required this.wallet, required this.chain, required this.client});
  final WalletProvider wallet;
  final MoneroChain chain;
  final MoneroNetworkClient client;

  @override
  State<_MoneroAccountSyncView> createState() => _MoneroAccountSyncViewState();
}

class _MoneroAccountSyncViewState extends MoneroAccountState<_MoneroAccountSyncView> {
  @override
  MoneroChain get account => widget.chain;
  @override
  MoneroNetworkClient get client => widget.client;
  late MoneroSyncTrackerController tracker;
  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  late _SyncTracker defaultTracker;
  MoneroSyncChain syncChain = MoneroSyncChain.none;
  bool get syncIsActive => syncChain.network == account.network.coinParam.network;
  StreamSubscription<ChainEvent>? listener;
  StreamSubscription<MoneroChainNotify>? syncEvent;
  List<_SyncTracker> requests = [];
  Map<_SyncTracker, Widget> syncRequests = {};
  Map<_SyncTracker, Widget> selectedItemBuilder = {};

  void clearRequests() {
    syncEvent?.cancel();
    syncEvent = null;
    final requests = this.requests.clone();
    this.requests = [];
    syncRequests = {};
    selectedItemBuilder = {};
    for (final i in requests) {
      i.dispose();
    }
  }

  void onChangeTracker(_SyncTracker? tracker) {
    if (tracker == null) return;
    defaultTracker = tracker;
    updateState();
  }

  Future<void> removeRequest(_SyncTracker request) async {
    final requestId = request.requestId;
    if (requestId == null) return;
    final accept = await context.openSliverDialog<bool>(
        widget: (context) => DialogTextView(
              buttonWidget: DialogDoubleButtonView(),
              text: request.tracker.offsets.status.synced
                  ? "remove_sync_block_request_from_account".tr
                  : null,
              widget: switch (request.tracker.offsets.status.synced) {
                false => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("remove_sync_block_request_from_account".tr),
                      AlertTextContainer(
                          message: "sync_not_complete_pending_utxos_will_be_removed".tr),
                    ],
                  ),
                true => null
              },
            ),
        label: 'sync_request'.tr);
    if (accept != true) return;
    progressKey.progressText("removing_request_please_wait".tr);
    final result = await account.removeSyncingRequest(requestId);
    result.watch(
      onErr: (error) {
        progressKey.errorText(error.localizationError,
            backToIdle: false, showBackButton: true);
      },
      onOk: (value) {
        final request = requests.firstWhere((e) => e.requestId == requestId);
        requests.removeWhere((e) => e.requestId == requestId);
        buildRequestsItems();
        defaultTracker = requests.first;
        progressKey.backToIdle();
        request.dispose();
      },
    );
  }

  void updateSyncNetwork() async {
    context.to(PageRouter.moneroUpdateSyncNetwork);
  }

  _SyncTracker createViewRequest({
    required MoneroSyncTracker tracker,
    required MoneroSyncing? syncing,
  }) {
    List<_SyncedAddressWithHeight> syncAddresses = [];
    final defaultAddresses = tracker.accountIndexes;
    for (final i in defaultAddresses) {
      final addr = account.fromAccountIndex(i.index);
      if (addr == null) continue;
      final addrInfo = account.getOrCreateReceiptFromNetworkAddressSync(account: addr);
      syncAddresses
          .add(_SyncedAddressWithHeight(height: i.startHeight, address: addrInfo));
    }
    final trackerOffset = syncing?.getTrackerOffsets(tracker) ?? [];
    return _SyncTracker(
        addresses: syncAddresses,
        syncing: syncing,
        tracker: tracker,
        items: trackerOffset
            .map((e) => _SyncOffset(syncOffset: e, offset: e.offset))
            .toList());
  }

  void buildRequestsItems() {
    syncRequests = {};
    for (final i in requests) {
      if (i.requestId == null) {
        syncRequests[i] = Text(
          "default_chain_sync".tr,
          style: context.onPrimaryTextTheme.bodyMedium,
        );
        selectedItemBuilder[i] = Text(
          "default_chain_sync".tr,
          style: context.textTheme.bodyMedium,
        );
      } else {
        selectedItemBuilder[i] = Text(
          "requested_synchronizations".tr.replaceOne(i.created.toDateAndTime()),
          style: context.textTheme.bodyMedium,
        );
        syncRequests[i] = Row(
          children: [
            Expanded(
                child: Text(
              "requested_synchronizations".tr.replaceOne(i.created.toDateAndTime()),
              style: context.onPrimaryTextTheme.bodyMedium,
            )),
            IconButton(
                onPressed: () {
                  removeRequest(i);
                },
                icon: Icon(
                  Icons.remove_circle,
                  color: context.onPrimaryContainer,
                ))
          ],
        );
      }
    }
  }

  Future<void> init() async {
    final tracker = await account.getChainTracker();
    final init = await tracker.andThenAsync((tracker) async {
      final syncChain = await account.getSyncChain();
      return syncChain.andThenAsync((syncChain) async {
        final syncingTracker = await account.getSyncing();
        return syncingTracker.mapAsync((syncing) async {
          this.syncChain = syncChain;
          syncEvent = syncing?.latestEvent.stream.listen(onSyncingEvent);
          final defaultOffset = tracker.trackers();
          requests = defaultOffset
              .map((e) => createViewRequest(tracker: e, syncing: syncing))
              .toList();
          buildRequestsItems();
          defaultTracker = requests.firstWhere((e) => e.requestId == null);
          updateState();
        });
      });
    });
    init.watch(
      onErr: (error) {
        progressKey.errorText(error.localizationError,
            backToIdle: false, showBackButton: false);
      },
      onOk: (_) {
        progressKey.backToIdle();
        updateState();
      },
    );
  }

  void onTrackerAccountChangedEvent(ChainEvent _) {
    progressKey.progressText("fetching_current_block_data".tr);
    clearRequests();
    init();
  }

  void onSyncingEvent(MoneroChainNotify event) {
    for (final i in requests) {
      i.onSyncingEvent(event);
    }
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    init();
    listener = account.stream.where((e) {
      if (e.type == MoneroChainNotify.trackerAccountChanged) return true;
      return false;
    }).listen(onTrackerAccountChangedEvent);
  }

  @override
  void safeDispose() {
    super.safeDispose();
    progressKey.dispose();
    listener?.cancel();
    listener = null;
    clearRequests();
  }

  @override
  Widget build(BuildContext context) {
    return StreamPageProgress(
      controller: progressKey,
      initialWidget: ProgressWithTextView(text: "fetching_current_block_data".tr),
      builder: (context) => CustomScrollView(
        slivers: [
          SliverConstraintsBoxView(
              padding: WidgetConstant.padding20,
              sliver: MultiSliver(
                children: [
                  SliverToBoxAdapter(
                    child: APPAnimated(
                      isActive: true,
                      onDeactive: (context) => WidgetConstant.sizedBox,
                      onActive: (context) => Column(
                        key: ValueKey(defaultTracker),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("sync_network".tr, style: context.textTheme.titleMedium),
                          WidgetConstant.height8,
                          ContainerWithBorder(
                            onRemove: () {},
                            enableTap: false,
                            onRemoveWidget: IconButton(
                                onPressed: updateSyncNetwork,
                                icon: Icon(
                                  Icons.edit,
                                  color: context.onPrimaryContainer,
                                )),
                            child: Text(syncChain.network?.name ?? "None".tr),
                          ),
                          ConditionalWidget(
                            onActive: (context) => Column(
                              children: [
                                ErrorTextContainer(
                                    enableTap: false,
                                    error: "chain_synchronization_disabled_desc".tr),
                              ],
                            ),
                            enable: !syncIsActive,
                          ),
                          WidgetConstant.height20,
                          Text("available_synchronizations".tr,
                              style: context.textTheme.titleMedium),
                          WidgetConstant.height8,
                          AppDropDownBottomWithBorder(
                              items: syncRequests,
                              selectedItemBuilder: selectedItemBuilder,
                              label: "available_synchronizations".tr,
                              value: defaultTracker,
                              onChanged: onChangeTracker,
                              isDense: false,
                              isExpanded: true),
                          WidgetConstant.height20,
                          APPStreamBuilder(
                            value: defaultTracker.notifier,
                            builder: (context, _) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("fetched_blocks".tr,
                                    style: context.textTheme.titleMedium),
                                WidgetConstant.height8,
                                ContainerWithBorder(
                                  enableTap: false,
                                  validate: !defaultTracker.status.hasError,
                                  onRemoveWidget: ConditionalWidgetWithValue(
                                    value: defaultTracker.status.status.errorMessage,
                                    onValue: (context, value) => Row(
                                      children: [
                                        ToolTipView(
                                            message: value,
                                            child: Icon(
                                              Icons.error,
                                              color: context.colors.error,
                                            )),
                                        WidgetConstant.width8,
                                        ConditionalWidget(
                                            enable: defaultTracker.isRequest,
                                            onActive: (context) => IconButton(
                                                onPressed: () =>
                                                    removeRequest(defaultTracker),
                                                icon: Icon(Icons.remove_circle,
                                                    color: context.onPrimaryContainer)))
                                      ],
                                    ),
                                  ),
                                  onRemove: () {},
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(defaultTracker.status.rangeStr,
                                          style: context.onPrimaryTextTheme.labelLarge),
                                      Text(defaultTracker.status.statusStr,
                                          style: context.onPrimaryTextTheme.bodyMedium),
                                    ],
                                  ),
                                ),
                                WidgetConstant.height20,
                                Text("syncing_status".tr,
                                    style: context.textTheme.titleMedium),
                                WidgetConstant.height8,
                                ConditionalWidgetWithValue(
                                  value: defaultTracker.syncing,
                                  onNull: (context) {
                                    return ContainerWithBorder(
                                      onRemove: () {},
                                      enableTap: false,
                                      onRemoveWidget: IconButton(
                                          onPressed: updateSyncNetwork,
                                          icon: Icon(
                                            Icons.open_in_new,
                                            color: context.onPrimaryContainer,
                                          )),
                                      child: Text(
                                        "chain_synchronization_disabled_desc".tr,
                                        style: context.onPrimaryTextTheme.bodyMedium,
                                      ),
                                    );
                                  },
                                  onValue: (context, value) {
                                    return APPStreamBuilder(
                                        value: value.latestEvent,
                                        builder: (context, status) {
                                          return Column(
                                            children: [
                                              ContainerWithBorder(
                                                onRemoveWidget: ConditionalWidget(
                                                  enable: value.status.isErr,
                                                  onActive: (context) => Row(
                                                    children: [
                                                      ToolTipView(
                                                          message:
                                                              value.status.errorMessage,
                                                          child: Icon(
                                                            Icons.error,
                                                            color: context.colors.error,
                                                          )),
                                                      WidgetConstant.width8,
                                                      IconButton(
                                                          onPressed: value.retryErrors,
                                                          icon: Icon(
                                                            Icons.sync,
                                                            color: context
                                                                .onPrimaryContainer,
                                                          ))
                                                    ],
                                                  ),
                                                  onDeactive: (context) {
                                                    return switch (value.status) {
                                                      BlockSyncStatusSynced() => Icon(
                                                          Icons.check_circle,
                                                          color:
                                                              context.onPrimaryContainer,
                                                        ),
                                                      BlockSyncStatusError() => Icon(
                                                          Icons.error_outline,
                                                          color: context.colors.error,
                                                        ),
                                                      BlockSyncStatusPending() => Icon(
                                                          Icons.sync,
                                                          color:
                                                              context.onPrimaryContainer,
                                                        ),
                                                    };
                                                  },
                                                ),
                                                onRemove: () {},
                                                enableTap: false,
                                                child: Text(
                                                  value.status.translate,
                                                  style: context
                                                      .onPrimaryTextTheme.bodyMedium,
                                                ),
                                              ),
                                              // Condi
                                              ContainerWithBorder(
                                                onRemoveWidget: ConditionalWidget(
                                                  enable: defaultTracker.items.isNotEmpty,
                                                  onActive: (context) => IconButton(
                                                      onPressed: () {
                                                        context.openSliverDialog(
                                                          label:
                                                              "block_tracking_per_thread"
                                                                  .tr,
                                                          sliver: (context) =>
                                                              _OffsetsView(
                                                            tracker: defaultTracker,
                                                          ),
                                                        );
                                                      },
                                                      icon: Icon(
                                                        Icons.open_in_new,
                                                        color: context.onPrimaryContainer,
                                                      )),
                                                ),
                                                enableTap: false,
                                                onRemove: defaultTracker.items.isEmpty
                                                    ? null
                                                    : () {},
                                                child: ConditionalWidget(
                                                  enable: defaultTracker.items.isNotEmpty,
                                                  onActive: (context) => Text(
                                                    "processing_progress".tr,
                                                    style: context
                                                        .onPrimaryTextTheme.bodyMedium,
                                                  ),
                                                  onDeactive: (context) => Text(
                                                    "no_active_processing".tr,
                                                    style: context
                                                        .onPrimaryTextTheme.bodyMedium,
                                                  ),
                                                ),
                                              ),

                                              ConditionalWidgetWithValue(
                                                  value: value.latestHeight,
                                                  onValue: (context, value) => Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment.start,
                                                        children: [
                                                          WidgetConstant.height20,
                                                          Text("current_block_height".tr,
                                                              style: context
                                                                  .textTheme.titleMedium),
                                                          WidgetConstant.height8,
                                                          ContainerWithBorder(
                                                            child: Text(value.toString(),
                                                                style: context
                                                                    .onPrimaryTextTheme
                                                                    .bodyMedium),
                                                          ),
                                                        ],
                                                      )),
                                            ],
                                          );
                                        });
                                  },
                                ),
                              ],
                            ),
                          ),
                          WidgetConstant.height20,
                          Text("addresses".tr, style: context.textTheme.titleMedium),
                          Text("addresses_and_initial_sync_block".tr,
                              style: context.textTheme.bodyMedium),
                          WidgetConstant.height8,
                          APPExpansionListTile(
                            title: Text("addresses".tr,
                                style: context.onPrimaryTextTheme.bodyMedium),
                            children: [_Addresses(defaultTracker.addresses)],
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ))
        ],
      ),
    );
  }
}

class _Addresses extends StatelessWidget {
  const _Addresses(this.syncAddresses);
  final List<_SyncedAddressWithHeight> syncAddresses;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        shrinkWrap: true,
        physics: WidgetConstant.noScrollPhysics,
        itemBuilder: (context, index) {
          final address = syncAddresses[index];
          return ContainerWithBorder(
            backgroundColor: context.onPrimaryContainer,
            child: Column(
              children: [
                ContainerWithBorder(
                  backgroundColor: context.primaryContainer,
                  child: ReceiptAddressDetailsView(
                    address: address.address,
                    color: context.onPrimaryContainer,
                  ),
                ),
                ContainerWithBorder(
                  backgroundColor: context.primaryContainer,
                  child: Text(address.height.toString(),
                      style: context.onPrimaryTextTheme.bodyMedium),
                )
              ],
            ),
          );
        },
        itemCount: syncAddresses.length,
        separatorBuilder: (context, index) => Divider(color: context.onPrimaryContainer));
  }
}

class _SyncedAddressWithHeight {
  final int height;
  final ReceiptAddress<MoneroAddress> address;
  const _SyncedAddressWithHeight({required this.height, required this.address});
}

class _SyncOffsetStatus with Equality {
  final String statusStr;
  final String rangeStr;
  final BlockSyncStatus status;
  bool get hasError => status.isErr;
  const _SyncOffsetStatus(
      {required this.statusStr, required this.rangeStr, required this.status});

  factory _SyncOffsetStatus.fromOffset(BlockTrackingOffset offset) {
    int? divisions = (offset.endHeight - offset.startHeight).toInt();
    if (divisions == 0) divisions = null;
    return _SyncOffsetStatus(
      status: offset.status,
      statusStr: offset.status.translate,
      rangeStr: "${offset.startHeight}/${offset.endHeight}",
    );
  }
  factory _SyncOffsetStatus.fromTracker(MoneroSyncTracker tracker) {
    int? divisions = (tracker.endHeight - tracker.startHeight).toInt();
    if (divisions == 0) divisions = null;
    return _SyncOffsetStatus(
      status: tracker.offsets.status,
      statusStr: tracker.offsets.status.translate,
      rangeStr:
          "${tracker.startHeight} - ${tracker.endHeight}${" (at ${tracker.currentHeight})"}",
    );
  }

  @override
  List<dynamic> get variables => [status, statusStr, rangeStr];
}

class _SyncOffsetRange with Equality {
  final double startHeight;
  final double endHeight;
  final double currentHeight;
  final _SyncOffsetStatus status;
  final int? divisions;
  const _SyncOffsetRange(
      {required this.startHeight,
      required this.endHeight,
      required this.currentHeight,
      required this.status,
      required this.divisions});
  factory _SyncOffsetRange.fromOffset(BlockTrackingOffset offset) {
    int? divisions = (offset.endHeight - offset.startHeight).toInt();
    if (divisions == 0) divisions = null;
    return _SyncOffsetRange(
        startHeight: offset.startHeight.toDouble(),
        endHeight: offset.endHeight.toDouble(),
        currentHeight: offset.currentHeight.toDouble(),
        status: _SyncOffsetStatus.fromOffset(offset),
        divisions: divisions);
  }

  @override
  List<dynamic> get variables => [
        startHeight,
        endHeight,
        currentHeight,
        status,
      ];
}

class _SyncOffset with Equality {
  BlockTrackingOffset get offset => syncOffset.offset;
  MoneroSyncTracker get tracker => syncOffset.tracker;
  final MoneroTrackingOffsetWithStatus syncOffset;
  StreamValue<_SyncOffsetRange> range;

  _SyncOffset({
    required this.syncOffset,
    required BlockTrackingOffset offset,
  }) : range = StreamValue(_SyncOffsetRange.fromOffset(offset), name: "_SyncOffset");

  void onTrackerEvent() {
    range.value = _SyncOffsetRange.fromOffset(offset);
  }

  void dispose() {
    range.dispose();
  }

  @override
  List<dynamic> get variables => [offset];
}

typedef _SYNCTRACKERCHANGED = void Function(List<_SyncOffset> items);

class _SyncTracker with DisposableMixin, StreamStateController {
  List<_SyncOffset> items;
  List<_SyncOffset> removedSyncs = [];
  final MoneroSyncTracker tracker;
  final List<_SyncedAddressWithHeight> addresses;
  final MoneroSyncing? syncing;
  List<_SYNCTRACKERCHANGED> listeners = [];
  void addListener(_SYNCTRACKERCHANGED listener) {
    listeners.add(listener);
    listener(items.clone());
  }

  void removeListener(_SYNCTRACKERCHANGED listener) {
    listeners.remove(listener);
    clearRemovedItems();
  }

  void emitListeners() {
    for (final i in listeners) {
      i(items.clone());
    }
  }

  void clearRemovedItems() {
    if (listeners.isNotEmpty) return;
    final items = removedSyncs.clone();
    removedSyncs = [];
    for (final i in items) {
      i.dispose();
    }
  }

  _SyncOffsetStatus status;
  // // final GlobalKey<APPAnimatedListState<_SyncOffset>> animatedKey = GlobalKey();
  int? get requestId => tracker.offsets.requestId;
  DateTime get created => tracker.created;
  bool get isRequest => requestId != null;
  _SyncTracker({
    required this.items,
    this.syncing,
    required this.tracker,
    required this.addresses,
  }) : status = _SyncOffsetStatus.fromTracker(tracker);

  void onSyncingEvent(MoneroChainNotify event) {
    bool itemsChanged = false;
    bool notifyRequired = false;
    bool hasItem = items.isNotEmpty;
    final newStatus = _SyncOffsetStatus.fromTracker(tracker);
    if (newStatus != status) {
      status = newStatus;
      notifyRequired = true;
    }
    final cItems = items.clone();
    if (event == MoneroChainNotify.trackerOffsetChanged) {
      final offsets = syncing?.getTrackerOffsets(tracker);
      if (offsets == null) {
        itemsChanged = items.isNotEmpty;
        items = [];
      } else {
        final existsOffset = items.map((e) => e.offset).toList();
        for (final i in offsets) {
          if (existsOffset.contains(i.offset)) continue;
          items.add(_SyncOffset(syncOffset: i, offset: i.offset));
          itemsChanged = true;
        }
        final syncedItems = items.where((e) => !e.offset.synced).toList();
        itemsChanged = syncedItems.isNotEmpty;
        items = syncedItems;
      }
    }
    for (final i in items) {
      i.onTrackerEvent();
    }
    if (hasItem != items.isNotEmpty) {
      notifyRequired = true;
    }
    if (notifyRequired) notify();
    if (itemsChanged) emitListeners();
    for (final i in cItems) {
      if (!items.contains(i)) {
        removedSyncs.add(i);
      }
    }
    clearRemovedItems();
    // for(final i in)
  }

  @override
  void dispose() {
    super.dispose();
    for (final i in items) {
      i.dispose();
    }
    items = [];
    listeners = [];
    clearRemovedItems();
  }
}

class _OffsetsView extends StatefulWidget {
  final _SyncTracker tracker;
  const _OffsetsView({required this.tracker});

  @override
  State<_OffsetsView> createState() => _OffsetsViewState();
}

class _OffsetsViewState extends State<_OffsetsView> with SafeState<_OffsetsView> {
  final GlobalKey<APPAnimatedListState<_SyncOffset>> animatedKey = GlobalKey();
  List<_SyncOffset> latestItem = [];

  void onOffsetChanged(List<_SyncOffset> items) {
    final state = animatedKey.currentState;
    assert(state != null);
    for (final i in items) {
      if (latestItem.contains(i)) continue;
      state?.addItem(i);
    }
    latestItem = items;
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    Future.delayed(
      Duration.zero,
      () => widget.tracker.addListener(onOffsetChanged),
    );
  }

  @override
  void safeDispose() {
    super.safeDispose();
    widget.tracker.removeListener(onOffsetChanged);
  }

  @override
  Widget build(BuildContext context) {
    return SliverConstraintsBoxView(
      padding: WidgetConstant.padding20,
      sliver: APPAnimatedList<_SyncOffset>(
        (context, item) => APPStreamBuilder(
          value: item.range,
          builder: (context, item) => ContainerWithBorder(
            onRemoveWidget: BlockSyncStatusIcon(
              status: item.status.status,
              color: context.onPrimaryContainer,
            ),
            onRemove: () {},
            enableTap: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.status.rangeStr,
                  style: context.onPrimaryTextTheme.bodyMedium,
                ),
                SliderTheme(
                    data: SliderThemeData(
                        valueIndicatorTextStyle: context.primaryTextTheme.labelMedium),
                    child: Slider(
                      min: item.startHeight,
                      max: item.endHeight,
                      divisions: item.divisions,
                      value: item.currentHeight,
                      label: item.currentHeight.toString(),
                      activeColor: context.onPrimaryContainer,
                      onChanged: (e) {},
                      showValueIndicator: ShowValueIndicator.onDrag,
                      allowedInteraction: SliderInteraction.tapOnly,
                      thumbColor: context.onPrimaryContainer,
                      mouseCursor: MouseCursor.uncontrolled,
                    )),
              ],
            ),
          ),
        ),
        key: animatedKey,
        physics: WidgetConstant.noScrollPhysics,
        shrinkWrap: true,
      ),
    );
  }
}
