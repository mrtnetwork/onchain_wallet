import 'dart:async';

import 'package:blockchain_utils/bip/bip/bip.dart';
import 'package:blockchain_utils/service/models/params.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/network/import/controller/form.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/network/update_native_token.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

enum _Page { selectChain, search, review }

class CosmosImportNetworkView extends StatelessWidget {
  const CosmosImportNetworkView({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessWalletView<WalletCredentialResponseLogin, WalletCredentialLogin>(
      request: WalletCredentialLogin.instance,
      appbar: AppBar(title: Text("import_network".tr)),
      onAccsess: (_) {
        return _CosmosImportNetworkView();
      },
    );
  }
}

class _CosmosImportNetworkView extends StatefulWidget {
  const _CosmosImportNetworkView();

  @override
  State<_CosmosImportNetworkView> createState() => __CosmosImportNetworkViewState();
}

class __CosmosImportNetworkViewState extends State<_CosmosImportNetworkView>
    with CosmosCustomRequest, SafeState {
  late final CosmosAddNewChainFrom form;
  @override
  INetApi get netApi => form.netApi;
  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  late final List<CosmosChain> existChains;
  String? networkName;
  Map<ChainType, Widget> chainTypeWidgets = {};
  late final WalletProvider wallet;
  Map<ChainType, Widget> buildChainType() {
    return {for (final i in ChainType.values) i: Text(i.tr.tr)};
  }

  ChainType? chaintype;
  _Page page = _Page.selectChain;
  List<CosmosSdkChain> chains = [];
  List<CosmosSdkChain> filtredChains = [];
  void onSelectChain(CosmosSdkChain chain) {
    form.buildFrom(chain);
    page = _Page.review;
    updateState();
  }

  void setManuallyImport() {
    form.buildFrom(null);
    page = _Page.review;
    updateState();
  }

  void changePage(_Page page) {
    this.page = page;
  }

  void onChangeChainType(ChainType? chaintype) async {
    this.chaintype = chaintype;
    switch (chaintype) {
      case ChainType.mainnet:
        chains = form.chains?.mainnet ?? [];
        filtredChains = form.chains?.mainnet ?? [];
        page = _Page.search;
        break;
      case ChainType.testnet:
        chains = form.chains?.testnet ?? [];
        filtredChains = form.chains?.testnet ?? [];
        page = _Page.search;
        break;
      default:
        page = _Page.selectChain;
        break;
    }
    updateState();
  }

  void onSearchNetworkName(String v) {
    if (v.trim().isEmpty) {
      filtredChains = chains;
    } else {
      filtredChains = chains.where((e) {
        return e.name.contains(v.trim().toLowerCase());
      }).toList();
    }
    updateState();
  }

  StreamSubscription<void>? _listener;

  Future<void> init() async {
    await IResult.call(() => form.initForm());
    _listener = form.stream.listen((void _) => updateState());
    chainTypeWidgets = buildChainType();
    wallet = context.wallet;
    existChains = wallet.wallet.getChains<CosmosChain>();
    progressKey.backToIdle();
  }

  Future<void> importChain() async {
    if (!form.formKey.ready()) return;
    final rpcUrl = form.getRpcUrl();
    if (rpcUrl == null) return;
    progressKey.progressText("checking_rpc_network_info".tr);

    final params = await IResult.call(() {
      return form.createNetwork(
        chainType: chaintype,
        onUnknownAlgAlert: () {
          return context.openSliverDialog<bool>(
              widget: (p0) => DialogTextView(
                    text: "cosmos_unknown_key_algorithm_desc".tr,
                    buttonWidget: const DialogDoubleButtonView(),
                  ),
              label: "verify_key_algorithm".tr);
        },
      );
    });
    if (params.isErr) {
      progressKey.errorText(params.unwrapErr().localizationError,
          backToIdle: false, showBackButton: true);
      return;
    }
    final network = params.unwrap();
    if (network == null) {
      progressKey.backToIdle();
      return;
    }
    final newNetwork = WalletCosmosNetwork(-1, network.$1);
    final result = await wallet.wallet.doAction(
        WalletActionImportNewNetwork(network: newNetwork, providers: [network.$2]));
    if (result.isErr) {
      progressKey.errorText(result.unwrapErr().localizationError,
          backToIdle: false, showBackButton: true);
    } else {
      progressKey.successText("network_imported_to_your_wallet".tr, backToIdle: false);
    }
    updateState();
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    form = CosmosAddNewChainFrom(context.appContext);
    MethodUtils.executeAfterDelay(() async => init());
  }

  Future<void> onBackButton() async {
    if (progressKey.inProgress || progressKey.isSuccess) return;
    if (progressKey.hasError) {
      progressKey.backToIdle();
      return;
    }
    if (page == _Page.review) {
      final close = await context.openSliverDialog<bool>(
          widget: (p0) => DialogTextView(
                text: "all_entered_information_will_be_lost".tr,
                buttonWidget: const DialogDoubleButtonView(),
              ),
          label: "back_to_previous_page".tr);
      if (close != true) return;
    }
    onChangeChainType(null);
  }

  @override
  void safeDispose() {
    super.safeDispose();
    _listener?.cancel();
    _listener = null;
    progressKey.dispose();
    form.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UnfocusableChild(
      child: PopScope(
        onPopInvokedWithResult: (didPop, result) {
          onBackButton();
        },
        canPop: chaintype == null || progressKey.isSuccess,
        child: StreamPageProgress(
          controller: progressKey,
          initialWidget: ProgressWithTextView(text: "retrieving_chains".tr),
          builder: (context) {
            return CustomScrollView(
              slivers: [
                APPSliverAnimatedSwitcher<_Page>(
                  enable: page,
                  widgets: {
                    _Page.selectChain: (context) => _SelectChainType(this),
                    _Page.search: (context) => _SelectNetwork(this),
                    _Page.review: (context) => SliverPageConstraintsBoxView(
                          sliver: CosmosImportNetworkFieldsView(
                              form: form, onImport: importChain),
                        ),
                  },
                )
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SelectChainType extends StatelessWidget {
  const _SelectChainType(this.state);
  final __CosmosImportNetworkViewState state;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Padding(
        padding: WidgetConstant.paddingHorizontal20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("chain_type".tr, style: context.textTheme.titleMedium),
            Text("select_cosmos_chain_type_desc".tr),
            WidgetConstant.height8,
            AppDropDownBottom<ChainType>(
                items: state.chainTypeWidgets,
                value: state.chaintype,
                hint: "chain_type".tr,
                onChanged: state.onChangeChainType)
          ],
        ),
      ),
    );
  }
}

class _SelectNetwork extends StatelessWidget {
  const _SelectNetwork(this.state);
  final __CosmosImportNetworkViewState state;

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      SliverPinnedHeaderSurface(
        elevation: APPConst.elevation,
        child: ConstraintsBoxView(
          padding: WidgetConstant.paddingHorizontal20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("network_name".tr, style: context.textTheme.titleMedium),
              Text("select_network_to_import_desc".tr),
              WidgetConstant.height8,
              AppTextField(
                label: "network_name".tr,
                onChanged: state.onSearchNetworkName,
                prefixIcon: Icon(Icons.search),
                initialValue: state.networkName,
              ),
            ],
          ),
        ),
      ),
      SliverConstraintsBoxView(
        padding: WidgetConstant.paddingHorizontal20,
        sliver: ConditionalWidget(
          enable: state.filtredChains.isNotEmpty,
          onDeactive: (context) {
            return SliverFillRemaining(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "chain_not_found_import_manually_desc".tr,
                    textAlign: TextAlign.center,
                  ),
                  WidgetConstant.height8,
                  FixedElevatedButton(
                      onPressed: state.setManuallyImport,
                      child: Text("import_manually".tr)),
                ],
              ),
            );
          },
          onActive: (context) => SliverList.separated(
            itemBuilder: (context, index) {
              final chain = state.filtredChains[index];
              return AppListTile(
                title: Text(chain.chainName),
                subtitle: Text(chain.chainId),
                onTap: () => state.onSelectChain(chain),
              );
            },
            separatorBuilder: (context, index) => WidgetConstant.divider,
            itemCount: state.filtredChains.length,
          ),
        ),
      ),
    ]);
  }
}

class CosmosImportNetworkFieldsView extends StatelessWidget {
  const CosmosImportNetworkFieldsView({super.key, required this.form, this.onImport});
  final CosmosAddNewChainFrom form;
  final DynamicVoid? onImport;

  @override
  Widget build(BuildContext context) {
    return MultiSliver(
      children: [
        SliverToBoxAdapter(
          child: Form(
            key: form.formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AlertTextContainer(
                    message: "import_network_experimental_feature_desc".tr),
                WidgetConstant.height20,
                Text("native_token".tr, style: context.textTheme.titleMedium),
                WidgetConstant.height8,
                FormField(
                  validator: (value) {
                    return form.nativeToken == null ? "network_token_required".tr : null;
                  },
                  builder: (f) => _CosmosTokenView(
                      validate: f.isValid,
                      validateError: f.errorText,
                      onTap: () {
                        form.onUpdateNativeToken(
                          (token) {
                            return context.openSliverBottomSheet(
                              token == null ? "setup_token".tr : "update_token".tr,
                              child: UpdateCosmosTokenView(token: token),
                            );
                          },
                        );
                      },
                      token: form.nativeToken),
                ),
                WidgetConstant.height20,
                Text("fee_tokens".tr, style: context.textTheme.titleMedium),
                Text("cosmos_fee_token_desc".tr),
                WidgetConstant.height8,
                ...List.generate(form.feeTokens.length, (i) {
                  final token = form.feeTokens[i];
                  return _CosmosTokenView(
                      enableTap: false,
                      isFeeToken: true,
                      onRemoveIcon:
                          Icon(Icons.remove_circle, color: context.onPrimaryContainer),
                      onTap: () {
                        form.onRemoveFeeToken(
                          token,
                          () => context.openSliverDialog<bool>(
                            widget: (context) => DialogTextView(
                              text: "remove_token_from_fee_token_list_desc".tr,
                              buttonWidget: const DialogDoubleButtonView(),
                            ),
                            label: "remove_token".tr,
                          ),
                        );
                      },
                      token: token);
                }),
                FormField(validator: (value) {
                  if (form.feeTokens.isNotEmpty) return null;
                  return "at_least_one_fee_token_required".tr;
                }, builder: (f) {
                  return _CosmosTokenView(
                      validate: f.isValid,
                      validateError: f.errorText,
                      onTap: () {
                        form.onAddNewToken((token) {
                          return context.openSliverBottomSheet(
                            "setup_token".tr,
                            child: UpdateCosmosTokenView(
                              token: token,
                              isFeeToken: true,
                            ),
                          );
                        }, () {
                          context.showAlert("token_already_exists".tr);
                        });
                      },
                      onNullTokenMessage: "tap_to_add_new_fee_token".tr);
                }),
                WidgetConstant.height20,
                Text("key_alg".tr, style: context.textTheme.titleMedium),
                Text("cosmos_key_alg_desc".tr),
                _ShowKeyAlgs(form),
                WidgetConstant.height20,
                Text("coin_type".tr, style: context.textTheme.titleMedium),
                LargeTextView(["slip_44_desc".tr, "coin_type_desc2".tr], maxLine: 1),
                WidgetConstant.height8,
                NumberTextField(
                    label: "coin_type".tr,
                    defaultValue: form.slip44,
                    onChangeValue: form.onChangeCoinType,
                    validator: form.validateCoinType,
                    max: Bip32KeyDataConst.keyIndexMaxVal,
                    min: 0),
                WidgetConstant.height20,
                //
                WidgetConstant.height20,
                Text("address_prefix_hrp".tr, style: context.textTheme.titleMedium),
                Text("cosmos_enter_hrp_desc".tr),
                WidgetConstant.height8,
                AppTextField(
                  initialValue: form.hrp,
                  onChanged: form.onChangeHrp,
                  validator: form.onValidateHrp,
                  label: "address_prefix_hrp".tr,
                  pasteIcon: true,
                ),
                WidgetConstant.height20,
                //
                Text("network_explorer_address_link".tr,
                    style: context.textTheme.titleMedium),
                LargeTextView(["network_evm_explorer_address_desc".tr], maxLine: 1),
                WidgetConstant.height8,
                AppTextField(
                  key: form.explorerFieldKey,
                  initialValue: form.explorerAddressLink,
                  onChanged: form.onChangeExplorerAddress,
                  validator: form.validateAddressLink,
                  label: "network_explorer_address_link".tr,
                  pasteIcon: true,
                ),
                WidgetConstant.height20,
                Text("network_explorer_transaction_link".tr,
                    style: context.textTheme.titleMedium),
                LargeTextView(["network_evm_explorer_transaction_desc".tr], maxLine: 1),
                WidgetConstant.height8,
                AppTextField(
                  key: form.transactionFieldKey,
                  initialValue: form.explorerTransaction,
                  onChanged: form.onChangeExplorerTransaction,
                  validator: form.validateAddressLink,
                  label: "network_explorer_transaction_link".tr,
                  pasteIcon: true,
                ),
                WidgetConstant.height20,
                Text("service_provider".tr, style: context.textTheme.titleMedium),
                WidgetConstant.height8,
                AppDropDownBottomWithBorder(
                    label: "service_provider".tr,
                    isExpanded: true,
                    items: {
                      for (final i in form.services)
                        i: Text(i.name, style: context.onPrimaryTextTheme.bodyMedium)
                    },
                    selectedItemBuilder: {for (final i in form.services) i: Text(i.name)},
                    labelStyle: context.onPrimaryTextTheme.labelLarge,
                    value: form.service,
                    onChanged: form.onChangeService),
                WidgetConstant.height20,
                Text("rpc_url".tr, style: context.textTheme.titleMedium),
                Text("enter_tendermint_rpc_desc".tr),
                WidgetConstant.height8,
                HTTPServiceProviderFields(
                  key: form.serviceProviderStateKey,
                  initialUrl: form.rpcUrl,
                  enableAuth: true,
                  protocols: [ServiceProtocol.http],
                ),
                ConditionalWidget(
                    enable: onImport != null,
                    onActive: (context) => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FixedElevatedButton(
                                padding: WidgetConstant.paddingVertical40,
                                activePress: form.supportedKeyAlg,
                                onPressed: onImport,
                                child: Text("import".tr))
                          ],
                        ))
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CosmosTokenView extends StatelessWidget {
  const _CosmosTokenView(
      {required this.onTap,
      this.onNullTokenMessage,
      this.token,
      this.validate = true,
      this.validateError,
      this.enableTap = true,
      this.onRemoveIcon,
      this.isFeeToken = false});
  final CosmosFeeToken? token;
  final DynamicVoid onTap;
  final String? onNullTokenMessage;
  final bool validate;
  final String? validateError;
  final bool enableTap;
  final Widget? onRemoveIcon;
  final bool isFeeToken;

  @override
  Widget build(BuildContext context) {
    return ContainerWithBorder(
      validate: validate,
      validateText: validateError,
      enableTap: enableTap,
      onRemoveIcon: onRemoveIcon ?? AddOrEditIconWidget(token != null),
      iconAlginment: token == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      onRemove: onTap,
      child: APPAnimatedSwitcher(
          width: context.mediaQuery.size.width,
          enable: token != null,
          widgets: {
            false: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(onNullTokenMessage ?? "tap_to_setup_native_token".tr,
                        style: context.onPrimaryTextTheme.bodyMedium),
                  ],
                ),
            true: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("token_info".tr, style: context.onPrimaryTextTheme.titleMedium),
                    WidgetConstant.height8,
                    ContainerWithBorder(
                      backgroundColor: context.onPrimaryContainer,
                      child: AccountTokenDetailsWidget(
                          token: token!.token,
                          color: context.primaryContainer,
                          radius: APPConst.circleRadius25),
                    ),
                    WidgetConstant.height20,
                    Text("decimals".tr, style: context.onPrimaryTextTheme.titleMedium),
                    WidgetConstant.height8,
                    ContainerWithBorder(
                        backgroundColor: context.onPrimaryContainer,
                        child: Text(token!.token.decimal.toString(),
                            style: context.primaryTextTheme.bodyMedium)),
                    if (isFeeToken) ...[
                      WidgetConstant.height20,
                      Text("avarage_gas_price".tr,
                          style: context.onPrimaryTextTheme.titleMedium),
                      WidgetConstant.height8,
                      ContainerWithBorder(
                          backgroundColor: context.onPrimaryContainer,
                          child: CoinAndMarketPriceView(
                            balance: token!.getAverageGasPrice(),
                            symbolColor: context.primaryContainer,
                            style: context.primaryTextTheme.titleMedium,
                          )),
                    ]
                  ],
                )
          }),
    );
  }
}

class _ShowKeyAlgs extends StatelessWidget {
  final CosmosAddNewChainFrom form;
  const _ShowKeyAlgs(this.form);

  @override
  Widget build(BuildContext context) {
    return ConditionalWidget(
        enable: form.unknowKeyAlg,
        onActive: (context) {
          return Column(
            children: [
              AlertTextContainer(message: "cosmos_key_alg_desc2".tr),
              WidgetConstant.height8,
              AppDropDownBottom(
                  items: form.keyAlgos,
                  value: form.keyAlg,
                  hint: "key_alg".tr,
                  onChanged: form.onChangeKeyAlgs,
                  validator: form.onValidateKeyAlgorithm),
            ],
          );
        },
        onDeactive: (context) {
          return Column(
            children: [
              if (!form.supportedKeyAlg)
                ErrorTextContainer(error: "unsupported_network_key_alg".tr),
              WidgetConstant.height8,
              ListView.builder(
                  itemBuilder: (context, index) {
                    final key = form.supportedAlgs[index];
                    return ContainerWithBorder(
                      enableTap: false,
                      onRemove: () {},
                      onRemoveWidget: TappedTooltipView(
                          tooltipWidget: ToolTipView(
                        message: key.supported
                            ? 'support_by_application'.tr
                            : 'unsupported_by_application'.tr,
                        child: ConditionalWidget(
                            enable: key.supported,
                            onDeactive: (context) =>
                                Icon(Icons.close, color: context.onPrimaryContainer),
                            onActive: (context) => Icon(Icons.check_circle,
                                color: context.onPrimaryContainer)),
                      )),
                      child: Text(key.alg, style: context.onPrimaryTextTheme.bodyMedium),
                    );
                  },
                  itemCount: form.supportedAlgs.length,
                  physics: WidgetConstant.noScrollPhysics,
                  shrinkWrap: true),
            ],
          );
        });
  }
}
