import 'package:flutter/material.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class MoneroUpdateSyncNetwork extends StatelessWidget {
  const MoneroUpdateSyncNetwork({super.key});
  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<MoneroNetworkClient, IMoneroAddress, MoneroChain>(
      title: "update_synchronization_network".tr,
      addressRequired: true,
      clientRequired: true,
      childBulder: (wallet, account, client, address) =>
          _MoneroUpdateSyncChain(account: account, client: client),
    );
  }
}

class _MoneroUpdateSyncChain extends StatefulWidget {
  final MoneroChain account;
  final MoneroNetworkClient client;
  const _MoneroUpdateSyncChain({required this.account, required this.client});

  @override
  State<_MoneroUpdateSyncChain> createState() => __MoneroUpdateSyncChain();
}

class __MoneroUpdateSyncChain extends State<_MoneroUpdateSyncChain>
    with SafeState<_MoneroUpdateSyncChain> {
  MoneroSyncChain currentSyncChain = MoneroSyncChain.none;
  _MoneroSyncChainWithActivity syncChain = _MoneroSyncChainWithActivity.none();

  // Map<MoneroSyncChain, MoneroChainTracker> trackers = {};
  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: PageProgressStatus.progress);
  Map<MoneroSyncChain, _MoneroSyncChainWithActivity> syncChains = {};
  bool isReady = false;
  bool resetTrackerState = false;
  int currentBlockHeight = 0;
  int trackerHeight = 0;
  int minTrackerHeight = 0;
  final formKey = GlobalKey<FormState>();

  @override
  void updateState([VoidCallback? fn]) {
    isReady = !resetTrackerState || (syncChain.selectedAddresses.isNotEmpty);
    super.updateState(fn);
  }

  void onChangeNetwork(_MoneroSyncChainWithActivity? chain) {
    if (chain == null || chain == syncChain) return;
    syncChain = chain;
    resetTrackerState = false;
    updateState();
  }

  void onChangeTrackerHeight(int? height) {
    trackerHeight = height ?? 0;
  }

  void addAddress(IMoneroAddress? address) {
    if (address == null) return;
    if (!syncChain.addAddress(address)) {
      context.showAlert("address_already_exist".tr);
    }
    updateState();
  }

  void removeAddress(IMoneroAddress? address) {
    syncChain.remove(address);
    updateState();
  }

  String? onValidateTrackerHeight(String? v) {
    final block = int.tryParse(v ?? '');
    if (block == null) {
      return "enter_valid_number".tr;
    }
    if (block < minTrackerHeight) {
      return "protocol_activiation_height_validator".tr;
    }
    if (block > currentBlockHeight) {
      return "block_must_be_lower_than_current_block".tr;
    }
    return null;
  }

  Future<void> toggleResetSynchronizationState() async {
    if (!resetTrackerState) {
      final ok = await context.openSliverDialog(
        widget: (context) => DialogTextView(
          buttonWidget: DialogDoubleButtonView(
            firstButtonLabel: "reset".tr,
            secoundButtonLabel: "cancel".tr,
          ),
          widget: Text("reset_syncronization_state_desc".tr),
        ),
        label: "reset_syncronization_state".tr,
      );
      if (ok != true) return;
    }
    resetTrackerState = !resetTrackerState;
    final network = syncChain.syncChain.network;
    if (network != null) {
      trackerHeight = currentBlockHeight;
      minTrackerHeight = widget.account.network.coinParam.rctHeight;
    }
    updateState();
  }

  Future<void> submit() async {
    if (!formKey.ready() || !isReady) return;
    int? trackerHeight;
    List<IMoneroAddress>? addresses;
    _MoneroSyncChainWithActivity syncChain = this.syncChain;
    if (resetTrackerState) {
      trackerHeight = this.trackerHeight;
      addresses = syncChain.selectedAddresses;
    }

    final chainController = context.wallet.wallet
        .chainController<MoneroNetworkController>(NetworkType.monero);
    if (chainController == null) return;
    progressKey.progressText("update_account_configuration_please_wait".tr);
    final result = await IResult.block(
        () async => await chainController.updateSyncChain(
            syncChain: syncChain.syncChain,
            resetTrackerHeight: trackerHeight,
            addresses: addresses),
        delay: APPConst.animationDuraion);
    result.watch(
      onErr: (error) {
        progressKey.errorText(error.localizationError,
            backToIdle: false, showBackButton: true);
      },
      onOk: (value) {
        syncChain = syncChains[value]!;
        progressKey.success();
      },
    );
  }

  Future<void> init() async {
    final syncChain = await widget.account.getSyncChain();
    final result = await syncChain.andThenAsync(
      (value) async {
        final height = await IResult.call(() async => await widget.client.getHeight());
        return height.andThenAsync((height) async {
          final chains = context.wallet.wallet.getChains<MoneroChain>();
          final chain = await IResult.anyError(chains.map((chain) async {
            final addresses = await chain.getAccountAddresses();
            return addresses.andThenAsync((_) async {
              final tracker = await chain.getChainTracker();
              return tracker.map((e) => (chain: chain, tracker: e));
            });
          }));
          return chain.andThenAsync((trackers) async {
            final syncChains = [
              ...trackers.map((e) =>
                  _MoneroSyncChainWithActivity(chain: e.chain, tracker: e.tracker)),
              _MoneroSyncChainWithActivity.none()
            ];
            return ResultOk((chain: value, height: height, syncChains: syncChains));
          });
        });
      },
    );

    result.map((e) {
      currentBlockHeight = e.height;

      currentSyncChain = e.chain;

      syncChains = e.syncChains.asMap().map((_, v) => MapEntry(v.syncChain, v));
      this.syncChain = syncChains[e.chain]!;
      // max = e.height;
      // defaultStartHeight = provider.activationHeight(
      //     MoneroNetworkProtocol.sapling, widget.account.zcashNetwork);
      // startBlock = defaultStartHeight;
      // endBlock = e;
      progressKey.backToIdle();
    }).mapErr((e) {
      progressKey.errorText(e.localizationError,
          backToIdle: false, showBackButton: false);
      return e.exception;
    });
  }

  @override
  void onInitOnce() {
    super.onInitOnce();

    init();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: StreamPageProgress(
          controller: progressKey,
          initialWidget: ProgressWithTextView(text: "fetching_current_block_data".tr),
          builder: (context) {
            return UnfocusableChild(
              child: CustomScrollView(
                slivers: [
                  SliverConstraintsBoxView(
                    padding: WidgetConstant.padding20,
                    sliver: SliverToBoxAdapter(
                      child:
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          "sync_network".tr,
                          style: context.textTheme.titleMedium,
                        ),
                        Text(
                          "select_network_to_enable_synchronization".tr,
                          style: context.textTheme.bodyMedium,
                        ),
                        Text("only_one_network_synchronization_desc".tr,
                            style: context.textTheme.bodyMedium),
                        WidgetConstant.height8,
                        AppGroupRadioBuilder<_MoneroSyncChainWithActivity>(
                          groupValue: syncChain,
                          onChanged: onChangeNetwork,
                          builder: (context) {
                            return Column(
                                children: syncChains.entries.map((e) {
                              final chain = e.key;
                              final bool isActive = e.value.isActive;
                              return AppRadioListTile(
                                value: e.value,
                                enabled: isActive,
                                subtitle: switch (chain.network) {
                                  null => Text("disable_synchronization".tr),
                                  _ when !isActive => Text("no_active_account".tr),
                                  _ => null
                                },
                                title: Text(chain.network?.name ?? "None".tr),
                              );
                            }).toList());
                          },
                        ),
                        APPAnimated(
                            isActive: syncChain.network != null,
                            onActive: (context) => Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppSwitchListTile(
                                        value: resetTrackerState,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text("reset_syncronization_state".tr),
                                        onChanged: (p0) {
                                          toggleResetSynchronizationState();
                                        },
                                      ),
                                      APPAnimated(
                                          isActive: resetTrackerState,
                                          onActive: (context) {
                                            return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text("addresses".tr,
                                                      style:
                                                          context.textTheme.titleMedium),
                                                  Text("reset_sync_select_addresses".tr),
                                                  WidgetConstant.height8,
                                                  AnimatedSize(
                                                    duration: APPConst.animationDuraion,
                                                    child: Column(
                                                      key: ValueKey<int>(syncChain
                                                          .selectedAddresses.length),
                                                      children: List.generate(
                                                          syncChain.selectedAddresses
                                                              .length, (index) {
                                                        final addr = syncChain
                                                            .selectedAddresses[index];
                                                        return CustomizedContainer(
                                                            enableTap: false,
                                                            onTapStackIcon: () =>
                                                                removeAddress(addr),
                                                            onStackIcon:
                                                                Icons.remove_circle,
                                                            child: AddressDetailsView(
                                                              address: addr,
                                                              color: context
                                                                  .onPrimaryContainer,
                                                              showBalance: false,
                                                            ));
                                                      }),
                                                    ),
                                                  ),
                                                  ContainerWithBorder(
                                                      onRemove: () {
                                                        context
                                                            .selectOrSwitchAccount<
                                                                    IMoneroAddress>(
                                                                account: syncChain.chain!,
                                                                defaultAddresses:
                                                                    syncChain
                                                                        .shieldAddresses,
                                                                showMultiSig: false)
                                                            .then(
                                                          (value) {
                                                            addAddress(value);
                                                          },
                                                        );
                                                      },
                                                      enableTap: true,
                                                      onRemoveIcon: Icon(
                                                        Icons.add_box,
                                                        color: context.onPrimaryContainer,
                                                      ),
                                                      validate: syncChain
                                                          .selectedAddresses.isNotEmpty,
                                                      child: Text(
                                                          "tap_to_select_address".tr)),
                                                  WidgetConstant.height20,
                                                  Text(
                                                      "start_block_for_synchronization"
                                                          .tr,
                                                      style:
                                                          context.textTheme.titleMedium),
                                                  Text("start_at_block".tr),
                                                  WidgetConstant.height8,
                                                  NumberTextField(
                                                      label:
                                                          "start_block_for_synchronization"
                                                              .tr,
                                                      onChangeValue:
                                                          onChangeTrackerHeight,
                                                      min: minTrackerHeight,
                                                      validator: onValidateTrackerHeight,
                                                      defaultValue: trackerHeight,
                                                      maxWidth: double.infinity,
                                                      max: currentBlockHeight),
                                                ]);
                                          })
                                    ])),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FixedElevatedButton(
                                activePress: isReady,
                                padding: WidgetConstant.paddingVertical40,
                                onPressed: submit,
                                child: Text("update".tr)),
                          ],
                        )
                      ]),
                    ),
                  )
                ],
              ),
            );
          }),
    );
  }
}

class MoneroCreateSynchronizationRequest extends StatelessWidget {
  const MoneroCreateSynchronizationRequest({super.key});
  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<MoneroNetworkClient, IMoneroAddress, MoneroChain>(
      title: "create_synchronization_request".tr,
      addressRequired: true,
      clientRequired: true,
      childBulder: (wallet, account, client, address) =>
          _MoneroCreateSyncRequest(account: account, client: client),
    );
  }
}

class _MoneroSyncChainWithActivity {
  final MoneroChain? chain;
  final MoneroSyncChain syncChain;
  final bool isActive;
  final MoneroSyncTrackerController? tracker;
  final List<IMoneroAddress> shieldAddresses;
  List<IMoneroAddress> selectedAddresses = [];
  MoneroNetwork? get network => syncChain.network;
  _MoneroSyncChainWithActivity._(
      this.chain, this.isActive, this.syncChain, this.tracker, this.shieldAddresses);
  factory _MoneroSyncChainWithActivity.none() {
    return _MoneroSyncChainWithActivity._(null, true, MoneroSyncChain.none, null, []);
  }
  factory _MoneroSyncChainWithActivity({
    required MoneroChain chain,
    required MoneroSyncTrackerController tracker,
  }) {
    final addresses = chain.addresses;
    final network = chain.moneroNetwork;
    final isActive = addresses.isNotEmpty;
    final syncChain = switch (network) {
      MoneroNetwork.mainnet => MoneroSyncChain.mainnet,
      MoneroNetwork.stagenet => MoneroSyncChain.stagenet,
      MoneroNetwork.testnet => MoneroSyncChain.testnet,
    };
    return _MoneroSyncChainWithActivity._(chain, isActive, syncChain, tracker, addresses);
  }

  bool addAddress(IMoneroAddress address) {
    // if (address == null) return;
    if (!shieldAddresses.contains(address)) {
      return false;
    }
    if (selectedAddresses.contains(address)) return false;
    selectedAddresses.add(address);
    return true;
  }

  void remove(IMoneroAddress? address) {
    selectedAddresses.remove(address);
  }
}

class _MoneroCreateSyncRequest extends StatefulWidget {
  final MoneroChain account;
  final MoneroNetworkClient client;
  const _MoneroCreateSyncRequest({required this.account, required this.client});

  @override
  State<_MoneroCreateSyncRequest> createState() => __CreateSyncHeightRequestState();
}

class __CreateSyncHeightRequestState extends State<_MoneroCreateSyncRequest>
    with SafeState<_MoneroCreateSyncRequest> {
  final List<IMoneroAddress> addresses = [];
  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: PageProgressStatus.progress);
  int max = 0;

  int defaultStartHeight = 0;
  bool enable = false;
  final GlobalKey<FormState> formKey = GlobalKey();

  void onBlockEnd(int? block) {
    endBlock = block ?? 0;
  }

  void onBlockStart(int? block) {
    startBlock = block ?? 0;
  }

  String? sartBlockValidator(String? v) {
    final block = int.tryParse(v ?? '');
    return validateBlockFilds(block);
  }

  int startBlock = 0;
  int endBlock = 0;

  void addAddress(IMoneroAddress? address) {
    if (address == null) return;
    if (addresses.contains(address)) {
      context.showAlert("address_already_exist".tr);
      return;
    }
    addresses.add(address);
    updateState();
  }

  void removeAddress(IMoneroAddress address) {
    addresses.remove(address);
    updateState();
  }

  String? validateBlockFilds(int? block) {
    if (block == null) {
      return "enter_valid_number".tr;
    }
    if (block < defaultStartHeight) {
      return "monero_rct_block_validator".tr.replaceOne(defaultStartHeight.toString());
    }
    return null;
  }

  String? endBlockValidator(String? v) {
    final block = int.tryParse(v ?? '');

    final err = validateBlockFilds(block);
    if (err != null) return err;
    if (block! <= startBlock) {
      return "end_block_number_validator".tr;
    }
    return null;
  }

  Future<void> submit() async {
    if (!enable) return;
    if (!formKey.ready()) return;
    progressKey.progressText("update_account_configuration_please_wait".tr);
    final request = MoneroSyncAccountRequest(
        indexes: addresses.map((e) => e.index).toList(),
        startHeight: startBlock,
        endHeight: endBlock);
    final result = await widget.account.addSyncRequest(request);
    result.watch(
      onErr: (error) {
        progressKey.errorText(error.localizationError,
            backToIdle: false, showBackButton: true);
      },
      onOk: (value) {
        progressKey.success(backToIdle: false);
      },
    );
  }

  Future<void> init() async {
    final height = await IResult.call(() async => await widget.client.getHeight());
    height.map((e) {
      max = e;
      defaultStartHeight = widget.account.network.coinParam.rctHeight;
      startBlock = defaultStartHeight;
      endBlock = e;
      progressKey.backToIdle();
    }).mapErr((e) {
      progressKey.errorText(e.localizationError,
          backToIdle: false, showBackButton: false);
      return e.exception;
    });
  }

  @override
  void updateState([VoidCallback? fn]) {
    enable = addresses.isNotEmpty;
    super.updateState(fn);
  }

  @override
  void onInitOnce() {
    super.onInitOnce();

    init();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: StreamPageProgress(
          controller: progressKey,
          initialWidget: ProgressWithTextView(text: "fetching_current_block_data".tr),
          builder: (context) {
            return UnfocusableChild(
              child: CustomScrollView(
                slivers: [
                  SliverConstraintsBoxView(
                    padding: WidgetConstant.padding20,
                    sliver: SliverToBoxAdapter(
                      child:
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("select_account".tr, style: context.textTheme.titleMedium),
                        Text("select_accounts_for_syncing".tr),
                        WidgetConstant.height8,
                        Column(
                          children: List.generate(addresses.length, (index) {
                            final address = addresses[index];
                            return Column(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomizedContainer(
                                      child: Column(
                                        children: [
                                          ContainerWithBorder(
                                            onRemoveIcon: IconButton(
                                                onPressed: () {
                                                  removeAddress(address);
                                                },
                                                icon: Icon(
                                                  Icons.remove_circle,
                                                  color: context.primaryContainer,
                                                )),
                                            onRemove: () {
                                              removeAddress(address);
                                            },
                                            enableTap: false,
                                            backgroundColor:
                                                context.colors.onPrimaryContainer,
                                            child: AddressDetailsView(
                                                address: address,
                                                showBalance: false,
                                                color: context.primaryContainer),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }),
                        ),
                        ContainerWithBorder(
                            validate: addresses.isNotEmpty,
                            onRemove: () {
                              context
                                  .selectOrSwitchAccount<IMoneroAddress>(
                                      account: widget.account, showMultiSig: true)
                                  .then(addAddress);
                            },
                            onRemoveIcon:
                                Icon(Icons.add_box, color: context.onPrimaryContainer),
                            child: Text("tap_to_add_account".tr,
                                style: context.onPrimaryTextTheme.bodyMedium)),
                        WidgetConstant.height20,
                        Text("start_block_for_synchronization".tr,
                            style: context.textTheme.titleMedium),
                        WidgetConstant.height8,
                        NumberTextField(
                            hintText: "start_at_block".tr,
                            onChangeValue: onBlockStart,
                            min: 0,
                            max: max,
                            defaultValue: startBlock,
                            maxWidth: double.infinity,
                            validator: sartBlockValidator),
                        WidgetConstant.height20,
                        Text("end_block_for_synchronization".tr,
                            style: context.textTheme.titleMedium),
                        WidgetConstant.height8,
                        NumberTextField(
                            hintText: "end_at_block".tr,
                            onChangeValue: onBlockEnd,
                            min: 0,
                            validator: endBlockValidator,
                            defaultValue: endBlock,
                            maxWidth: double.infinity,
                            max: max),
                        WidgetConstant.height20,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FixedElevatedButton(
                                activePress: enable,
                                padding: WidgetConstant.paddingVertical40,
                                onPressed: submit,
                                child: Text("submit".tr)),
                          ],
                        )
                      ]),
                    ),
                  )
                ],
              ),
            );
          }),
    );
  }
}
