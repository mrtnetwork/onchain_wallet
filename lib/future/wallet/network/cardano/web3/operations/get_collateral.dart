import 'package:flutter/material.dart';
import 'package:on_chain/ada/src/models/transaction/input/models/transaction_unspent_output.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/controllers/utxos.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/web3/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/web3/pages/get_collateral.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/cardano.dart';

class Web3ADGetCollateralStateController extends Web3CardanoStateController<
        List<TransactionUnspentOutput>, ADANetworkClient, Web3ADAGetCollateral>
    with
        ADATransactionApiController,
        CardanoWeb3TransactionApiController,
        ADATransactionUtxosController {
  Web3ADGetCollateralStateController(
      {required super.walletProvider, required super.request});
  List<CardanoAccountUtxo> _utxos = [];
  List<CardanoAccountUtxo> get utxos => _utxos;
  late final BigInt amount = params.coin ?? BigInt.zero;

  late final LiveFormField<IntegerBalance, IntegerBalance> _totalUtxos = LiveFormField(
      title: "total_amount".tr,
      value: IntegerBalance.zero(network.token),
      optional: false);

  @override
  LiveFormField<IntegerBalance, IntegerBalance> get totalUtxos => _totalUtxos;
  @override
  void onSelectedUtxosChanged(List<CardanoAccountUtxo> utxos) {
    _utxos = utxos;
    onStateUpdated();
  }

  @override
  void onUpdateUtxo(ADAAccountFetchedUtxos address, CardanoAccountUtxo utxo) {
    if (utxo.haveAssets) {
      return;
    }
    super.onUpdateUtxo(address, utxo);
  }

  @override
  TransactionStateStatus getStateStatus() {
    if (_utxos.isEmpty) return TransactionStateStatus.error();
    final total = _utxos.map((e) => e.utxoBalance.balance).sum;
    final remain = total - amount;
    if (remain.isNegative) {
      final balance = IntegerBalance.token(amount, network.token);
      final String absBalance = balance.price.replaceFirst("-", "");
      return TransactionStateStatus.error(
          error: "at_least_ada_for_collateral"
              .tr
              .replaceOne("$absBalance ${balance.token.symbol}"));
    }

    return super.getStateStatus();
  }

  @override
  Future<Web3RequestResponseData<List<TransactionUnspentOutput>>> getResponse() async {
    return Web3RequestResponseData(
        response: _utxos
            .map((e) =>
                TransactionUnspentOutput(input: e.utxo.input, output: e.utxo.output))
            .toList());
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3CardanoGetCollateralStateView(form: this);
  }

  @override
  Future<void> initForm(ADANetworkClient client) async {
    await super.initForm(client);
    final List<ICardanoAddress> addresses = [];
    for (int i = 0; i < params.requiredAccounts.length; i++) {
      final web3Account = params.requiredAccounts[i];
      if (web3Account.isRewardAddress) continue;
      final address = accounts[i];
      if (address.multiSigAccount) {
        final mAccount = address as ICardanoMultiSigAddress;
        if (mAccount.addressInfo.credential.type.isScript) continue;
      }
      addresses.add(address);
    }
    await initUtxos(addresses: addresses, allowAssets: false);
  }
}
