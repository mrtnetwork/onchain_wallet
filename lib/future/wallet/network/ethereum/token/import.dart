import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/account/controller/account_controller.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain/on_chain.dart';

class ImportERC20TokenView extends StatelessWidget {
  const ImportERC20TokenView({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<EthereumNetworkClient, IEthereumAddress,
            EthereumChain>(
        addressRequired: true,
        clientRequired: true,
        childBulder: (wallet, account, client, address) {
          return _ImportErc20TokenView(account: account, apiProvider: client);
        },
        title: "import_token".tr);
  }
}

class _ImportErc20TokenView extends StatefulWidget {
  const _ImportErc20TokenView({required this.account, required this.apiProvider});
  final EthereumChain account;
  final EthereumNetworkClient apiProvider;

  @override
  State<_ImportErc20TokenView> createState() => __ImportErc20TokenViewState();
}

class __ImportErc20TokenViewState extends State<_ImportErc20TokenView>
    with SafeState<_ImportErc20TokenView>, ProgressMixin<_ImportErc20TokenView> {
  late final address = widget.account.addressSync;
  ReceiptAddress<ETHAddress>? contractAddress;

  bool get hasContractAddress => contractAddress != null;

  void onSetupAddress(ReceiptAddress<ETHAddress>? addr) {
    contractAddress = addr;
    setState(() {});
  }

  ETHERC20Token? token;
  Future<void> onAddToAccount() async {
    if (!hasContractAddress) return;
    progressKey.progressText("retrieving_contract_detauls".tr);
    final result = await IResult.call(() async {
      final data = await widget.apiProvider
          .getAccountERC20Token(address.networkAddress, contractAddress!.networkAddress);
      return data;
    });
    if (result.isErr) {
      progressKey.errorText(result.unwrapErr().localizationError);
    } else if (result.ok() == null) {
      progressKey.errorText("smart_contract_not_found".tr,
          backToIdle: false, showBackButton: true);
    } else {
      final addResult = await widget.account
          .addNewToken(address: address, token: result.unwrap()! as ETHERC20Token);
      addResult.watch(
        onErr: (error) => progressKey.errorText(error.localizationError,
            backToIdle: false, showBackButton: true),
        onOk: (value) {
          token = value;
          progressKey.success();
        },
      );
    }
  }

  void onNewToken() {
    contractAddress = null;
    token = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamPageProgress(
      controller: progressKey,
      builder: (c) => ConstraintsBoxView(
          padding: WidgetConstant.padding20,
          alignment: Alignment.center,
          child: token != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleTokenImageView(token!.token, radius: 60),
                    WidgetConstant.height8,
                    Text(token!.token.name, style: context.textTheme.labelLarge),
                    if (token!.issuer != null) OneLineTextWidget(token!.issuer!),
                    WidgetConstant.height8,
                    CoinAndMarketLivePriceView(
                        liveBalance: token!.streamBalance,
                        style: context.textTheme.titleLarge),
                    WidgetConstant.height20,
                    FilledButton(
                        onPressed: onNewToken, child: Text("import_new_token".tr))
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PageTitleSubtitle(
                          title: "import_erc20_token".tr,
                          body: Text("import_erc20_desc".tr)),
                      ReceiptAddressView(
                        address: contractAddress,
                        subtitle: "import_erc20_desc".tr,
                        title: "contract_address".tr,
                        onTap: () {
                          context
                              .selectAccount<ETHAddress>(
                                  account: widget.account, title: "contract_address".tr)
                              .then((e) => onSetupAddress(e?.firstOrNull));
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FixedElevatedButton(
                            padding: WidgetConstant.paddingVertical40,
                            onPressed: hasContractAddress ? onAddToAccount : null,
                            child: Text("add_to_my_account".tr),
                          )
                        ],
                      )
                    ],
                  ),
                )),
    );
  }
}
