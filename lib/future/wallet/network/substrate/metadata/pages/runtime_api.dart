import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/account/account.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/account/state.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/metadata/fields/fields.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/metadata/forms/metadata.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

class SubstrateMetadataRuntimeApiView extends StatelessWidget {
  const SubstrateMetadataRuntimeApiView(
      {required this.account, this.scrollController, super.key});
  final ScrollController? scrollController;
  final SubstrateChain account;

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<SubstrateNetworkClient, ISubstrateAddress,
            SubstrateChain>(
        addressRequired: true,
        clientRequired: true,
        account: account,
        title: 'runtime_apis'.tr,
        childBulder: (wallet, account, client, address) =>
            SubstrateMetadataRuntimeApiWidget(
                account: account, scrollController: scrollController, client: client));
  }
}

enum _APIPage { select, api }

class SubstrateMetadataRuntimeApiWidget extends StatefulWidget {
  const SubstrateMetadataRuntimeApiWidget(
      {super.key,
      required this.account,
      required this.scrollController,
      required this.client});
  final SubstrateChain account;
  final SubstrateNetworkClient client;
  final ScrollController? scrollController;

  @override
  State<SubstrateMetadataRuntimeApiWidget> createState() =>
      _SubstrateMetadataRuntimeApiWidgetState();
}

class _SubstrateMetadataRuntimeApiWidgetState
    extends SubstrateAccountState<SubstrateMetadataRuntimeApiWidget> {
  late final List<RuntimeApiInfo> apis;
  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  _APIPage page = _APIPage.select;
  _RuntimeLookupFields? field;
  @override
  SubstrateChain get account => widget.account;
  @override
  SubstrateNetworkClient get client => widget.client;
  Map<RuntimeApiInfo, Text> items = {};
  bool get canPop => page == _APIPage.select;
  late RuntimeApiInfo api;
  SubstrateChainMetadata get metadata => client.metadata;

  void onTapMethod(RuntimeApiMethodInfo method) {
    List<MetadataTypeInfo> fields = [];
    for (final i in method.inputs ?? <RuntimeApiInputInfo>[]) {
      MetadataTypeInfo loockup = metadata.getLookupTypeInfo(i.lockupId)!;
      loockup = loockup.copyWith(name: loockup.name ?? i.name);
      fields.add(loockup);
    }
    field = _RuntimeLookupFields(
        method: method,
        apiName: api.name,
        forms: fields.map((e) => MetadataFormValidator.fromType(e)).toList());
    page = _APIPage.api;
    updateState();
  }

  void onChangePallet(RuntimeApiInfo? api) {
    this.api = api ?? this.api;
    updateState();
  }

  void init() {
    final apis = metadata.metadataInfos.apis;
    if (!metadata.supportRuntimeApi || apis == null) {
      progressKey.errorText("unsupported_current_network_feature".tr, backToIdle: false);
      return;
    }
    this.apis = metadata.metadataInfos.apis!;
    items = {for (final i in apis) i: Text(i.name)};
    api = apis.first;
    progressKey.backToIdle();
  }

  void onBackButton() {
    if (canPop) return;
    page = _APIPage.select;
    callAgain();
    field?.dispose();
    field = null;
  }

  void callAgain() {
    _showResult = false;
    updateState();
    _result = null;
  }

  bool _showResult = false;
  bool get showResult => _showResult;
  final GlobalKey<FormState> formState =
      GlobalKey(debugLabel: "RuntimeApiFieldsStateController_formState");
  String? _result;
  String? get result => _result;

  Future<void> callApi() async {
    if (!formState.ready()) return;
    final field = this.field;
    if (field == null) return;
    final hasError = field.forms.any((e) => e.error != null);
    if (hasError) return;
    progressKey.progressText("retrieving_data_please_wait".tr);

    final r = await IResult.call(() async {
      return client.runtimeCall(
          methodName: field.method.name,
          apiName: field.apiName,
          inputs: field.forms.map((e) => e.getResult()).toList());
    });
    if (r.isErr) {
      progressKey.errorText(r.unwrapErr().localizationError,
          backToIdle: false, showBackButton: true);
    } else {
      _result = r.unwrap();
      _showResult = true;
      progressKey.success();
    }
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    init();
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
                sliver: APPSliverAnimatedSwitcher<_APIPage>(enable: page, widgets: {
                  _APIPage.select: (context) => MultiSliver(children: [
                        SliverPinnedHeaderSurface(
                            elevation: APPConst.elevation,
                            child: AppDropDownBottom(
                                items: items, onChanged: onChangePallet, value: api)),
                        SliverPadding(
                          padding: WidgetConstant.paddingHorizontal20,
                          sliver: APPSliverAnimatedSwitcher(enable: api, widgets: {
                            api: (context) => SliverList.builder(
                                  itemBuilder: (context, index) {
                                    final method = api.methods![index];
                                    return AppListTile(
                                        title: Text(method.viewName),
                                        maxLine: 10,
                                        trailing: IconButton(
                                            onPressed: () {
                                              onTapMethod(method);
                                            },
                                            icon: const Icon(Icons.build)),
                                        contentPadding: EdgeInsets.zero,
                                        subtitle: LargeTextView(method.docs,
                                            textAligen: TextAlign.start));
                                  },
                                  itemCount: api.methods!.length,
                                )
                          }),
                        )
                      ]),
                  _APIPage.api: (context) => _RuntimeApiFieldsWidget(state: this)
                }),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _RuntimeApiFieldsWidget extends StatelessWidget {
  const _RuntimeApiFieldsWidget({required this.state});
  final _SubstrateMetadataRuntimeApiWidgetState state;

  @override
  Widget build(BuildContext context) {
    return APPSliverAnimatedSwitcher(enable: state.showResult, widgets: {
      false: (context) => MultiSliver(
            children: [
              if (state.field!.forms.isEmpty)
                SliverToBoxAdapter(child: Text("inputs_not_needed".tr)),
              for (final form in state.field!.forms)
                SubstrateMetadataValidatorView(
                    validator: form, account: state.account, metadata: state.metadata),
              SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FixedElevatedButton(
                        padding: WidgetConstant.paddingVertical40,
                        onPressed: () {
                          state.callApi();
                        },
                        child: Text("call_api".tr)),
                  ],
                ),
              )
            ],
          ),
      true: (context) => SliverToBoxAdapter(
            child: Column(
              children: [
                ContainerWithBorder(
                    child: CopyableTextWidget(
                  text: state.result ?? '',
                  color: context.onPrimaryContainer,
                  widget: APPSelectableText(state.result ?? '',
                      style: context.onPrimaryTextTheme.bodyMedium),
                  maxLines: 10,
                )),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FixedElevatedButton.icon(
                        padding: WidgetConstant.paddingVertical40,
                        onPressed: () {
                          state.callAgain();
                        },
                        label: Text("call_again".tr),
                        icon: const Icon(Icons.refresh)),
                  ],
                )
              ],
            ),
          )
    });
  }
}

class _RuntimeLookupFields {
  final List<MetadataFormValidator> forms;
  final RuntimeApiMethodInfo method;
  final String apiName;
  const _RuntimeLookupFields(
      {required this.method, required this.apiName, required this.forms});
  void dispose() {
    for (final i in forms) {
      i.dispose();
    }
  }
}
