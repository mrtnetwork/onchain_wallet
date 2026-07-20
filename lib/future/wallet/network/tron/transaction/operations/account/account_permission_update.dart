import 'dart:async';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/tron/tron.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/widgets/widgets/update_account_permission.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class TronTransactionAccountPermissionUpdateContractOperation
    extends TronTransactionStateController2<AccountPermissionUpdateContract> {
  TronTransactionAccountPermissionUpdateContractOperation(
      {required super.walletProvider, required super.account, required super.address});

  List<TronPermissionBuilder> _permissions = const [];
  List<TronPermissionBuilder> get permissions => _permissions;

  List<TransactionContractType>? _operations;
  List<TransactionContractType>? get operations => _operations;

  late final LiveFormField<TronPermissionBuilder?, TronPermissionBuilder> permission =
      LiveFormField(title: "permissions".tr, value: null, optional: true);

  TronPermissionBuilder _createNewPermission() {
    final List<int> ids = permissions
        .where((element) => element.canUpdateOperations)
        .map((e) => e.permission.id)
        .toList()
        .cast();
    final nextId = StrUtils.findFirstMissingNumber(ids, start: 2);
    return TronPermissionBuilder(AccountPermission(
        keys: [],
        threshold: BigInt.one,
        id: nextId,
        type: PermissionType.active,
        operations: TronUtils.defaultActivePermissionOperation,
        permissionName: "Active permission $nextId"));
  }

  void onUpdatePermission(TronPermissionBuilder? permission) {
    if (permission == null) {
      permission = _createNewPermission();
      permissions.add(permission);
    }
    this.permission.setValue(permission);
    permission.checkError();
    notify();
  }

  void onSavePermission() {
    final permission = this.permission.value;
    if (permission == null) return;
    final updatedPermission = permission.buildPermission();
    if (updatedPermission == null) return;

    this.permission.setValue(null);
    getStateStatus();
    estimateFee();
    notify();
  }

  void onRemovePermission() {
    final permission = this.permission.value;
    if (permission == null || !permission.permission.isActivePermission) return;
    permissions
        .removeWhere((element) => element.permission.id == permission.permission.id);
    this.permission.setValue(null);
    getStateStatus();
    estimateFee();
    notify();
  }

  @override
  Future<ITronTransactionData<AccountPermissionUpdateContract>> buildTransactionData(
      {bool simulate = false}) async {
    final blockData = await transactionBlockRequirment(simulate: simulate);
    final witnessPermission = permissions
        .firstWhereOrNull((element) => element.permission.type == PermissionType.witness);
    final ownerPermission = permissions
        .firstWhere((element) => element.permission.type == PermissionType.owner);
    final activates = permissions
        .where((element) => element.permission.type == PermissionType.active)
        .map((e) => e.buildPermission()!.toPermission())
        .toList();
    return ITronTransactionData(
      fee: txFee.fee,
      blockData: blockData,
      memo: memo.value,
      contract: AccountPermissionUpdateContract(
          ownerAddress: address.networkAddress,
          owner: ownerPermission.buildPermission()!.toPermission(),
          actives: activates,
          witness: witnessPermission?.buildPermission()?.toPermission()),
    );
  }

  @override
  Future<TransactionStateController> cloneController(ITronAddress address) async {
    return TronTransactionAccountPermissionUpdateContractOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return TronTransactionAccountPermissionUpdateContractWidget(form: this);
  }

  @override
  TransactionContractType get transactionType =>
      TransactionContractType.accountPermissionUpdateContract;

  @override
  List<LiveFormField<Object?, Object>> get fields => [permission];

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required TronClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await super.initForm(context: context, client: client, updateAccount: updateAccount);
    _permissions = accountInfo!.permissions
        .map((e) => e.clone())
        .cast<AccountPermission>()
        .map((e) => TronPermissionBuilder(e))
        .toList();
    return this;
  }

  @override
  void dispose() {
    super.dispose();
    for (final i in [..._permissions]) {
      i.dispose();
    }
    _operations = [];
  }
}

class TronPermissionBuilder with DisposableMixin, StreamStateController {
  bool get canUpdateOperations => _permission.operations != null;
  AccountPermission _permission;
  AccountPermission get permission => _permission;
  List<TransactionContractType> _operations;
  List<TransactionContractType> get operations => _operations;
  String? _error;
  String? get error => _error;

  void checkError() {
    _error = validatePermission();
    notify();
  }

  bool get allOperationSelected =>
      _operations.length == TronUtils.supportedOperations.length;

  TronPermissionBuilder(AccountPermission permission)
      : _permission = permission,
        _operations = permission.operations == null
            ? []
            : TronHelper.decodePermissionOperation(permission.operations!);

  void onUpdateOperations(TransactionContractType operation) {
    if (!canUpdateOperations) return;
    if (!operations.remove(operation)) {
      operations.add(operation);
    }
    checkError();
  }

  void onUpdateTheresHold(int? v) {
    final threshHold = BigInt.from(v ?? 1);
    if (permission.threshold == threshHold) {
      return;
    }
    _permission = permission.copyWith(threshold: threshHold);
    checkError();
  }

  void onUpdatePermissionName(String? name) {
    _permission = permission.copyWith(permissionName: name);
    checkError();
  }

  void onTogglePermissions() {
    if (!canUpdateOperations) return;
    if (allOperationSelected) {
      _operations.clear();
    } else {
      _operations = TronUtils.supportedOperations.clone();
    }
    checkError();
  }

  String? validatePermission() {
    if (permission.keys.length > TronUtils.maxPermissionKeyLength) {
      return "tron_signer_validator_desc".tr;
    }
    if (permission.isWitnessPermission &&
        permission.keys.length > TronUtils.maxWitnessPermissionKeyLength) {
      return "tron_signer_validator_witness_desc".tr;
    }
    final sum = permission.keys
        .fold(BigInt.zero, (previousValue, element) => previousValue + element.weight);
    if (sum < permission.threshold) {
      return "tron_permission_threshhold_validator".tr;
    }
    return null;
  }

  String? filterAccount(TronAddress address) {
    final exist =
        permission.keys.firstWhereOrNull((element) => element.address == address);
    if (exist != null) {
      return "signer_already_exist".tr;
    }
    return null;
  }

  void onAddNewSigner(ReceiptAddress<TronAddress>? address) {
    if (address == null) return;
    final exist = permission.keys
        .firstWhereOrNull((element) => element.address == address.networkAddress);
    if (exist != null) {
      return;
    }
    _permission = permission.copyWith(keys: [
      ...permission.keys,
      PermissionKeys(address: address.networkAddress, weight: BigInt.one)
    ]);
    checkError();
  }

  void onRemoveSigner(PermissionKeys? key) {
    if (key == null) return;
    final keys = permission.keys
      ..removeWhere((element) => element.address.toAddress() == key.address.toAddress());
    _permission = permission.copyWith(keys: keys);
    checkError();
  }

  String? _buildOperation() {
    if (canUpdateOperations) {
      return BytesUtils.toHexString(TronHelper.encodePermissionOperations(_operations));
    }
    return null;
  }

  AccountPermission? buildPermission() {
    final String? operations = _buildOperation();
    final error = validatePermission();
    if (error != null) return null;
    return permission.copyWith(operations: operations);
  }

  /// ADD threshold validator for feild
  void updateKeyThereshHold(PermissionKeys? key, int? v) {
    if (key == null) return;
    final weight = BigInt.from(v ?? 1);
    if (key.weight == weight) return;
    final keyIndex = permission.keys
        .indexWhere((element) => element.address.toAddress() == key.address.toAddress());
    permission.keys[keyIndex] = PermissionKeys(address: key.address, weight: weight);
    checkError();
  }
}
