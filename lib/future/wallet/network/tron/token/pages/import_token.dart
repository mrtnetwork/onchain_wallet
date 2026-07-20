import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/account/controller/account_controller.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/account/state.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain/tron/src/address/tron_address.dart';

class MonitorTronTokenView extends StatelessWidget {
  const MonitorTronTokenView({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<TronClient, ITronAddress, TronChain>(
      title: "import_token".tr,
      addressRequired: true,
      clientRequired: true,
      childBulder: (wallet, account, client, address) {
        return _MonitorTronTokenView(account: account, wallet: wallet, client: client);
      },
    );
  }
}

class _MonitorTronTokenView extends StatefulWidget {
  const _MonitorTronTokenView(
      {required this.account, required this.wallet, required this.client});
  final TronChain account;
  final WalletProvider wallet;
  final TronClient client;

  @override
  State<_MonitorTronTokenView> createState() => _MonitorTronTokenViewState();
}

class _MonitorTronTokenViewState extends TronAccountState<_MonitorTronTokenView> {
  @override
  TronChain get account => widget.account;
  @override
  TronClient get client => widget.client;
  List<TronToken> accountTokens = [];
  final StreamPageProgressController pageStreamController =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  final StreamPageProgressController trc10ProgressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  final StreamPageProgressController trc20ProgressKey = StreamPageProgressController();
  final Set<TronTRC10Token> tokens = {};

  bool get hasContractAddress => contractAddress != null;
  ReceiptAddress<TronAddress>? contractAddress;
  void onSetupAddress(ReceiptAddress<TronAddress>? addr) {
    contractAddress = addr;
    updateState(() {});
  }

  TronTRC20Token? token;
  void onNewToken() {
    contractAddress = null;
    token = null;
    updateState(() {});
  }

  Future<void> onAddTrc20Token() async {
    if (!hasContractAddress) return;
    final exists = accountTokens.any((e) => e.issuer == contractAddress!.view);
    if (exists) {
      context.showAlert("token_already_exists".tr);
      return;
    }
    trc20ProgressKey.progressText("retrieving_contract_detauls".tr);
    final result = await IResult.call(() async {
      final data = await client.ethClient
          .getAccountERC20Token(address.networkAddress, contractAddress!.networkAddress);
      return data;
    });
    if (result.isErr) {
      trc20ProgressKey.errorText(result.unwrapErr().localizationError,
          backToIdle: false, showBackButton: true);
    } else if (result.ok() == null) {
      trc20ProgressKey.errorText("smart_contract_not_found".tr,
          backToIdle: false, showBackButton: true);
    } else {
      final addResult = await widget.account
          .addNewToken(token: result.unwrap()! as TronToken, address: address);
      addResult.watch(
        onErr: (err) => trc20ProgressKey.errorText(err.localizationError),
        onOk: (value) {
          token = value as TronTRC20Token;
          trc20ProgressKey.success();
        },
      );
    }
  }

  Future<void> fetchingTokens() async {
    final result = await IResult.call(() async {
      TronAccountInfo? tronAccount = (await address.getAccountInfo_()).unwrap();
      if (tronAccount == null) {
        await account.updateAddressBalance(address);
      }
      tronAccount = (await address.getAccountInfo_()).unwrap();
      if (tronAccount == null) {
        return null;
      }
      if (tronAccount.assetV2.isEmpty) {
        return <TronTRC10Token>[];
      }
      final issueList = await client.getIssueAssetList();
      final List<TronTRC10Token> accountTokens = [];
      for (final i in tronAccount.assetV2) {
        final token = issueList.firstWhere((element) => element.id == i.key);
        accountTokens.add(TronTRC10Token.create(
            balance: i.value,
            token: Token(
                name: token.name,
                symbol: token.abbr ?? token.name,
                decimal: token.precision ?? 0),
            tokenID: i.key));
      }
      return accountTokens;
    });
    if (result.isErr) {
      trc10ProgressKey.errorText(result.unwrapErr().localizationError, backToIdle: false);
    } else {
      if (result.ok() == null) {
        trc10ProgressKey.errorText("account_not_found".tr, backToIdle: false);
      } else {
        tokens.addAll(result.unwrap()!);
        trc10ProgressKey.success();
      }
    }
  }

  Future<TronToken> add(TronTRC10Token token) async {
    final result = await widget.account.addNewToken(
        token: TronTRC10Token.create(
          balance: token.balance.balance,
          token: token.token,
          tokenID: token.tokenID,
        ),
        address: address);
    return result.unwrap();
  }

  Future<void> removeToken(TronToken token) async {
    final remove = await widget.account.removeToken(token: token, address: address);
    return remove.unwrap();
  }

  Future<void> onTap(TronTRC10Token token, bool exist) async {
    try {
      if (exist) {
        await removeToken(token);
      } else {
        await add(token);
      }
    } finally {
      setState(() {});
    }
  }

  Future<void> init() async {
    final tokens = await address.getAccountTokens();
    tokens.watch(
      onErr: (error) =>
          pageStreamController.errorText(error.localizationError, backToIdle: false),
      onOk: (tokens) {
        accountTokens = tokens;
        pageStreamController.backToIdle();
      },
    );
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    init();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    trc10ProgressKey.dispose();
    trc20ProgressKey.dispose();
    pageStreamController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamPageProgress(
        controller: pageStreamController,
        initialWidget:
            ProgressWithTextView(text: "fetching_account_token_please_wait".tr),
        builder: (context) {
          return DefaultTabController(
            length: TronTokenTypes.values.length,
            child: Column(
              children: [
                TabBar(
                    tabs: TronTokenTypes.values
                        .map((e) => Tab(
                              text: e.name.tr,
                            ))
                        .toList()),
                Expanded(
                    child: TabBarView(
                        children: [_TRC20TokenView(this), _TRC10TokenView(this)])),
              ],
            ),
          );
        });
  }
}

class _TRC10TokenView extends StatefulWidget {
  const _TRC10TokenView(this.state);
  final _MonitorTronTokenViewState state;

  @override
  State<_TRC10TokenView> createState() => _TRC10TokenViewState();
}

class _TRC10TokenViewState extends State<_TRC10TokenView>
    with AutomaticKeepAliveClientMixin, SafeState {
  @override
  bool get wantKeepAlive => true;

  @override
  void onInitOnce() {
    super.onInitOnce();
    widget.state.fetchingTokens();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamPageProgress(
      controller: widget.state.trc10ProgressKey,
      initialWidget: ProgressWithTextView(text: "fetching_account_token_please_wait".tr),
      builder: (context) => CustomScrollView(
        slivers: [
          SliverConstraintsBoxView(
            padding: WidgetConstant.paddingHorizontal20,
            sliver: EmptyItemSliverWidgetView(
              isEmpty: widget.state.tokens.isEmpty,
              itemBuilder: (context) => SliverList.separated(
                separatorBuilder: (context, index) => WidgetConstant.divider,
                itemBuilder: (context, index) {
                  final token = widget.state.tokens.elementAt(0);
                  final bool exist = widget.state.accountTokens.contains(token);
                  return AccountTokenDetailsView(
                    token: token,
                    onSelect: () {
                      context.openSliverDialog(
                          widget: (ctx) => DialogTextView(
                              buttonWidget: AsyncDialogDoubleButtonView(
                                firstButtonPressed: () =>
                                    widget.state.onTap(token, exist),
                              ),
                              text: exist
                                  ? "remove_token_from_account".tr
                                  : "add_token_to_your_account".tr),
                          label: exist ? "remove_token".tr : "add_token".tr);
                    },
                    onSelectIcon:
                        APPCheckBox(value: exist, ignoring: true, onChanged: (e) {}),
                  );
                },
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: false,
                itemCount: widget.state.tokens.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TRC20TokenView extends StatefulWidget {
  const _TRC20TokenView(this.state);
  final _MonitorTronTokenViewState state;

  @override
  State<_TRC20TokenView> createState() => _TRC20TokenViewState();
}

class _TRC20TokenViewState extends State<_TRC20TokenView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamPageProgress(
      controller: widget.state.trc20ProgressKey,
      // backToIdle: APPConst.oneSecoundDuration,
      builder: (context) => ConstraintsBoxView(
        padding: WidgetConstant.paddingHorizontal20,
        child: Center(
          child: widget.state.token != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AccountTokenDetailsView(token: widget.state.token!),
                    FixedElevatedButton(
                        padding: WidgetConstant.paddingVertical40,
                        onPressed: widget.state.onNewToken,
                        child: Text("import_new_token".tr))
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PageTitleSubtitle(
                          title: "import_trc20_token".tr,
                          body: Text("import_erc20_desc".tr)),
                      ReceiptAddressView(
                        address: widget.state.contractAddress,
                        title: "contract_address".tr,
                        onTap: () {
                          context
                              .selectAccount<TronAddress>(
                                  account: widget.state.account,
                                  title: "contract_address".tr)
                              .then((v) => widget.state.onSetupAddress(v?.firstOrNull));
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FixedElevatedButton(
                              activePress: widget.state.hasContractAddress,
                              padding: WidgetConstant.paddingVertical40,
                              onPressed: widget.state.onAddTrc20Token,
                              child: Text("add_to_my_account".tr))
                        ],
                      )
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
