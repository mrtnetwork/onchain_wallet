import 'dart:async';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/operations/multisig_operation.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/future/widgets/widgets/json/json/widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

class SubstrateMultisigAddressTxesRouteArgument {
  final SubstrateChain account;
  final ISubstrateMultiSigAddress address;
  final SubstrateMultisigCall? call;
  final StreamPageProgressController? controller;
  const SubstrateMultisigAddressTxesRouteArgument(
      {required this.account, required this.address, this.call, this.controller});
}

class SubstrateMultisigAddressTxesView extends StatelessWidget {
  const SubstrateMultisigAddressTxesView({super.key});

  @override
  Widget build(BuildContext context) {
    final SubstrateMultisigAddressTxesRouteArgument? newMultisig =
        context.getNullArgruments();
    return NetworkAccountControllerView<SubstrateNetworkClient, ISubstrateMultiSigAddress,
        SubstrateChain>(
      addressRequired: true,
      clientRequired: true,
      multisigAccount: true,
      account: newMultisig?.account,
      address: newMultisig?.address,
      childBulder: (wallet, account, client, address) {
        return _SubstrateMutltisigAddressTxesView(
            args: newMultisig ??
                SubstrateMultisigAddressTxesRouteArgument(
                    account: account, address: address),
            client: client);
      },
    );
  }
}

class _SubstrateMutltisigAddressTxesView extends StatefulWidget {
  final SubstrateMultisigAddressTxesRouteArgument args;
  final SubstrateNetworkClient client;
  const _SubstrateMutltisigAddressTxesView({
    required this.args,
    required this.client,
  });

  @override
  State<_SubstrateMutltisigAddressTxesView> createState() =>
      _SubstrateMutltisigAddressTxesViewState();
}

class _SubstrateMutltisigAddressTxesViewState
    extends State<_SubstrateMutltisigAddressTxesView>
    with SafeState<_SubstrateMutltisigAddressTxesView> {
  late final controller =
      _SubstrateMultisigTxesStateController(args: widget.args, client: widget.client);
  @override
  void onInitOnce() {
    super.onInitOnce();
    controller.stream.listen((_) => updateState());
    controller.init();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("multisig_transactions".tr)),
      body: StreamPageProgress(
        controller: controller.pageProgress,
        builder: (context) => CustomScrollView(
          slivers: [
            SliverConstraintsBoxView(
              padding: WidgetConstant.padding20,
              sliver: EmptyItemSliverWidgetView(
                isEmpty: controller.txes.isEmpty,
                itemBuilder: (context) {
                  return MultiSliver(children: [
                    Text("transactions".tr, style: context.textTheme.titleMedium),
                    WidgetConstant.height8,
                    SliverList.builder(
                      itemCount: controller.txes.length,
                      itemBuilder: (context, index) {
                        final tx = controller.txes[index];
                        final callData = tx.callData;
                        return CustomizedContainer(
                          enableTap: false,
                          onStackWidget: TappedTooltipView(
                              tooltipWidget: ToolTipView(
                                  message: tx.status.tr.tr,
                                  child: IconButton(
                                      onPressed: () {},
                                      icon: ConditionalWidgets<_MultisigTxStatus>(
                                          enable: tx.status,
                                          widgets: {
                                            _MultisigTxStatus.inProgress: (context) =>
                                                Icon(Icons.padding,
                                                    color: context.primaryContainer),
                                            _MultisigTxStatus.newRequest: (context) =>
                                                Icon(Icons.new_label,
                                                    color: context.primaryContainer),
                                            _MultisigTxStatus.complete: (context) => Icon(
                                                Icons.check_circle,
                                                color: context.primaryContainer),
                                          })))),
                          onTapStackIcon: () {},
                          child: APPExpansionListTile(
                            title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  OneLineTextWidget(tx.callData.call.callHashHex,
                                      style: context.onPrimaryTextTheme.bodyMedium),
                                  ConditionalWidget(
                                    enable: tx.status != _MultisigTxStatus.complete,
                                    onActive: (context) => ConditionalWidget(
                                      enable: tx.isReady,
                                      onDeactive: (context) => Text(
                                          "n_approvals_required"
                                              .tr
                                              .replaceOne(tx.requiredApprove.toString()),
                                          style: context.onPrimaryTextTheme.labelSmall),
                                      onActive: (context) => Text(
                                          "ready_for_execution".tr,
                                          style: context.onPrimaryTextTheme.labelSmall),
                                    ),
                                  ),
                                ]),
                            children: [
                              ContainerWithBorder(
                                backgroundColor: context.onPrimaryContainer,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ConditionalWidget(
                                      enable: tx.pendingTx != null,
                                      onActive: (context) {
                                        return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("latest_operation".tr,
                                                  style: context
                                                      .primaryTextTheme.labelLarge),
                                              WidgetConstant.height8,
                                              TrackTransactionStatusView(
                                                  account: controller.account,
                                                  txId: tx.pendingTx!.transaction.txId,
                                                  transaction: tx.pendingTx!.transaction),
                                              WidgetConstant.height20,
                                            ]);
                                      },
                                    ),
                                    Text("multisig_call_hash".tr,
                                        style: context.primaryTextTheme.labelLarge),
                                    WidgetConstant.height8,
                                    ContainerWithBorder(
                                      child: LargeTextContainer(
                                          color: context.onPrimaryContainer,
                                          text: callData.call.callHashHex),
                                    ),
                                    ConditionalWidget(
                                      enable: callData.call.callDataHex != null,
                                      onActive: (context) => Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          WidgetConstant.height20,
                                          Text("multisig_call_data".tr,
                                              style: context.primaryTextTheme.labelLarge),
                                          WidgetConstant.height8,
                                          ContainerWithBorder(
                                            child: LargeTextContainer(
                                                color: context.onPrimaryContainer,
                                                text: callData.call.callDataHex!),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ConditionalWidget(
                                        enable: callData.content != null,
                                        onActive: (context) => Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                WidgetConstant.height20,
                                                Text("content".tr,
                                                    style: context
                                                        .primaryTextTheme.bodyMedium),
                                                WidgetConstant.height8,
                                                ContainerWithBorder(
                                                    onRemoveIcon: Icon(Icons.open_in_full,
                                                        color:
                                                            context.onPrimaryContainer),
                                                    onRemove: () {
                                                      context.openDialogPage(
                                                        '',
                                                        child: (context) => JsonView(
                                                            text: callData.content!,
                                                            title: 'content'.tr),
                                                      );
                                                    },
                                                    child: Text("content".tr,
                                                        style: context.onPrimaryTextTheme
                                                            .bodyMedium)),
                                              ],
                                            )),
                                    ConditionalWidget(
                                        enable: tx.allowMethods.isNotEmpty,
                                        onActive: (context) => Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  WidgetConstant.height20,
                                                  Text("operations".tr,
                                                      style: context
                                                          .primaryTextTheme.titleMedium),
                                                  Text(
                                                      "substrate_select_multisig_operation_desc"
                                                          .tr,
                                                      style: context
                                                          .primaryTextTheme.bodyMedium),
                                                  WidgetConstant.height8,
                                                  ...tx.allowMethods
                                                      .map((m) => ContainerWithBorder(
                                                            onRemove: () {
                                                              controller.onTapMethod(
                                                                  tx: tx,
                                                                  context: context,
                                                                  method: m);
                                                            },
                                                            onRemoveIcon: Icon(
                                                                Icons.open_in_new,
                                                                color: context
                                                                    .onPrimaryContainer),
                                                            child: Text(
                                                              m.name.camelCase,
                                                              style: context
                                                                  .onPrimaryTextTheme
                                                                  .bodyMedium,
                                                            ),
                                                          ))
                                                ]))
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    )
                  ]);
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _OnPickSigner extends StatelessWidget {
  final MultisigCallPalletMethod method;
  final List<ReceiptAddress<BaseSubstrateAddress>> signers;
  const _OnPickSigner({required this.signers, required this.method});

  @override
  Widget build(BuildContext context) {
    return SliverConstraintsBoxView(
      padding: WidgetConstant.padding20,
      sliver: MultiSliver(
        children: [
          Text(method.name.camelCase, style: context.textTheme.titleMedium),
          Text("choose_a_signer_to_continue".tr, style: context.textTheme.bodyMedium),
          WidgetConstant.height8,
          SliverList.separated(
            itemBuilder: (context, index) {
              final signer = signers[index];
              return ContainerWithBorder(
                  onRemove: () {
                    context.pop(signer);
                  },
                  enableTap: signer.account != null,
                  onRemoveWidget: ConditionalWidget(
                      enable: signer.account != null,
                      onDeactive: (context) => TappedTooltipView(
                          tooltipWidget: ToolTipView(
                              message: "account_not_found_in_connected_wallet".tr,
                              child: Icon(
                                Icons.no_accounts,
                                color: context.onPrimaryContainer,
                              ))),
                      onActive: (context) => Icon(
                            Icons.open_in_new,
                            color: context.onPrimaryContainer,
                          )),
                  child: ReceiptAddressDetailsView(
                      address: signer, color: context.onPrimaryContainer));
            },
            separatorBuilder: (context, index) => const Divider(),
            itemCount: signers.length,
          ),
        ],
      ),
    );
  }
}

class _SubstrateMultisigTxesStateController with DisposableMixin, StreamStateController {
  List<MultisigCallPalletMethod> availableMethods = [];
  final SubstrateMultisigAddressTxesRouteArgument args;
  SubstrateMultisigCall? get newMultisig => args.call;
  SubstrateChain get account => args.account;
  ISubstrateMultiSigAddress get address => args.address;
  final SubstrateNetworkClient client;
  PeriodicRunner<List<_MultisigTx>>? _periodicRunner;
  final Map<String, StreamSubscription> _onTxEvents = {};
  _SubstrateMultisigTxesStateController({required this.client, required this.args});
  final StreamPageProgressController pageProgress =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  Map<String, _MultisigTx> _txes = {};
  List<_MultisigTx> get txes => _txes.values.toList();

  void _onPeriodicUpdated(PeriodicRunner<List<_MultisigTx>> runner) {
    if (runner.status.isSuccess) {
      final runnetKeys = runner.value.map((e) => e.callData.call.callHashHex).toList();
      for (final i in runner.value) {
        final tx = _txes[i.callHash];
        if (tx == null) {
          _txes[i.callHash] = i;
          continue;
        }
        tx.merge(i);
      }
      for (final i in _txes.entries) {
        if (!runnetKeys.contains(i.key)) i.value.merge(null);
      }
      notify();
    }
  }

  Future<List<_MultisigTx>> _getMultisigs() async {
    final accountTxes =
        (await account.getAccountMultisigs(address, newRequest: newMultisig)).unwrap();
    return await Future.wait(accountTxes.map((e) async {
      return _MultisigTx(
          callData: e,
          threshold: address.multiSignatureAddress.threshold,
          signers: await _buildSigners(e),
          status: e.multisig == null
              ? _MultisigTxStatus.newRequest
              : _MultisigTxStatus.inProgress);
    }).toList());
  }

  Future<List<_Signer>> _buildSigners(SubstrateMultisigCallData result) async {
    final threshold = address.multiSignatureAddress.threshold;
    final multisig = result.multisig;
    final approvals = multisig?.approvals ?? [];
    final addresses = address.signers();
    final approvalsCount = approvals.length;
    final isLastSigner = approvalsCount + 1 >= threshold;
    final bool thresholdReached = approvalsCount >= threshold;
    List<MultisigCallPalletMethod> methods = [];
    if (multisig == null) {
      if (threshold == 1) {
        methods.add(MultisigCallPalletMethod.asMultiThreshold1);
      } else {
        methods.add(MultisigCallPalletMethod.approveAsMulti);
      }
    } else {
      if (isLastSigner && result.call.callData != null) {
        methods.add(MultisigCallPalletMethod.asMulti);
      } else {
        methods.add(MultisigCallPalletMethod.approveAsMulti);
      }
    }
    return addresses.map((e) {
      final signed = approvals.any((a) => a.rawAddress == e.rawAddress);
      final depositor = multisig != null && multisig.depositor.rawAddress == e.rawAddress;
      final allowedMethods = methods.clone();
      if (depositor) {
        allowedMethods.add(MultisigCallPalletMethod.cancelAsMulti);
        if (availableMethods.contains(MultisigCallPalletMethod.pokeDeposit)) {
          allowedMethods.add(MultisigCallPalletMethod.pokeDeposit);
        }
      }
      if (signed) {
        allowedMethods.remove(MultisigCallPalletMethod.approveAsMulti);
      }
      if (signed && !thresholdReached) {
        allowedMethods.remove(MultisigCallPalletMethod.asMulti);
      }
      final address = account.getOrCreateReceiptFromNetworkAddressSync(address: e);
      return _Signer(allowMethods: allowedMethods, address: address, signed: signed);
    }).toList();
  }

  Future<void> onTapMethod(
      {required BuildContext context,
      required _MultisigTx tx,
      required MultisigCallPalletMethod method}) async {
    final signers = tx.signers.where((e) => e.allowMethods.contains(method));
    final signer = await context.openSliverDialog<ReceiptAddress<BaseSubstrateAddress>>(
        label: "signers".tr,
        sliver: (context) => _OnPickSigner(
            signers: signers.map((e) => e.address).toList(), method: method));
    if (signer == null || signer.account == null) return;
    final signerAddress = signer.account!.cast<ISubstrateAddress>();
    final operation = SubstrateTransactionMultisigOperation(
        walletProvider: context.wallet,
        account: account,
        address: signerAddress,
        multisig: SubstrateMultisigTransactionData(
            callData: tx.callData, method: method, address: address));

    _onTxEvents[tx.callData.call.callHashHex] = operation
        .onStateEvent(type: TransactionStateControllerEventType.walletTxs)
        .listen(
      (event) {
        final walletTx = event.walletTxs?.firstOrNull;
        if (walletTx == null) return;
        tx.setTx(_LatestTx(
            transaction: walletTx.transaction,
            method: method,
            signer: signerAddress,
            account: account,
            onStatusChanged: () => _periodicRunner?.update()));
        notify();
        args.controller?.success(
            backToIdle: false,
            progressWidget: SuccessTransactionTextView(
                txId: walletTx.transaction.txId,
                address: signerAddress,
                warning: null,
                account: account,
                transaction: walletTx.transaction));
        final sub = _onTxEvents.remove(tx.callData.call.callHashHex);
        sub?.cancel();
      },
    );
    await context.to(PageRouter.transaction, argruments: operation);
  }

  Future<void> init() async {
    availableMethods = client.metadata.multisigMethods();
    if (availableMethods.isEmpty) {
      pageProgress.errorText("unsupported_current_network_feature".tr, backToIdle: false);
      return;
    }
    // client.metadata.transferTypes;
    final result = await IResult.call(() async {
      return _getMultisigs();
    });
    if (result.isErr) {
      pageProgress.errorText(result.unwrapErr().localizationError, backToIdle: false);
      return;
    }
    _txes = {for (final i in result.unwrap()) i.callData.call.callHashHex: i};
    pageProgress.backToIdle();
    _periodicRunner =
        PeriodicRunner(onFetch: _getMultisigs, periodic: const Duration(minutes: 1));
    _periodicRunner?.stream.listen((event) => _onPeriodicUpdated(_periodicRunner!));
  }

  @override
  void dispose() {
    _periodicRunner?.dispose();
    _periodicRunner = null;
    for (final i in _onTxEvents.values) {
      i.cancel();
    }
    _onTxEvents.clear();
    for (final i in txes) {
      i.removeTx();
    }
    _txes.clear();
    super.dispose();
  }
}

enum _MultisigTxStatus {
  newRequest("new_transaction"),
  inProgress("pending"),
  complete("complete");

  final String tr;
  const _MultisigTxStatus(this.tr);
  bool get isNewRequest => this == newRequest;
}

class _MultisigTx {
  final int threshold;
  SubstrateMultisigCallData callData;
  List<_Signer> signers;
  List<MultisigCallPalletMethod> allowMethods;
  int requiredApprove;
  _MultisigTxStatus status;
  _LatestTx? pendingTx;
  bool get isReady => requiredApprove == 0;
  String get callHash => callData.call.callHashHex;

  _MultisigTx._(
      {required this.callData,
      required this.requiredApprove,
      required this.status,
      this.signers = const [],
      required this.threshold})
      : allowMethods = signers.expand((e) => e.allowMethods).toSet().toList();
  factory _MultisigTx(
      {required SubstrateMultisigCallData callData,
      required int threshold,
      required List<_Signer> signers,
      required _MultisigTxStatus status}) {
    final approvals = callData.multisig?.approvals.length ?? 0;
    int requiredApprove = threshold - approvals;
    return _MultisigTx._(
        callData: callData,
        requiredApprove: requiredApprove.isNegative ? 0 : requiredApprove,
        signers: signers,
        status: status,
        threshold: threshold);
  }
  void merge(_MultisigTx? other) {
    bool isComplete = false;
    if (other == null) {
      isComplete = true;
    } else if (other.status.isNewRequest && !status.isNewRequest) {
      isComplete = true;
    } else if (threshold == 1) {
      final pendingTx = this.pendingTx;
      isComplete = pendingTx != null && !pendingTx.transaction.status.inMempool;
    }
    if (isComplete) {
      _MultisigTxStatus newStatus = _MultisigTxStatus.complete;
      status = newStatus;
      allowMethods = [];
    } else {
      callData = other!.callData;
      signers = other.signers;
      allowMethods = other.allowMethods;

      requiredApprove = other.requiredApprove;
      status = other.status;
    }
  }

  void setTx(_LatestTx tx) {
    removeTx();
    pendingTx = tx;
  }

  void removeTx() {
    pendingTx?.dispose();
    pendingTx = null;
  }
}

class _Signer {
  final ReceiptAddress<BaseSubstrateAddress> address;
  final bool signed;
  final List<MultisigCallPalletMethod> allowMethods;
  const _Signer(
      {required this.address, required this.signed, required this.allowMethods});
}

class _LatestTx {
  final SubstrateWalletTransaction transaction;
  final MultisigCallPalletMethod method;
  final ISubstrateAddress signer;
  final DynamicVoid onStatusChanged;
  StreamSubscription<ChainEvent>? _onAccountEvent;
  _LatestTx(
      {required this.transaction,
      required this.method,
      required this.signer,
      required this.onStatusChanged,
      required Chain account}) {
    _onAccountEvent = account.stream.listen(onEvent);
    onEvent(null);
  }
  void onEvent(ChainEvent? event) {
    if (!transaction.status.inMempool) {
      onStatusChanged();
      _onAccountEvent?.cancel();
    }
  }

  void dispose() {
    _onAccountEvent?.cancel();
    _onAccountEvent = null;
  }
}
