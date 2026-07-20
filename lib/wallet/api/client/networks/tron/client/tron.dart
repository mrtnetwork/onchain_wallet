import 'dart:async';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/api/client/core/client.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/ethereum/client/ethereum.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/tron/tron.dart';
import 'package:on_chain_wallet/wallet/api/provider/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/services/default.dart';
import 'package:on_chain_wallet/wallet/api/service/types/network_providers.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/network.dart';
import 'package:on_chain_wallet/wallet/models/networks/networks.dart';
import 'package:on_chain_wallet/wallet/models/token/token.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/tron.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class TronClient extends NetworkClient<TronWalletTransaction, TronNetworkToken,
    TronAddress, WalletTronNetwork> {
  @override
  final TronNetworkProvider networkProvider;
  TronClient._(
      {required this.provider,
      required this.ethClient,
      required super.network,
      required this.networkProvider});

  factory TronClient.fromProvider({
    required TronNetworkProvider provider,
    required WalletTronNetwork network,
    required INetApi netApi,
  }) {
    return TronClient._(
        networkProvider: provider,
        provider: DefaultProvider(TronProvider(MultiChainServiceClient.fromProvider(
            provider: provider.node, netApi: netApi))),
        ethClient:
            EthereumClient.fromProviders(provider: provider.ethereum, netApi: netApi),
        network: network);
  }

  factory TronClient.fromService({
    required TronNetworkProvider provider,
    required WalletTronNetwork network,
    required MultiChainServiceClient node,
    required MultiChainServiceClient ethereum,
  }) {
    assert(provider.ethereum == ethereum.provider);
    assert(provider.node == node.provider);
    return TronClient._(
        networkProvider: provider,
        provider: DefaultProvider(TronProvider(node)),
        ethClient: EthereumClient.fromService(ethereum),
        network: network);
  }

  final DefaultProvider<TronProvider<MultiChainServiceClient>, TronRequestDetails>
      provider;
  final EthereumClient ethClient;

  Future<TronAccountInfo?> getAccount(TronAddress account) async {
    final tronAccount =
        await provider.request(TronRequestGetAccountInfo(address: account));
    return tronAccount;
  }

  Future<TronAccountData?> getAccountInfo(TronAddress address) async {
    final account = await getAccount(address);
    if (account == null) return TronAccountData();
    final resource = await getAccountResource(address);
    return TronAccountData(accountInfo: account, resource: resource);
  }

  Future<BigInt> getTrc10Balance(String tokenID, TronAddress account) async {
    final tronAccount =
        await provider.request(TronRequestGetAccountInfo(address: account));
    final tokenBalance = tronAccount?.assetV2.firstWhereOrNull((e) => e.key == tokenID);
    return tokenBalance?.value ?? BigInt.zero;
  }

  Future<TronAccountResourceInfo> getAccountResource(TronAddress account) async {
    return await provider.request(TronRequestGetAccountResourceInfo(address: account));
  }

  Future<TronChainParameters> getChainParameters() async {
    return await provider.request(TronRequestGetChainParameters());
  }

  Future<TronBlock> getNowBlock() async {
    final tronBlock = await provider.request(TronRequestGetNowBlock());
    return tronBlock;
  }

  Future<List<TronIssueTRC10Token>> getIssueAssetList() async {
    final tokens = await provider.request(TronRequestListOfIssueTRC10());
    return tokens;
  }

  Future<TronTRC10Token?> getIssueById(String id, {TronAddress? account}) async {
    final issue = await provider.request(TronRequestIssueById(id));
    if (issue == null) {
      return null;
    }
    BigInt balance = BigInt.zero;
    if (account != null) {
      balance = await getTrc10Balance(issue.id, account);
    }
    return TronTRC10Token.create(
        balance: balance,
        token: Token(
            name: issue.name,
            symbol: issue.abbr ?? issue.name,
            decimal: issue.precision ?? 0),
        tokenID: issue.id);
  }

  Future<TronBroadcastHexResponse> sendTransaction(String digest) async {
    final result = await provider.request(TronRequestBroadcastHex(transaction: digest));
    return result;
  }

  Future<int> estimateContractEnergy({
    required TronAddress ownerAddress,
    required TronAddress contractAddress,
    AbiFunctionFragment? fragment,
    required String data,
    BigInt? callValue,
    BigInt? callTokenValue,
    BigInt? tokenID,
  }) async {
    final energyRequired = await provider.request(TronRequestTriggerConstantContract(
        ownerAddress: ownerAddress,
        contractAddress: contractAddress,
        data: data,
        fragment: fragment,
        callValue: callValue,
        callTokenValue: callTokenValue,
        tokenId: tokenID));
    if (!energyRequired.isSuccess) {
      final error = energyRequired.error;
      throw AppException(error ?? 'fee_estimate_failed', localizedMessage: error != null);
    }
    return energyRequired.energyUsed!;
  }

  Future<int> estimateCreateContractEnergy({
    required TronAddress ownerAddress,
    required String byteCode,
    BigInt? callValue,
    BigInt? callTokenValue,
    BigInt? tokenID,
  }) async {
    final energyRequired = await provider.request(TronRequestTriggerConstantContract(
        ownerAddress: ownerAddress,
        data: byteCode,
        callValue: callValue,
        callTokenValue: callTokenValue,
        tokenId: tokenID));
    if (!energyRequired.isSuccess) {
      final error = energyRequired.error;
      throw AppException(energyRequired.error ?? 'fee_estimate_failed',
          localizedMessage: error != null);
    }
    return energyRequired.energyUsed!;
  }

  Future<(MaxDelegatedResourceAmount, MaxDelegatedResourceAmount)>
      getMaxDelegatedEnergyAndBandwidth(TronAddress address) async {
    final bandwidth = await provider.request(TronRequestGetCanDelegatedMaxSizeV2(
        ownerAddress: address, type: ResourceCode.bandWidth.value, network: network));
    final energy = await provider.request(TronRequestGetCanDelegatedMaxSizeV2(
        ownerAddress: address, type: ResourceCode.energy.value, network: network));
    return (energy, bandwidth);
  }

  Future<List<String>> getDelegatedResourceAddresses(ITronAddress address) async {
    final delegatedAddresses = await provider.request(
        TronRequestGetAccountDelegatedResourceAddresses(value: address.networkAddress));
    return delegatedAddresses;
  }

  Future<DelegatedAccountResourceInfo> getDelegatedResourceInfo(
      TronAddress from, TronAddress to) async {
    final details = await provider.request(TronRequestGetDelegatedResourceV2Details(
        fromAddress: from, toAddress: to, network: network));
    return details;
  }

  Future<bool> checkGenesis() async {
    final block = await provider.request(TronRequestGetBlockByNum(num: 0));
    return block["blockID"] == network.genesisBlock;
  }

  Future<bool> checkSolidityChainId() async {
    final chainId = await ethClient.getChainId();
    return chainId.toInt() == network.tronNetworkType.genesisBlockNumber;
  }

  Future<IResult<TronScanAccountTokens>> getTronScanAccountTokens(TronAddress address,
      {int start = 0}) async {
    final tokens = await provider.netApi.httpGet<Map<String, dynamic>>(
        TronClientUtils.buildTronScanUrl(
            address: address, chain: network.tronNetworkType, start: start),
        headers: TronClientUtils.getHeaders(network.tronNetworkType),
        responseType: StreamEncoding.map);
    return tokens.mapCatchAsync((e) {
      return TronScanAccountTokens.fromJson(e);
    });
  }

  Future<void> _fetchTrc10TokenMetadatas(List<TronNetworkToken> tokens) async {
    final trc10Tokens = tokens
        .where((e) => e.token.tronTokenType.isTrc10 && e.status.allowRetry)
        .toList();
    if (trc10Tokens.isEmpty) return;

    for (final i in trc10Tokens) {
      i.setPending();
    }
    final issueList = await IResult.call(
      () async {
        return await getIssueAssetList();
      },
      onError: (exception, trace) => AppLogData(
          runtime: runtimeType,
          function: "_fetchTrc10TokenMetadatas",
          err: exception,
          trace: trace.toString()),
    );

    final issueTokens = issueList.ok() ?? [];
    for (final i in trc10Tokens) {
      final token =
          issueTokens.firstWhereNullable((element) => element.id == i.token.issuer);
      assert(issueList.isErr || token != null, "unknow trc10 asset.");
      if (token == null) {
        i.setError();
        continue;
      }
      i.updaetTokenMetadata(Token(
          name: token.name,
          symbol: token.abbr ?? token.name,
          decimal: token.precision ?? 0));
    }
  }

  @override
  Stream<List<TronNetworkToken>> getAccountTokensStream(TronAddress address) {
    final controller = SafeStreamController<List<TronNetworkToken>>(
        name: "TronClient.getAccountTokensStream");
    void add(List<TronNetworkToken> tokens) {
      if (!controller.isClosed) {
        controller.add(tokens);
      }
    }

    void error(Object err) {
      if (!controller.isClosed) controller.addError(IExceptionUtils.findError(err));
    }

    void close() {
      if (!controller.isClosed) controller.close();
    }

    Future<void> fetchTokens() async {
      try {
        final result = await IResult.call(() async => await getAccount(address));
        if (result.isErr) {
          error(result.unwrapErr().exception);
          close();
          return;
        }

        final account = result.unwrap();
        List<TronNetworkToken> trc10Tokens = [];
        if (account != null && account.assetV2.isNotEmpty) {
          trc10Tokens = account.assetV2
              .map((e) => TronTRC10Token.create(
                  balance: e.value,
                  token: Token(name: e.key, symbol: e.key, decimal: 0),
                  tokenID: e.key))
              .map((e) => TronNetworkToken(token: e))
              .toList();
          add(trc10Tokens);
          _fetchTrc10TokenMetadatas(trc10Tokens);
        }

        int max = TronClientUtils.tronScanMaxTokenLimit;
        int offset = 0;
        while (max == TronClientUtils.tronScanMaxTokenLimit) {
          final tronscanAssets = await getTronScanAccountTokens(address,
              start: offset * TronClientUtils.tronScanMaxTokenLimit);
          if (tronscanAssets.isErr) {
            error(tronscanAssets.unwrapErr().exception);
            close();
            return;
          }
          final tokens = tronscanAssets.unwrap().tokens;
          final trc10Metadatas =
              tokens.where((e) => e.tokenType == TronTokenTypes.trc10.name).toList();
          for (final i in trc10Tokens) {
            final metadata =
                trc10Metadatas.firstWhereNullable((e) => e.tokenId == i.token.identifier);
            if (metadata != null) {
              i.updaetTokenMetadata(i.token.token
                  .copyWith(assetLogo: APPImage.network(metadata.tokenLogo)));
            }
          }
          final tc20Assets = tokens
              .where((e) => e.tokenType == TronTokenTypes.trc20.name)
              .map((e) => TronNetworkToken(
                  status: NetworkTokenFetchingStatus.success,
                  token: TronTRC20Token.create(
                      balance: e.balance,
                      token: Token(
                          name: e.tokenAbbr,
                          symbol: e.tokenName,
                          decimal: e.tokenDecimal,
                          assetLogo: APPImage.network(e.tokenLogo)),
                      contractAddress: TronAddress(e.tokenId))))
              .toList();
          max = tokens.length;
          offset++;
          add(tc20Assets);
        }
      } catch (e) {
        error(e);
      } finally {
        close();
      }
    }

    controller.onListenListener(fetchTokens);
    controller.onCancelListener(close);

    return controller.stream();
  }

  @override
  Future<WalletTransactionStatus> transactionStatus(
      TronWalletTransaction transaction) async {
    final tx =
        await provider.request(TronRequestGetTransactionById(value: transaction.txId));
    if (tx == null) return WalletTransactionStatus.unknown;
    if (tx.isSuccess) return WalletTransactionStatus.block;
    return WalletTransactionStatus.failed;
  }

  @override
  List<MultiChainServiceClient> services() {
    return [provider.service];
  }

  @override
  Future<bool> verifyService(DefaultAPIProvider provider) async {
    if (provider == this.provider.service.provider) {
      return checkGenesis();
    }
    if (provider == ethClient.provider.service.provider) {
      return checkSolidityChainId();
    }
    return false;
  }
}
