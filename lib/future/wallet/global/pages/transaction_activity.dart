import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class AccountTransactionActivityView<TRANSACTION extends ChainTransaction,
    CHAINACCOUNT extends APPCHAINTX<TRANSACTION>> extends StatefulWidget {
  final APPCHAINACCOUNTTX<TRANSACTION, CHAINACCOUNT> account;
  final CHAINACCOUNT address;
  const AccountTransactionActivityView(
      {required this.account, required this.address, super.key});

  @override
  State<AccountTransactionActivityView<TRANSACTION, CHAINACCOUNT>> createState() =>
      _AccountTransactionActivityViewState<TRANSACTION, CHAINACCOUNT>();
}

class _AccountTransactionActivityViewState<TRANSACTION extends ChainTransaction,
        CHAINACCOUNT extends APPCHAINTX<TRANSACTION>>
    extends State<AccountTransactionActivityView<TRANSACTION, CHAINACCOUNT>>
    with SafeState<AccountTransactionActivityView<TRANSACTION, CHAINACCOUNT>> {
  List<TRANSACTION>? transactions;
  APPCHAINACCOUNTTX<TRANSACTION, CHAINACCOUNT> get account => widget.account;
  StreamSubscription<ChainEvent>? _listener;
  Future<void> getAccountTransactions() async {
    final result = await widget.address.getAccountTransactions();
    result.watch(
      onErr: (error) {
        transactions = [];
        updateState();
        context.showAlert(error.localizationError);
      },
      onOk: (transactions) {
        this.transactions = transactions;
        updateState();
      },
    );
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    _listener = widget.account.stream.listen((e) async {
      if (e.type == DefaultChainNotify.transaction) {
        getAccountTransactions();
      }
    });
    getAccountTransactions();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    _listener?.cancel();
    _listener = null;
    transactions = null;
  }

  @override
  Widget build(BuildContext context) {
    return ChainStreamBuilder(
        allowNotify: [DefaultChainNotify.transaction],
        builder: (context, _) {
          return AccountTabbarScrollWidget(slivers: [
            Shimmer(
                sliver: true,
                onActive: (enable, context) {
                  return ConditionalWidgetWithValue(
                      value: transactions,
                      onNull: (context) => ShimmerBox(),
                      onValue: (context, transaction) => EmptyItemSliverWidgetView(
                            isEmpty: transaction.isEmpty,
                            itemBuilder: (context) {
                              return SliverList.separated(
                                  itemBuilder: (context, index) {
                                    return TransactionView<TRANSACTION, CHAINACCOUNT>(
                                      transaction: transaction[index],
                                      account: account,
                                      address: widget.address,
                                    );
                                  },
                                  separatorBuilder: (context, index) =>
                                      WidgetConstant.divider,
                                  itemCount: transaction.length);
                            },
                          ));
                },
                enable: transactions != null)
          ]);
        },
        account: account);
  }
}
