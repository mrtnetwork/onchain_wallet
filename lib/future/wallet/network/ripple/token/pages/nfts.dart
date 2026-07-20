import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/account/controller/account_controller.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/widgets/nft_info.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class MonitorRippleNFTsView extends StatelessWidget {
  const MonitorRippleNFTsView({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<XRPNetworkClient, IXRPAddress, XRPChain>(
      title: "manage_nfts".tr,
      addressRequired: true,
      clientRequired: true,
      childBulder: (wallet, account, client, address) {
        return _MonitorRippleNFTsView(account: account, wallet: wallet, provider: client);
      },
    );
  }
}

class _MonitorRippleNFTsView extends StatefulWidget {
  const _MonitorRippleNFTsView(
      {required this.account, required this.wallet, required this.provider});
  final XRPChain account;
  final WalletProvider wallet;
  final XRPNetworkClient provider;

  @override
  State<_MonitorRippleNFTsView> createState() => ___MonitorRippleNFTsViewState();
}

class ___MonitorRippleNFTsViewState extends State<_MonitorRippleNFTsView>
    with SafeState<_MonitorRippleNFTsView> {
  IXRPAddress get address => widget.account.addressSync;
  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  final Set<RippleNFToken> nfts = {};
  final ScrollController controller = ScrollController();
  Future<void> fetchingTokens() async {
    final result = await IResult.call(() async {
      return await widget.provider.getAccountNtfs(
        address: address.networkAddress,
      );
    });
    if (result.isErr) {
      progressKey.errorText(result.unwrapErr().localizationError, backToIdle: false);
    } else {
      final rippleNfts = result.unwrap().map((e) => RippleNFToken(
          flags: e.flags,
          nftokenId: e.nftokenId,
          issuer: e.issuer,
          nftokenTaxon: e.nftokenTaxon,
          serial: e.serial,
          uri: e.uri == null ? null : QuickBytesUtils.tryAsUtf8String(e.uri!)));
      nfts.addAll(rippleNfts);
      progressKey.backToIdle();
    }
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    fetchingTokens();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    progressKey.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamPageProgress(
      controller: progressKey,
      initialWidget: ProgressWithTextView(text: "fetching_account_token_please_wait".tr),
      builder: (c) {
        return EmptyItemWidgetView(
          isEmpty: nfts.isEmpty,
          itemBuilder: () => ConstraintsBoxView(
            padding: WidgetConstant.padding20,
            child: ListView.separated(
              controller: controller,
              itemBuilder: (context, index) {
                final nft = nfts.elementAt(index);
                return RippleNFTokenView(
                    nft: nft, address: address, account: widget.account);
              },
              separatorBuilder: (context, index) => WidgetConstant.divider,
              shrinkWrap: true,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: false,
              itemCount: nfts.length,
            ),
          ),
        );
      },
    );
  }
}
