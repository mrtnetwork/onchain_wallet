import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/zcash.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:zcash_dart/zcash.dart';

class ZcashUpdateSyncNetwork extends StatelessWidget {
  const ZcashUpdateSyncNetwork({super.key});
  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<ZcashNetworkClient, IZcashAddress, ZcashChain>(
      title: "update_synchronization_network".tr,
      addressRequired: true,
      clientRequired: true,
      childBulder: (wallet, account, client, address) =>
          _ZcashUpdateSyncChain(account: account, client: client),
    );
  }
}

class _ZcashUpdateSyncChain extends StatefulWidget {
  final ZcashChain account;
  final ZcashNetworkClient client;
  const _ZcashUpdateSyncChain({required this.account, required this.client});

  @override
  State<_ZcashUpdateSyncChain> createState() => __ZcashUpdateSyncChain();
}

class __ZcashUpdateSyncChain extends State<_ZcashUpdateSyncChain>
    with SafeState<_ZcashUpdateSyncChain> {
  ZcashSyncChain currentSyncChain = ZcashSyncChain.none;
  _ZcashSyncChainWithActivity syncChain = _ZcashSyncChainWithActivity.none();

  // Map<ZcashSyncChain, ZcashChainTracker> trackers = {};
  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: PageProgressStatus.progress);
  final provider = DefaultUpgradeActivationProvider();
  Map<ZcashSyncChain, _ZcashSyncChainWithActivity> syncChains = {};
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

  void onChangeNetwork(_ZcashSyncChainWithActivity? chain) {
    if (chain == null || chain == syncChain) return;
    syncChain = chain;
    resetTrackerState = false;
    updateState();
  }

  void onChangeTrackerHeight(int? height) {
    trackerHeight = height ?? 0;
  }

  void addAddress(IZcashAddress? address) {
    if (address == null) return;
    if (!syncChain.addAddress(address)) {
      context.showAlert("address_already_exist".tr);
    }
    updateState();
  }

  void removeAddress(IZcashAddress? address) {
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
      minTrackerHeight = provider.activationHeight(ZcashNetworkProtocol.sapling, network);
    }
    updateState();
  }

  Future<void> submit() async {
    if (!formKey.ready() || !isReady) return;
    int? trackerHeight;
    List<IZcashAddress>? addresses;
    _ZcashSyncChainWithActivity syncChain = this.syncChain;
    if (resetTrackerState) {
      trackerHeight = this.trackerHeight;
      addresses = syncChain.selectedAddresses;
    }

    final chainController =
        context.wallet.wallet.chainController<ZcashNetworkController>(NetworkType.zcash);
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
        final height =
            await IResult.call(() async => await widget.client.getLatestBlockHeight());
        return height.andThenAsync((height) async {
          final chains = context.wallet.wallet.getChains<ZcashChain>();
          final chain = await IResult.anyError(chains.map((chain) async {
            final addresses = await chain.getAccountAddresses();
            return addresses.andThenAsync((_) async {
              final tracker = await chain.getChainTracker();
              return tracker.map((e) => (chain: chain, tracker: e));
            });
          }));
          return chain.andThenAsync((trackers) async {
            final syncChains = [
              ...trackers.map((e) => _ZcashSyncChainWithActivity(
                  chain: e.chain,
                  tracker: e.tracker,
                  currentAccountSyncChain: widget.account.accountSyncChain)),
              _ZcashSyncChainWithActivity.none()
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
                        AppGroupRadioBuilder<_ZcashSyncChainWithActivity>(
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
                            isActive: syncChain.allowResetState,
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
                                                                    IZcashAddress>(
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

class _ZcashSyncChainWithActivity {
  final ZcashChain? chain;
  final ZcashSyncChain syncChain;
  final bool isActive;
  final ZcashSyncTrackerController? tracker;
  final List<IZcashAddress> shieldAddresses;
  List<IZcashAddress> selectedAddresses = [];
  ZcashNetwork? get network => syncChain.network;
  final bool allowResetState;
  _ZcashSyncChainWithActivity._(this.chain, this.isActive, this.syncChain, this.tracker,
      this.shieldAddresses, this.allowResetState);
  factory _ZcashSyncChainWithActivity.none() {
    return _ZcashSyncChainWithActivity._(
        null, true, ZcashSyncChain.none, null, [], false);
  }
  factory _ZcashSyncChainWithActivity({
    required ZcashChain chain,
    required ZcashSyncTrackerController tracker,
    required ZcashSyncChain currentAccountSyncChain,
  }) {
    final shieldAddresses =
        chain.addresses.where((e) => e.account.hasSheildAccount()).toList();
    final network = chain.zcashNetwork;
    final isActive = shieldAddresses.isNotEmpty;
    final syncChain = switch (network) {
      ZcashNetwork.mainnet => ZcashSyncChain.mainnet,
      ZcashNetwork.testnet => ZcashSyncChain.testnet,
      ZcashNetwork.regtest => ZcashSyncChain.regtest,
    };
    return _ZcashSyncChainWithActivity._(chain, isActive, syncChain, tracker,
        shieldAddresses, currentAccountSyncChain == syncChain);
  }

  bool addAddress(IZcashAddress address) {
    // if (address == null) return;
    if (!shieldAddresses.contains(address)) {
      return false;
    }
    if (selectedAddresses.contains(address)) return false;
    selectedAddresses.add(address);
    return true;
  }

  void remove(IZcashAddress? address) {
    selectedAddresses.remove(address);
  }
}
