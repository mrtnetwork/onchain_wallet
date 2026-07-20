import 'dart:async';

import 'package:blockchain_utils/networks/types/address.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/tokens/tokens.dart';
import 'package:on_chain_wallet/wallet/api/client/core/client.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/nfts/core/core.dart';
import 'package:on_chain_wallet/wallet/models/token/network/token.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/core/core.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';

class ManageAccountTokenView extends StatefulWidget {
  const ManageAccountTokenView({super.key});

  @override
  State<ManageAccountTokenView> createState() => _ManageAccountTokenViewState();
}

class _ManageAccountTokenViewState extends State<ManageAccountTokenView> {
  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<NetworkClient, ChainAccount, Chain>(
        childBulder: (wallet, account, client, address) {
          switch (account.network.type) {
            case NetworkType.substrate:
              return ManageSubstrateAccountToken(
                  account: account.cast(),
                  address: address.cast(),
                  client: client.cast());
            default:
              return _ManageAccountToken(
                  account: account, client: client, address: address);
          }
        },
        addressRequired: true,
        clientRequired: true);
  }
}

class _ManageAccountToken extends StatefulWidget {
  final NetworkClient client;
  final Chain account;
  final ChainAccount address;
  const _ManageAccountToken(
      {required this.client, required this.account, required this.address});

  @override
  State<_ManageAccountToken> createState() => __ManageAccountTokenState();
}

class __ManageAccountTokenState extends State<_ManageAccountToken>
    with
        SafeState<_ManageAccountToken>,
        ManageAccountTokenState<
            _ManageAccountToken,
            NetworkClient,
            TokenCore,
            ChainAccount<IAddress, TokenCore, NFTCore, ChainTransaction, WalletNetwork>,
            Chain> {
  @override
  Chain get account => widget.account;

  @override
  NetworkClient get client => widget.client;
}

mixin ManageAccountTokenState<
    W extends StatefulWidget,
    CL extends NetworkClient,
    TOKEN extends TokenCore,
    ACCOUNT extends ChainAccount<IAddress, TOKEN, NFTCore, ChainTransaction,
        WalletNetwork>,
    CHAIN extends APPCHAINTOKENCLIENTACCOUNT<TOKEN, CL, ACCOUNT>> on SafeState<W> {
  List<TOKEN> addressTokens = [];
  CHAIN get account;
  CL get client;
  late WalletProvider wallet;
  StreamSubscription<List<BaseNetworkToken>>? listener;
  StreamSubscription? accountListener;
  ACCOUNT get address => account.addressSync;
  List<ShimmerAction<BaseNetworkToken>> tokens = [];
  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);

  void onNewToken(List<BaseNetworkToken> token) {
    tokens.addAll(token.map((e) => ShimmerAction(object: e)));
    updateState();
    if (progressKey.inProgress) progressKey.backToIdle();
  }

  void onError(Object e) {
    final error = ResultErr.from(e).localizationError;
    if (progressKey.inProgress) {
      progressKey.errorText(error, backToIdle: false);
    }
  }

  void onDone() {
    if (progressKey.inProgress) progressKey.backToIdle();
  }

  Future<IResult<void>> addOrRemoveToken(BaseNetworkToken token) async {
    if (addressTokens.contains(token.token)) {
      return await account.removeToken(
          token: token.token.clone() as TOKEN, address: address);
    }
    if (token.status.isFailed) {
      Token? updated;
      await context.openSliverBottomSheet<bool>("update_token".tr,
          bodyBuilder: (scrollController) => UpdateTokenDetailsView(
              token: token.token.token,
              account: account,
              title: PageTitleSubtitle(
                  title: "update_token_information".tr,
                  body: AlertTextContainer(
                      message: "update_unknown_token_metadata_desc".tr,
                      enableTap: false)),
              address: account.addressSync,
              onUpdateToken: (context, updatedToken) {
                context.pop();
                updated = updatedToken;
              },
              scrollController: scrollController),
          centerContent: false);
      if (updated != null) {
        token.updaetTokenMetadata(updated!);
      }
    }
    final result =
        await account.addNewToken(token: token.token as TOKEN, address: address);
    return result;
  }

  Future<void> onTap(ShimmerAction<BaseNetworkToken> token) async {
    try {
      token.setAction(true);
      updateState();
      final update = await addOrRemoveToken(token.object);
      update.mapErr((e) {
        context.showAlert(e.localizationError);
        return e.exception;
      });
    } finally {
      token.setAction(false);
      updateState();
    }
  }

  void onAccountEvent(ChainEvent event) {
    addressTokens = address.tokenSync;
    updateState();
  }

  void init() {
    address.getAccountTokens().then((result) {
      result.watch(
        onErr: (error) {
          if (closed) return;
          context.showAlert(error.localizationError);
        },
        onOk: (tokens) {
          if (closed) return;
          addressTokens = tokens;
          updateState();
        },
      );
    });
    listener = client
        .getAccountTokensStream(address.networkAddress)
        .listen(onNewToken, onError: onError, onDone: onDone, cancelOnError: true);
    accountListener = account.filterStream([DefaultChainNotify.token],
        status: ChainNotifyStatus.complete).listen(onAccountEvent);
    wallet = context.wallet;
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
    listener?.cancel();
    listener = null;
    accountListener?.cancel();
    accountListener = null;
    for (final i in tokens) {
      i.object.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("manage_tokens".tr)),
      body: StreamPageProgress(
        controller: progressKey,
        initialWidget:
            ProgressWithTextView(text: 'fetching_account_token_please_wait'.tr),
        builder: (context) => ChainStreamBuilder(
          account: account,
          allowNotify: [DefaultChainNotify.token],
          builder: (context, _) => CustomScrollView(
            slivers: [
              EmptyItemSliverWidgetView(
                isEmpty: tokens.isEmpty,
                itemBuilder: (context) => SliverConstraintsBoxView(
                  padding: WidgetConstant.paddingHorizontal20,
                  sliver: SliverList.separated(
                      separatorBuilder: (context, index) => WidgetConstant.divider,
                      itemBuilder: (context, index) {
                        final token = tokens.elementAt(index);
                        final bool exist = addressTokens.contains(token.object.token);
                        return APPStreamBuilder(
                          value: token.object.notifier,
                          builder: (context, value) => Shimmer(
                              onActive: (enable, context) => AccountTokenDetailsView(
                                  error: token.object.status.isFailed
                                      ? "update_unknown_token_metadata_desc".tr
                                      : null,
                                  onTapError: () {},
                                  onSelect: () {
                                    context
                                        .openSliverDialog<bool>(
                                            widget: (ctx) => DialogTextView(
                                                buttonWidget: DialogDoubleButtonView(),
                                                text: exist
                                                    ? "remove_token_from_account".tr
                                                    : "add_token_to_your_account".tr),
                                            label: exist
                                                ? "remove_token".tr
                                                : "add_token".tr)
                                        .then((v) {
                                      if (v == null) return;
                                      onTap(token);
                                    });
                                  },
                                  onSelectIcon: APPCheckBox(
                                      value: exist,
                                      ignoring: true,
                                      onChanged: (value) {}),
                                  token: token.object.token),
                              enable: (!token.action && !token.object.status.isPending)),
                        );
                      },
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: false,
                      itemCount: tokens.length),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
