import 'package:blockchain_utils/service/models/params.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/account/state.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/wallet/api/types/types.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class MoneroImportUtxos extends StatelessWidget {
  const MoneroImportUtxos({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessWalletView<WalletCredentialResponseLogin, WalletCredentialLogin>(
      request: WalletCredentialLogin.instance,
      title: "import_utxos".tr,
      onAccsess: (_) {
        return NetworkAccountControllerView<MoneroNetworkClient, IMoneroAddress,
                MoneroChain>(
            addressRequired: true,
            appBarOnError: false,
            clientRequired: true,
            childBulder: (wallet, account, client, address) =>
                _MoneroImportUtxosView(account: account, client: client));
      },
    );
  }
}

class _MoneroImportUtxosView extends StatefulWidget {
  const _MoneroImportUtxosView({required this.account, required this.client});
  final MoneroChain account;
  final MoneroNetworkClient client;

  @override
  State<_MoneroImportUtxosView> createState() => _MoneroImportUtxosViewState();
}

class _MoneroImportUtxosViewState extends MoneroAccountState<_MoneroImportUtxosView>
    with ProgressMixin {
  final GlobalKey<FormState> formKey = GlobalKey();
  final Cancelable _cancelable = Cancelable();
  bool showUtxos = false;
  @override
  MoneroChain get account => widget.account;
  @override
  MoneroNetworkClient get client => widget.client;
  String txIds = "";

  List<_TransactionTxsWithUtxos> utxos = [];

  String? validateTransactionIds(String? v) {
    if (v == null || v.trim().isEmpty) {
      return "enter_transaction_ids_validator".tr;
    }
    final txIds = StrUtils.separateBySpace(v).map((e) => e.toLowerCase());
    if (txIds.isEmpty) {
      return "enter_transaction_ids_validator".tr;
    }
    final isValid = txIds.every((e) => APPConst.hex32Bytes.hasMatch(e));
    if (!isValid) return "enter_transaction_ids_validator2".tr;
    if (txIds.toSet().length != txIds.length) {
      return "duplicate_transaction_ids_detected".tr;
    }
    return null;
  }

  void onChangeTransactionIds(String v) {
    txIds = v;
  }

  final GlobalKey<AppTextFieldState> txIdsStateKey = GlobalKey();

  Future<void> syncTransactionIds() async {
    if (!formKey.ready()) return;
    _cancelable.cancel();
    final txes = txIdsStateKey.currentState?.getValue();
    final txIds = StrUtils.separateBySpace(txes);
    if (txIds.isEmpty) return;
    progressKey.progressText("retrieving_transaction".tr);
    final result = await IResult.block(() async => await account.importUtxos(txIds),
        cancelable: _cancelable);
    result.watch(
      onErr: (error) {
        if (result.canceled()) {
          progressKey.backToIdle();
          updateState();
          return;
        }
        progressKey.errorText(error.localizationError,
            backToIdle: false, showBackButton: true);
      },
      onOk: (u) {
        final Map<String, List<_MoneroAccountTxTrackerStatusWithAccount>> utxos = {};
        Map<MoneroAccountIndex, IMoneroAddress?> indexToAccount = {};
        for (final i in u) {
          final txUtxos = utxos[i.txId] ??= [];
          switch (i) {
            case MoneroAccountTxTrackerUtxo(:final index, :final utxo):
              final account =
                  indexToAccount[index] ??= this.account.fromAccountIndex(index);
              txUtxos.add(_MoneroAccountTxTrackerStatusWithAccount(
                  account: account,
                  utxos: i,
                  amount: IntegerBalance.token(utxo.amount, this.account.network.token)));
              break;
            default:
              txUtxos.add(_MoneroAccountTxTrackerStatusWithAccount(utxos: i));
              break;
          }
        }
        this.utxos = utxos.entries
            .map((e) => _TransactionTxsWithUtxos(txId: e.key, utxos: e.value))
            .toList();
        showUtxos = true;
        progressKey.success(backToIdle: true);
      },
    );
  }

  void onPopInvokedWithResult(_, __) {
    if (progressKey.inProgress) {
      _cancelable.cancel();
      return;
    }
    showUtxos = false;
    updateState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      canPop: !showUtxos,
      onPopInvokedWithResult: onPopInvokedWithResult,
      child: StreamPageProgress(
        controller: progressKey,
        builder: (context) {
          return CustomScrollView(slivers: [
            SliverConstraintsBoxView(
              padding: WidgetConstant.padding20,
              sliver: APPSliverAnimatedSwitcher(enable: showUtxos, widgets: {
                false: (context) => SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PageTitleSubtitle(
                              title: "import_utxos".tr,
                              body: Text("monero_wallet_transaction_sync_desc2".tr)),
                          Text("transaction_id".tr, style: context.textTheme.titleMedium),
                          Text("enter_transaction_ids_desc".tr),
                          WidgetConstant.height8,
                          AppTextField(
                              label: "transaction_ids".tr,
                              pasteIcon: true,
                              maxLines: 5,
                              minlines: 2,
                              onChanged: onChangeTransactionIds,
                              initialValue: txIds,
                              validator: validateTransactionIds,
                              keyboardType: TextInputType.text,
                              key: txIdsStateKey),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FixedElevatedButton(
                                  padding: WidgetConstant.paddingVertical40,
                                  onPressed: syncTransactionIds,
                                  child: Text("sync_now".tr)),
                            ],
                          )
                        ],
                      ),
                    ),
                true: (context) => _ShowTxes(utxos)
              }),
            ),
          ]);
        },
      ),
    );
  }
}

class _ShowTxes extends StatelessWidget {
  final List<_TransactionTxsWithUtxos> utxos;
  const _ShowTxes(this.utxos);

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "transactions".tr,
              style: context.textTheme.titleMedium,
            ),
            Text(
              "transactions_and_utxos_status".tr,
              style: context.textTheme.bodyMedium,
            ),
            WidgetConstant.height8,
          ],
        ),
      ),
      SliverList.separated(
        separatorBuilder: (context, index) => WidgetConstant.height5,
        itemCount: utxos.length,
        itemBuilder: (context, index) {
          final txUtxos = utxos[index];
          return APPExpansionListTile(
            title: CopyableTextWidget(
              text: txUtxos.txId,
              color: context.onPrimaryContainer,
              maxLines: 1,
            ),
            children: [
              ListView.builder(
                itemBuilder: (context, index) {
                  final utxo = txUtxos.utxos[index];
                  return ContainerWithBorder(
                    child: Column(children: [
                      switch (utxo.utxos) {
                        MoneroAccountTxTrackerUtxo() => ContainerWithBorder(
                            backgroundColor: context.onPrimaryContainer,
                            onRemove: () {},
                            enableTap: false,
                            onRemoveIcon: ToolTipView(
                                message: "utxo_successfully_imported_to_your_account".tr,
                                child: Icon(
                                  Icons.download,
                                  color: context.primaryContainer,
                                )),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ConditionalWidgetWithValue(
                                  value: utxo.account,
                                  onValue: (context, account) => AddressDetailsView(
                                    address: account,
                                    color: context.primaryContainer,
                                    showBalance: false,
                                  ),
                                ),
                                WidgetConstant.height8,
                                ConditionalWidgetWithValue(
                                  value: utxo.amount,
                                  onValue: (context, amount) => CoinAndMarketPriceView(
                                    balance: amount,
                                    style: context.primaryTextTheme.bodyMedium,
                                    showTokenImage: true,
                                    symbolColor: context.primaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        MoneroAccountTxTrackerNotFound(:final inMempool) when inMempool =>
                          ContainerWithBorder(
                            backgroundColor: context.onPrimaryContainer,
                            child: Text(
                              "utxo_already_spent".tr,
                              style: context.primaryTextTheme.bodyMedium,
                            ),
                          ),
                        MoneroAccountTxTrackerNotFound(:final hasError) when hasError =>
                          ContainerWithBorder(
                            backgroundColor: context.onPrimaryContainer,
                            child: Text(
                              "an_error_during_export_transaction_utxos".tr,
                              style: context.primaryTextTheme.bodyMedium,
                            ),
                          ),
                        MoneroAccountTxTrackerNotFound(:final noAccountUtxos)
                            when noAccountUtxos =>
                          ContainerWithBorder(
                            backgroundColor: context.onPrimaryContainer,
                            child: Text(
                              "no_related_account_utxos".tr,
                              style: context.primaryTextTheme.bodyMedium,
                            ),
                          ),
                        MoneroAccountTxTrackerNotFound() => ContainerWithBorder(
                            backgroundColor: context.onPrimaryContainer,
                            child: Text(
                              "transaction_not_found".tr,
                              style: context.primaryTextTheme.bodyMedium,
                            ),
                          ),
                        MoneroAccountTxTrackerSpended() => ContainerWithBorder(
                            backgroundColor: context.onPrimaryContainer,
                            child: Text(
                              "utxo_already_spent".tr,
                              style: context.primaryTextTheme.bodyMedium,
                            ),
                          ),
                      }
                    ]),
                  );
                },
                itemCount: txUtxos.utxos.length,
                shrinkWrap: true,
                physics: WidgetConstant.noScrollPhysics,
              )
            ],
          );
        },
      ),
    ]);
  }
}

class _MoneroAccountTxTrackerStatusWithAccount {
  final IMoneroAddress? account;
  final IntegerBalance? amount;
  final MoneroAccountTxTrackerStatus utxos;
  const _MoneroAccountTxTrackerStatusWithAccount(
      {this.account, required this.utxos, this.amount});
}

class _TransactionTxsWithUtxos {
  final String txId;
  final List<_MoneroAccountTxTrackerStatusWithAccount> utxos;
  _TransactionTxsWithUtxos({required this.txId, required this.utxos});
}

class MoneroSyncWithWalletRpcView extends StatelessWidget {
  const MoneroSyncWithWalletRpcView({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessWalletView<WalletCredentialResponseLogin, WalletCredentialLogin>(
      request: WalletCredentialLogin.instance,
      title: "wallet_rpc_synchronization".tr,
      onAccsess: (_) {
        return NetworkAccountControllerView<MoneroNetworkClient, IMoneroAddress,
                MoneroChain>(
            addressRequired: true,
            appBarOnError: false,
            clientRequired: true,
            childBulder: (wallet, account, client, address) =>
                _MoneroMergeWalletRpcView(account: account, client: client));
      },
    );
  }
}

class _MoneroMergeWalletRpcView extends StatefulWidget {
  const _MoneroMergeWalletRpcView({required this.account, required this.client});
  final MoneroChain account;
  final MoneroNetworkClient client;

  @override
  State<_MoneroMergeWalletRpcView> createState() => _MoneroMergeWalletRpcViewState();
}

class _MoneroMergeWalletRpcViewState extends MoneroAccountState<_MoneroMergeWalletRpcView>
    with ProgressMixin {
  bool showUtxos = false;
  @override
  MoneroChain get account => widget.account;
  @override
  MoneroNetworkClient get client => widget.client;
  String txIds = "";
  DefaultAPIProvider? walletProvider;
  RPCURL? rpcUrl;
  final GlobalKey<HTTPServiceProviderFieldsState> serviceProviderStateKey =
      GlobalKey(debugLabel: "_MoneroMergeWalletRpcViewState");
  final GlobalKey<FormState> formKey = GlobalKey();
  List<_TransactionTxsWithUtxos> utxos = [];
  final Cancelable _cancelable = Cancelable();

  Future<void> syncFromRpc() async {
    _cancelable.cancel();
    final url = rpcUrl = serviceProviderStateKey.currentState?.getEndpoint();

    if (!formKey.ready() || url == null) return;
    progressKey.progressText("monero_fetching_wallet_addresses".tr);
    bool canceled = false;
    void setPageMessage(String text) {
      if (canceled) return;
      progressKey.progressText(text);
    }

    final result = await IResult.block(() async {
      final provider = url.toProvider(APIProviderServices.moneroWalletRpc);
      final client = MoneroWalletClient.fromProvider(
          netApi: context.appContext.netApi,
          provider: provider,
          network: account.moneroNetwork);
      final addresses = await client.getRelatedAccount(account.addresses);
      if (addresses.isEmpty) throw AppException("no_related_account_found");
      setPageMessage("monero_fetching_Wallet_available_transfers".tr);
      final txIds = await client.getRelatedAccountsTxes(addresses);
      if (txIds.isEmpty) throw AppException("monero_wallet_rpc_sync_no_tx_found_desc");
      setPageMessage("retrieving_transaction".tr);
      return await account.importUtxos(txIds);
    }, cancelable: _cancelable);
    canceled = true;
    result.watch(
      onErr: (error) {
        if (error.canceled()) {
          progressKey.backToIdle();
          return;
        }
        progressKey.errorText(error.localizationError,
            backToIdle: false, showBackButton: true);
      },
      onOk: (u) {
        final Map<String, List<_MoneroAccountTxTrackerStatusWithAccount>> utxos = {};
        Map<MoneroAccountIndex, IMoneroAddress?> indexToAccount = {};
        for (final i in u) {
          final txUtxos = utxos[i.txId] ??= [];
          switch (i) {
            case MoneroAccountTxTrackerUtxo(:final index, :final utxo):
              final account =
                  indexToAccount[index] ??= this.account.fromAccountIndex(index);
              txUtxos.add(_MoneroAccountTxTrackerStatusWithAccount(
                  account: account,
                  utxos: i,
                  amount: IntegerBalance.token(utxo.amount, this.account.network.token)));
              break;
            default:
              txUtxos.add(_MoneroAccountTxTrackerStatusWithAccount(utxos: i));
              break;
          }
        }
        this.utxos = utxos.entries
            .map((e) => _TransactionTxsWithUtxos(txId: e.key, utxos: e.value))
            .toList();
        showUtxos = true;
        progressKey.success(backToIdle: true);
      },
    );
  }

  void onPopInvokedWithResult(_, __) {
    if (progressKey.inProgress) {
      _cancelable.cancel();
      return;
    }
    showUtxos = false;
    updateState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      canPop: !showUtxos,
      onPopInvokedWithResult: onPopInvokedWithResult,
      child: StreamPageProgress(
        controller: progressKey,
        builder: (context) {
          return CustomScrollView(slivers: [
            SliverConstraintsBoxView(
                padding: WidgetConstant.padding20,
                sliver: APPSliverAnimatedSwitcher(enable: showUtxos, widgets: {
                  false: (context) => SliverToBoxAdapter(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PageTitleSubtitle(
                                  title: "monero_wallet_rpc_sync_desc".tr,
                                  body: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("monero_wallet_rpc_sync_desc1".tr),
                                        Text("monero_wallet_rpc_sync_desc2".tr),
                                        WidgetConstant.height8,
                                        ErrorTextContainer(
                                            error:
                                                "monero_wallet_rpc_safty_interacting_desc"
                                                    .tr,
                                            enableTap: false),
                                      ])),
                              WidgetConstant.height20,
                              Text("wallet_rpc_url".tr,
                                  style: context.textTheme.titleMedium),
                              Text("wallet_rpc_url_desc".tr),
                              WidgetConstant.height8,
                              HTTPServiceProviderFields(
                                key: serviceProviderStateKey,
                                initialUrl: rpcUrl,
                                hint: MoneroConst.walletRPCLinkExample,
                                enableAuth: true,
                                protocols: [ServiceProtocol.http],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FixedElevatedButton(
                                      padding: WidgetConstant.paddingVertical40,
                                      onPressed: syncFromRpc,
                                      child: Text("sync_now".tr)),
                                ],
                              )
                            ]),
                      ),
                  true: (context) => _ShowTxes(utxos)
                })),
          ]);
        },
      ),
    );
  }
}
