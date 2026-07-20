import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/api/client/core/client.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/cardano/types/types.dart';
import 'package:on_chain_wallet/wallet/api/provider/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/services/default.dart';
import 'package:on_chain_wallet/wallet/api/service/types/network_providers.dart';
import 'package:on_chain_wallet/wallet/models/network/network.dart';
import 'package:on_chain_wallet/wallet/models/token/network/token.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/ada.dart';
import 'package:on_chain/ada/src/provider/exception/blockfrost_api_error.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class _ADAClientConst {
  static const int blockfrostMaxUtxoResponse = 100;
}

class ADANetworkClient extends NetworkClient<ADAWalletTransaction, BaseNetworkToken,
    ADAAddress, WalletCardanoNetwork> {
  @override
  final CardanoNetworkProvider networkProvider;
  ADANetworkClient._(
      {required this.provider, required super.network, required this.networkProvider});
  final DefaultProvider<BlockFrostProvider<MultiChainServiceClient>,
      BlockFrostRequestDetails> provider;

  factory ADANetworkClient.fromProvider({
    required CardanoNetworkProvider provider,
    required WalletCardanoNetwork network,
    required INetApi netApi,
  }) {
    return ADANetworkClient._(
      network: network,
      networkProvider: provider,
      provider: DefaultProvider(BlockFrostProvider(MultiChainServiceClient.fromProvider(
          provider: provider.provider, netApi: netApi))),
    );
  }
  factory ADANetworkClient.fromService(
      {required CardanoNetworkProvider provider,
      required WalletCardanoNetwork network,
      required MultiChainServiceClient service}) {
    assert(service.provider == provider.provider);
    return ADANetworkClient._(
      network: network,
      networkProvider: provider,
      provider: DefaultProvider(BlockFrostProvider(service)),
    );
  }

  Future<List<ADAAccountUTXOResponse>> getAccountUtxos(
      {required ADAAddress address}) async {
    try {
      int page = 1;
      List<ADAAccountUTXOResponse> utxos = [];
      while (true) {
        final result = await provider.request(BlockfrostRequestAddressUTXOs(address,
            filter: BlockFrostRequestFilterParams(
                count: _ADAClientConst.blockfrostMaxUtxoResponse, page: page)));
        utxos.addAll(result);
        page++;
        if (result.length < _ADAClientConst.blockfrostMaxUtxoResponse) break;
      }
      return utxos;
    } on APIError catch (e) {
      if (e.errorCode == BlockfrostStatusCode.resourceDoesNotExist) {
        return [];
      }
      rethrow;
    }
  }

  Future<List<TransactionUnspentOutput>> getUtxosOutputs(
      List<TransactionInput> inputs) async {
    final txIds = inputs.map((e) => e.txIdHex).toSet();
    List<TransactionUnspentOutput> outputs = [];
    await Future.wait(txIds.map((e) async {
      final tx = await tryGetTransaction(e);
      if (tx == null) return null;
      final input = inputs.where((i) => StringUtils.hexEqual(i.txIdHex, e));
      for (final e in input) {
        final rOutput = tx.body.outputs?.outputs.elementAtOrNull(e.index);
        if (rOutput != null) {
          outputs.add(TransactionUnspentOutput(output: rOutput, input: e));
        }
      }
    }));
    return outputs;
  }

  Future<ADATransaction?> tryGetTransaction(String txId) async {
    final tx = await () async {
      try {
        final cbor = await provider.request(BlockfrostRequestTransactionCbor(txId));
        return ADATransaction.deserialize(CborObject.fromCborHex(cbor).cast());
      } catch (_) {
        return null;
      }
    }();
    assert(tx != null, "fetch tx id failed $txId");
    return tx;
  }

  Future<List<ADATransactionWithTxId>> getTxesFromInputs(
      List<TransactionInput> inputs) async {
    final txIds = inputs.map((e) => e.txIdHex).toSet();
    List<ADATransactionWithTxId> txes = [];
    await Future.wait(txIds.map((e) async {
      final tx = await provider.request(BlockfrostRequestSpecificTransaction(e));
      final cbor = await provider.request(BlockfrostRequestTransactionCbor(e));
      final txInputs = inputs.where((i) => i.txIdHex == e);
      final adaTransaction =
          ADATransaction.deserialize(CborObject.fromCborHex(cbor).cast());
      for (final i in txInputs) {
        final output = adaTransaction.body.outputs?.outputs.elementAtOrNull(i.index);
        assert(output != null, "invalid utxo output");
        if (output == null) continue;
        txes.add(ADATransactionWithTxId(
            txInput: i,
            blockTime: DateTimeUtils.fromSecondsSinceEpoch(tx.blockTime),
            output: output));
      }
    }));

    return txes;
  }

  Future<ADAEpochParametersResponse> latestEpochProtocolParameters() async {
    return await provider.request(BlockfrostRequestLatestEpochProtocolParameters());
  }

  Future<ADAGenesisParametersResponse> getNetworkGenesisParameters() async {
    return await provider.request(BlockfrostRequestBlockchainGenesis());
  }

  Future<String> broadcastTransaction(List<int> txCborBytes) async {
    return await provider
        .request(BlockfrostRequestSubmitTransaction(transactionCborBytes: txCborBytes));
  }

  @override
  Future<WalletTransactionStatus> transactionStatus(
      ADAWalletTransaction transaction) async {
    try {
      await provider.request(BlockfrostRequestSpecificTransaction(transaction.txId));
      return WalletTransactionStatus.block;
    } on APIError catch (e) {
      if (e.errorCode == BlockfrostStatusCode.resourceDoesNotExist) {
        return WalletTransactionStatus.unknown;
      }
      rethrow;
    }
  }

  Future<bool> validateNetworkMagicNumber() async {
    final magic = await getNetworkGenesisParameters();
    return magic.networkMagic == network.coinParam.networkType.protocolMagic;
  }

  @override
  List<MultiChainServiceClient> services() {
    return [provider.service];
  }

  @override
  Future<bool> verifyService(DefaultAPIProvider provider) async {
    if (provider == this.provider.service.provider) {
      return validateNetworkMagicNumber();
    }
    return false;
  }
}
