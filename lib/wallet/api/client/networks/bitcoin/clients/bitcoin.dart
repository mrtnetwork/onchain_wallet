import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/api/client/core/client.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/bitcoin/methods/types.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/bitcoin/types/types.dart';
import 'package:on_chain_wallet/wallet/api/provider/provider.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/services/default.dart';
import 'package:on_chain_wallet/wallet/api/service/types/network_providers.dart';
import 'package:on_chain_wallet/wallet/api/types/types.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/token/network/token.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/bitcoin.dart';
import 'package:on_chain_swap/on_chain_swap.dart';

class BitcoinNetworkClient<T extends IBitcoinAddress> extends NetworkClient<
    BitcoinWalletTransaction,
    BaseNetworkToken,
    BitcoinNetworkAddress,
    WalletBitcoinNetwork> implements BaseSwapBitcoinClient {
  @override
  final BitcoinNetworkProvider networkProvider;
  final BitcoinProviderApi api;
  late final CachedObject<int> _latestCachedBlock =
      CachedObject(interval: Duration(seconds: network.coinParam.averageBlockTime));
  BitcoinNetworkClient._(
      {required this.provider,
      required super.network,
      required this.networkProvider,
      required this.api});

  factory BitcoinNetworkClient.fromProvider({
    required BitcoinNetworkProvider provider,
    required WalletBitcoinNetwork network,
    required INetApi netApi,
  }) {
    return BitcoinNetworkClient._(
      network: network,
      networkProvider: provider,
      api: switch (provider.provider.service) {
        APIProviderServices.electrum => BitcoinProviderApi.electrum,
        APIProviderServices.mempool => BitcoinProviderApi.mempool,
        APIProviderServices.blockCypher => BitcoinProviderApi.blockCypher,
        _ => throw WalletExceptionConst.invalidProviderInformation
      },
      provider: DefaultProvider(BitcoinProvider(MultiChainServiceClient.fromProvider(
          provider: provider.provider, netApi: netApi))),
    );
  }
  factory BitcoinNetworkClient.fromService(
      {required BitcoinNetworkProvider provider,
      required WalletBitcoinNetwork network,
      required MultiChainServiceClient service}) {
    assert(service.provider == provider.provider);
    return BitcoinNetworkClient._(
      network: network,
      networkProvider: provider,
      provider: DefaultProvider(BitcoinProvider(service)),
      api: switch (provider.provider.service) {
        APIProviderServices.electrum => BitcoinProviderApi.electrum,
        APIProviderServices.mempool => BitcoinProviderApi.mempool,
        APIProviderServices.blockCypher => BitcoinProviderApi.blockCypher,
        _ => throw WalletExceptionConst.invalidProviderInformation
      },
    );
  }

  final DefaultProvider<BitcoinProvider<MultiChainServiceClient>, BitcoinRequestDetails>
      provider;

  Future<BigInt> getAccountBalance(BitcoinBaseAddress address) async {
    final owner = UtxoAddressDetails.watchOnly(address);
    final utxos = await readUtxos(owner);
    return utxos.sumOfUtxosValue();
  }

  Future<BitcoinAccountUtxosInfo> readAddressUtxos({
    required UtxoAddressDetails address,
    required List<BitcoinUtxo> existsUtxos,
    bool includeTokens = false,
  }) async {
    List<UtxoWithAddress> newUtxos = [];
    Map<String, ElectrumVerbosTxResponse> transactions = {};
    final utxos = await readUtxos(address, includeTokens);
    for (final i in utxos) {
      final exist = existsUtxos.firstWhereOrNull((e) => e == i.utxo);
      if (exist != null) {
        newUtxos.add(UtxoWithAddress(
            utxo: i.utxo.copyWith(coinbase: exist.coinbase), ownerDetails: address));
        continue;
      }
      if (i.utxo.blockHeight <= 0) {
        newUtxos.add(UtxoWithAddress(
            utxo: i.utxo.copyWith(coinbase: false), ownerDetails: i.ownerDetails));
        continue;
      }
      final tx = transactions[i.utxo.txHash] ??= await getVervoseTx(i.utxo.txHash);
      newUtxos.add(UtxoWithAddress(
          utxo: i.utxo.copyWith(coinbase: tx.isCoinbase), ownerDetails: i.ownerDetails));
    }

    return BitcoinAccountUtxosInfo(utxos: newUtxos, fetchedTransaction: transactions);
  }

  Future<List<UtxoWithAddress>> readUtxos(UtxoAddressDetails address,
      [bool includeTokens = false]) async {
    assert(network.coinParam.isBCH || !includeTokens,
        "bitcoin explorer api does not support include tokens");
    assert(api == BitcoinProviderApi.electrum || !includeTokens);
    final addr = address.address.toAddress(network.coinParam.transacationNetwork);
    final utxos = switch (api) {
      BitcoinProviderApi.mempool => await provider
          .request(MempoolRequestGetAccountUtxos(owner: address, address: addr)),
      BitcoinProviderApi.blockCypher => await provider
          .request(BlockCypherRequestGetAccountUtxos(owner: address, address: addr)),
      BitcoinProviderApi.electrum => await (() async {
          final utxos = await provider.request(ElectrumRequestScriptHashListUnspent(
              scriptHash: address.address.pubKeyHash(), includeTokens: includeTokens));
          return utxos
              .where((element) => (!includeTokens) ? element.token == null : true)
              .map<UtxoWithAddress>((e) {
            return UtxoWithAddress(
                utxo: e.toUtxo(address.address.type), ownerDetails: address);
          }).toList();
        }())
    };
    return utxos;
  }

  Future<BitcoinFeeRate?> getFeeRate() async {
    return switch (api) {
      BitcoinProviderApi.mempool =>
        await provider.request(MempoolRequestGetNetworkFeeRate()),
      BitcoinProviderApi.blockCypher =>
        await provider.request(BlockCypherRequestGetNetworkFeeRate()),
      BitcoinProviderApi.electrum => await (() async {
          final BigInt? high =
              await provider.request(ElectrumRequestEstimateFee(numberOfBlock: 2));
          if (high == null) {
            return null;
          }
          final BigInt? medium =
              await provider.request(ElectrumRequestEstimateFee(numberOfBlock: 5));
          final BigInt? low =
              await provider.request(ElectrumRequestEstimateFee(numberOfBlock: 10));
          return BitcoinFeeRate(high: high, low: low ?? high, medium: medium ?? high);
        }())
    };
  }

  @override
  Future<String> sendTransaction(BtcTransaction transaction) async {
    final digest = transaction.serialize();
    return await switch (api) {
      BitcoinProviderApi.mempool =>
        provider.request(MempoolRequestSendRawTransaction(digest)),
      BitcoinProviderApi.blockCypher =>
        provider.request(BlockCypherRequestSendRawTransaction(digest)),
      BitcoinProviderApi.electrum => () async {
          final result = await provider
              .request(ElectrumRequestBroadCastTransaction(transactionRaw: digest));
          if (StringUtils.isHexBytes(result,
              lengthInBytes: QuickCrypto.sha256DigestSize)) {
            return result;
          }
          Logging.info(
              fn: () => AppLogData(
                  runtime: runtimeType,
                  function: "sendTransaction",
                  msg: "Unexpected electrum response: $result"));
          return transaction.txId();
        }(),
    };
  }

  Future<BtcTransaction> getTx(String txId) async {
    return await switch (api) {
      BitcoinProviderApi.mempool =>
        provider.request(MempoolRequestGetRawTransaction(txId)),
      BitcoinProviderApi.blockCypher =>
        provider.request(BlockCypherRequestGetRawTransaction(txId)),
      BitcoinProviderApi.electrum =>
        provider.request(ElectrumRequestGetRawTransaction(txId)),
    };
  }

  @override
  Future<BigRational> estimateFeePerByte(SwapBitcoinNetwork network) async {
    final fee = await getFeeRate();
    if (fee == null) {
      if (!network.chainType.isMainnet) {
        return BigRational.parseDecimal('1.1');
      }
      throw APIErrorConst.serverUnexpectedResponse;
    }
    return BigRational(fee.medium) / BigRational.from(1024);
  }

  Future<ElectrumVerbosTxResponse?> getTransactionData(String txId) async {
    try {
      switch (api) {
        case BitcoinProviderApi.blockCypher:
          final tx = await provider.request(BlockCypherRequestGetTransaction(txId));
          return ElectrumVerbosTxResponse(
              txId: txId,
              version: tx.ver,
              size: tx.size,
              vsize: tx.vSize,
              weight: tx.size,
              locktime: 0,
              blockhash: tx.hash,
              blocktime: tx.received == null
                  ? null
                  : DateTimeUtils.secondsSinceEpoch(tx.received!),
              confirmations: tx.confirmations,
              isCoinbase: tx.isCoinbase());
        case BitcoinProviderApi.mempool:
          final tx = await provider.request(MempoolRequestGetTransaction(txId));
          return ElectrumVerbosTxResponse(
              txId: txId,
              version: tx.version,
              size: tx.size,
              vsize: tx.size,
              weight: tx.weight,
              locktime: tx.locktime,
              blockhash: tx.status.blockHash,
              blocktime: tx.status.blockTime,
              confirmations: tx.status.confirmed ? 1 : null,
              isCoinbase: tx.isCoinbse());

        case BitcoinProviderApi.electrum:
          return await provider.request(ElectrumRequestGetVerboseTransaction(txId));
      }
    } catch (_) {
      return null;
    }
  }

  Future<ElectrumVerbosTxResponse> getVervoseTx(String txId) async {
    switch (api) {
      case BitcoinProviderApi.blockCypher:
        final tx = await provider.request(BlockCypherRequestGetTransaction(txId));
        return ElectrumVerbosTxResponse(
            txId: txId,
            version: tx.ver,
            size: tx.size,
            vsize: tx.vSize,
            weight: tx.size,
            locktime: 0,
            blockhash: tx.hash,
            blocktime: tx.received == null
                ? null
                : DateTimeUtils.secondsSinceEpoch(tx.received!),
            confirmations: tx.confirmations,
            isCoinbase: tx.isCoinbase());
      case BitcoinProviderApi.mempool:
        final tx = await provider.request(MempoolRequestGetTransaction(txId));
        return ElectrumVerbosTxResponse(
            txId: txId,
            version: tx.version,
            size: tx.size,
            vsize: tx.size,
            weight: tx.weight,
            locktime: tx.locktime,
            blockhash: tx.status.blockHash,
            blocktime: tx.status.blockTime,
            confirmations: tx.status.confirmed ? 1 : null,
            isCoinbase: tx.isCoinbse());

      case BitcoinProviderApi.electrum:
        return await provider.request(ElectrumRequestGetVerboseTransaction(txId));
    }
  }

  @override
  Future<String> genesisHash() async {
    return switch (api) {
      BitcoinProviderApi.mempool =>
        await provider.request(MempoolRequestGetBlockHashByHeight(0)),
      BitcoinProviderApi.blockCypher =>
        await provider.request(BlockCypherRequestGetBlockHashByHeight(0)),
      BitcoinProviderApi.electrum => await (() async {
          final header = await provider
              .request(ElectrumRequestBlockHeader(startHeight: 0, cpHeight: 0));
          final hash = BytesUtils.toHexString(
              QuickCrypto.sha256DoubleHash(BytesUtils.fromHexString(header))
                  .reversed
                  .toList());
          return hash;
        }()),
    };
  }

  @override
  Future<BigInt> getBalance(BitcoinBaseAddress address) {
    return getAccountBalance(address);
  }

  @override
  Future<WalletTransactionStatus> transactionStatus(
      BitcoinWalletTransaction transaction) async {
    switch (api) {
      case BitcoinProviderApi.electrum:
        final tx = await provider
            .request(ElectrumRequestGetVerboseTransaction(transaction.txId));
        if (tx.confirmations == null) {
          return WalletTransactionStatus.pending;
        }
        return WalletTransactionStatus.block;
      case BitcoinProviderApi.mempool:
        final tx = await provider.request(MempoolRequestGetTransaction(transaction.txId));
        if (tx.status.confirmed) {
          return WalletTransactionStatus.block;
        }
        return WalletTransactionStatus.pending;
      case BitcoinProviderApi.blockCypher:
        final tx =
            await provider.request(BlockCypherRequestGetTransaction(transaction.txId));
        if (tx.doubleSpend) {
          return WalletTransactionStatus.failed;
        }
        if (tx.confirmations > 0) {
          return WalletTransactionStatus.block;
        }
        return WalletTransactionStatus.pending;
    }
  }

  Future<int> getLatestBlockHeight() async {
    return _latestCachedBlock.get(onFetch: () async {
      return switch (api) {
        BitcoinProviderApi.mempool =>
          await provider.request(MempoolRequestLatestBlockHeight()),
        BitcoinProviderApi.blockCypher =>
          await provider.request(BlockCypherRequestLatestBlockHeight()),
        BitcoinProviderApi.electrum => await (() async {
            final block = await provider.request(ElectrumRequestHeaderSubscribe());
            return block.block;
          }()),
      };
    });
  }

  @override
  Future<BigInt> getBlockHeight() async {
    final height = await getLatestBlockHeight();
    return BigInt.from(height);
  }

  @override
  Future<List<PsbtUtxo>> getAccountsUtxos(List<BitcoinSpenderAddress> addresses) async {
    final utxos = await _getAccountsUtxo(addresses);
    return utxos.where((e) {
      final height = e.utxo.blockHeight;
      return height > 0;
    }).toList();
  }

  Future<List<PsbtUtxo>> _getAccountsUtxo(List<BitcoinSpenderAddress> addresses) async {
    final accountsUtxos = await Future.wait(addresses.map((e) async {
      return await readUtxos(UtxoAddressDetails.watchOnly(e.address.baseAddress));
    }));
    final accountsPsbtUtxos =
        await Future.wait(List.generate(accountsUtxos.length, (i) async {
      final request = addresses[i];
      final accountUtxos = accountsUtxos[i];
      final psbtUtxos =
          await Future.wait(accountUtxos.map((e) => getTx(e.utxo.txHash)).toList());
      return List.generate(
        accountUtxos.length,
        (index) {
          return PsbtUtxo(
              utxo: accountUtxos[index].utxo,
              p2shRedeemScript: request.p2shreedemScript,
              p2wshWitnessScript: request.witnessScript,
              tx: psbtUtxos[index],
              scriptPubKey: request.address.baseAddress.toScriptPubKey(),
              xOnlyOrInternalPubKey: request.taprootInternal);
        },
      );
    }));
    return accountsPsbtUtxos.expand((e) => e).toList();
  }

  Future<bool> validateGenesisHash() async {
    final genesisHash = await this.genesisHash();

    /// TODO should find genesis hash
    if (network.coinParam.transacationNetwork == BitcoinSVNetwork.testnet) {
      return true;
    }
    return genesisHash == network.identifier;
  }

  Future<List<BitcoinBlockTransactionInfo>> getTrasactionsBlockInfo(
      List<String> txIds) async {
    txIds = txIds.toSet().toList();
    List<BitcoinBlockTransactionInfo> transactions = [];
    await Future.wait(txIds.map((e) async {
      final result = await getTransactionData(e);
      if (result == null) return;
      final confirmed = (result.confirmations ?? 0) > 0;
      assert(!confirmed || result.blocktime != null);
      if (confirmed && result.blocktime == null) return;
      transactions.add(BitcoinBlockTransactionInfo(
          confirmed: confirmed,
          blockTime: confirmed ? DateTimeUtils.detectEpochUnit(result.blocktime!) : null,
          txId: e));
    }));
    return transactions;
  }

  // Future<BitcoinBlockTransactionInfo?> getTrasactionBlockInfo(String txId) async {
  //   final result = await getVervoseTx(txId);
  //   // txIds = txIds.toSet().toList();
  //   // List<BitcoinBlockTransactionInfo> transactions = [];
  //   await Future.wait(txIds.map((e) async {
  //     final result = await getTransactionData(e);
  //     if (result == null) return;
  //     final confirmed = (result.confirmations ?? 0) > 0;
  //     assert(!confirmed || result.blocktime != null);
  //     if (confirmed && result.blocktime == null) return;
  //     transactions.add(BitcoinBlockTransactionInfo(
  //         confirmed: confirmed,
  //         blockTime: confirmed ? DateTimeUtils.detectEpochUnit(result.blocktime!) : null,
  //         txId: e));
  //   }));
  //   return transactions;
  // }

  Stream<int> blockSubscribtion({Duration? interval}) {
    interval ??= Duration(seconds: network.coinParam.averageBlockTime);
    return Stream.periodic(
      interval,
      (computationCount) => computationCount,
    ).asyncMap((e) async {
      final latestBlock = await getLatestBlockHeight();
      return latestBlock;
    });
  }

  @override
  List<MultiChainServiceClient> services() {
    return [provider.service];
  }

  @override
  Future<bool> verifyService(DefaultAPIProvider provider) async {
    if (provider == this.provider.service.provider) {
      final result = await validateGenesisHash();
      if (!result || provider.service != APIProviderServices.electrum) return result;
      return true;
    }
    return false;
  }
}
