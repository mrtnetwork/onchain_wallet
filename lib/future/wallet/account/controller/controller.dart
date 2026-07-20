import 'package:blockchain_utils/networks/types/address.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

import 'actions.dart';

class NetworkAccountActionView<
    NETWORKADDRESS extends IAddress,
    NETWORK extends WalletNetwork,
    CHAINACCOUNT extends ACCOUNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
    CL extends CLIENTNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
    CHAIN extends APPCHAINADDRESSNETWORKACCOUNTCLIENT<NETWORKADDRESS, NETWORK,
        CHAINACCOUNT, CL>,
    RESPONSE extends NetworkViewActionResponse<NETWORKADDRESS, NETWORK, CHAINACCOUNT, CL,
        CHAIN>> extends StatefulWidget {
  const NetworkAccountActionView({
    super.key,
    required this.childBulder,
    required this.action,
    // this.account,
    this.title,
    // required this.addressRequired,
    // this.address,
    // this.clientRequired = true,
    // this.initAccount = false,
    // this.multisigAccount = false,
    this.appBarOnError = true,
  });
  final Widget Function(RESPONSE) childBulder;
  final String? title;
  final NetworkViewAction<NETWORKADDRESS, NETWORK, CHAINACCOUNT, CL, CHAIN, RESPONSE>
      action;
  // final bool addressRequired;
  // final bool clientRequired;
  // final T? account;
  // final CHAINACCOUNT? address;
  // final bool initAccount;
  // final bool multisigAccount;
  final bool appBarOnError;

  @override
  State<
      NetworkAccountActionView<NETWORKADDRESS, NETWORK, CHAINACCOUNT, CL, CHAIN,
          RESPONSE>> createState() => _NetworkAccountControllerViewState<NETWORKADDRESS,
      NETWORK, CHAINACCOUNT, CL, CHAIN, RESPONSE>();
}

class _NetworkAccountControllerViewState<
        NETWORKADDRESS extends IAddress,
        NETWORK extends WalletNetwork,
        CHAINACCOUNT extends ACCOUNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
        CL extends CLIENTNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
        CHAIN extends APPCHAINADDRESSNETWORKACCOUNTCLIENT<NETWORKADDRESS, NETWORK,
            CHAINACCOUNT, CL>,
        RESPONSE extends NetworkViewActionResponse<NETWORKADDRESS, NETWORK, CHAINACCOUNT,
            CL, CHAIN>>
    extends State<
        NetworkAccountActionView<NETWORKADDRESS, NETWORK, CHAINACCOUNT, CL, CHAIN,
            RESPONSE>>
    with
        SafeState<
            NetworkAccountActionView<NETWORKADDRESS, NETWORK, CHAINACCOUNT, CL, CHAIN,
                RESPONSE>> {
  late WalletProvider wallet;
  RESPONSE? response;

  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  Future<void> _checkAccounts() async {
    progressKey.progressText("page_retrieval_requirment".tr);
    final response = await widget.action.getResponse(wallet);
    response.watch(
      onErr: (error) => progressKey.errorText(error.localizationError, backToIdle: false),
      onOk: (response) {
        this.response = response;
        progressKey.backToIdle();
      },
    );
    updateState();
  }

  PreferredSizeWidget? appBar() {
    final title = widget.title;
    if (title == null) {
      if (progressKey.hasError && widget.appBarOnError) {
        return AppBar();
      }
      return null;
    }

    return AppBar(
      title: Text(title),
      actions: [
        CircleTokenImageView(
            response?.chain.network.token ??
                context.wallet.wallet.currentChain.network.token,
            radius: APPConst.circleRadius12),
        WidgetConstant.width8,
      ],
    );
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    wallet = context.wallet;
    _checkAccounts();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    progressKey.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      body: StreamPageProgress(
          initialWidget: ProgressWithTextView(text: "page_retrieval_requirment".tr),
          controller: progressKey,
          builder: (c) {
            return ConditionalWidgetWithValue(
              onValue: (context, response) => widget.childBulder(response),
              value: response,
            );
          }),
    );
  }
}

// sealed class NetworkAccountControllerActios{}
