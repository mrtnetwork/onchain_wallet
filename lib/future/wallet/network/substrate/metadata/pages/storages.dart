import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/metadata/fields/fields.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/metadata/forms/metadata.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

enum _StoragePage { select, query }

class SubstrateMetadataStoragesView extends StatelessWidget {
  const SubstrateMetadataStoragesView(
      {required this.account, this.storage, this.scrollController, super.key});
  final ScrollController? scrollController;
  final SubstrateChain account;
  final StorageInfo? storage;

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<SubstrateNetworkClient, ISubstrateAddress,
            SubstrateChain>(
        addressRequired: true,
        clientRequired: true,
        account: account,
        title: 'storages'.tr,
        childBulder: (wallet, account, client, address) =>
            SubstrateMetadataStoragesWidget(
                account: account, scrollController: scrollController, client: client));
  }
}

class SubstrateMetadataStoragesWidget extends StatefulWidget {
  const SubstrateMetadataStoragesWidget(
      {super.key,
      required this.account,
      this.scrollController,
      this.storage,
      required this.client});
  final ScrollController? scrollController;
  final SubstrateChain account;
  final StorageInfo? storage;
  final SubstrateNetworkClient client;

  @override
  State<SubstrateMetadataStoragesWidget> createState() =>
      _SubstrateMetadataStoragesWidgetState();
}

class _SubstrateMetadataStoragesWidgetState
    extends SubstrateAccountState<SubstrateMetadataStoragesWidget> {
  @override
  SubstrateChain get account => widget.account;
  @override
  SubstrateNetworkClient get client => widget.client;

  SubstrateChainMetadata get metadata => client.metadata;

  late final List<PalletInfo> storagePallets;
  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  GlobalKey? getStoragesKey = GlobalKey();
  final List<StorageInfo> storages = [];
  _StoragePage page = _StoragePage.select;
  List<_StorageLookupField> fields = [];
  Map<PalletInfo, Text> items = {};
  late PalletInfo pallet;
  bool get canPop => page == _StoragePage.select;

  void queryStorages() {
    if (storages.isEmpty) return;
    final List<_StorageLookupField> fields = [];
    for (final i in storages) {
      final loockup = metadata.getLookupTypeInfo(i.inputLookupId, name: i.viewName);
      final field = _StorageLookupField(
          form: loockup == null ? null : MetadataFormValidator.fromType(loockup),
          storage: i,
          pallet: pallet.name);
      fields.add(field);
    }
    this.fields = fields;
    page = _StoragePage.query;
    updateState();
  }

  void onChangePallet(PalletInfo? pallet) {
    this.pallet = pallet ?? this.pallet;
    updateState();
  }

  Future<void> onTapStorage(StorageInfo storage) async {
    final r = storages.remove(storage);
    if (!r) {
      storages.add(storage);
    }
    updateState();
    if (storages.length == 1) {
      await getStoragesKey?.ensureKeyVisible();
      getStoragesKey = null;
    }
  }

  Future<void> init() async {
    storagePallets = metadata.storagePallets();
    items = {for (final i in storagePallets) i: Text(i.name)};
    pallet = storagePallets.first;
    if (widget.storage != null) {
      storages.add(widget.storage!);
      queryStorages();
    }
    progressKey.backToIdle();
  }

  void onBackButton() {
    if (canPop) return;
    page = _StoragePage.select;
    queryAgain();
  }

  ///
  final GlobalKey<FormState> formState =
      GlobalKey(debugLabel: "FieldsStateController_formState");
  bool _showResult = false;
  bool get showResult => _showResult;
  List<String> _results = [];
  List<String> get results => _results;
  Future<void> callStorage() async {
    if (!formState.ready()) return;
    final error = fields.any((e) => e.form?.error != null);
    if (error) return;
    progressKey.progressText("retrieving_data_please_wait".tr);
    final r = await IResult.call(() async {
      _results.clear();
      return client.queryStorage(fields
          .map((e) => SubstrateStorageQueryParams(
              pallet: pallet.name, storage: e.storage, input: e.form?.getResult()))
          .toList());
    });
    if (r.isErr) {
      progressKey.errorText(r.unwrapErr().localizationError,
          backToIdle: false, showBackButton: true);
    } else {
      _results = r.unwrap();
      _showResult = true;
      progressKey.success();
    }
  }

  void queryAgain() {
    _results.clear();
    _showResult = false;
    updateState();
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    MethodUtils.executeAfterDelay(() => init(), duration: APPConst.animationDuraion);
  }

  @override
  void safeDispose() {
    super.safeDispose();
    progressKey.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formState,
      canPop: canPop,
      onPopInvokedWithResult: (_, __) {
        onBackButton();
      },
      child: StreamPageProgress(
        controller: progressKey,
        initialWidget: ProgressWithTextView(text: 'retrieving_data_please_wait'.tr),
        builder: (context) => UnfocusableChild(
          child: CustomScrollView(
            controller: widget.scrollController,
            slivers: [
              SliverConstraintsBoxView(
                padding: WidgetConstant.paddingHorizontal20,
                sliver: APPSliverAnimatedSwitcher<_StoragePage>(enable: page, widgets: {
                  _StoragePage.select: (context) => MultiSliver(children: [
                        SliverPinnedHeaderSurface(
                            elevation: APPConst.elevation,
                            child: AppDropDownBottom(
                                items: items, onChanged: onChangePallet, value: pallet)),
                        SliverPadding(
                          padding: WidgetConstant.paddingHorizontal20,
                          sliver: APPSliverAnimatedSwitcher(enable: pallet, widgets: {
                            pallet: (context) => PalletStoragesView(
                                pallet: pallet, onTap: onTapStorage, storages: storages)
                          }),
                        ),
                        SliverToBoxAdapter(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FixedElevatedButton(
                                  activePress: storages.isNotEmpty,
                                  padding: WidgetConstant.paddingVertical40,
                                  key: getStoragesKey,
                                  onPressed: () {
                                    queryStorages();
                                  },
                                  child: Text("get_storages".tr))
                            ],
                          ),
                        ),
                      ]),
                  _StoragePage.query: (context) => _StorageFieldsWidget(state: this)
                }),
              )
            ],
          ),
        ),
      ),
    );
  }
}

typedef ONTAPSTORAGE = void Function(StorageInfo);

class PalletStoragesView extends StatelessWidget {
  const PalletStoragesView(
      {super.key, required this.pallet, required this.onTap, required this.storages});
  final PalletInfo pallet;
  final ONTAPSTORAGE onTap;
  final List<StorageInfo> storages;

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
        itemBuilder: (context, index) {
          final storage = pallet.storage![index];
          return AppCheckListTile(
              title: Text(storage.name),
              maxLine: 10,
              onChanged: (v) {
                onTap(storage);
              },
              value: storages.contains(storage),
              contentPadding: EdgeInsets.zero,
              subtitle: LargeTextView(storage.docs, textAligen: TextAlign.start));
        },
        itemCount: pallet.storage!.length);
  }
}

class _StorageFieldsWidget extends StatelessWidget {
  const _StorageFieldsWidget({required this.state});
  // final List<_StorageLookupField> fields;
  final _SubstrateMetadataStoragesWidgetState state;

  @override
  Widget build(BuildContext context) {
    return APPSliverAnimatedSwitcher(enable: state.showResult, widgets: {
      false: (context) => SliverMainAxisGroup(
            slivers: [
              for (final form in state.fields) ...[
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (form.form == null) ...[
                        Text("inputs_not_needed".tr),
                        WidgetConstant.height8,
                        WidgetConstant.divider
                      ],
                    ],
                  ),
                ),
                if (form.form != null) ...[
                  SubstrateMetadataValidatorView(
                      validator: form.form!,
                      account: state.account,
                      metadata: state.metadata),
                  const SliverToBoxAdapter(child: WidgetConstant.divider),
                ],
              ],
              SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FixedElevatedButton(
                        padding: WidgetConstant.paddingVertical40,
                        onPressed: () {
                          state.callStorage();
                        },
                        child: Text("get_storages".tr)),
                  ],
                ),
              )
            ],
          ),
      true: (context) => MultiSliver(
            children: [
              SliverList.separated(
                itemCount: state.fields.length,
                separatorBuilder: (context, index) => WidgetConstant.divider,
                itemBuilder: (context, index) {
                  final result = state.results[index];
                  final storage = state.fields[index].storage;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(storage.name, style: context.textTheme.titleMedium),
                      WidgetConstant.height8,
                      ContainerWithBorder(
                          child: CopyableTextWidget(
                              text: result,
                              color: context.onPrimaryContainer,
                              widget: APPSelectableText(result,
                                  style: context.onPrimaryTextTheme.bodyMedium),
                              maxLines: 10)),
                    ],
                  );
                },
              ),
              SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FixedElevatedButton(
                        padding: WidgetConstant.paddingVertical40,
                        onPressed: () {
                          state.queryAgain();
                        },
                        child: Text("query_again".tr)),
                  ],
                ),
              )
            ],
          )
    });
  }
}

class _StorageLookupField {
  final StorageInfo storage;
  final MetadataFormValidator? form;
  final String pallet;
  const _StorageLookupField(
      {required this.storage, required this.form, required this.pallet});
}
