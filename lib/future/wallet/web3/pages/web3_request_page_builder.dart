import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/address_details.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/ton/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/appbar_action.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/client_info.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/widgets/parogress.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/access/wallet_access.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';

class Web3StatePageBuilder extends StatefulWidget {
  const Web3StatePageBuilder({super.key, this.width = APPConst.maxViewWidth});
  final double? width;

  @override
  State<Web3StatePageBuilder> createState() => _Web3StatePageBuilderState();
}

class _Web3StatePageBuilderState extends State<Web3StatePageBuilder>
    with SafeState<Web3StatePageBuilder> {
  late BaseWeb3StateController controller;
  late Web3NetworkRequest request;

  void init() {
    request = context.getArgruments();
    controller = switch (request) {
      BaseWeb3BitcoinRequest request => Web3BitcoinStateController.findController(
          request: request, walletProvider: context.wallet),
      Web3AptosRequest request => Web3AptosStateController.findController(
          request: request, walletProvider: context.wallet),
      Web3CosmosRequest request => Web3CosmosStateController.findController(
          request: request, walletProvider: context.wallet),
      Web3EthereumRequest request => Web3EthereumStateController.findController(
          request: request, walletProvider: context.wallet),
      Web3SolanaRequest request => Web3SolanaStateController.findController(
          request: request, walletProvider: context.wallet),
      Web3StellarRequest request => Web3StellarStateController.findController(
          request: request, walletProvider: context.wallet),
      Web3SubstrateRequest request => Web3SubstrateStateController.findController(
          request: request, walletProvider: context.wallet),
      Web3SuiRequest request => Web3SuiStateController.findController(
          request: request, walletProvider: context.wallet),
      Web3TonRequest request => Web3TonStateController.findController(
          request: request, walletProvider: context.wallet),
      Web3TronRequest request => Web3TronStateController.findController(
          request: request, walletProvider: context.wallet),
      Web3XRPRequest request => Web3XRPStateController.findController(
          request: request, walletProvider: context.wallet),
      Web3MoneroRequest request => Web3MoneroStateController.findController(
          request: request, walletProvider: context.wallet),
      Web3ADARequest request => Web3CardanoStateController.findController(
          request: request, walletProvider: context.wallet),
      Web3ZcashRequest request => Web3ZcashStateController.findController(
          request: request, walletProvider: context.wallet),
      _ => throw AppInternalError.internalError("_Web3StatePageBuilderState",
          reason: "Unexpected request.")
    };
    controller.init();
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    init();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        request.onPopRequestPage();
      },
      child: AccessWalletView<WalletCredentialResponseLogin, WalletCredentialLogin>(
        request: WalletCredentialLogin.instance,
        appbar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(request.params.method.name.tr),
              Text(request.params.method.name, style: context.textTheme.bodySmall)
            ],
          ),
          actions: [
            Web3PermissionAppbarActionView(request: request),
            WidgetConstant.width8,
          ],
        ),
        subtitle:
            Web3ApplicationView(permission: request.authenticated, info: request.info),
        onAccsess: (_) {
          final bool hasAccount = controller.accounts.isNotEmpty;
          return StreamWeb3PageProgress(
              controller: controller.pageKey,
              initialWidget: PageProgressChildWidget(
                  ProgressWithTextView(text: "web3_retrieval_requirment".tr)),
              builder: (context) => CustomScrollView(slivers: [
                    SliverConstraintsBoxView(
                        maxWidth: widget.width,
                        padding: WidgetConstant.paddingHorizontal20,
                        sliver: MultiSliver(children: [
                          WidgetConstant.sliverPaddingVertial20,
                          ConditionalWidget(
                            enable: controller.showRequestAccount && hasAccount,
                            onActive: (context) => SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("account".tr,
                                      style: context.textTheme.titleMedium),
                                  Text("web3_request_account_desc".tr),
                                  WidgetConstant.height8,
                                  ContainerWithBorder(
                                      child: AddressDetailsView(
                                          address: controller.accounts.first,
                                          color: context.onPrimaryContainer)),
                                  WidgetConstant.height20
                                ],
                              ),
                            ),
                          ),
                          controller.onPageBuilder(context)
                        ])),
                  ]));
        },
      ),
    );
  }
}

typedef ONACCEPTREQUEST = void Function({BuildContext? context});

class Web3StateAcceptRequestView extends StatelessWidget {
  final BaseWeb3StateController controller;
  final String title;
  final ONACCEPTREQUEST? onAcceptRequest;
  final GlobalKey? buttonKey;
  const Web3StateAcceptRequestView(
      {super.key,
      required this.controller,
      required this.title,
      this.buttonKey,
      this.onAcceptRequest});

  @override
  Widget build(BuildContext context) {
    return APPStreamBuilder(
        value: controller.stateStatus,
        builder: (context, value) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ErrorTextContainer(error: value.error),
            AlertTextContainer(message: value.warning),
            Padding(
              padding: WidgetConstant.paddingVertical40,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                FixedElevatedButton(
                    key: buttonKey,
                    onPressed: () {
                      final callBack = onAcceptRequest;
                      if (callBack == null) {
                        controller.acceptRequest(context: context);
                        return;
                      }
                      callBack(context: context);
                    },
                    activePress: value.isReady,
                    child: Text(title.tr))
              ]),
            )
          ]);
        });
  }
}

class Web3StateSignMessageView extends StatelessWidget {
  const Web3StateSignMessageView(
      {required this.controller,
      required this.message,
      required this.content,
      this.prefix,
      this.isPersonalSign = false,
      super.key});
  final BaseWeb3StateController controller;
  final String message;
  final String? content;
  final String? prefix;
  final bool isPersonalSign;
  @override
  Widget build(BuildContext context) {
    return MultiSliver(
      children: [
        ConditionalWidget(
            enable: !isPersonalSign,
            onActive: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ErrorTextContainer(
                        error: "sign_message_private_key_desc".tr, enableTap: false),
                    WidgetConstant.height20,
                  ],
                )),
        Text("message".tr, style: context.textTheme.titleMedium),
        Text("sign_message_private_key".tr),
        WidgetConstant.height8,
        ContainerWithBorder(
            onRemove: () {},
            onRemoveWidget: CopyTextIcon(dataToCopy: message, isSensitive: false),
            enableTap: false,
            child: Text(message, style: context.onPrimaryTextTheme.bodyMedium)),
        ConditionalWidgetWithValue(
            value: content,
            onValue: (context, content) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WidgetConstant.height20,
                    Text("content".tr, style: context.textTheme.titleMedium),
                    ContainerWithBorder(
                        onRemove: () {},
                        onRemoveWidget:
                            CopyTextIcon(dataToCopy: content, isSensitive: false),
                        enableTap: false,
                        child: SelectableText(content,
                            style: context.onPrimaryTextTheme.bodyMedium,
                            minLines: 1,
                            maxLines: 5)),
                  ],
                )),
        ConditionalWidgetWithValue(
            value: prefix,
            onValue: (context, prefix) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WidgetConstant.height20,
                    Text("prefix".tr, style: context.textTheme.titleMedium),
                    ContainerWithBorder(
                        onRemove: () {},
                        onRemoveWidget:
                            CopyTextIcon(dataToCopy: prefix, isSensitive: false),
                        enableTap: false,
                        child: SelectableText(prefix,
                            style: context.onPrimaryTextTheme.bodyMedium,
                            minLines: 1,
                            maxLines: 5)),
                  ],
                )),
        Web3StateAcceptRequestView(controller: controller, title: "sign_message".tr),
      ],
    );
  }
}
