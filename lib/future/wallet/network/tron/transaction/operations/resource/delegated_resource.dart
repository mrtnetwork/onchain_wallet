import 'dart:async';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/crypto/networks/tron/tron.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/widgets/widgets/delegate_resource.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class TronTransactionDelegateResourceContractOperation
    extends TronTransactionStateController2<DelegateResourceContract> {
  MaxDelegatedResourceAmount? _bandWidthResource;
  MaxDelegatedResourceAmount? _energy;
  MaxDelegatedResourceAmount get bandWidthResource => _bandWidthResource!;
  MaxDelegatedResourceAmount get energy => _energy!;
  MaxDelegatedResourceAmount? _maxResourceBalance;
  MaxDelegatedResourceAmount get maxResourceBalance => _maxResourceBalance!;

  TronTransactionDelegateResourceContractOperation(
      {required super.walletProvider, required super.account, required super.address});

  late final LiveFormField<IntegerBalance, IntegerBalance> amount = LiveFormField(
      title: "amount".tr,
      subtitle: "resource_delegated_amount".tr,
      value: IntegerBalance.zero(network.token, allowNegative: false),
      optional: false,
      onValidateError: (field, value) {
        if (value.largerThanZero) return null;
        return "";
      });

  final LiveFormField<ResourceCode, ResourceCode> resource = LiveFormField(
      title: "resource".tr,
      subtitle: "trx_stake_type".tr,
      value: ResourceCode.bandWidth,
      optional: false);
  final LiveFormField<ReceiptAddress<TronAddress>?, ReceiptAddress<TronAddress>>
      destination = LiveFormField(
          title: "receiver_address".tr,
          subtitle: "resource_receiver_address".tr,
          value: null,
          optional: false);

  final LiveFormField<bool, bool> lockResource = LiveFormField(
      title: "lock".tr,
      subtitle: "tron_delegate_resource_lock_desc".tr,
      value: false,
      optional: false);

  final LiveFormField<BigRational?, BigRational> lockPeriod = LiveFormField(
    title: "lock_period".tr,
    subtitle: "tron_delegate_lock_time_desc".tr,
    value: TronUtils.defaultDelegateLockPeriod,
    optional: false,
    onUpdateValue: (previous, current) {
      if (current == null) return true;
      if (current.isNegative || current.isZero || current.isDecimal) {
        return false;
      }
      if (current > TronUtils.maxDelegatedLockPeriod) {
        return false;
      }
      return true;
    },
  );
  void onUpdateLockPeriod(BigRational? lockPeriod) {
    this.lockPeriod.setValue(lockPeriod);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateLock(bool lock) {
    lockResource.setValue(lock);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateResource(ResourceCode? resource) {
    if (resource == null) return;
    this.resource.setValue(resource);
    _maxResourceBalance =
        this.resource.value == ResourceCode.bandWidth ? bandWidthResource : energy;
    onUpdateAmount(BigInt.zero);
  }

  void onUpdateAmount(BigInt amount) {
    this.amount.value.updateBalance(amount);
    this.amount.notify();
    onStateUpdated();
    estimateFee();
  }

  void onUpdateDestination(ReceiptAddress<TronAddress>? address) {
    if (address == null) return;
    destination.setValue(address);
    onStateUpdated();
    estimateFee();
  }

  @override
  Future<ITronTransactionData<DelegateResourceContract>> buildTransactionData(
      {bool simulate = false}) async {
    final blockData = await transactionBlockRequirment(simulate: simulate);
    BigInt? lockTime;
    if (lockResource.value == true) {
      if (lockPeriod.value != null &&
          lockPeriod.value != TronUtils.defaultDelegateLockPeriod) {
        lockTime = lockPeriod.value?.toBigInt();
      }
    }
    return ITronTransactionData(
      fee: txFee.fee,
      blockData: blockData,
      memo: memo.value,
      contract: DelegateResourceContract(
          ownerAddress: address.networkAddress,
          receiverAddress: destination.value!.networkAddress,
          balance: amount.value.balance,
          resource: resource.value,
          lock: lockResource.value == true ? true : null,
          lockPeriod: lockTime),
    );
  }

  @override
  Future<TransactionStateController> cloneController(ITronAddress address) async {
    return TronTransactionDelegateResourceContractOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return TronTransactionDelegateResourceContractWidget(form: this);
  }

  @override
  TransactionContractType get transactionType =>
      TransactionContractType.delegateResourceContract;

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required TronClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await super.initForm(context: context, client: client, updateAccount: updateAccount);
    final delegated = await getMaxDelegatedEnergyAndBandwidth(address);
    _energy = delegated.$1;
    _bandWidthResource = delegated.$2;
    _maxResourceBalance =
        resource.value == ResourceCode.bandWidth ? bandWidthResource : energy;
    return this;
  }

  @override
  List<LiveFormField<Object?, Object>> get fields =>
      [amount, destination, resource, lockPeriod, lockResource];
}
