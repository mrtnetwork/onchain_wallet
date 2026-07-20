import 'dart:async';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/bitcoin/clients/bitcoin.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';

mixin BitcoinTransactionUtxosController on DisposableMixin {
  WalletBitcoinNetwork get network;
  BitcoinNetworkClient get client;
  WalletProvider get walletProvider;
  final Cancelable _cancelable = Cancelable();
  BitcoinChain get account;
  bool get includeTokens => true;
  late final StreamValue<List<BitcoinAccountFetchedUtxos>> accountUtxos = StreamValue(
      account.addresses.map((e) => BitcoinAccountFetchedUtxos(address: e)).toList(),
      name: "BitcoinTransactionUtxosController");
  void onSelectedUtxosChanged(List<BitcoinUtxoInfo> utxos);
  bool get hasUtxos => totalUtxos.value.largerThanZero;
  bool _allSelected = false;
  bool get allUtxosSelected => _allSelected;
  StreamSubscription<int>? _blockSubscribition;

  void _onHeightUpdated(int latestHeight) {
    _onAccountUtxoChanged();
    for (final i in accountUtxos.value) {
      i.onHeightUpdated(latestHeight);
    }
  }

  late final LiveFormField<IntegerBalance, IntegerBalance> totalUtxos = LiveFormField(
      title: "spendable_amount".tr,
      subtitle: "total_selected_amount".tr,
      value: IntegerBalance.zero(network.token),
      optional: false);

  Future<void> initAccountUtxos({required List<IBitcoinAddress> addresses}) async {
    accountUtxos.value =
        addresses.map((e) => BitcoinAccountFetchedUtxos(address: e)).toList();
    _blockSubscribition = client.blockSubscribtion().listen(_onHeightUpdated);
    getAccountsUtxos();
  }

  Future<void> getAccountsUtxos({List<BitcoinAccountFetchedUtxos>? accountUtxos}) async {
    _cancelable.cancel();
    accountUtxos ??= this.accountUtxos.value;
    final result = await IResult.call(() async {
      await Future.wait(accountUtxos!.map((e) {
        return e.lock.run(() async {
          await e.setPending();
          if (e.isSuccess) return;
          final utxos =
              await account.getAccountUtxos(e.address, includeTokens: includeTokens);
          await utxos.mapErr((err) {
            e.setError(BitcoinAccountUtxosStatusErr(err.localizationError));
            return err.exception;
          }).mapAsync((utxos) {
            e.setUtxos(BitcoinAccountWithUtxos(
                address: e.address,
                addressDetails: e.address.toUtxoRequest,
                utxos: utxos.utxos,
                network: account.network));
          });
        });
      }));
    }, cancelable: _cancelable);
    if (result.err()?.canceled() ?? false) return;
    this.accountUtxos.notify();
    _updateTotoalSelectedUtxos();
  }

  Future<void> _onAccountUtxoChanged() async {
    bool updated = false;
    await Future.wait(accountUtxos.value.map((i) async {
      await i.lock.run(() async {
        final utxos =
            await account.getAccountUtxos(i.address, includeTokens: includeTokens);
        final result = await utxos.mapAsync((utxos) async {
          final merge = await i.merge(
              utxos: BitcoinAccountWithUtxos(
                  address: i.address,
                  addressDetails: i.address.toUtxoRequest,
                  utxos: utxos.utxos,
                  network: account.network));
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
      {required BitcoinAccountFetchedUtxos address,
      required BitcoinUtxoInfo utxo,
      required StringVoid onErr}) async {
    await address.addUtxo(utxo, onErr);
    _updateAmount();
  }

  Future<void> toggleAllAddressUtxos(
      BitcoinAccountFetchedUtxos address, StringVoid onErr) async {
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
