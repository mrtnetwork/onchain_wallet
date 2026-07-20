import 'dart:async';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/api/client/core/client.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/ton/methods/methods.dart';
import 'package:on_chain_wallet/wallet/api/provider/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/services/default.dart';
import 'package:on_chain_wallet/wallet/api/service/types/network_providers.dart';
import 'package:on_chain_wallet/wallet/api/types/types.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/constant/networks/ton.dart';
import 'package:on_chain_wallet/wallet/models/models.dart';
import 'package:on_chain_wallet/web3/web3/networks/ton/params/params.dart';
import 'package:ton_dart/ton_dart.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class TonNetworkClient extends NetworkClient<TonWalletTransaction, TonNetworkToken,
    TonAddress, WalletTonNetwork> {
  @override
  final TonNetworkProvider networkProvider;
  TonNetworkClient._(
      {required this.provider, required super.network, required this.networkProvider});
  factory TonNetworkClient.fromProvider({
    required TonNetworkProvider provider,
    required WalletTonNetwork network,
    required INetApi netApi,
  }) {
    return TonNetworkClient._(
      network: network,
      networkProvider: provider,
      provider: DefaultProvider(TonProvider(
          MultiChainServiceClient.fromProvider(
              provider: provider.provider, netApi: netApi),
          switch (provider.provider.service) {
            APIProviderServices.tonApi => TonApiType.tonApi,
            APIProviderServices.tonCenter => TonApiType.tonCenter,
            _ => throw WalletExceptionConst.invalidProviderInformation
          })),
    );
  }
  factory TonNetworkClient.fromService(
      {required TonNetworkProvider provider,
      required WalletTonNetwork network,
      required MultiChainServiceClient service}) {
    assert(service.provider == provider.provider);
    return TonNetworkClient._(
        network: network,
        networkProvider: provider,
        provider: DefaultProvider(TonProvider(
            service,
            switch (provider.provider.service) {
              APIProviderServices.tonApi => TonApiType.tonApi,
              APIProviderServices.tonCenter => TonApiType.tonCenter,
              _ => throw WalletExceptionConst.invalidProviderInformation
            })));
  }
  final DefaultProvider<TonProvider<MultiChainServiceClient>, TonRequestDetails> provider;
  bool get isTonCenter => provider.inner.isTonCenter;

  TonApiType get apiType => provider.inner.api;
  final _msgForwardPrices =
      CachedObject<MsgForwardPricesResponse>(interval: const Duration(hours: 1));
  final _gasLimitPrices =
      CachedObject<GasLimitPricesResponse>(interval: const Duration(hours: 1));

  final _storagePrices = CachedObject<List<BlockchainConfig18StoragePricesItem>>(
      interval: const Duration(hours: 1));

  Future<BigInt> getAccountBalance(TonAddress address) async {
    final balance =
        await provider.request(TonRquestGetBalance(address: address, api: apiType));
    if (balance.isNegative) return BigInt.zero;
    return balance;
  }

  Future<BlockchainRawAccountResponse?> getRawAccountReponse(TonAddress address) async {
    if (isTonCenter) return null;
    return await provider.request(TonApiGetBlockchainRawAccount(address.address));
  }

  Future<AccountStateResponse> getStaticState(TonAddress address) async {
    if (isTonCenter) {
      final state =
          await provider.request(TonCenterGetAddressInformation(address.toString()));
      return AccountStateResponse(
          balance: state.balance,
          code: TonHelper.tryToCell(state.code),
          data: TonHelper.tryToCell(state.data),
          state: state.state);
    }
    try {
      final state =
          await provider.request(TonApiGetBlockchainRawAccount(address.toString()));
      return AccountStateResponse(
          balance: state.balance,
          code: TonHelper.tryToCell(state.code),
          data: TonHelper.tryToCell(state.data),
          state: state.status);
    } on APIError catch (e) {
      if (e.message == ApiProviderConst.tonApiEntityNotFound) {
        return AccountStateResponse(
            balance: BigInt.zero,
            code: null,
            data: null,
            state: AccountStatusResponse.uninit);
      }

      rethrow;
    }
  }

  Future<BigInt> getJettonBalance(TonAddress walletAddress) async {
    final result = await getJettonWalletData(walletAddress);
    return result.balance;
  }

  Future<MsgForwardPricesResponse> getMsgFrowardPricesConfig() async {
    return _msgForwardPrices.get(
      onFetch: () async {
        return await provider
            .request(TonRquestGetMsgForwardPricesConfig(apiType, isMasterChan: true));
      },
    );
  }

  Future<GasLimitPricesResponse> getGasLimitPricesConfig() async {
    return _gasLimitPrices.get(
      onFetch: () async {
        return await provider
            .request(TonRquestGetMsgForwardGasLimitPrice(apiType, isMasterChan: true));
      },
    );
  }

  Future<List<BlockchainConfig18StoragePricesItem>> getStoragePrices(
      {bool isMasterChain = true}) async {
    return _storagePrices.get(
      onFetch: () async {
        return await provider.request(
            TonRquestGetMsgForwardStoragePrices(apiType, isMasterChan: isMasterChain));
      },
    );
    // return ;
  }

  Future<TonTransactionFeeDetails> getTransactionFee({
    required TonAddress address,
    required Message message,
    required WalletTonNetwork network,
    required List<OutActionSendMsg> messages,
  }) async {
    return await provider.request(TonRquestGetFee(
        message: message,
        address: address,
        messages: messages,
        api: apiType,
        network: network));
  }

  Future<(String, bool)> submitBoc({required Cell boc}) async {
    final txId = StringUtils.decode(boc.hash(), encoding: StringEncoding.base64);
    try {
      if (isTonCenter) {
        await provider.requestDynamic(TonCenterSendBocReturnHash(boc.toBase64()));
      } else {
        await provider
            .requestDynamic(TonApiSendBlockchainMessage(batch: [], boc: boc.toBase64()));
      }
      return (txId, true);
    } on APIError catch (e) {
      Logging.error(
        fn: () => AppLogData(runtime: runtimeType, function: "sendMessage", err: e),
      );
      rethrow;
    } catch (e) {
      Logging.error(
        fn: () => AppLogData(runtime: runtimeType, function: "sendMessage", err: e),
      );
      return (txId, false);
    }
  }

  Future<TonAddress> getJettonWalletAddress(
      {required TonAddress minterAddress, required TonAddress owner}) async {
    final data =
        await getStateStack(address: minterAddress, method: "get_wallet_address", stack: [
      if (isTonCenter)
        ["tvm.Slice", beginCell().storeAddress(owner).endCell().toBase64()]
      else
        owner.toString()
    ]);
    return data.reader().readAddress();
  }

  Future<JettonWalletState> getJettonWalletData(TonAddress jettonWalletAddress) async {
    final data =
        await getStateStack(method: "get_wallet_data", address: jettonWalletAddress);
    return JettonWalletState.fromTuple(data.reader());
  }

  Future<TonWeb3TransactionMessageInfo> getWeb3TransactionMessageInfo(
      {required ITonAddress address,
      required TonChain account,
      required Web3TonTransactionMessage message}) async {
    final destination =
        account.getOrCreateReceiptFromNetworkAddressSync(address: message.address);
    final StateInit? init = message.stateInit == null
        ? null
        : StateInit.deserialize(message.stateInit!.beginParse());
    if (message.payload == null) {
      return TonWeb3TransactionMessageInfo(
          amount: message.amount,
          destination: destination,
          initState: init,
          network: account.network);
    }
    final info = TonWeb3TransactionPayload.fromPayload(
        payload: message.payload!,
        destination: message.address,
        chainId: network.coinParam.chainId);
    switch (info.type) {
      case TonWeb3TransactionPayloadType.transfer:
      case TonWeb3TransactionPayloadType.jetton:
        break;
      default:
        return TonWeb3TransactionMessageInfo(
            amount: message.amount,
            destination: destination,
            payload: info,
            initState: init,
            network: account.network);
    }

    final jettonInfo = await IResult.call(() async {
      final tokenInfo = await getJettonWalletData(message.address);
      final tokens = (await address.getAccountTokens()).unwrap();
      TonJettonToken? jetton =
          tokens.firstWhereOrNull((e) => e.walletAddress == message.address);

      bool? isAccountJetton = jetton == null ? null : true;
      if (jetton == null) {
        final balance =
            await IResult.call(() async => await getJettonBalance(message.address));
        jetton = await getJettonInfo(TonAccountJettonResponse(
            tokenAddress: tokenInfo.minterAddress,
            balance: balance.ok() ?? BigInt.zero,
            owner: address.networkAddress,
            jettonWalletAddress: message.address));
        final jettonWalletAddress = await IResult.call(() async =>
            await getJettonWalletAddress(
                minterAddress: jetton!.minterAddress, owner: address.networkAddress));
        if (jettonWalletAddress.ok() == message.address) {
          isAccountJetton = true;
        }
      }
      // updateJettonBalance(jetton);
      return (jetton, isAccountJetton);
    });
    if (jettonInfo.isErr) {
      return TonWeb3TransactionMessageInfo(
          amount: message.amount,
          destination: destination,
          initState: init,
          payload: info,
          network: account.network);
    }
    final contractInfo = info as ContractTonTransactionPayload;
    BigInt? transfer;
    if (info.type == TonWeb3TransactionPayloadType.transfer) {
      transfer = info.jettonAmount;
    }
    final TonWeb3TransactionPayload payload = JettonContractTonTransactionPayload(
        payload: info.payload,
        content: contractInfo.contentJson,
        token: jettonInfo.unwrap().$1,
        isAccountJetton: jettonInfo.unwrap().$2,
        transferAmount: transfer,
        type: transfer != null
            ? TonWeb3TransactionPayloadType.transfer
            : TonWeb3TransactionPayloadType.jetton,
        operation: info.operation,
        tonAmount: info.tonAmount);
    return TonWeb3TransactionMessageInfo(
        amount: message.amount,
        destination: destination,
        initState: init,
        payload: payload,
        network: account.network);
  }

  Future<RunMethodResponse> getStateStack(
      {required String method,
      required TonAddress address,
      List<dynamic> stack = const [],
      bool throwOnFail = true}) async {
    final RunMethodResponse response;
    if (isTonCenter) {
      final request = await provider.request(TonCenterRunGetMethod(
          address: address.toString(), methodName: method, stack: stack));
      response = RunMethodResponse(items: request.items, exitCode: request.exitCode);
    } else {
      final request = await provider.request(TonApiExecGetMethodForBlockchainAccount(
          accountId: address.toString(), methodName: method, args: stack.cast()));
      response = RunMethodResponse(items: request.toTuples(), exitCode: request.exitCode);
    }
    return response;
  }

  Future<MinterWalletState> getJettonData(TonAddress jettonAddress) async {
    final data = await getStateStack(method: "get_jetton_data", address: jettonAddress);
    return MinterWalletState.fromTupple(data.reader());
  }

  final Map<TonAddress, Cell> _contractsCode = {};

  Future<Cell?> getContractCode(TonAddress address) async {
    if (_contractsCode.containsKey(address)) return _contractsCode[address];
    final state = await getStaticState(address);
    if (state.code == null) return null;
    _contractsCode[address] = state.code!;
    return state.code!;
  }

  Future<TonJettonToken> getJettonInfo(TonAccountJettonResponse jetton) async {
    final result = await getJettonData(jetton.tokenAddress);
    final metdata = TokneMetadataUtils.loadContent(result.content);
    final noneVerifiedToken = TonJettonToken.create(
        balance: jetton.balance,
        token: Token(
            name: jetton.tokenAddress.address,
            symbol: jetton.tokenAddress.address,
            decimal: 0),
        minterAddress: jetton.tokenAddress,
        walletAddress: jetton.jettonWalletAddress);
    if (metdata.type == TokenContentType.unknown) {
      return noneVerifiedToken;
    }
    JettonOnChainMetadata? onChainMetadata;
    String? url;
    TokenContentType type = TokenContentType.onchain;
    switch (metdata.type) {
      case TokenContentType.unknown:
        return noneVerifiedToken;
      case TokenContentType.offchain:
        url = (metdata as JettonOffChainMetadata).uri;
        type = TokenContentType.offchain;
        break;
      case TokenContentType.onchain:
        onChainMetadata = metdata.cast<JettonOnChainMetadata>();
        break;
    }

    url ??= onChainMetadata?.uri;

    if (url == null) {
      return TonJettonToken.create(
        balance: jetton.balance,
        token: Token(
            name: onChainMetadata?.name ?? jetton.tokenAddress.address,
            symbol: onChainMetadata?.symbol ?? jetton.tokenAddress.address,
            decimal: onChainMetadata?.decimals ?? 9),
        minterAddress: jetton.tokenAddress,
        walletAddress: jetton.jettonWalletAddress,
      );
    }
    final json = (await provider.netApi
            .httpGet<Map<String, dynamic>>(url, responseType: StreamEncoding.map))
        .ok();
    if (type == TokenContentType.onchain) {
      return TonJettonToken.create(
        balance: jetton.balance,
        token: Token(
            name: json?["name"] ?? onChainMetadata?.name ?? jetton.tokenAddress.address,
            symbol:
                json?["symbol"] ?? onChainMetadata?.symbol ?? jetton.tokenAddress.address,
            decimal:
                IntUtils.tryParse(json?["decimals"]) ?? onChainMetadata?.decimals ?? 9),
        minterAddress: jetton.tokenAddress,
        walletAddress: jetton.jettonWalletAddress,
      );
    }
    if (json == null) {
      return noneVerifiedToken;
    } else {
      return TonJettonToken.create(
        balance: jetton.balance,
        token: Token(
            name: json["name"] ?? jetton.tokenAddress.address,
            symbol: json["symbol"] ?? jetton.tokenAddress.address,
            decimal: IntUtils.tryParse(json["decimals"]) ?? 9),
        minterAddress: jetton.tokenAddress,
        walletAddress: jetton.jettonWalletAddress,
      );
    }
  }

  Future<bool> validateGlobalId() async {
    final networkId = network.coinParam.chainId.id;
    if (isTonCenter) {
      final result = await provider.request(TonCenterGetMasterchainInfo());
      final latest = result.valueAsMap<Map<String, dynamic>?>("last");
      if (latest == null) return false;
      final header = await provider.request(TonCenterGetBlockHeader(
          workchain: latest.valueAs("workchain"),
          shard: latest.valueAsInt("shard"),
          seqno: latest.valueAsInt("seqno")));
      return header.valueAsInt("global_id") == networkId;
    } else {
      final result = await provider.request(TonApiGetBlockchainMasterchainHead());
      return result.globalId == networkId;
    }
  }

  @override
  Future<WalletTransactionStatus> transactionStatus(
      TonWalletTransaction trransaction) async {
    return provider
        .request(TonRquestTransactionStatus(txId: trransaction.txId, api: apiType));
  }

  @override
  Stream<List<TonNetworkToken>> getAccountTokensStream(TonAddress address) {
    final controller = SafeStreamController<List<TonNetworkToken>>(
        name: "TonNetworkClient.getAccountTokensStream");
    void close() {
      if (!controller.isClosed) controller.close();
    }

    void addErr(Object err) {
      if (!controller.isClosed) controller.addError(err);
    }

    Future<void> fetchToken() async {
      try {
        void add(List<TonAccountJettonResponse> tokens) {
          final jettons = tokens
              .map((e) => TonNetworkToken(
                  status: e.metadata != null
                      ? NetworkTokenFetchingStatus.success
                      : NetworkTokenFetchingStatus.failed,
                  token: TonJettonToken.create(
                      balance: e.balance,
                      token: e.token,
                      minterAddress: e.tokenAddress,
                      walletAddress: e.jettonWalletAddress)))
              .toList();
          if (!controller.isClosed) controller.add(jettons);
        }

        if (isTonCenter) {
          int offset = 0;
          int max = TonCenterV3GetJettonWallets.maximumLimit;
          while (
              !controller.isClosed && max == TonCenterV3GetJettonWallets.maximumLimit) {
            final result = await provider.request(TonCenterV3GetJettonWallets(
                ownerAddress: address.address,
                offset: offset,
                limit: TonCenterV3GetJettonWallets.maximumLimit));
            offset++;
            max = result.jettonWallets.length;
            final fetchedJettons = result.jettonWallets.map((e) {
              final metadata = result.metadata
                  .firstWhereOrNull((t) => t.address == e.jetton)
                  ?.tokens
                  .whereType<JettonWalletTokenInfoMaster>()
                  .firstOrNull;
              return TonAccountJettonResponse(
                  balance: e.balance,
                  tokenAddress: e.jetton,
                  owner: address,
                  jettonWalletAddress: e.address,
                  metadata: metadata == null
                      ? null
                      : Token(
                          name: metadata.name,
                          symbol: metadata.symbol,
                          decimal: metadata.decimals ?? TonConst.deciaml,
                          assetLogo: APPImage.network(metadata.image)));
            }).toList();
            add(fetchedJettons);
          }
          return;
        }
        final result = await provider
            .request(TonApiGetAccountJettonsBalances(accountId: address.address));
        final tokens = result.balances.map((e) {
          return TonAccountJettonResponse(
              tokenAddress: e.jetton.address,
              balance: e.balance,
              owner: address,
              metadata: Token(
                  assetLogo: APPImage.network(e.jetton.image),
                  name: e.jetton.name,
                  symbol: e.jetton.symbol,
                  decimal: e.jetton.decimals),
              jettonWalletAddress: e.walletAddress.address);
        }).toList();
        add(tokens);
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

  @override
  Future<bool> verifyService(DefaultAPIProvider provider) async {
    if (provider == this.provider.service.provider) {
      return await validateGlobalId();
    }
    return false;
  }

  @override
  List<MultiChainServiceClient> services() {
    return [provider.service];
  }
}
