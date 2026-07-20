import 'dart:async';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/dev/src/logger.dart' show Logging;
import 'package:on_chain_wallet/app/core.dart';

import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/monero/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/constant/networks/monero.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/networks/monero/monero.dart';

///  final remain = MoneroConst.ringSize - totalSelected + _selectedUtxos.length;
mixin MoneroTransactionUtxosController on DisposableMixin {
  WalletMoneroNetwork get network;
  WalletProvider get walletProvider;
  final Cancelable _cancelable = Cancelable();
  MoneroChain get account;
  MoneroSyncing? _syncing;
  bool _unsyncedAlert = false;
  bool get unsyncedAlert => _unsyncedAlert;
  late final StreamValue<List<MoneroAccountFetchedUtxos>> accountUtxos = StreamValue(
      account.addresses.map((e) => MoneroAccountFetchedUtxos(address: e)).toList(),
      name: 'MoneroTransactionUtxosController');
  void onSelectedUtxosChanged(List<MoneroUtxoWithBalanceInfo> utxos);
  bool get hasUtxos => totalUtxos.value.largerThanZero;
  bool _allSelected = false;
  bool _allowSelectUtxos = true;
  bool get allowSelectUtxos => _allSelected;
  bool get allUtxosSelected => _allSelected;
  StreamSubscription<MoneroChainNotify>? _syncingSubscribition;
  final _lock = SafeAtomicLock();

  late final LiveFormField<IntegerBalance, IntegerBalance> totalUtxos = LiveFormField(
      title: "spendable_amount".tr,
      subtitle: "total_selected_amount".tr,
      value: IntegerBalance.zero(network.token),
      optional: false);

  void _onSyncingEvent(MoneroSyncing syncing, MoneroChainNotify event) {
    Logging.debug(
        fn: () => AppLogData(
            runtime: runtimeType,
            function: "_onSyncingEvent",
            msg: "On syncing event: ${event.name} blockHeight: ${syncing.latestHeight}"));
    switch (event) {
      case MoneroChainNotify.blockHeightUpdated:
        _checkUnsyncingStatus();
        _onHeightUpdated();
        _onAccountUtxoChanged();
        break;
      case MoneroChainNotify.trackerAccountChanged:
        _checkUnsyncingStatus();
        break;
      case MoneroChainNotify.accountUtxosChanged:
        _onAccountUtxoChanged();
        break;
      default:
        break;
    }
  }

  Future<void> initAccountUtxos({
    required List<IMoneroAddress> addresses,
    required MoneroSyncing syncing,
    required int latestHeight,
  }) async {
    _syncing = syncing;
    _checkUnsyncingStatus(latestHeight: latestHeight);
    accountUtxos.value =
        addresses.map((e) => MoneroAccountFetchedUtxos(address: e)).toList();
    getAccountsUtxos();
    _syncingSubscribition = syncing.latestEvent.stream.listen(
      (event) => _onSyncingEvent(syncing, event),
    );
  }

  Future<void> getAccountsUtxos({List<MoneroAccountFetchedUtxos>? accountUtxos}) async {
    _cancelable.cancel();
    accountUtxos ??= this.accountUtxos.value;
    final result = await IResult.call(() async {
      await Future.wait(accountUtxos!.map((e) {
        return e.lock.run(() async {
          await e.setPending();
          if (e.isSuccess) return;
          final utxos = await account.getAddressUtxos(e.address);
          await utxos.mapErr((err) {
            e.setError(MoneroAccountUtxosStatusErr(err.localizationError));
            return err.exception;
          }).mapAsync((utxos) {
            e.setUtxos(MoneroAccountWithUtxos(address: e.address, utxo: utxos));
          });
        });
      }));
    }, cancelable: _cancelable);
    if (result.err()?.canceled() ?? false) return;
    this
        .accountUtxos
        .value
        .removeWhere((e) => e.isSuccess && e.utxos!.utxosWithBalance.isEmpty);
    _updateTotoalSelectedUtxos();
    this.accountUtxos.notify();
  }

  void _checkUnsyncingStatus({int? latestHeight}) {
    latestHeight ??= _syncing?.latestHeight;
    if (latestHeight == null) return;
    int? latestSyncedHeight = _syncing?.latestSyncedHeight;
    final syncInterval = _syncing?.maxSyncingInterval.inSeconds;
    if (latestSyncedHeight == null || syncInterval == null) return;
    int totalUnsyncingHeight = latestHeight - latestSyncedHeight;
    assert(!totalUnsyncingHeight.isNegative, "Unexpected current block height");
    bool unsyncedAlert = _unsyncedAlert;
    _unsyncedAlert = totalUnsyncingHeight >
        (syncInterval ~/ account.network.coinParam.averageBlockTime);
    if (unsyncedAlert != _unsyncedAlert) accountUtxos.notify();
  }

  void _onHeightUpdated() {
    int? blockHeight = _syncing?.latestHeight;
    if (blockHeight == null) return;
    for (final i in accountUtxos.value) {
      i.onHeightUpdated(blockHeight);
    }
  }

  Future<void> _onAccountUtxoChanged() async {
    bool updated = false;
    await Future.wait(accountUtxos.value.map((i) async {
      await i.lock.run(() async {
        final utxos = await account.getAddressUtxos(i.address);
        final result = await utxos.mapAsync((utxos) async {
          final merge =
              await i.merge(MoneroAccountWithUtxos(address: i.address, utxo: utxos));
          updated |= merge;
        });
        result.mapErr((e) {
          AppLogData(
              runtime: runtimeType, function: "_onAccountUtxoChanged", err: e.exception);
          return e.exception;
        });
      });
    }));
    if (closed) return;
    if (updated) {
      _updateAmount();
      walletProvider.showAlert("utxos_has_been_updated".tr);
    }
  }

  void _onSelectedUtxosChanged() {
    final utxos = accountUtxos.value.expand((e) => e.selectedUtxos).toList();
    onSelectedUtxosChanged(utxos);
  }

  void _updateTotoalSelectedUtxos() {
    _allowSelectUtxos =
        accountUtxos.value.map((e) => e.totalSelected).sum < MoneroConst.ringSize;
    _allSelected = accountUtxos.value.every((e) => e.allSelected);
  }

  void _updateAmount() {
    final total = accountUtxos.value.fold(BigInt.zero, (p, c) => p + c.totalUtxo.balance);
    totalUtxos.value.updateBalance(total);
    totalUtxos.notify();
    _onSelectedUtxosChanged();
    _updateTotoalSelectedUtxos();
    accountUtxos.notify();
  }

  Future<void> addUtxo(
      {required MoneroAccountFetchedUtxos address,
      required MoneroUtxoWithBalanceInfo utxo,
      required StringVoid onErr}) async {
    await _lock.run(() async {
      if (!_allowSelectUtxos && !address.selectedUtxos.contains(utxo)) {
        onErr("transaction_input_exceeds_16_desc".tr);
        return;
      }
      await address.addUtxo(utxo, onErr);
      _updateAmount();
    });
  }

  Future<void> toggleAllAddressUtxos(
      MoneroAccountFetchedUtxos address, StringVoid onErr) async {
    await _lock.run(() async {
      if (address.status.isError) return;
      if (address.allSelected) {
        await address.removeAllSelectedUtxos();
        _updateAmount();
        return;
      }
      if (!_allowSelectUtxos) {
        onErr("transaction_input_exceeds_16_desc".tr);
        return;
      }
      final utxos = address.utxos?.utxosWithBalance ?? [];
      for (final i in utxos) {
        final update = await address.addUtxo(i, (_) {});
        if (update) {
          _updateTotoalSelectedUtxos();
        }
        if (!_allowSelectUtxos) break;
      }
      if (!_allowSelectUtxos) {
        onErr("transaction_input_exceeds_16_desc".tr);
      } else if (!address.allSelected) {
        onErr("select_all_utxos_failed_due_unconfirmation_desc".tr);
      }
      _updateAmount();
    });
  }

  @override
  void dispose() {
    _syncingSubscribition?.cancel();
    _syncingSubscribition = null;
    _cancelable.cancel();
    totalUtxos.dispose();
    for (final i in accountUtxos.value) {
      i.dispose();
    }
    accountUtxos.value = [];
    accountUtxos.dispose();

    super.dispose();
  }
}
