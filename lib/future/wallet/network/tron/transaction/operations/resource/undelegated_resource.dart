import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/widgets/widgets/undelegate_resource.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class TronTransactionUnDelegateResourceContractOperation
    extends TronTransactionStateController2<UnDelegateResourceContract> {
  List<TransactionResourceRequirementTronDelegatedResource> _resourceAddresses = [];
  List<TransactionResourceRequirementTronDelegatedResource> get resourceAddresses =>
      _resourceAddresses;
  final LiveFormField<TransactionResourceRequirementTronDelegatedResource?,
          TransactionResourceRequirementTronDelegatedResource> resourceInf0 =
      LiveFormField(title: "resource_receiver_address".tr, value: null, optional: false);

  DelegateResourceDetailsCore? _selectedResource;
  DelegateResourceDetailsCore? get selectedResource => _selectedResource;
  TronTransactionUnDelegateResourceContractOperation(
      {required super.walletProvider, required super.account, required super.address});

  late final LiveFormField<IntegerBalance, IntegerBalance> balance = LiveFormField(
    title: "balance".tr,
    subtitle: "undelegated_balance_desc".tr,
    value: IntegerBalance.zero(network.token, allowNegative: false),
    optional: false,
    onValidateError: (field, value) {
      if (value.largerThanZero) return null;
      return "field_is_required".tr.replaceOne(field.title.tr);
    },
  );

  void onUpdateBalance(BigInt amount) {
    balance.value.updateBalance(amount);
    balance.notify();
    onStateUpdated();
    estimateFee();
  }

  void onUpdateDelegateResource(DelegateResourceDetailsCore? resource) {
    if (resource == null || !resource.canUnDelegated) return;
    _selectedResource = resource;
    resourceInf0.notify();
  }

  void onUpdateResource(TransactionResourceRequirementTronDelegatedResource? resource) {
    if (resource == null || resource == resourceInf0.value) return;
    _selectedResource = null;
    balance.value.updateBalance(BigInt.zero);
    resourceInf0.setValue(resource);
    fetchAccountDelegateInfo(resource);
    onStateUpdated();
    estimateFee();
  }

  Future<void> fetchAccountDelegateInfo(
      TransactionResourceRequirementTronDelegatedResource to) async {
    await to.lock.run(() async {
      if (!to.status.canRetry || to.closed) return;
      to.setPendig();
      final result = await IResult.call(() async {
        return await getDelegatedResourceInfo(
            address.networkAddress, to.address.networkAddress);
      });
      if (to.closed) return;
      if (result.isErr) {
        to.setError(error: result.unwrapErr().localizationError);
      } else {
        to.setResource(result.unwrap());
      }
    });
  }

  @override
  Future<ITronTransactionData<UnDelegateResourceContract>> buildTransactionData(
      {bool simulate = false}) async {
    final blockData = await transactionBlockRequirment(simulate: simulate);
    return ITronTransactionData(
      fee: txFee.fee,
      blockData: blockData,
      memo: memo.value,
      contract: UnDelegateResourceContract(
          ownerAddress: address.networkAddress,
          receiverAddress: resourceInf0.value!.address.networkAddress,
          balance: balance.value.balance,
          resource: _selectedResource!.resource),
    );
  }

  @override
  Future<TransactionStateController> cloneController(ITronAddress address) async {
    return TronTransactionUnDelegateResourceContractOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return TronTransactionUnDelegateResourceContractWidget(form: this);
  }

  @override
  TransactionContractType get transactionType =>
      TransactionContractType.unDelegateResourceContract;

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required TronClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await super.initForm(context: context, client: client, updateAccount: updateAccount);
    // walletProvider.wallet.currentChain
    final delegated = await client.getDelegatedResourceAddresses(address);
    _resourceAddresses = delegated
        .map((e) => TransactionResourceRequirementTronDelegatedResource(
            account.getOrCreateReceiptFromNetworkAddressSync(address: TronAddress(e))))
        .toList();
    if (_resourceAddresses.isEmpty) {
      throw AppException("no_delegated_resources_found");
    }
    final resource = _resourceAddresses.first;
    resourceInf0.setValue(resource);
    fetchAccountDelegateInfo(resource);
    return this;
  }

  @override
  List<LiveFormField<Object?, Object>> get fields => [balance];

  @override
  void dispose() {
    super.dispose();
    resourceInf0.dispose();
    for (final i in _resourceAddresses) {
      i.dispose();
    }
  }
}
