import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/widgets/cash_token_info.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/types/types.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/crypto/networks/bitcoin/bitcoin.dart';

class TransactionOrderingView extends StatefulWidget {
  const TransactionOrderingView(
      {super.key,
      required this.inputs,
      required this.outputs,
      required this.network,
      required this.controller});
  final List<UtxoWithAddress> inputs;
  final List<IBitcoinOutput> outputs;
  final WalletBitcoinNetwork network;
  final ScrollController controller;

  @override
  State<TransactionOrderingView> createState() => _TransactionOrderingViewState();
}

class _TransactionOrderingViewState extends State<TransactionOrderingView>
    with SafeState<TransactionOrderingView> {
  List<IBitcoinOutput> burnableOutputs = [];
  List<_OutputWithKey> outputs = [];
  List<_InputsWithKey> inputs = [];

  void ordering() {
    final orderedInputs = inputs.map((e) => e.item).toList();
    final List<IBitcoinOutput> orderedOutputs = [
      ...outputs.map((e) => e.output),
      ...burnableOutputs
    ];
    context.pop((orderedInputs, orderedOutputs));
  }

  void onUpdate() => setState(() {});

  @override
  void safeDispose() {
    super.safeDispose();
    burnableOutputs = [];
    outputs = [];
    inputs = [];
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    final outs = widget.outputs;
    burnableOutputs = outs
        .where((element) =>
            switch (element.output) { BitcoinBurnableOutput() => true, _ => false })
        .toImutableList;
    outputs = outs
        .where((element) => !burnableOutputs.contains(element))
        .map((e) => _OutputWithKey._(e, widget.network))
        .toList();
    inputs = widget.inputs
        .map((e) => _InputsWithKey(item: e, network: widget.network))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: ordering,
          child: Icon(Icons.save),
        ),
        appBar: AppBar(
          title: Text("transaction_ordering".tr),
          bottom: TabBar(tabs: [
            Tab(text: "inputs".tr),
            Tab(text: "outputs".tr),
          ]),
        ),
        body: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context)
              .copyWith(scrollbars: false, physics: const ClampingScrollPhysics()),
          child: NestedScrollView(
              controller: widget.controller,
              headerSliverBuilder: (c, e) => [],
              body: TabBarView(children: [
                _InputOrdering(
                  inputs: inputs,
                  network: widget.network,
                  onUpdate: onUpdate,
                  controller: widget.controller,
                ),
                _OutputOrdering(
                  outputs: outputs,
                  network: widget.network,
                  onUpdate: onUpdate,
                  controller: widget.controller,
                )
              ])),
        ),
      ),
    );
  }
}

class _InputOrdering extends StatelessWidget {
  const _InputOrdering(
      {required this.inputs,
      required this.network,
      required this.onUpdate,
      required this.controller});
  final List<_InputsWithKey> inputs;
  final WalletBitcoinNetwork network;
  final DynamicVoid onUpdate;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      scrollController: controller,
      buildDefaultDragHandles: false,
      onReorderItem: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        final item = inputs.removeAt(oldIndex);
        inputs.insert(newIndex, item);
        onUpdate();
      },
      children: List.generate(inputs.length, (index) {
        final input = inputs[index];
        return Padding(
          padding: WidgetConstant.paddingHorizontal20,
          key: input.key,
          child: ConstraintsBoxView(
            child: ContainerWithBorder(
              onRemove: () {},
              enableTap: false,
              onRemoveIcon: ReorderableDragStartListener(
                  index: index,
                  child: Icon(Icons.touch_app, color: context.onPrimaryContainer)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(input.item.ownerDetails.address.type.name,
                      style: context.onPrimaryTextTheme.labelLarge),
                  OneLineTextWidget(
                      input.item.ownerDetails.address
                          .toAddress(network.coinParam.transacationNetwork),
                      style: context.onPrimaryTextTheme.bodyMedium),
                  Divider(color: context.onPrimaryContainer),
                  OneLineTextWidget(input.item.utxo.txHash,
                      style: context.onPrimaryTextTheme.bodyMedium),
                  CoinAndMarketPriceView(
                      balance: input.inputValue,
                      style: context.onPrimaryTextTheme.titleMedium,
                      symbolColor: context.onPrimaryContainer)
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _OutputOrdering extends StatelessWidget {
  const _OutputOrdering(
      {required this.outputs,
      required this.network,
      required this.onUpdate,
      required this.controller});
  final List<_OutputWithKey> outputs;
  final WalletBitcoinNetwork network;
  final DynamicVoid onUpdate;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      scrollController: controller,
      onReorderItem: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        final item = outputs.removeAt(oldIndex);
        outputs.insert(newIndex, item);
        onUpdate();
      },
      buildDefaultDragHandles: false,
      children: List.generate(outputs.length, (index) {
        final output = outputs[index];
        return Padding(
          padding: WidgetConstant.paddingHorizontal20,
          key: output.key,
          child: ContainerWithBorder(
            onRemove: () {},
            enableTap: false,
            onRemoveIcon: ReorderableDragStartListener(
                index: index,
                child: Icon(Icons.touch_app, color: context.onPrimaryContainer)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                        child: output.output.output is BitcoinSpendableBaseOutput
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  OneLineTextWidget(output.addressView!,
                                      style: context.onPrimaryTextTheme.bodyMedium),
                                  CoinAndMarketPriceView(
                                      balance: output.value,
                                      style: context.onPrimaryTextTheme.titleMedium,
                                      symbolColor: context.onPrimaryContainer),
                                ],
                              )
                            : Text(
                                output.script ?? "",
                                style: context.onPrimaryTextTheme.bodyMedium,
                              )),
                  ],
                ),
                if (output.token != null) ...[
                  Divider(color: context.colors.onPrimaryContainer),
                  BCHCashTokenDetailsView(
                      token: output.token!, color: context.colors.onPrimaryContainer),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _OutputWithKey<T> {
  _OutputWithKey(
      {this.addressView,
      required this.output,
      required this.value,
      this.script,
      this.token})
      : key = GlobalKey();
  factory _OutputWithKey._(IBitcoinOutput output, WalletBitcoinNetwork network) {
    return switch (output.output) {
      BitcoinScriptOutput out => _OutputWithKey(
          output: output,
          value: IntegerBalance.zero(network.token),
          addressView: null,
          script: BTCUtils.opReturnToView(out.script)),
      BitcoinTokenOutput out => _OutputWithKey(
          output: output,
          addressView: out.address.toAddress(network.coinParam.transacationNetwork),
          token: BCHCashToken(cashToken: out.token),
          value: IntegerBalance.token(out.value, network.token)),
      BitcoinOutput out => _OutputWithKey(
          output: output,
          addressView: out.address.toAddress(network.coinParam.transacationNetwork),
          value: IntegerBalance.token(out.value, network.token)),
      _ => throw AppInternalError.internalError("_OutputWithKey",
          reason: "Unexpected bitcoin output.")
    };
  }
  final GlobalKey key;
  final String? addressView;
  final IBitcoinOutput output;
  final IntegerBalance value;
  final String? script;
  final BCHCashToken? token;
}

class _InputsWithKey {
  _InputsWithKey({required this.item, required WalletBitcoinNetwork network})
      : key = GlobalKey(),
        inputValue = IntegerBalance.token(item.utxo.value, network.token);
  final GlobalKey key;
  final UtxoWithAddress item;
  final IntegerBalance inputValue;
}
