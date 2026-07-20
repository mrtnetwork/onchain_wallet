import 'package:blockchain_utils/utils/numbers/numbers.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/api/client/core/client.dart';
import 'package:on_chain_wallet/wallet/api/provider/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/services/default.dart';
import 'package:on_chain_wallet/wallet/api/service/types/network_providers.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/network.dart';
import 'package:on_chain_wallet/wallet/models/networks/monero/account/account.dart';
import 'package:on_chain_wallet/wallet/models/token/network/token.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/monero.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class _MoneroClientConst {
  static const int maxTxRequestPerCall = 50;
}

abstract mixin class MoneroClientMethods {
  DefaultProvider<MoneroProvider<MultiChainServiceClient>, MoneroRequestDetails>
      get provider;
  String? _genesis;

  Future<int> getHeight() async {
    final block = await provider.request(DaemonRequestGetLastBlockHeader());
    return block.blockHeader.height;
  }

  Future<DaemonGetBlocksByHeightResponse> getBlockByRange(int start, int end) async {
    final List<int> heights = List.generate(end - start, (i) => start + i);
    if (heights.isEmpty) {
      heights.add(start);
    }
    final blocks = await provider.request(DaemonRequestGetBlocksByHeightBin(heights));
    if (blocks.blocks.length != heights.length) {
      throw APIErrorConst.serverUnexpectedResponse;
    }
    return blocks;
  }

  Future<List<int>> getBlocksByRangeBinary(int start, {Duration? timeout}) async {
    final genesis = await getGenesisBlockHash();
    final blocks = await provider.requestBinary(
        DaemonRequestGetBlocksBin(
            startHeight: start,
            requestedInfo: DaemonRequestBlocksInfo.blocksOnly,
            blockIds: [genesis]),
        timeout: timeout);
    return blocks;
  }

  Future<List<DaemonBlockHeaderResponse>> getBlockHeadersRange(
      {required int start, required int end, bool validateResponse = true}) async {
    final r = await provider
        .request(DaemonRequestGetBlockHeaderByRange(startHeight: start, endHeight: end));
    if (validateResponse && r.headers.length != (end - start) + 1) {
      throw APIErrorConst.serverUnexpectedResponse;
    }
    return r.headers;
  }

  Future<DaemonGetEstimateFeeResponse> getFeeEstimate() async {
    final result = await provider.request(
        const DaemonRequestGetFeeEstimate(MoneroNetworkConst.feeEstimateGraceBlocks));
    return result;
  }

  Future<DaemonGetInfoResponse> getChainInfo() async {
    return await provider.request(DaemonRequestGetInfo());
  }

  Future<String> getGenesisBlockHash() async {
    _genesis ??= await provider.request(DaemonRequestOnGetBlockHash(0));
    return _genesis!;
  }

  Future<Map<String, MoneroTxResponse?>> getTxes(
      {required List<String> txIds, bool prune = false}) async {
    int offset = 0;
    Map<String, MoneroTxResponse> txes = {};
    while (offset < txIds.length) {
      int end = offset + _MoneroClientConst.maxTxRequestPerCall;
      if (end >= txIds.length) {
        end = txIds.length;
      }
      final rParams = DaemonRequestGetTransactions(txIds.sublist(offset, end),
          prune: prune, decodeAsJson: false, split: false);
      final result = await provider.request(rParams);
      for (final i in result) {
        txes[i.txHash] = i;
      }
      offset += rParams.txHashes.length;
    }
    return {for (final i in txIds) i: txes[i]};
  }

  Future<MoneroTransaction> getTx(String txId) async {
    final rParams = DaemonRequestGetTransactions([txId],
        prune: false, decodeAsJson: false, split: false);
    final result = await provider.request(rParams);
    if (result.length != 1) {
      throw AppException("transaction_not_found");
    }
    return result[0].toTx();
  }

  Future<List<DaemonKeyImageSpentStatus>> keyImagesStatus(List<String> keyImages,
      {bool validateResponse = true}) async {
    int offset = 0;
    List<DaemonKeyImageSpentStatus> status = [];
    while (offset < keyImages.length) {
      int end = offset + _MoneroClientConst.maxTxRequestPerCall;
      if (end >= keyImages.length) {
        end = keyImages.length;
      }
      final rParams = DaemonRequestIsKeyImageSpent(keyImages.sublist(offset, end));
      final result = await provider.request(rParams);
      if (validateResponse) {
        if (rParams.keyImages.length != result.spentStatus.length) {
          throw APIErrorConst.serverUnexpectedResponse;
        }
      }
      status.addAll(result.spentStatus);
      offset += rParams.keyImages.length;
    }
    assert(status.length == keyImages.length);
    return status;
  }

  Future<List<TxKeyImage>> getSpendedKeyImages(List<TxKeyImage> keyImages) async {
    List<TxKeyImage> spendedKeyImage = [];
    final keyImagesStatus =
        await this.keyImagesStatus(keyImages.map((e) => e.toHex()).toList());
    for (final i in keyImagesStatus.indexed) {
      if (i.$2.isSpent) spendedKeyImage.add(keyImages[i.$1]);
    }
    return spendedKeyImage;
  }

  Future<OutputDistributionResponse> getBinaryAbsoluteDistribution() async {
    final distributions = await provider.request(DaemonRequestGetOutputDistributionBin(
        amounts: [BigInt.zero], compress: true, cumulative: false));
    return distributions;
  }

  Future<GetOutResponse> getOuts(List<DaemonGetOutRequestParams> outputs) async {
    final outs =
        await provider.request(DaemonRequestGetOuts(outputs: outputs, getTxId: false));
    return outs;
  }

  Future<DaemonSendRawTxResponse> sendTx(String txHex,
      {bool doNotRelay = false, bool doSanityChecks = true}) async {
    return await provider.request(DaemonRequestSendRawTransaction(
        txAsHex: txHex, doNotRelay: doNotRelay, doSanityChecks: doSanityChecks));
  }

  Future<WalletTransactionStatus> transactionStatus(
      MoneroWalletTransaction transaction) async {
    final r = await provider.request(DaemonRequestGetTransactions([transaction.txId]));
    if (r.length != 1) return WalletTransactionStatus.unknown;
    final tx = r[0];
    if (tx.inPool || tx.height == null) return WalletTransactionStatus.pending;
    if (tx.doubleSpend) return WalletTransactionStatus.failed;
    return WalletTransactionStatus.block;
  }
}

class MoneroNetworkClient extends NetworkClient<MoneroWalletTransaction, BaseNetworkToken,
    MoneroAddress, WalletMoneroNetwork> with MoneroClientMethods {
  @override
  final MoneroNetworkProvider networkProvider;
  MoneroNetworkClient._(
      {required this.provider, required super.network, required this.networkProvider});
  @override
  final DefaultProvider<MoneroProvider<MultiChainServiceClient>, MoneroRequestDetails>
      provider;

  factory MoneroNetworkClient.fromProvider({
    required MoneroNetworkProvider provider,
    required WalletMoneroNetwork network,
    required INetApi netApi,
  }) {
    return MoneroNetworkClient._(
      network: network,
      networkProvider: provider,
      provider: DefaultProvider(MoneroProvider(
        MultiChainServiceClient.fromProvider(provider: provider.provider, netApi: netApi),
      )),
    );
  }
  factory MoneroNetworkClient.fromService(
      {required MoneroNetworkProvider provider,
      required WalletMoneroNetwork network,
      required MultiChainServiceClient service}) {
    assert(service.provider == provider.provider);
    return MoneroNetworkClient._(
        network: network,
        networkProvider: provider,
        provider: DefaultProvider(MoneroProvider(service)));
  }

  Future<bool> validateNetworkGenesis({int latestFetchedHeight = 0}) async {
    final gnesis = await getGenesisBlockHash();
    if (gnesis == network.genesisBlock) {
      if (network.coinParam.network == MoneroNetwork.testnet) {
        return true;
      }
      final latestBlockId = await getHeight();
      if (latestBlockId <= network.coinParam.rctHeight) return false;
      if (latestFetchedHeight != 0) {
        final diff = latestFetchedHeight - latestBlockId;
        if (diff > 2) {
          throw APIErrorConst.serviceOutOfSync;
        }
      }
      final start = IntUtils.max(0, latestBlockId - 20);
      final _ = await getBlockByRange(start, latestBlockId - 1);
      return true;
    }
    if (network.coinParam.network == MoneroNetwork.testnet) {
      final info = await getChainInfo();

      /// Accept offline developer daemons in addition to real testnet daemons.
      return info.offline || info.testnet;
    }
    return false;
  }

  @override
  NetworkType get networkType => NetworkType.monero;

  late final CachedObject<int> _height =
      CachedObject(interval: Duration(seconds: network.coinParam.averageBlockTime));

  CachedObject<int> get currentHeight => _height;

  @override
  Future<int> getHeight() async {
    final height = await _height.get(onFetch: super.getHeight);
    return height;
  }

  @override
  List<MultiChainServiceClient> services() {
    return [provider.service];
  }

  @override
  Future<bool> verifyService(DefaultAPIProvider provider) async {
    if (provider == this.provider.service.provider) {
      if (!await validateNetworkGenesis()) {
        return false;
      }
      final height = await getHeight();
      await getBlocksByRangeBinary(IntUtils.min(height, IntUtils.max(0, height - 20)));
      return true;
    }
    return false;
  }
}

class MoneroClient with MoneroClientMethods {
  MoneroClient({required this.provider});
  @override
  final DefaultProvider<MoneroProvider<MultiChainServiceClient>, MoneroRequestDetails>
      provider;

  factory MoneroClient.fromProviders({
    required DefaultAPIProvider provider,
    required INetApi netApi,
  }) {
    return MoneroClient(
      provider: DefaultProvider(MoneroProvider(
        MultiChainServiceClient.fromProvider(provider: provider, netApi: netApi),
      )),
    );
  }

  void dispose() {
    provider.service.dispose();
  }
}

class MoneroWalletClient {
  final DefaultAPIProvider service;
  final MoneroNetwork network;
  factory MoneroWalletClient.fromProvider({
    required DefaultAPIProvider provider,
    required MoneroNetwork network,
    required INetApi netApi,
  }) {
    return MoneroWalletClient._(
      service: provider,
      network: network,
      provider: MoneroProvider(
          MultiChainServiceClient.fromProvider(provider: provider, netApi: netApi)),
    );
  }

  final MoneroProvider<MultiChainServiceClient> provider;
  MoneroWalletClient._({
    required this.provider,
    required this.service,
    required this.network,
  });

  Future<WalletRPCGetAccountsResponse> readMoneroWalletAccounts() async {
    return provider.request(WalletRequestGetAccounts());
  }

  Future<List<MoneroWalletRPCAddress>> readMoneroWalletAdresses() async {
    final accounts = await readMoneroWalletAccounts();
    final List<MoneroWalletRPCAddress> existsAccounts = [];
    for (final i in accounts.subaddressAccounts) {
      final addresses =
          await provider.request(WalletRequestGetAddress(accountIndex: i.accountIndex));
      existsAccounts.addAll(addresses.addresses
          .map((e) => MoneroWalletRPCAddress(
                address: e.address,
                index: MoneroSubIndex(major: i.accountIndex, minor: e.addressIndex),
              ))
          .toList());
    }
    return existsAccounts;
  }

  List<MoneroSubIndex> relateAccountIndexes(
      List<IMoneroAddress> addresses, DerivableIndex masterIndex) {
    final accounts = relatedTxAccounts(addresses, masterIndex);
    return accounts.map((e) => e.index.index).toList();
  }

  Map<int, Set<int>> relateAccountSubIndexes(
      List<IMoneroAddress> addresses, DerivableIndex masterIndex) {
    final accounts = relatedTxAccounts(addresses, masterIndex);
    final Map<int, Set<int>> indexSubIndex = {};
    for (final i in accounts) {
      final minors = indexSubIndex[i.index.index.major] ??= {};
      minors.add(i.index.index.minor);
    }
    return indexSubIndex;
    // return accounts.map((e) => e.index.index).toList();
  }

  List<IMoneroAddress> relatedTxAccounts(
      List<IMoneroAddress> addresses, DerivableIndex masterIndex) {
    return addresses.where((e) => e.index.masterIndex == masterIndex).toList();
  }

  Future<List<IMoneroAddress>> getRelatedAccount(
      List<IMoneroAddress> accountAddresses) async {
    final addresses = await readMoneroWalletAdresses();
    return accountAddresses
        .where((e) => addresses.any((r) => e.networkAddress == r.address))
        .toList();
  }

  Future<List<String>> getRelatedAccountsTxes(
      List<IMoneroAddress> relatedAddresses) async {
    final masterKeys = relatedAddresses.map((e) => e.index.masterIndex).toSet();
    if (masterKeys.isEmpty) return [];

    List<String> txes = [];
    for (final i in masterKeys) {
      final allIndexes = relateAccountSubIndexes(relatedAddresses, i);
      for (final index in allIndexes.entries) {
        final result = await provider.request(WalletRequestIncommingTransfers(
            transferType: IncommingTransferType.available,
            accountIndex: index.key,
            subaddrIndices: index.value.toList()));
        final indexes = result.where((e) =>
            index.value.contains(e.subAddrIndex?.minor) &&
            e.subAddrIndex?.major == index.key);
        txes.addAll(indexes.map((e) => e.txHash));
      }
    }

    return txes;
  }

  Future<List<String>> getAccountsTxes(List<IMoneroAddress> accountAddresses) async {
    final relatedAddresses = await getRelatedAccount(accountAddresses);
    return getRelatedAccountsTxes(relatedAddresses);
  }

  Future<bool> init() async {
    return true;
  }

  void dispose() {
    provider.service.dispose();
  }
}

extension ExtMoneroProvider
    on DefaultProvider<MoneroProvider<MultiChainServiceClient>, MoneroRequestDetails> {
  Future<List<int>> requestBinary<RESULT, SERVICERESPONSE>(
    MoneroDaemonRequestParam<RESULT, SERVICERESPONSE> request, {
    Duration? timeout,
  }) async {
    try {
      return await inner.requestBinary(request, timeout: timeout);
    } catch (e) {
      throw IExceptionUtils.findError(e);
    }
  }
}
