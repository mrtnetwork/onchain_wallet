import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'mnemonic_view.dart';

typedef OnValidateMnemonic = void Function(List<String>);

class VerifyMnemonicView extends StatefulWidget {
  const VerifyMnemonicView(
      {required this.mnemonic, required this.onValidate, this.submitText, super.key});
  final List<String> mnemonic;
  final OnValidateMnemonic onValidate;
  final String? submitText;
  @override
  State<VerifyMnemonicView> createState() => _VerifyMnemonicViewState();
}

class _VerifyMnemonicViewState extends State<VerifyMnemonicView>
    with SafeState<VerifyMnemonicView> {
  late final List<String> shuffleMnemonic = List<String>.from(widget.mnemonic)..shuffle();

  late List<SelectedMnemonic> inSelectMnemonic;
  bool equal = false;
  bool compelte = false;
  bool get wrongFilled => compelte && !equal;

  void isEqual() {
    compelte = inSelectMnemonic.where((element) => element.selected).length ==
        inSelectMnemonic.length;
    equal = compelte &&
        inSelectMnemonic.every((e) {
          final readIndex = e.readIndex - 1;
          return e.word == widget.mnemonic.elementAt(readIndex);
        });
  }

  final List<int> selectedIndex = [];
  void tap(int index) {
    try {
      if (selectedIndex.contains(index)) {
        final selcetIndex =
            inSelectMnemonic.indexWhere((element) => element.index == index);
        inSelectMnemonic[selcetIndex] =
            SelectedMnemonic.notSelected(inSelectMnemonic[selcetIndex].readIndex);
        selectedIndex.remove(index);

        return;
      }

      final word = shuffleMnemonic.elementAt(index);
      final emptyIndex = inSelectMnemonic.indexWhere((element) => element.index == null);
      if (emptyIndex.isNegative) return;
      selectedIndex.add(index);
      inSelectMnemonic[emptyIndex] = SelectedMnemonic.select(
          index: index, word: word, readIndex: inSelectMnemonic[emptyIndex].readIndex);
    } finally {
      updateState(() {
        isEqual();
      });
    }
  }

  void clear() {
    _init();
    selectedIndex.clear();
    isEqual();
    updateState(() {});
  }

  /// boy hour plate liquid charge champion electric eye grit lizard anxiety space
  void validate() {
    final mnemonic = widget.mnemonic.clone();
    final equal = inSelectMnemonic.every((e) {
      final readIndex = e.readIndex - 1;
      return e.word == mnemonic.elementAt(readIndex);
    });
    if (!equal) return;
    widget.onValidate(mnemonic);
  }

  void _init() {
    List<int> selected = [];
    while (selected.length < 4) {
      final index = QuickCrypto.prng.nextInt(shuffleMnemonic.length - 1);
      if (selected.contains(index + 1)) continue;
      selected.add(index + 1);
    }
    inSelectMnemonic = List<SelectedMnemonic>.generate(
        selected.length, (i) => SelectedMnemonic.notSelected(selected[i]));
  }

  void _autoFill() {
    for (int i = 0; i < inSelectMnemonic.length; i++) {
      inSelectMnemonic[i] = SelectedMnemonic.select(
          index: 0,
          readIndex: inSelectMnemonic[i].readIndex,
          word: widget.mnemonic.elementAt(inSelectMnemonic[i].readIndex - 1));
    }
    isEqual();
    updateState(() {});
  }

  Timer? timer;

  void onLongTabCancel(LongPressEndDetails _) {
    timer?.cancel();
    timer = null;
  }

  void onLongTab(LongPressStartDetails _) {
    timer = Timer(const Duration(seconds: 3), () {
      _autoFill();
    });
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    _init();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    timer?.cancel();
    timer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitleSubtitle(
          title: "v_mnemonic".tr,
          body: LargeTextView(["v_mnemonic_desc".tr]),
        ),
        Align(
            alignment: Alignment.center,
            child: APPAnimated(
                isActive: equal,
                onDeactive: (context) => GestureDetector(
                    onLongPressStart: onLongTab,
                    onLongPressEnd: onLongTabCancel,
                    child: _MnemonicView(mnemonic: inSelectMnemonic)),
                onActive: (context) => MnemonicView(mnemonic: widget.mnemonic))),
        WidgetConstant.height20,
        AnimatedSwitcher(
            duration: APPConst.animationDuraion,
            child: APPAnimated(
                isActive: equal,
                onActive: (context) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            FixedElevatedButton(
                                padding: WidgetConstant.paddingVertical40,
                                onPressed: validate,
                                child: Text(widget.submitText ?? "continue".tr)),
                          ],
                        ),
                      ],
                    ),
                onDeactive: (context) => Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(borderRadius: WidgetConstant.border8),
                          child: Padding(
                            padding: WidgetConstant.padding10,
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              alignment: WrapAlignment.center,
                              spacing: 8.0,
                              children: List.generate(shuffleMnemonic.length, (index) {
                                return Card(
                                  surfaceTintColor: Colors.transparent,
                                  color: selectedIndex.contains(index)
                                      ? context.colors.primaryFixed
                                      : null,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: WidgetConstant.border4,
                                      side: const BorderSide(width: 1)),
                                  child: InkWell(
                                    onTap: () {
                                      tap(index);
                                    },
                                    child: Padding(
                                        padding: WidgetConstant.padding20,
                                        child: Text(
                                          shuffleMnemonic[index],
                                          style: context.textTheme.bodyMedium?.copyWith(
                                              color: selectedIndex.contains(index)
                                                  ? context.colors.onPrimaryFixed
                                                  : null),
                                        )),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                        ErrorTextContainer(
                            error: wrongFilled ? "invalid_mnemonic_ordering".tr : null),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FixedElevatedButton(
                                padding: WidgetConstant.paddingVertical40,
                                onPressed: clear,
                                child: Text("reset".tr))
                          ],
                        )
                      ],
                    )))
      ],
    );
  }
}

class _MnemonicView extends StatelessWidget {
  const _MnemonicView({required this.mnemonic});
  final List<SelectedMnemonic> mnemonic;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: WidgetConstant.border8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: WidgetConstant.border8,
        ),
        padding: WidgetConstant.padding10,
        child: Wrap(
          alignment: WrapAlignment.center,
          children: List.generate(
              mnemonic.length,
              (index) => AnimatedSize(
                    duration: APPConst.animationDuraion,
                    child: Padding(
                      key: ValueKey(mnemonic[index]),
                      padding: WidgetConstant.padding10,
                      child: Stack(
                        children: [
                          Chip(
                            elevation: 3,
                            padding: WidgetConstant.padding10,
                            backgroundColor: context.colors.primaryContainer,
                            label: Text(mnemonic[index].word ?? ""),
                          ),
                          Badge.count(
                              count: mnemonic[index].readIndex,
                              backgroundColor: context.colors.tertiary,
                              textColor: context.colors.onTertiary)
                        ],
                      ),
                    ),
                  )),
        ),
      ),
    );
  }
}
