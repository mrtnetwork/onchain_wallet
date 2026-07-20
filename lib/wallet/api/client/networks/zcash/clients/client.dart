import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exception/rpc_error.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_bridge/net_sdk/dart/types/types.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/api/client/core/client.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/zcash/types/types.dart';
import 'package:on_chain_wallet/wallet/api/provider/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/services/default.dart';
import 'package:on_chain_wallet/wallet/api/service/types/network_providers.dart';

import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/utxos.dart';
import 'package:on_chain_wallet/wallet/models/token/network/token.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/zcash.dart';
import 'package:zcash_dart/zcash.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

abstract mixin class ZcashClientMethods {
  DefaultProvider<ZcashWalletdProvider<MultiChainServiceClient>,
      ZcashWalletdRequestDetails> get provider;

  Future<List<TransparentFullUtxoInfos>> getTransparentAddressUtxos(
      TransparentUtxoOwner account,
      {List<ZcashUtxoTransparent> exclude = const []}) async {
    Map<TransparentUtxo, ZcashUtxoTransparent> exitUtxos = {};
    for (final i in exclude) {
      exitUtxos[i.utxo] = i;
    }
    List<TransparentFullUtxoInfos> newUtxos = [];
    Map<ZcashTxId, ZcashTransactionWithBlockInfo> txes = {};
    final utxos =
        await provider.request(WalletdRequestGetAddressUtxosWithAccountOwner([account]));
    for (final i in utxos) {
      final exists = exitUtxos[i.utxo];
      if (exists != null) {
        newUtxos.add(TransparentFullUtxoInfos(utxo: exists, transaction: null));
        continue;
      }
      ZcashTransactionWithBlockInfo? tx = txes[i.utxo.txId];
      if (tx == null) {
        final result = await getBlockTransactionWithBlockInfo(i.utxo.txId);
        if (result == null) continue;
        tx = result;
      }
      newUtxos.add(TransparentFullUtxoInfos(
          utxo: ZcashUtxoTransparent(
              utxo: i.utxo,
              coinbase:
                  tx.transaction.transparentBundle?.vin.firstOrNull?.txId.isCoinbase() ??
                      false,
              time: tx.block.time),
          transaction: tx));
    }
    return newUtxos;
  }

  Future<T> query<T extends ZcashProtoMessage>(IZcashProtoQueryMessage<T> request) async {
    return await provider.request(ZcashGrpcRequestMessage(request: request));
  }

  Future<TransactionData?> getBlockTransaction(ZcashTxId txId) async {
    final rawTx = await query(
        ZWalletdGetTransaction(getTransaction: ZWalletdTxFilter(hash: txId.hash)));
    if (rawTx.height == null) return null;
    return rawTx.toTransaction();
  }

  Future<Map<ZcashTxId, TransactionData?>> getTransactions(List<ZcashTxId> txes) async {
    final tx = await Future.wait(txes.map((e) async {
      final txData = await query(
          ZWalletdGetTransaction(getTransaction: ZWalletdTxFilter(hash: e.hash)));
      return MapEntry(e, txData.toTransaction());
    }));
    return Map<ZcashTxId, TransactionData?>.fromEntries(tx);
  }

  Future<ZcashTransactionWithBlockInfo?> getBlockTransactionWithBlockInfo(
      ZcashTxId txId) async {
    try {
      final txData = await query(
          ZWalletdGetTransaction(getTransaction: ZWalletdTxFilter(hash: txId.hash)));
      final height = txData.height;
      if (height == null) return null;
      ZWalletdCompactBlock? block = await getBlock(height.toIntOrThrow);
      final tx = txData.toTransaction();
      return ZcashTransactionWithBlockInfo(transaction: tx, block: block, txId: txId);
    } on APIError catch (e) {
      if (e.errorCode == GrpcErrorCode.notFound.code) {
        return null;
      }
      return null;
    }
  }

  Future<ZWalletdBlockID> getLatestBlock() async {
    return await query(ZWalletdGetLatestBlock());
  }

  Future<int> getLatestBlockHeight() async {
    final latestBlock = await getLatestBlock();
    final height = latestBlock.height?.toIntOrThrow;
    if (height == null) {
      throw APIErrorConst.serverUnexpectedResponse;
    }
    return height;
  }

  Future<Map<int, ZWalletdCompactBlock>> getBlocks(List<int> heights) async {
    final blocks = await Future.wait(heights.map((e) async {
      final blockData = await query(
          ZWalletdGetBlock(getBlock: ZWalletdBlockID(height: BigInt.from(e))));
      return MapEntry(e, blockData);
    }));
    return Map<int, ZWalletdCompactBlock>.fromEntries(blocks);
  }

  Future<ZWalletdCompactBlock> getBlock(int block) async {
    final blockData = await query(
        ZWalletdGetBlock(getBlock: ZWalletdBlockID(height: BigInt.from(block))));
    return blockData;
  }

  Future<ZWalletdLightdInfo> getLightInfo() async {
    final blockData = await query(ZWalletdGetLightdInfo());
    return blockData;
  }

  Future<ZWalletdTreeState> getBlockTreeState() async {
    final blockData = await query(
        ZWalletdGetTreeState(getTreeState: ZWalletdBlockID(height: BigInt.one)));
    return blockData;
  }

  Future<String?> submitTransaction(List<int> transactionData) async {
    final result = await query(
      ZWalletdSendTransaction(
          sendTransaction: ZWalletdRawTransaction(data: transactionData)),
    );
    if (result.errorCode != 0) {
      throw RPCError(
        message: result.errorMessage ?? "",
        errorCode: result.errorCode,
      );
    }
    final message = result.errorMessage;
    final toBytes = BytesUtils.tryFromHexString(message);
    if (toBytes != null && toBytes.length == QuickCrypto.blake2b256DigestSize) {
      return message;
    }
    return null;
  }

  Future<WalletTransactionStatus> transactionStatus(
      ZcashWalletTransaction transaction) async {
    final tx = await getBlockTransaction(ZcashTxId.fromTxId(transaction.txId));
    if (tx == null) {
      return WalletTransactionStatus.pending;
    }
    return WalletTransactionStatus.block;
  }
}

class ZcashNetworkClient extends NetworkClient<ZcashWalletTransaction, BaseNetworkToken,
    ZcashAddress, WalletZcashNetwork> with ZcashClientMethods {
  @override
  final ZcashNetworkProvider networkProvider;

  late final CachedObject<int> _latestCachedBlock =
      CachedObject(interval: Duration(seconds: network.coinParam.averageBlockTime));
  ZcashNetworkClient._(
      {required this.provider, required super.network, required this.networkProvider});
  factory ZcashNetworkClient.fromProvider({
    required ZcashNetworkProvider provider,
    required WalletZcashNetwork network,
    required INetApi netApi,
  }) {
    return ZcashNetworkClient._(
      network: network,
      networkProvider: provider,
      provider: DefaultProvider(ZcashWalletdProvider(MultiChainServiceClient.fromProvider(
          provider: provider.provider, netApi: netApi))),
    );
  }
  factory ZcashNetworkClient.fromService(
      {required ZcashNetworkProvider provider,
      required WalletZcashNetwork network,
      required MultiChainServiceClient service}) {
    assert(service.provider == provider.provider);
    return ZcashNetworkClient._(
        network: network,
        networkProvider: provider,
        provider: DefaultProvider(ZcashWalletdProvider(service)));
  }
  @override
  final DefaultProvider<ZcashWalletdProvider<MultiChainServiceClient>,
      ZcashWalletdRequestDetails> provider;

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
  Future<int> getLatestBlockHeight() {
    return _latestCachedBlock.get(onFetch: super.getLatestBlockHeight);
  }

  @override
  List<MultiChainServiceClient> services() {
    return [provider.service];
  }

  Future<bool> validateNu6ActiveHeight() async {
    final result = await getBlock(network.coinParam.getNu6ActiveHeight());
    final hash = result.hash;
    if (hash == null) return false;
    final nu6BlockHash = network.getNu6BlockHash();
    if (nu6BlockHash == null) return true;
    return StringUtils.hexEqual(
        nu6BlockHash, BytesUtils.toHexString(hash.reversed.toList()));
  }

  @override
  Future<bool> verifyService(DefaultAPIProvider provider) async {
    if (provider == this.provider.service.provider) {
      return validateNu6ActiveHeight();
    }
    return false;
  }
}

class ZcashClient with ZcashClientMethods {
  @override
  final DefaultProvider<ZcashWalletdProvider<MultiChainServiceClient>,
      ZcashWalletdRequestDetails> provider;

  ZcashClient({required this.provider});
  factory ZcashClient.fromProviders({
    required DefaultAPIProvider provider,
    required INetApi netApi,
  }) {
    return ZcashClient(
      provider: DefaultProvider(ZcashWalletdProvider(
          MultiChainServiceClient.fromProvider(provider: provider, netApi: netApi))),
    );
  }

  void dispose() {
    provider.service.dispose();
  }
}
