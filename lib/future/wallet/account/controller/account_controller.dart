import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

typedef PageChainBuilder<CL extends NetworkClient?, CHAINACCOUNT extends ChainAccount?,
        T extends APPCHAIN?>
    = Widget Function(WalletProvider wallet, T account, CL client, CHAINACCOUNT address);

typedef OnNetworkAccountChange<CHAINACCOUNT extends ChainAccount?> = void Function(
    CHAINACCOUNT? address);

class NetworkAccountControllerView<CL extends NetworkClient?,
    CHAINACCOUNT extends ChainAccount?, T extends APPCHAIN> extends StatefulWidget {
  const NetworkAccountControllerView({
    super.key,
    required this.childBulder,
    this.account,
    this.title,
    required this.addressRequired,
    this.address,
    this.clientRequired = true,
    // this.initAccount = false,
    this.multisigAccount = false,
    this.appBarOnError = true,
  });
  final PageChainBuilder<CL, CHAINACCOUNT, T> childBulder;
  final String? title;
  final bool addressRequired;
  final bool clientRequired;
  final T? account;
  final CHAINACCOUNT? address;
  final bool multisigAccount;
  final bool appBarOnError;

  @override
  State<NetworkAccountControllerView<CL, CHAINACCOUNT, T>> createState() =>
      _NetworkAccountControllerViewState<CL, CHAINACCOUNT, T>();
}

class _NetworkAccountControllerViewState<CL extends NetworkClient?,
        CHAINACCOUNT extends ChainAccount?, T extends APPCHAIN>
    extends State<NetworkAccountControllerView<CL, CHAINACCOUNT, T>>
    with SafeState<NetworkAccountControllerView<CL, CHAINACCOUNT, T>> {
  late WalletProvider wallet;
  T? account;
  CHAINACCOUNT? address;
  CL? client;

  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  void switchAccount(CHAINACCOUNT? updateAddress) async {
    final account = this.account;
    if (updateAddress == null ||
        account == null ||
        updateAddress == account.addressSync) {
      return;
    }
    progressKey.progressText("switch_account".tr);
    final result = await account.switchAccount(updateAddress);
    result.fold(
      onErr: (error) {
        progressKey.errorText(error.localizationError, backToIdle: false);
      },
      onOk: (value) {
        address = updateAddress;
        progressKey.backToIdle();
      },
    );
  }

  Future<void> _checkAccounts() async {
    try {
      progressKey.progressText("page_retrieval_requirment".tr);
      account = null;
      this.client = null;
      this.address = null;

      final accout = widget.account ?? wallet.wallet.currentChain;
      final address = widget.address ?? accout.addressSyncOrNull;
      if (widget.addressRequired && address == null) {
        progressKey.errorText("page_required_address".tr, backToIdle: false);
        return;
      }
      if (address != null && widget.multisigAccount && !address.multiSigAccount) {
        progressKey.errorText("page_required_multisig_address".tr, backToIdle: false);
        return;
      }
      NetworkClient? client;
      if (widget.clientRequired) {
        progressKey.progressText("node_connectiong_please_wait".tr);
        final c = await accout.client();
        if (c.isErr) {
          progressKey.errorText(c.unwrapErr().localizationError, backToIdle: false);
          return;
        }
        client = c.unwrap();
      }
      if (accout is! T ||
          widget.addressRequired && address is! CHAINACCOUNT ||
          widget.clientRequired && client is! CL) {
        progressKey.errorText("requested_chain_differs".tr, backToIdle: false);
        return;
      }
      await accout.initAsMainNetwork();
      account = accout;
      this.client = client as CL;
      this.address = address as CHAINACCOUNT;
      progressKey.backToIdle();
    } finally {
      updateState();
    }
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
            account?.network.token ?? context.wallet.wallet.currentChain.network.token,
            radius: APPConst.circleRadius12),
        WidgetConstant.width8,
      ],
    );
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    wallet = context.wallet;
    MethodUtils.executeAfterDelay(() => _checkAccounts());
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
            return widget.childBulder(
                wallet, account!.cast<T>(), client as CL, address as CHAINACCOUNT);
          }),
    );
  }
}

// sealed class NetworkAccountControllerActios{}
