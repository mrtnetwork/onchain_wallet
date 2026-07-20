import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class UpdateNetworkView extends StatelessWidget {
  const UpdateNetworkView({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessWalletView<WalletCredentialResponseLogin, WalletCredentialLogin>(
        request: WalletCredentialLogin.instance,
        title: "update_network".tr,
        onAccsess: (_) => _UpdateNetworkView());
  }
}

class _UpdateNetworkView extends StatefulWidget {
  const _UpdateNetworkView();
  // final WalletNetwork network;
  @override
  State<_UpdateNetworkView> createState() => _UpdateNetworkViewState();
}

class _UpdateNetworkViewState extends State<_UpdateNetworkView>
    with SafeState<_UpdateNetworkView> {
  late final WalletNetwork network;
  String symbol = '';
  String networkName = '';
  String explorerAddressLink = "";
  String explorerTransaction = "";
  final StreamPageProgressController progressKey = StreamPageProgressController();
  // final GlobalKey<PageProgressState> pageProgressKey = GlobalKey();
  void onChangeSymbol(String v) {
    symbol = v;
  }

  void onChangeNetworkName(String v) {
    networkName = v;
  }

  void onChangeExplorerAddress(String v) {
    explorerAddressLink = v;
  }

  void onChangeExplorerTransaction(String v) {
    explorerTransaction = v;
  }

  String? validateAddressLink(String? v) {
    if (v?.trim().isEmpty ?? true) return null;
    final link = StrUtils.validateUri(v);
    if (link == null) return "validate_link_desc".tr;
    return null;
  }

  String? validateNetworkName(String? v) {
    if ((v?.isEmpty ?? true) || v!.length < 2 || v.length > 25) {
      return "network_name_validator".tr;
    }
    return null;
  }

  String? validateSymbol(String? v) {
    if ((v?.isEmpty ?? true) || v!.isEmpty || v.length > 6) {
      return "symbol_validator".tr;
    }
    return null;
  }

  Future<void> updateNetwork() async {
    final wallet = context.wallet;
    progressKey.progressText("updating_network".tr);
    final updateNetwork = network.copyWith(
        coinParam: network.coinParam.updateParams(
            token: Token(
                name: networkName,
                symbol: symbol,
                decimal: network.coinParam.token.decimal,
                assetLogo: network.coinParam.logo,
                market: network.coinParam.token.market),
            addressExplorer: explorerAddressLink.nullOnEmpty,
            transactionExplorer: explorerTransaction.nullOnEmpty));
    final update = await IResult.call(() async =>
        wallet.wallet.doAction(WalletActionUpdateNetwork(network: updateNetwork)));
    if (update.isErr) {
      progressKey.errorText(update.unwrapErr().localizationError,
          backToIdle: false, showBackButton: true);
    } else {
      progressKey.successText("network_imported_to_your_wallet".tr, backToIdle: false);
    }
  }

  void _init() {
    network = context.wallet.wallet.network;
    networkName = network.token.name;
    symbol = network.token.symbol;
    explorerAddressLink = network.coinParam.addressExplorer ?? '';
    explorerTransaction = network.coinParam.transactionExplorer ?? '';
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    _init();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    progressKey.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UnfocusableChild(
      child: StreamPageProgress(
        controller: progressKey,
        // initialStatus: StreamWidgetStatus.progress,
        builder: (context) => CustomScrollView(
          slivers: [
            SliverConstraintsBoxView(
              padding: WidgetConstant.paddingHorizontal20,
              sliver: SliverToBoxAdapter(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("network_name".tr, style: context.textTheme.titleMedium),
                  Text("network_name_desc".tr),
                  WidgetConstant.height8,
                  AppTextField(
                    initialValue: networkName,
                    onChanged: onChangeNetworkName,
                    validator: validateNetworkName,
                    label: "network_name".tr,
                  ),
                  WidgetConstant.height20,
                  Text("symbol".tr, style: context.textTheme.titleMedium),
                  Text("symbol_desc".tr),
                  WidgetConstant.height8,
                  AppTextField(
                      initialValue: symbol,
                      onChanged: onChangeSymbol,
                      validator: validateSymbol,
                      label: "symbol".tr),
                  WidgetConstant.height20,
                  Text("network_explorer_address_link".tr,
                      style: context.textTheme.titleMedium),
                  LargeTextView(["network_evm_explorer_address_desc".tr], maxLine: 1),
                  WidgetConstant.height8,
                  AppTextField(
                    initialValue: explorerAddressLink,
                    onChanged: onChangeExplorerAddress,
                    validator: validateAddressLink,
                    label: "network_explorer_address_link".tr,
                    pasteIcon: true,
                  ),
                  WidgetConstant.height20,
                  Text("network_explorer_transaction_link".tr,
                      style: context.textTheme.titleMedium),
                  LargeTextView(["network_evm_explorer_transaction_desc".tr], maxLine: 1),
                  WidgetConstant.height8,
                  AppTextField(
                    initialValue: explorerAddressLink,
                    onChanged: onChangeExplorerTransaction,
                    validator: validateAddressLink,
                    label: "network_explorer_transaction_link".tr,
                    pasteIcon: true,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FixedElevatedButton(
                          padding: WidgetConstant.paddingVertical40,
                          onPressed: updateNetwork,
                          child: Text("update_network".tr))
                    ],
                  )
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
