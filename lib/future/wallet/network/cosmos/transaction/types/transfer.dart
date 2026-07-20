import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:cosmos_sdk/proto_messages/cosmos/base/v1beta1/models.dart';
import 'package:cosmos_sdk/proto_messages/ibc/applications/transfer/v1/src/tx.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/operations/ibc.dart';
import 'package:on_chain_wallet/wallet/constant/networks/cosmos.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/networks/cosmos/models/network_types.dart';
import 'package:on_chain_wallet/wallet/models/others/models/receipt_address.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/cw20.dart';
import 'package:cosmos_sdk/proto_messages/thorchain/types/src/msg_send.dart'
    as thorchain_tx;
import 'package:cosmos_sdk/proto_messages/cosmos/bank/v1beta1/src/tx.dart' as cosmos_tx;

class CosmosTransferDetails with DisposableMixin, StreamStateController {
  CW20Token _token;
  CW20Token get token => _token;
  IntegerBalance _amount;
  IntegerBalance get amount => _amount;
  final ReceiptAddress<CosmosBaseAddress> recipient;
  bool get hasAmount => amount.largerThanZero;
  bool get isReady => hasAmount;
  CosmosTransferDetails({
    // required IntegerBalance amount,
    required this.recipient,
    required CW20Token token,
    required StreamValue<IntegerBalance> balance,
  })  : _amount = IntegerBalance.zero(token.token, allowNegative: false),
        _token = token;

  void onUpdateBalance(BigInt amount) {
    assert(!amount.isNegative, "Invalid transfer amount.");
    if (amount.isNegative) return;
    this.amount.updateBalance(amount);
    notify();
  }

  void onUpdateToken(CW20Token token) {
    if (token == _token) return;
    _token = token;
    _amount = IntegerBalance.zero(token.token, allowNegative: false);
    notify();
  }

  ICosmosProtoServiceMessage toMessage(
      CosmosBaseAddress from, WalletCosmosNetwork network) {
    final amount = "${this.amount.balance}";
    if (network.coinParam.networkType != CosmosNetworkTypes.thorAndForked) {
      return cosmos_tx.MsgSend(
          fromAddress: from.address,
          toAddress: recipient.networkAddress.address,
          amount: [Coin(amount: amount, denom: token.denom)]);
    }
    return thorchain_tx.MsgSend(
        fromAddress: from.toBytes(),
        toAddress: recipient.networkAddress.toBytes(),
        amount: [Coin(amount: amount, denom: token.denom)]);
  }
}

class CosmosIbcTransferForm with DisposableMixin, StreamStateController {
  final StreamValue<TransactionStateStatus> stateStatus =
      StreamValue(TransactionStateStatus.error(), name: "CosmosIbcTransferForm");
  final CosmosTransactionIbcTransferOperation controller;
  List<CosmosChain> get destinationChains => controller.ibcDestinationChains;
  final _ibcChannelRegex = RegExp(CosmosConst.ibcChannelRegex);

  final LiveFormField<CosmosChain?, CosmosChain> destinationChain =
      LiveFormField(title: 'destination_chain'.tr, value: null);

  final LiveFormField<DateTime, DateTime> timeout = LiveFormField(
    title: 'transaction_timeout'.tr,
    value: DateTime.now().toLocal().add(const Duration(minutes: 30)),
  );

  late final LiveFormField<IntegerBalance, IntegerBalance> amount = LiveFormField(
    title: 'amount'.tr,
    value: IntegerBalance.zero(controller.network.token, allowNegative: false),
    onValidateError: (field, value) {
      if (value.largerThanZero) return null;
      return "field_is_required".tr.replaceOne(field.title.tr);
    },
  );

  final LiveFormField<ReceiptAddress<CosmosBaseAddress>?,
          ReceiptAddress<CosmosBaseAddress>> recipient =
      LiveFormField(title: 'recipient'.tr, value: null);

  final LiveFormField<String?, String?> memo =
      LiveFormField(title: "setup_memo".tr, value: null, optional: true);
  final LiveFormField<String?, String> channelId =
      LiveFormField(title: "channel_id".tr, subtitle: "ibc_channel_desc".tr, value: null);
  late final LiveFormField<CW20Token, CW20Token> token = LiveFormField(
      title: "transfer_token".tr,
      subtitle: "select_token_for_transfer".tr,
      value: controller.nativeToken);

  CosmosIbcTransferForm._({required this.controller});
  factory CosmosIbcTransferForm(
      {required CosmosTransactionIbcTransferOperation controller}) {
    return CosmosIbcTransferForm._(controller: controller);
  }

  BigInt _getMaxInput() {
    final token = controller.tokens.firstWhereOrNull((e) => e == this.token.value);
    if (token == null) return BigInt.zero;
    final total = controller.transfers.value
        .where((e) => e.transfer.token == token)
        .fold<BigInt>(BigInt.zero, (p, c) => p + c.transfer.amount.balance);
    BigInt remain = token.balance.balance - total;
    if (token.denom == controller.txFee.denom) {
      remain - controller.txFee.fee.fee.balance;
    }
    return remain;
  }

  BigInt getMaxInput() {
    final remain = _getMaxInput();
    if (remain.isNegative) return BigInt.zero;
    return remain;
  }

  TransactionStateStatus getStateStatus() {
    for (final i in fields) {
      final err = i.validate;
      if (err != null) {
        return TransactionStateStatus.error();
      }
    }
    if (timeout.value.isBefore(DateTime.now())) {
      return TransactionStateStatus.error(error: "transaction_expired".tr);
    }

    final remain = _getMaxInput();
    if (remain.isNegative) {
      return TransactionStateStatus.insufficient(
          IntegerBalance.token(remain, token.value.token));
    }
    return TransactionStateStatus.ready();
  }

  void onStateUpdated() {
    final status = getStateStatus();
    stateStatus.value = status;
  }

  void onUpdateDestinationChain(CosmosChain? chain) {
    if (chain == null) return;
    destinationChain.setValue(chain);
    onStateUpdated();
  }

  void onUpdateMemo(String? memo) {
    if (memo == null) return;
    this.memo.setValue(memo);
    onStateUpdated();
  }

  void onRemoveMemo() {
    memo.setValue(null);
    onStateUpdated();
  }

  void onUpdateChannelId(String? channelId) {
    if (channelId == null || !_ibcChannelRegex.hasMatch(channelId)) return;
    this.channelId.setValue(channelId);
    onStateUpdated();
  }

  void onUpdateTimeOut(TimeOfDay? timeout) {
    if (timeout == null) return;
    DateTime dateTime = DateTime.now();
    if (timeout.isBefore(DateTime.now().toLocal().timeOfDay())) {
      dateTime = DateTime.now().toLocal().add(const Duration(days: 1));
    }
    dateTime = dateTime.copyWith(hour: timeout.hour, minute: timeout.minute);
    if (dateTime.isBefore(DateTime.now())) return;
    this.timeout.setValue(dateTime);
    onStateUpdated();
  }

  void onUpdateAmount(BigInt amount) {
    this.amount.value.updateBalance(amount);
    this.amount.notify();
    onStateUpdated();
  }

  void onUpdateTransferToken(CW20Token? token) {
    if (token == null || token.denom == this.token.value.denom) {
      return;
    }
    this.token.setValue(token);
    amount.setValue(IntegerBalance.zero(token.token, allowNegative: false));
    onStateUpdated();
  }

  void onUpdateRecipient(ReceiptAddress<CosmosBaseAddress>? address) {
    if (address == null || address.networkAddress == recipient.value?.networkAddress) {
      return;
    }
    recipient.setValue(address);
    onStateUpdated();
  }

  CosmosIbcTransfer toMessage() {
    return CosmosIbcTransfer(
        chain: destinationChain.output,
        amount: IntegerBalance.token(amount.output.balance, amount.output.token,
            immutable: true),
        address: recipient.output,
        token: token.output,
        channelId: channelId.output,
        memo: memo.output,
        timeout: timeout.output);
  }

  @override
  void dispose() {
    super.dispose();
    for (final i in fields) {
      i.dispose();
    }
  }

  List<LiveFormField> get fields =>
      [destinationChain, timeout, amount, recipient, memo, channelId, token];
}

class CosmosIbcTransfer {
  final CosmosChain chain;
  final IntegerBalance amount;
  final ReceiptAddress<CosmosBaseAddress> address;
  final CW20Token token;
  final String channelId;
  final String? memo;
  final DateTime timeout;
  CosmosIbcTransfer(
      {required this.chain,
      required this.amount,
      required this.address,
      required this.token,
      required this.channelId,
      required this.memo,
      required this.timeout});

  ICosmosProtoServiceMessage toMessage(
      CosmosBaseAddress from, WalletCosmosNetwork network) {
    BigInt timeout = BigInt.from(this.timeout.millisecondsSinceEpoch);
    timeout = timeout * BigInt.from(1000000);
    return MsgTransfer(
        token: Coin(amount: "${amount.balance}", denom: token.denom),
        memo: memo,
        receiver: address.networkAddress.address,
        sender: from.address,
        sourceChannel: channelId,
        sourcePort: CosmosConst.transferIbcPort,
        timeoutTimestamp: timeout);
  }
}

class CosmosIbcTransferData {
  final CosmosIbcTransferForm form;
  final CosmosIbcTransfer transfer;
  const CosmosIbcTransferData({required this.form, required this.transfer});
}
