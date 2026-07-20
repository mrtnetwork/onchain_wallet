import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:stellar_dart/stellar_dart.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/types/types.dart';

enum _MemoFieldTypes { text, number, hide }

class CreateStellarMemoView extends StatefulWidget {
  const CreateStellarMemoView({super.key, this.memo});
  final StellarMemoDetils? memo;

  @override
  State<CreateStellarMemoView> createState() => _CreateStellarMemoViewState();
}

class _CreateStellarMemoViewState extends State<CreateStellarMemoView> with SafeState {
  final GlobalKey<FormState> formKey =
      GlobalKey(debugLabel: "_CreateStellarMemoViewState_form");

  String text = '';
  BigInt id = BigInt.zero;

  void onChangeValue(String v) {
    text = v;
  }

  void onChangeMemoId(BigInt v) {
    id = v;
  }

  String? validator(String? v) {
    switch (type) {
      case MemoType.id:
        final num = BigintUtils.tryParse(v);
        final toU64 =
            MethodUtils.fallbackOnException(() => num?.asI64, logOnDebug: false);
        if (toU64 == null) {
          return "enter_stellar_muxed_id_desc".tr;
        }
        return null;
      case MemoType.hash:
      case MemoType.returnHash:
        if (APPConst.hex32Bytes.hasMatch(v ?? '')) {
          return null;
        }
        return "32bytes_hex_validator_desc".tr;
      case MemoType.text:
        if (v == null || v.length <= StellarConst.memoTextMaxLength) {
          return null;
        }
        return "text_max_validator"
            .tr
            .replaceOne(StellarConst.memoTextMaxLength.toString());
      default:
        return null;
    }
  }

  late MemoType type = MemoType.none;
  late _MemoFieldTypes fieldType = _MemoFieldTypes.hide;
  bool get isText => type == MemoType.text;

  late final Map<MemoType, Widget> memoTypesView = {
    for (final i in MemoType.values) i: Text(i.name.camelCase)
  };

  void init() {
    final currentMemo = widget.memo;
    if (currentMemo == null) return;
    type = currentMemo.memo.type;
    updateFeildType();
    if (type == MemoType.id) {
      id = BigInt.parse(currentMemo.val!);
    } else {
      text = currentMemo.val ?? '';
    }
  }

  void updateFeildType() {
    switch (type) {
      case MemoType.id:
        fieldType = _MemoFieldTypes.number;
        break;
      case MemoType.none:
        fieldType = _MemoFieldTypes.hide;
        break;
      default:
        fieldType = _MemoFieldTypes.text;
    }
  }

  void onChangeType(MemoType? type) {
    this.type = type ?? this.type;
    updateFeildType();
    updateState();
  }

  StellarMemo? createMemo() {
    switch (type) {
      case MemoType.id:
        return StellarMemoID(id);
      case MemoType.none:
        return const StellarMemoNone();
      case MemoType.returnHash:
        return StellarMemoReturnHash(BytesUtils.fromHexString(text));
      case MemoType.hash:
        return StellarMemoHash(BytesUtils.fromHexString(text));
      case MemoType.text:
        return StellarMemoText(text);
      default:
        return null;
    }
  }

  void onSetupMemo() {
    if (!formKey.ready()) return;
    final memo = MethodUtils.fallbackOnException(() => createMemo(), logOnDebug: false);
    if (memo == null) return;
    context.pop(memo);
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitleSubtitle(
              title: "stellar_memo".tr,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextAndLinkView(
                      text: "stellar_memo_desc".tr, url: LinkConst.reviewStellarMemos),
                  WidgetConstant.height8,
                  Text("stellar_memo_desc2"
                      .tr
                      .replaceOne(MemoType.none.name.camelCase)
                      .replaceTwo("setup_memo".tr)),
                ],
              )),
          Text("memo_type".tr, style: context.textTheme.titleMedium),
          Text("add_stellar_memo_type_desc".tr),
          WidgetConstant.height8,
          AppDropDownBottom<MemoType>(
            items: memoTypesView,
            value: type,
            onChanged: onChangeType,
            hint: "memo_type".tr,
          ),
          WidgetConstant.height20,
          APPAnimatedSwitcher<_MemoFieldTypes>(enable: fieldType, widgets: {
            _MemoFieldTypes.text: (c) => AppTextField(
                  label: type.name.camelCase,
                  validator: validator,
                  pasteIcon: true,
                  initialValue: text,
                  onChanged: onChangeValue,
                  minlines: 2,
                  maxLines: 4,
                  helperText: isText
                      ? "stellar_memo_text_desc".tr
                      : "32bytes_hex_validator_desc".tr,
                ),
            _MemoFieldTypes.number: (c) => BigNumberTextField(
                  label: 'id'.tr,
                  onChange: onChangeMemoId,
                  validator: validator,
                  defaultValue: id,
                  max: BinaryOps.maxU64,
                  min: BigInt.zero,
                  helperText: "enter_stellar_muxed_id_desc".tr,
                ),
            _MemoFieldTypes.hide: (c) => WidgetConstant.sizedBox
          }),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                padding: WidgetConstant.paddingVertical20,
                onPressed: onSetupMemo,
                child: Text("setup_memo".tr),
              )
            ],
          )
        ],
      ),
    );
  }
}
