import 'package:on_chain/ada/src/provider/blockfrost/models/models/epoch_parameters.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/types/types.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

mixin ADATransactionApiController on DisposableMixin {
  ADANetworkClient get client;
  WalletCardanoNetwork get network;
  late final CachedObject<ADAEpochParametersResponse> _latestEpochProtocolParameters =
      CachedObject<ADAEpochParametersResponse>(
          interval: Duration(seconds: network.coinParam.averageBlockTime));

  Future<List<CardanoAccountUtxo>> getAccountUtxos(
      ADAChain account, ICardanoAddress address) async {
    final utxos = (await account.getAccountUtxos(address)).unwrap();
    return utxos
        .map((e) => CardanoAccountUtxo(utxo: e, network: network, address: address))
        .toList();
  }

  Future<ADAEpochParametersResponse> latestEpochProtocolParameters() async {
    return await _latestEpochProtocolParameters.get(
        onFetch: () async => await client.latestEpochProtocolParameters());
  }
}
