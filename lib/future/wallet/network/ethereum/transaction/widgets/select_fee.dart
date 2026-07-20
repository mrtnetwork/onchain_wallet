import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/text_field/input_formaters.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/crypto/networks/ethereum/utils.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class EthereumGasOptionsView extends StatelessWidget {
  const EthereumGasOptionsView({super.key, required this.fee});
  final EthereumTransactionFeeData fee;

  @override
  Widget build(BuildContext context) {
    return switch (fee.mode) {
      EthereumFeeMode.legacy => _LegacyCustomGasOptionsView(fee: fee),
      EthereumFeeMode.eip1559 => _EIP1559CustomGasOptionsView(fee: fee)
    };
  }
}

class _EIP1559CustomGasOptionsView extends StatefulWidget {
  const _EIP1559CustomGasOptionsView({required this.fee});
  final EthereumTransactionFeeData fee;

  @override
  State<_EIP1559CustomGasOptionsView> createState() =>
      _EIP1559CustomGasOptionsViewState();
}

class _EIP1559CustomGasOptionsViewState extends State<_EIP1559CustomGasOptionsView>
    with SafeState {
  final GlobalKey<FormState> formKey = GlobalKey();
  late EthereumTransactionFee initialFee = widget.fee.fees.firstWhere(
    (e) => e.type == TxFeeTypes.manually,
    orElse: () =>
        EthereumTransactionFee.init(mode: widget.fee.mode, feeToken: widget.fee.feeToken),
  );
  BigRational initialMaxFee = BigRational.zero;
  BigRational initialMaxPriority = BigRational.zero;
  int initialGasLimit = EthereumUtils.baseGasLimit;
  int minGasLimit = EthereumUtils.baseGasLimit;

  BigRational? priorityFee;
  BigRational? maxGasFee;
  int? gasLimit;

  String? gasLimitHelper;
  String? gasPriceHelper;
  String? gasProrityHelper;
  void onChangeGasLimit(String v) {
    final valid = validateGasLimit(v);
    if (valid != null) {
      gasLimit = null;
      return;
    }
    final val = int.parse(v);
    if (val < minGasLimit) {
      gasLimitHelper = "gas_limit_helper".tr;
    } else {
      gasLimitHelper = null;
    }
    gasLimit = val;
    onChangeFee();
  }

  void onChangeGasPrice(String v) {
    final valid = validatorBaseGass(v);
    if (valid != null) {
      maxGasFee = null;
      return;
    }
    final val = BigRational.parseDecimal(v);
    if (val < lowMaxFee) {
      gasPriceHelper = "max_base_fee_helper1".tr;
    } else if (highMaxFee != null && val > highMaxFee!) {
      gasPriceHelper = "max_base_fee_helper2".tr;
    } else {
      gasPriceHelper = null;
    }
    maxGasFee = val;
    onChangeFee();
  }

  void onChangeProrityFee(String v) {
    final valid = validateProrityFee(v);
    if (valid != null) {
      priorityFee = null;
      return;
    }
    final val = BigRational.parseDecimal(v);

    if (val < lowProrityFee) {
      gasProrityHelper = "max_priority_helper1".tr;
    } else if (highProrityFee != null && val > highProrityFee!) {
      gasProrityHelper = "max_priority_helper2".tr;
    } else {
      gasProrityHelper = null;
    }
    priorityFee = val;
    onChangeFee();
  }

  String? validateGasLimit(String? v) {
    final val = int.tryParse(v ?? "");
    if (val == null || val <= 0) {
      return "gas_limit_validator".tr;
    }
    return null;
  }

  String? validateProrityFee(String? v) {
    final val = BigRational.tryParse(v ?? "");

    if (val?.isNegative ?? true) {
      return "prority_fee_validator".tr;
    }
    return null;
  }

  String? validatorBaseGass(String? v) {
    final val = BigRational.tryParse(v ?? "");
    if (val?.isNegative ?? true) {
      return "max_base_fee_validator".tr;
    }
    return null;
  }

  void onChangeFee() {
    try {
      final maxPriorityFeePerGas = priorityFee == null
          ? initialFee.maxPriorityFeePerGas
          : EthereumUtils.gWeiDeciamlToWei(priorityFee!);
      if (maxPriorityFeePerGas == null) return;
      final maxBaseFee = maxGasFee == null
          ? initialFee.maxFeePerGas
          : EthereumUtils.gWeiDeciamlToWei(maxGasFee!);
      if (maxBaseFee == null) return;
      initialFee = EthereumTransactionFee.eip1559(
          gasLimit: gasLimit ?? initialGasLimit,
          maxPriorityFeePerGas: maxPriorityFeePerGas,
          baseFee: maxBaseFee,
          feeToken: widget.fee.feeToken,
          maxFeePerGas: maxBaseFee,
          type: TxFeeTypes.manually);
    } finally {
      updateState();
    }
  }

  void setupFee() {
    if (!formKey.ready()) return;
    widget.fee.setManualFee(initialFee);
    context.showAlert("transaction_fee_has_been_updated".tr);
    context.pop();
  }

  /// low
  BigRational lowMaxFee = BigRational.zero;
  BigRational lowProrityFee = BigRational.zero;

  /// hight
  BigRational? highMaxFee;
  BigRational? highProrityFee;

  @override
  void onInitOnce() {
    super.onInitOnce();
    EthereumTransactionFee? initialFee =
        widget.fee.fees.firstWhereOrNull((e) => e.type == TxFeeTypes.manually);
    final normalFee =
        widget.fee.fees.firstWhereOrNull((e) => e.type == TxFeeTypes.normal);
    if (normalFee != null) {
      minGasLimit = normalFee.gasLimit;
    }
    initialFee ??= normalFee;
    if (initialFee != null) {
      initialMaxFee = EthereumUtils.weiToGwei(initialFee.maxFeePerGas!);
      initialMaxPriority = EthereumUtils.weiToGwei(initialFee.maxPriorityFeePerGas!);
      initialGasLimit = initialFee.gasLimit;
    }
    final min = widget.fee.fees.firstWhereOrNull((e) => e.type == TxFeeTypes.slow);
    if (min != null) {
      lowMaxFee = EthereumUtils.weiToGwei(min.maxFeePerGas!);
      lowProrityFee = EthereumUtils.weiToGwei(min.maxPriorityFeePerGas!);
    }
    final max = widget.fee.fees.firstWhereOrNull((e) => e.type == TxFeeTypes.high);
    if (max != null) {
      highMaxFee = EthereumUtils.weiToGwei(max.maxFeePerGas!);
      highProrityFee = EthereumUtils.weiToGwei(max.maxPriorityFeePerGas!);
    }
  }

  ///

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitleSubtitle(title: "eip_1559_gas_fee".tr, body: Text("eth_fee_desc".tr)),
          Text("transaction_fee".tr),
          WidgetConstant.height8,
          ContainerWithBorder(
            onRemoveWidget: WidgetConstant.sizedBox,
            onRemove: () {},
            child: CoinAndMarketPriceView(
                balance: initialFee.fee, style: context.textTheme.titleLarge),
          ),
          WidgetConstant.height20,
          Text("max_base_fee".tr, style: context.textTheme.titleMedium),
          Text("what_is_max_fee".tr, style: context.textTheme.bodyMedium),
          WidgetConstant.height8,
          AppTextField(
            label: "max_base_fee".tr,
            minlines: 1,
            maxLines: 2,
            initialValue: initialMaxFee.toDecimal(),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true, signed: false),
            inputFormatters: [
              BigRetionalTextInputFormatter(
                  max: null, allowDecimal: true, allowSign: false),
            ],
            textAlign: TextAlign.center,
            validator: validatorBaseGass,
            onChanged: onChangeGasPrice,
            helperText: gasPriceHelper,
            helperStyle:
                context.textTheme.bodyMedium?.copyWith(color: context.colors.orange),
            suffixIcon: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: WidgetConstant.padding20,
                  child: Text(
                    "gwei".tr,
                    style: context.textTheme.labelLarge?.copyWith(
                        color: context.colors.primary, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          WidgetConstant.height20,
          Text("max_priority".tr, style: context.textTheme.titleMedium),
          Text("what_is_prority_fee".tr, style: context.textTheme.bodyMedium),
          WidgetConstant.height8,
          AppTextField(
            label: "max_priority".tr,
            minlines: 1,
            maxLines: 2,
            initialValue: initialMaxPriority.toDecimal(),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true, signed: false),
            inputFormatters: [
              BigRetionalTextInputFormatter(
                  max: null, allowDecimal: true, allowSign: false),
            ],
            textAlign: TextAlign.center,
            validator: validateProrityFee,
            onChanged: onChangeProrityFee,
            helperText: gasProrityHelper,
            helperStyle:
                context.textTheme.bodyMedium?.copyWith(color: context.colors.orange),
            suffixIcon: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: WidgetConstant.padding20,
                  child: Text(
                    "gwei".tr,
                    style: context.textTheme.labelLarge?.copyWith(
                        color: context.colors.primary, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          WidgetConstant.height20,
          Text("gas_limit".tr, style: context.textTheme.titleMedium),
          Text("gas_limit_desc".tr),
          WidgetConstant.height8,
          AppTextField(
            label: "gas_limit".tr,
            minlines: 1,
            helperStyle:
                context.textTheme.bodyMedium?.copyWith(color: context.colors.orange),
            maxLines: 2,
            initialValue: initialGasLimit.toString(),
            validator: validateGasLimit,
            onChanged: onChangeGasLimit,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true, signed: false),
            helperText: gasLimitHelper,
            inputFormatters: [
              BigRetionalTextInputFormatter(
                  max: null, allowDecimal: false, allowSign: false),
            ],
            textAlign: TextAlign.center,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                padding: WidgetConstant.paddingVertical20,
                onPressed: setupFee,
                child: Text("setup_custom_fee".tr),
              )
            ],
          )
        ],
      ),
    );
  }
}

class _LegacyCustomGasOptionsView extends StatefulWidget {
  const _LegacyCustomGasOptionsView({required this.fee});
  final EthereumTransactionFeeData fee;

  @override
  State<_LegacyCustomGasOptionsView> createState() =>
      __ETHLegacyCustomGasViewSelectViewState();
}

class __ETHLegacyCustomGasViewSelectViewState extends State<_LegacyCustomGasOptionsView>
    with SafeState<_LegacyCustomGasOptionsView> {
  final GlobalKey<FormState> formKey = GlobalKey();
  late EthereumTransactionFee initialFee = widget.fee.fees.firstWhere(
    (e) => e.type == TxFeeTypes.manually,
    orElse: () =>
        EthereumTransactionFee.init(mode: widget.fee.mode, feeToken: widget.fee.feeToken),
  );
  BigRational initialGasPrice = BigRational.zero;
  int initialGasLimit = EthereumUtils.baseGasLimit;
  int minGasLimit = EthereumUtils.baseGasLimit;

  BigRational? gasPrice;
  int? gasLimit;

  ///
  String? gasLimitHelper;
  String? gasPriceHelper;
  String? gasProrityHelper;
  void onChangeGasLimit(String v) {
    final valid = validateGasLimit(v);
    if (valid != null) {
      gasLimit = null;
      return;
    }
    final val = int.parse(v);
    if (val < minGasLimit) {
      gasLimitHelper = "gas_limit_helper".tr;
    } else {
      gasLimitHelper = null;
    }
    gasLimit = val;
    onChangeFee();
  }

  void onChangeGasPrice(String v) {
    final valid = validatorBaseGass(v);
    if (valid != null) {
      gasPrice = null;
      return;
    }
    final val = BigRational.parseDecimal(v);
    if (val < lowGasPrice) {
      gasPriceHelper = "gas_price_fee_helper1".tr;
    } else if (val > hightGasPrice) {
      gasPriceHelper = "gas_price_fee_helper2".tr;
    } else {
      gasPriceHelper = null;
    }
    gasPrice = val;
    onChangeFee();
  }

  String? validateGasLimit(String? v) {
    final val = int.tryParse(v ?? "");
    if (val == null || val <= 0) {
      return "gas_limit_validator".tr;
    }
    return null;
  }

  String? validatorBaseGass(String? v) {
    final val = BigRational.tryParse(v ?? "");
    if (val?.isNegative ?? true) {
      return "gas_price_fee_validator".tr;
    }
    return null;
  }

  void onChangeFee() {
    try {
      final gPrice = gasPrice == null
          ? initialFee.gasPrice
          : EthereumUtils.gWeiDeciamlToWei(gasPrice!);
      if (gPrice == null) return;
      initialFee = EthereumTransactionFee.legacy(
          feeToken: widget.fee.feeToken,
          gasLimit: gasLimit ?? initialGasLimit,
          gasPrice: gPrice,
          type: TxFeeTypes.manually);
    } finally {
      updateState();
    }
  }

  void setupFee() {
    if (!formKey.ready()) return;
    widget.fee.setManualFee(initialFee);
    context.showAlert("transaction_fee_has_been_updated".tr);
    context.pop();
  }

  BigRational lowGasPrice = BigRational.zero;
  BigRational hightGasPrice = BigRational.zero;

  @override
  void onInitOnce() {
    super.onInitOnce();
    EthereumTransactionFee? initialFee =
        widget.fee.fees.firstWhereOrNull((e) => e.type == TxFeeTypes.manually);
    final normalFee =
        widget.fee.fees.firstWhereOrNull((e) => e.type == TxFeeTypes.normal);
    if (normalFee != null) {
      minGasLimit = normalFee.gasLimit;
    }
    initialFee ??= normalFee;
    if (initialFee != null) {
      initialGasPrice = EthereumUtils.weiToGwei(initialFee.gasPrice!);
      initialGasLimit = initialFee.gasLimit;
    }
    final normal = widget.fee.fees.firstWhereOrNull((e) => e.type == TxFeeTypes.normal);
    if (normal != null) {
      lowGasPrice = EthereumUtils.weiToGwei(normal.gasPrice!);
      hightGasPrice = EthereumUtils.weiToGwei(normal.gasPrice!);
    }
  }

  ///

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitleSubtitle(
              title: "legacy_gas_fee".tr, body: Text("eth_legacy_fee_desc".tr)),
          Text("transaction_fee".tr),
          WidgetConstant.height8,
          ContainerWithBorder(
            onRemoveWidget: WidgetConstant.sizedBox,
            onRemove: () {},
            child: CoinAndMarketPriceView(
                balance: initialFee.fee, style: context.textTheme.titleLarge),
          ),
          WidgetConstant.height20,
          Text("gas_price".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          AppTextField(
            label: "gas_price".tr,
            minlines: 1,
            maxLines: 2,
            initialValue: initialGasPrice.toDecimal(),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true, signed: false),
            inputFormatters: [
              BigRetionalTextInputFormatter(
                  max: null, allowSign: false, allowDecimal: true),
            ],
            textAlign: TextAlign.center,
            validator: validatorBaseGass,
            onChanged: onChangeGasPrice,
            helperText: gasPriceHelper,
            helperStyle:
                context.textTheme.bodyMedium?.copyWith(color: context.colors.orange),
            suffixIcon: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: WidgetConstant.padding20,
                  child: Text(
                    "gwei".tr,
                    style: context.textTheme.labelLarge?.copyWith(
                        color: context.colors.primary, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          WidgetConstant.height20,
          Text("gas_limit".tr, style: context.textTheme.titleMedium),
          Text("gas_limit_desc".tr),
          WidgetConstant.height8,
          AppTextField(
            label: "gas_limit".tr,
            minlines: 1,
            helperStyle:
                context.textTheme.bodyMedium?.copyWith(color: context.colors.orange),
            maxLines: 2,
            initialValue: initialGasLimit.toString(),
            validator: validateGasLimit,
            onChanged: onChangeGasLimit,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true, signed: false),
            helperText: gasLimitHelper,
            inputFormatters: [
              BigRetionalTextInputFormatter(
                max: null,
                allowSign: false,
                allowDecimal: false,
              ),
            ],
            textAlign: TextAlign.center,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                padding: WidgetConstant.paddingVertical20,
                onPressed: setupFee,
                child: Text("setup_custom_fee".tr),
              )
            ],
          )
        ],
      ),
    );
  }
}
