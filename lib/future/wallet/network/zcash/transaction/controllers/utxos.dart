import 'dart:async';

import 'package:blockchain_utils/bip/bip/zip32/zip32/types.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/zcash/clients/client.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/sync/syncing.dart';

mixin ZcashTransactionUtxosController on DisposableMixin {
  WalletZcashNetwork get network;
  WalletProvider get walletProvider;
  final Cancelable _cancelable = Cancelable();
  ZcashChain get account;
  bool _unsyncedAlert = false;
  bool get unsyncedAlert => _unsyncedAlert;
  ZcashTransactionSpenderPrivacy _privacy = ZcashTransactionSpenderPrivacy.shieldOnly;
  ZcashTransactionSpenderPrivacy get privacy => _privacy;
  ZcashSyncing? _syncing;
  bool get accountSynced => _syncing != null;
  final StreamValue<List<ZcashAccountFetchedUtxos>> accountUtxos =
      StreamValue([], name: "ZcashTransactionUtxosController");
  void onSelectedUtxosChanged(List<ZcashUtxoWithBalanceInfo> utxos);
  bool get hasUtxos => totalUtxos.value.largerThanZero;
  bool _allSelected = false;
  bool get allUtxosSelected => _allSelected;
  StreamSubscription<ZcashChainNotify>? _syncingSubscribition;
  StreamSubscription<int>? _blockSubscribition;
  late final LiveFormField<IntegerBalance, IntegerBalance> totalUtxos = LiveFormField(
      title: "spendable_amount".tr,
      subtitle: "total_selected_amount".tr,
      value: IntegerBalance.zero(network.token),
      optional: false);

  void _onSyncingEvent(ZcashSyncing syncing, ZcashChainNotify event) {
    Logging.debug(
        fn: () => AppLogData(
            runtime: runtimeType,
            function: "_onSyncingEvent",
            msg: "On syncing event: ${event.name} blockHeight: ${syncing.latestHeight}"));
    switch (event) {
      case ZcashChainNotify.blockHeightUpdated:
        _checkUnsyncingStatus(syncing);
        break;
      case ZcashChainNotify.accountUtxosChanged:
        _onAccountUtxoChanged();
        break;
      default:
        break;
    }
  }

  Future<void> initAccountUtxos({
    required List<IZcashAddress> addresses,
    required ZcashSyncing? syncing,
    required int latestHeight,
    required ZcashNetworkClient client,
    ZcashTransactionSpenderPrivacy privacy = ZcashTransactionSpenderPrivacy.auto,
  }) async {
    _syncing = syncing;
    _privacy = privacy;
    if (syncing != null) {
      _checkUnsyncingStatus(syncing, latestHeight: latestHeight);
    }
    accountUtxos.value = addresses
        .map((e) => ZcashAccountFetchedUtxos(
            address: e, privacy: privacy, accountSynced: accountSynced))
        .toList();
    getAccountsUtxos();
    if (syncing != null) {
      _syncingSubscribition = syncing.latestEvent.stream.listen(
        (event) => _onSyncingEvent(syncing, event),
      );
    }
    _blockSubscribition = client.blockSubscribtion().listen(_onHeightUpdated);
  }

  Future<void> getAccountsUtxos({List<ZcashAccountFetchedUtxos>? accountUtxos}) async {
    _cancelable.cancel();
    accountUtxos ??= this.accountUtxos.value;
    final result = await IResult.call(() async {
      await Future.wait(accountUtxos!.map((e) {
        return e.lock.run(() async {
          await e.setPending();
          if (e.isSuccess) return;
          final utxos = await account.getAccountUtxos(e.address);
          await utxos.mapErr((err) {
            e.setError(ZcashAccountUtxosStatusErr(err.localizationError));
            return err.exception;
          }).mapAsync((utxos) {
            e.setUtxos(ZcashAccountWithUtxos(address: e.address, utxos: utxos));
          });
        });
      }));
    }, cancelable: _cancelable);
    if (result.err()?.canceled() ?? false) return;
    this.accountUtxos.notify();
    _updateTotoalSelectedUtxos();
  }

  void _checkUnsyncingStatus(ZcashSyncing syncing, {int? latestHeight}) {
    latestHeight ??= syncing.latestHeight;
    if (latestHeight == null) return;
    int? latestSyncedHeight = syncing.latestSyncedHeight;
    final syncInterval = syncing.maxSyncingInterval.inSeconds;
    int totalUnsyncingHeight = latestHeight - latestSyncedHeight;
    assert(!totalUnsyncingHeight.isNegative, "Unexpected current block height");
    bool unsyncedAlert = _unsyncedAlert;
    _unsyncedAlert = totalUnsyncingHeight >
        (syncInterval ~/ account.network.coinParam.averageBlockTime);
    if (unsyncedAlert != _unsyncedAlert) accountUtxos.notify();
  }

  void _onHeightUpdated(int latestHeight) {
    _onAccountUtxoChanged(protocol: ZcashProtocol.transparent);
    for (final i in accountUtxos.value) {
      i.onHeightUpdated(latestHeight);
    }
  }

  Future<void> _onAccountUtxoChanged({ZcashProtocol? protocol}) async {
    bool updated = false;
    await Future.wait(accountUtxos.value.map((i) async {
      await i.lock.run(() async {
        final utxos = await account.getAccountUtxos(i.address, protocol: protocol);
        await utxos.mapErr((e) {
          AppLogData(
              runtime: runtimeType, function: "_onAccountUtxoChanged", err: e.exception);
          return e.exception;
        }).mapAsync((utxos) async {
          final merge = await i.merge(
              utxos: ZcashAccountWithUtxos(address: i.address, utxos: utxos),
              protocol: protocol);
          updated |= merge;
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
    final allSelected = accountUtxos.value.every((e) => e.allSelected);
    if (allSelected != _allSelected) {
      _allSelected = accountUtxos.value.every((e) => e.allSelected);
      accountUtxos.notify();
    }
  }

  void _updateAmount() {
    final total = accountUtxos.value.fold(BigInt.zero, (p, c) => p + c.totalUtxo.balance);
    totalUtxos.value.updateBalance(total);
    totalUtxos.notify();

    _onSelectedUtxosChanged();
    _updateTotoalSelectedUtxos();
  }

  Future<void> addUtxo(
      {required ZcashAccountFetchedUtxos address,
      required ZcashUtxoWithBalanceInfo utxo,
      required StringVoid onErr}) async {
    await address.addUtxo(utxo, onErr);
    _updateAmount();
  }

  Future<void> toggleAllAddressUtxos(
      ZcashAccountFetchedUtxos address, StringVoid onErr) async {
    await address.toggleAll(onErr);
    _updateAmount();
  }

  Future<void> toggleAllUtxos(StringVoid onErr) async {
    for (final i in accountUtxos.value) {
      if (!i.isSuccess) continue;
      await i.selectAll(onErr, select: !_allSelected);
    }
    _updateAmount();
  }

  @override
  void dispose() {
    _syncingSubscribition?.cancel();
    _syncingSubscribition = null;
    _blockSubscribition?.cancel();
    _blockSubscribition = null;
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
