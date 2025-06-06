import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:on_chain_wallet/future/wallet/network/forms/core/core.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/wallet/network/forms/cosmos/forms/core/cosmos.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';

class CosmosTransferForm extends CosmosTransactionForm {
  CosmosTransferForm();
  BigInt _callValue = BigInt.zero;
  Map<CW20Token, IntegerBalance> remindTokenAmounts = {};
  CosmosTransactionFeeInfo? _feeInfo;
  @override
  void setFeeToken(CosmosTransactionFeeInfo fee) {
    _feeInfo = fee;
    _checkValue();
  }

  @override
  BigInt get callValue => _callValue;
  void _checkValue() {
    _callValue = destinations.value.fold<BigInt>(BigInt.zero,
        (previousValue, element) => previousValue + element.nativeAmount);
    final tokens = remindTokenAmounts.keys.toList();
    for (final i in tokens) {
      final tokenDestinations = destinations.value.where((e) => e.token == i);
      BigInt amount =
          tokenDestinations.fold(BigInt.zero, (p, c) => p + c.balance.balance);
      if (_feeInfo?.customFeeToken == i) {
        amount += _feeInfo?.feeAmount.balance ?? BigInt.zero;
      }
      remindTokenAmounts[i]!.updateBalance(i.balance.balance - amount);
    }
  }

  final TransactionListFormField<CosmosOutputWithBalance> destinations =
      TransactionListFormField(
          name: "destination",
          optional: false,
          onChangeForm: (p0) {
            return p0;
          });

  void _setReceiver(
      {required ReceiptAddress<CosmosBaseAddress> address,
      required WalletCosmosNetwork network}) {
    destinations
        .addValue(CosmosOutputWithBalance(address: address, network: network));
  }

  void setReceiver(
      {required List<ReceiptAddress<CosmosBaseAddress>>? addresses,
      required WalletCosmosNetwork network}) {
    if (addresses == null || addresses.isEmpty) return;
    for (final i in addresses) {
      _setReceiver(address: i, network: network);
    }
    onChanged?.call();
  }

  void onRemoveReceiver(CosmosOutputWithBalance? address) {
    final r = destinations.removeValue(address);
    if (!r) return;
    _checkValue();
    onChanged?.call();
  }

  void setBalance(CosmosOutputWithBalance destination, BigInt? balance) {
    if (balance == null || !destinations.value.contains(destination)) return;
    destination.updateBalance(balance);
    _checkValue();
    onChanged?.call();
  }

  @override
  String get name => "transfer";

  void setToken(CosmosOutputWithBalance destination, CW20Token? token) {
    if (token == null) return;
    destination.setToken(token, network);
    if (destination.isTokenTransfer) {
      remindTokenAmounts[destination.token!] ??=
          IntegerBalance.zero(token.token);
    }
    _checkValue();
    onChanged?.call();
  }

  @override
  String? validateError({ICosmosAddress? account}) {
    if (destinations.value.isEmpty) {
      return "add_least_one_receipt".tr;
    }
    for (final i in remindTokenAmounts.values) {
      if (i.isNegative) return "insufficient_token_balance".tr;
    }
    for (final i in destinations.value) {
      if (!i.hasAmount) {
        return "the_amount_is_unspecified".tr;
      }
    }

    return null;
  }

  BigInt max(
      {required ICosmosAddress address,
      required BigInt fee,
      required CosmosOutputWithBalance destination}) {
    if (destination.isTokenTransfer) {
      return remindTokenAmounts[destination.token]!.balance +
          destination.balance.balance;
    }

    return (address.address.currencyBalance -
        callValue -
        fee +
        destination.balance.balance);
  }

  @override
  List<ServiceMessage> messages() {
    return destinations.value
        .map((e) => e.toMessage(address.networkAddress, network))
        .toList();
  }

  @override
  void close() {
    _callValue = BigInt.zero;
    remindTokenAmounts.clear();
    _feeInfo = null;
    destinations.clear();
    super.close();
  }

  @override
  CosmosWalletTransaction toWalletTransaction(String txId) {
    final outs = destinations.value;
    final outputs = outs.map((e) => e.toOutput(network)).toList();
    return CosmosWalletTransaction(
        txId: txId,
        time: DateTime.now(),
        outputs: outputs,
        totalOutput: WalletTransactionIntegerAmount(
            amount:
                outs.fold<BigInt>(BigInt.zero, (p, c) => p + c.nativeAmount),
            network: network),
        network: network);
  }
}
