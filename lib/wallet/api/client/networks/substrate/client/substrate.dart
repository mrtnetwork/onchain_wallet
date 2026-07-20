import 'dart:async';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain/ethereum/src/rpc/core/methods.dart';
import 'package:on_chain/ethereum/src/rpc/methds/ethereum/rpc_call.dart';
import 'package:on_chain/ethereum/src/rpc/provider/provider.dart';
import 'package:on_chain/solidity/contract/fragments.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_swap/on_chain_swap.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/substrate/methods/metadata.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:polkadot_dart/polkadot_dart.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

abstract mixin class SubstrateClientMethods
    implements SubstrateNetworkControllerParams, SubstrateEvmNetworkControllerParams {
  EthereumProvider? _evmProvider;
  DefaultProvider<SubstrateProvider<MultiChainServiceClient>, SubstrateRequestDetails>
      get provider;
  SubstrateChainMetadata? _metadata;
  SubstrateChainMetadata? get metadataNullable => _metadata;
  SubstrateChainMetadata get metadata {
    final metadata = _metadata;
    if (metadata == null) {
      throw APIErrorConst.clientIsNotInitialized;
    }
    return metadata;
  }

  BaseSubstrateNetworkController? get _internalController => metadata.controller;

  MetadataApi get api => metadata.metadata;
  String get genesisBlock => metadata.genesis;

  Future<BigInt> getAccountBalance(BaseSubstrateAddress address) async {
    final controller = _internalController;
    if (controller != null) {
      final balance = await controller.getNativeAssetFreeBalance(address);
      return balance?.free ?? BigInt.zero;
    }
    final account = await SubstrateQuickStorageApi.system
        .accountWithDataFrame(api: api, rpc: provider, address: address);
    return account.data.free;
  }

  Future<BigInt> getAccountNonce(BaseSubstrateAddress address) async {
    return await SubstrateQuickStorageApi.system
        .nonce(api: api, rpc: provider, address: address);
  }

  Future<SubstrateBlockHash> getBlockHash({int? atNumber}) async {
    final blockHash =
        await provider.request(SubstrateRequestChainGetBlockHash(number: atNumber));
    if (blockHash == null) {
      throw APIErrorConst.serverUnexpectedResponse;
    }
    return SubstrateBlockHash.hash(blockHash);
  }

  Future<ChainProperties?> systemProperties() async {
    final result =
        await IResult.call(() => provider.request(SubstrateRequestSystemProperties()));
    return result.ok();
  }

  Future<String?> systemChain() async {
    final resilt =
        await IResult.call(() => provider.request(SubstrateRequestSystemChain()));
    return resilt.ok();
  }

  Future<SubstrateBlockHash> getFinalizBlock({int? atNumber}) async {
    final blockHash =
        await provider.request(const SubstrateRequestChainChainGetFinalizedHead());
    return SubstrateBlockHash.hash(blockHash);
  }

  Future<SubstrateHeaderResponse> getBlockHeader({String? atBlockHash}) async {
    final header = await provider
        .request(SubstrateRequestChainChainGetHeader(atBlockHash: atBlockHash));
    return header;
  }

  Future<SubstrateTxIdWithBlock> broadcastTransaction(List<int> extrinsic) async {
    int? blockId;
    try {
      final finalizeHash =
          await provider.request(SubstrateRequestChainChainGetFinalizedHead());
      final finalBlockHead = await provider
          .request(SubstrateRequestChainGetBlock(atBlockHash: finalizeHash));
      blockId = finalBlockHead.block.header.number;
    } catch (_) {}
    final txId = await provider.request(SubstrateRequestAuthorSubmitExtrinsic(
        BytesUtils.toHexString(extrinsic, prefix: "0x")));
    return SubstrateTxIdWithBlock(txId: txId, block: blockId);
  }

  Future<SubstrateBlockWithEra> finalizeBlockWithEra() async {
    final finalizeBlock =
        await provider.request(const SubstrateRequestChainChainGetFinalizedHead());
    final header = await getBlockHeader(atBlockHash: finalizeBlock);
    return SubstrateBlockWithEra(
        block: finalizeBlock,
        era: header.toMortalEra(period: APPSubstrateConst.defaultEraPeriod),
        blockHashBytes: BytesUtils.fromHexString(finalizeBlock));
  }

  Future<QueryFeeDetails> queryFeeDetails({required List<int> extrinsic}) async {
    return await provider.request(
        SubstrateRequestRuntimeTransactionPaymentApiQueryFeeDetails.fromExtrinsic(
            exirceBytes: extrinsic));
  }

  Future<QueryFeeInfo> queryFeeInfo({required List<int> extrinsic}) async {
    return await provider.request(
        SubstrateRequestRuntimeTransactionPaymentApiQueryInfo.fromExtrinsic(
            exirceBytes: extrinsic));
  }

  // Future<XCMVersion> safeXcmVersion(){}

  Future<SubstrateDispatchResult<CallDryRunEffects>?> dryRunCall(
      {required BaseSubstrateAddress owner, required List<int> callData}) async {
    if (!metadata.hasDryRunApi) return null;
    return await SubstrateQuickRuntimeApi.dryRun.dryRunCall(
        owner: owner,
        callBytes: callData,
        api: metadata.metadata,
        rpc: provider,
        version: metadata.xcmVersion);
  }

  Future<BigInt?> quotePriceTokensForExactTokens(
      {required XCMMultiLocation baseAsset,
      required XCMMultiLocation asset,
      required BigInt amount,
      bool includeFee = true}) async {
    if (!metadata.hasCurrencyConvertionApi) {
      return null;
    }
    return await SubstrateQuickRuntimeApi.assetConversion.quotePriceTokensForExactTokens(
        params: QuotePriceParams(
            includeFee: includeFee, amount: amount, assetB: baseAsset, assetA: asset),
        api: metadata.metadata,
        rpc: provider);
  }

  Future<SubstrateFeeInfos> estimateFee(
      {required List<int> extrinsic, required WalletSubstrateNetwork network}) async {
    final fee = await provider.request(
        SubstrateRequestRuntimeTransactionPaymentApiQueryFeeDetails.fromExtrinsic(
            exirceBytes: extrinsic));
    return SubstrateFeeInfos.fromFeeDetails(fee: fee, network: network);
  }

  Future<QueryFeeInfo> callQueryInfo(
      {required List<int> call,
      String? pallet,
      String? method,
      required BaseSubstrateAddress owner,
      SubstrateKeyAlgorithm? fakeSignatureAlgorithm =
          SubstrateKeyAlgorithm.ecdsa}) async {
    final extrinsic = await SubstrateTransactionBuilder.buildAndSignTransactionStatic(
        owner: owner,
        calls: SubstrateTransactionSubmitableParams(calls: [
          SubstrateEncodedCallParams(
              pallet: pallet ?? '', method: method ?? '', bytes: call)
        ]),
        provider: MetadataWithProvider(
            provider: provider,
            metadata: MetadataWithExtrinsic(api: api, extrinsic: metadata.extrinsic)),
        params: TransactionBuilderParams(
          nonce: BigInt.zero,
          genesisHash: genesisBlock,
          specVersion: metadata.specVersion,
          transactionVesrion: metadata.transactionVersion,
        ),
        fakeSignatureAlgorithm: metadata.extrinsic.crypto.cryptoAlgoritms.firstWhere(
            (e) => e == fakeSignatureAlgorithm,
            orElse: () => metadata.extrinsic.crypto.cryptoAlgoritms.first),
        fakeSignature: true);

    final feeInfo = await provider.request(
        SubstrateRequestRuntimeTransactionPaymentApiQueryInfo.fromExtrinsic(
            exirceBytes: extrinsic.serialize()));
    return feeInfo;
  }

  Future<MetadataApi?> getLastestVersionedMetadata() async {
    List<int> versionIds = [];
    try {
      versionIds =
          await provider.request(const SubstrateRequestRuntimeMetadataGetVersions());
    } on APIError catch (_) {}
    versionIds.sort((a, b) => b.compareTo(a));
    for (final i in versionIds) {
      if (APPSubstrateConst.supportedVersion.contains(i)) {
        try {
          final request = SubstrateGetApiAt(i);
          final metadata = await provider.requestDynamic(request);
          final supported = request.onResonse(metadata);
          if (supported != null) return supported;
        } on APIError {
          rethrow;
        } catch (_) {}
      }
    }
    final request = const SubstrateGetStateApi();
    final metadata = await provider.request(request);
    return metadata;
  }

  Future<SubstrateChainMetadata?> loadApi() async {
    final api = await getLastestVersionedMetadata();
    if (api == null) return null;
    final genesis = (await _loadGenesis()).toHex();
    final methods = await IResult.call(
        () async => await provider.request(SubstrateRequestRpcMethods()));
    assert(methods.isOk, "failed to fetch rpc methods");
    return SubstrateChainMetadata(
        genesis: genesis,
        metadata: api,
        apiParams: this,
        rpcMethods: methods.ok()?.methods ?? []);
  }

  Future<SubstrateBlockHash> _loadGenesis() async {
    final genesis =
        await provider.request(const SubstrateRequestChainGetBlockHash(number: 0));
    if (genesis == null) {
      throw APIErrorConst.serverUnexpectedResponse;
    }
    return SubstrateBlockHash.hash(genesis);
  }

  Future<List<String>> queryStorage(List<SubstrateStorageQueryParams> requests) async {
    final r = await api.queryStorageAtBlock(
        requestes: List.generate(requests.length, (i) {
          final request = requests[i];
          return GetStorageRequest<Object?, Object>(
            palletNameOrIndex: request.pallet,
            methodName: request.storage.name,
          );
        }),
        rpc: provider,
        fromTemplate: false);
    return List.generate(requests.length, (i) {
      final result = r.results[i].result;
      if (result is Map) {
        return StringUtils.fromJson(result, indent: '', toStringEncodable: true);
      }
      return result.toString();
    });
  }

  Future<String> runtimeCall(
      {required String methodName,
      required String apiName,
      List<Object?> inputs = const []}) async {
    final result = await api.runtimeCall(
        rpc: provider,
        fromTemplate: false,
        methodName: methodName,
        apiName: apiName,
        params: inputs);
    if (result is Map) {
      return StringUtils.fromJson(result, indent: '', toStringEncodable: true);
    }
    return result.toString();
  }

  Future<BigInt> getBalance(BaseSubstrateAddress address) async {
    return getAccountBalance(address);
  }

  Future<SubstrateBlockHash> getGenesis() {
    return _loadGenesis();
  }

  Future<String> sendTransaction(Extrinsic extrinsic) async {
    final txInfo = await broadcastTransaction(extrinsic.serialize());
    return txInfo.txId;
  }

  Future<WalletTransactionStatus> transactionStatus(
      SubstrateWalletTransaction transaction) async {
    final block = transaction.block;
    if (block == null) {
      return WalletTransactionStatus.unknown;
    }
    final stream = SubstrateTransactionBuilder.findEextrinsic(
        txId: transaction.txId,
        provider: metadataWitPorvider(),
        extrinsic: transaction.extrinsics,
        blockId: block);
    final result = await stream.first;
    final eventResult = result.txEvents;
    Logging.error(
      when: () => result.status == SubtrateTransactionSubmitionStatus.failed,
      fn: () => AppLogData(
          function: "trackMempoolTransaction",
          runtime: runtimeType,
          data: result.toJson()),
    );
    if (eventResult == null) {
      return WalletTransactionStatus.unknown;
    }
    if (result.status.isSuccess) return WalletTransactionStatus.block;
    return WalletTransactionStatus.failed;
  }

  Future<List<SubstrateMultisigWithCallhash>> getMultisigs(
      BaseSubstrateAddress address) async {
    return await SubstrateQuickStorageApi.multisig
        .multisigsEntires(api: api, rpc: provider, address: address);
  }

  Future<SubstrateMultisigCallData> getMultisig(
      {required SubstrateMultisigCall call,
      required BaseSubstrateAddress address}) async {
    final multisig = await SubstrateQuickStorageApi.multisig
        .multisigs(api: api, rpc: provider, address: address, callHashTx: call.callHash);
    QueryFeeInfo? fee;
    Map<String, dynamic>? content;
    final callBytes = call.callData;
    if (callBytes != null) {
      fee = await callQueryInfo(call: callBytes, owner: address);
      content = MethodUtils.fallbackOnException(
        () => api.decodeCall(callBytes).toJson(),
        mode: LoggerMode.danger,
        onError: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "getMultisig",
            err: exception,
            trace: trace.toString(),
            msg: "Failed to decode transaction call data."),
      );
      if (content == null) {
        throw AppException("failed_to_decode_call_data");
      }
    }
    return SubstrateMultisigCallData(
        call: call, multisig: multisig, weight: fee?.weight, content: content);
  }

  Future<List<SubstrateAccountAssetBalance>> getAddressTokensBalances({
    required BaseSubstrateAddress address,
    required List<Object> identifiers,
  }) async {
    final tokens = await _internalController?.getAccountAssets(
        address: address, knownAssetIds: identifiers);
    return tokens?.balances ?? [];
  }

  Future<SubstrateNetworkAssets> getNetworkAssets() async {
    final internalController = metadata.controller;
    assert(internalController != null, "unsuported network assets.");
    final tokens = await internalController?.getAssets();
    return tokens!;
  }

  Stream<List<SubstrateNetworkToken>> getAccountTokensStream(
      BaseSubstrateAddress address) {
    BaseSubstrateNetworkController? internalController = metadata.controller;

    final controller = SafeStreamController<List<SubstrateNetworkToken>>(
        name: "SubstrateClientMethods.getAccountTokensStream");
    void close() {
      if (!controller.isClosed) controller.close();
    }

    void addErr(Object err) {
      if (!controller.isClosed) controller.addError(err);
    }

    Future<void> fetchToken() async {
      try {
        void add(List<SubstrateAccountAssetBalance> tokens) {
          final jettons = tokens
              .map((e) => SubstrateNetworkToken(
                  status: e.asset.hasMetadata
                      ? NetworkTokenFetchingStatus.success
                      : NetworkTokenFetchingStatus.failed,
                  token: SubstrateToken.create(
                      balance: e.free,
                      token: Token(
                          name: e.asset.name,
                          symbol: e.asset.symbol,
                          decimal: e.asset.decimals ?? 0),
                      assetIdentifier: e.asset.identifier!)))
              .toList();
          if (!controller.isClosed) controller.add(jettons);
        }

        final tokens = await internalController?.getAccountAssets(
            address: address, nativeBalance: false);
        add(tokens?.balances
                .where((e) => e.asset.identifier != null && !e.asset.type.isNative)
                .toList() ??
            []);
      } catch (e) {
        addErr(e);
      } finally {
        close();
      }
    }

    controller.onListenListener(fetchToken);
    controller.onCancelListener(close);

    return controller.stream();
  }

  Future<SubtrateTransactionSubmitionResult> submitExtrinsicAndWatch(
      {required SubstrateSubmitableTransaction extrinsic,
      int maxRetryEachBlock = 10}) async {
    final stream = await SubstrateTransactionBuilder.submitExtrinsicAndWatchStatic(
        extrinsic: extrinsic,
        provider: MetadataWithProvider(
            provider: provider,
            metadata: MetadataWithExtrinsic(api: api, extrinsic: metadata.extrinsic)));
    return stream.first;
  }

  Future<SubstrateTransactionBlockRequirment> transactionBlockRequirment() async {
    final finalizeBlock = (await getFinalizBlock());
    final genesis = await getGenesis();
    final blockHash = finalizeBlock.toHex();

    final header = await getBlockHeader(atBlockHash: blockHash);
    return SubstrateTransactionBlockRequirment(
        blockNumber: header.number,
        era: header.toMortalEra(period: APPSubstrateConst.defaultEraPeriod),
        blockHashBytes: finalizeBlock.bytes,
        genesisBlock: genesis);
  }

  Future<BigInt> _getPoladitAssetBalanceInternal(
      BaseSubstrateAddress account, BigInt assetId) async {
    final balancesEntries = await SubstrateNetworkControllerAssetQueryHelper
        .getAssetsPalletAccountIdentifierBigInt(
            provider: metadataWitPorvider(), address: account, assetIds: [assetId]);
    final balanceEntry =
        balancesEntries.entries.firstWhereNullable((e) => e.key == assetId)?.value;
    if (balanceEntry == null) return BigInt.zero;
    final balance = PolkadotAssetBalance.fromJson(balanceEntry);
    return balance.balance;
  }

  Future<SwapPolkadotAccountAssetBalance> getAccountsAssetBalance(
      PolkadotSwapAsset asset, BaseSubstrateAddress account) async {
    BigInt balance;
    if (!asset.type.isNative) {
      final assetId = asset.assetId;
      if (assetId == null) {
        throw APIErrorConst.unexpectedRequestData;
      }
      final internalController = _internalController;
      if (internalController == null) {
        balance = await _getPoladitAssetBalanceInternal(account, assetId);
      } else {
        final assetBalance = await internalController
            .getAccountAssets(address: account, knownAssetIds: [assetId]);
        balance = assetBalance.balances
                .firstWhereOrNull((e) => e.asset.identifierEqual(assetId))
                ?.free ??
            BigInt.zero;
      }
    } else {
      balance = await getBalance(account);
    }
    return SwapPolkadotAccountAssetBalance(
        address: account, balance: balance, asset: asset);
  }

  Future<BigInt> getBlockHeight() async {
    final header = await getBlockHeader();
    return BigInt.from(header.number);
  }

  MetadataWithProvider metadataWitPorvider() {
    return MetadataWithProvider(
        provider: provider,
        metadata: MetadataWithExtrinsic(api: api, extrinsic: metadata.extrinsic));
  }

  @override
  Future<MetadataWithProvider> loadMetadata(BaseSubstrateNetwork network) async {
    return metadataWitPorvider();
  }

  @override
  Future<
      DefaultProvider<SubstrateProvider<MultiChainServiceClient>,
          SubstrateRequestDetails>> loadProvider(BaseSubstrateNetwork network) async {
    return provider;
  }

  @override
  late final SubstrateEvmNetworkControllerParams evmParams = this;

  @override
  final BaseSubstrateCachedAssetStorage storage =
      DefaultSubstrateCachedAssetStorage(interval: const Duration(hours: 1));

  @override
  Future<RESPONSE> ethCall<RESPONSE extends Object?>(
      {required SubstrateEthereumAddress contract,
      required EvmFunctionAbi<RESPONSE> function,
      required MetadataWithProvider provider,
      List<Object>? params}) async {
    if (_metadata?.rpcMethods.contains(EthereumMethods.call.value) ?? false) {
      final evmProvider = _evmProvider ??= EthereumProvider(provider.provider.service);
      final result = await evmProvider.request(EthereumRequestFunctionCall(
          contractAddress: contract.address,
          function: AbiFunctionFragment.fromJson(function.abi),
          params: params ?? []));

      return function.parser(result.cast());
    }
    final result = await SubstrateQuickRuntimeApi.ethereumRuntimeRPCApis.call(
        api: api,
        rpc: provider.provider,
        from: SubstrateEthereumAddress.zero,
        to: SubstrateEthereumAddress(contract.address),
        inputs: AbiFunctionFragment.fromJson(function.abi).encode(params ?? []),
        gasLmit: BigInt.one);
    final ok = result.ok;
    if (ok == null || !ok.exitReason.isSucceed) {
      throw APIErrorConst.serverUnexpectedResponse;
    }
    final value = AbiFunctionFragment.fromJson(function.abi).decodeOutput(ok.value);
    return function.parser(value.cast());
  }
}

class SubstrateNetworkClient extends NetworkClient<SubstrateWalletTransaction,
        SubstrateNetworkToken, BaseSubstrateAddress, WalletSubstrateNetwork>
    with SubstrateClientMethods
    implements BaseSwapSubstrateClient {
  @override
  final SubstrateNetworkProvider networkProvider;
  SubstrateNetworkClient._(
      {required this.provider, required super.network, required this.networkProvider});

  @override
  final DefaultProvider<SubstrateProvider<MultiChainServiceClient>,
      SubstrateRequestDetails> provider;

  factory SubstrateNetworkClient.fromProvider({
    required SubstrateNetworkProvider provider,
    required WalletSubstrateNetwork network,
    required INetApi netApi,
  }) {
    return SubstrateNetworkClient._(
      network: network,
      networkProvider: provider,
      provider: DefaultProvider(SubstrateProvider(MultiChainServiceClient.fromProvider(
          provider: provider.provider, netApi: netApi))),
    );
  }
  factory SubstrateNetworkClient.fromService(
      {required SubstrateNetworkProvider provider,
      required WalletSubstrateNetwork network,
      required MultiChainServiceClient service}) {
    assert(service.provider == provider.provider);
    return SubstrateNetworkClient._(
        network: network,
        networkProvider: provider,
        provider: DefaultProvider(SubstrateProvider(service)));
  }

  Future<bool> validateNetworkGenesis() async {
    final genesis = await _loadGenesis();
    return StringUtils.hexEqual(genesis.toHex(), network.genesisBlock);
  }

  @override
  List<MultiChainServiceClient> services() {
    return [provider.service];
  }

  @override
  Future<bool> verifyService(DefaultAPIProvider provider) async {
    if (provider == this.provider.service.provider) {
      if (_metadata != null) return true;
      final api = await loadApi();
      if (api == null) return false;
      final metadata = api;
      if (!StringUtils.hexEqual(metadata.genesis, network.genesisBlock)) {
        return false;
      }
      _metadata = metadata;
      return true;
    }

    return false;
  }
}

class SubstrateClient with SubstrateClientMethods {
  SubstrateClient({required this.provider});

  @override
  final DefaultProvider<SubstrateProvider<MultiChainServiceClient>,
      SubstrateRequestDetails> provider;

  factory SubstrateClient.fromProviders({
    required DefaultAPIProvider provider,
    required INetApi netApi,
  }) {
    return SubstrateClient(
      provider: DefaultProvider(SubstrateProvider(
          MultiChainServiceClient.fromProvider(provider: provider, netApi: netApi))),
    );
  }

  void dispose() {
    provider.service.dispose();
  }
}
