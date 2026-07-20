import 'dart:async';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain/solidity/address/core.dart';
import 'package:on_chain_swap/on_chain_swap.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/api/client/core/client.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/ethereum/methods/methods.dart';
import 'package:on_chain_wallet/wallet/api/provider/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/services/default.dart';
import 'package:on_chain_wallet/wallet/api/service/types/network_providers.dart';
import 'package:on_chain_wallet/wallet/models/models.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

abstract mixin class EthereumClientMethods {
  DefaultProvider<EthereumProvider<MultiChainServiceClient>, EthereumRequestDetails>
      get provider;

  Future<FeeHistorical> getHistoricalFee() async {
    final historical = await provider.request(EthereumRequestGetFeeHistory(
        blockCount: 10,
        newestBlock: BlockTagOrNumber.latest,
        rewardPercentiles: [30, 60, 99]));
    return historical!.toFee();
  }

  Future<(BigInt, bool)> getNetworkInfo() async {
    final BigInt chainId = await provider.request(EthereumRequestGetChainId());
    try {
      final eip = await provider.request(EthereumRequestGetFeeHistory(
          blockCount: 25,
          newestBlock: BlockTagOrNumber.pending,
          rewardPercentiles: [25, 50, 90]));
      return (chainId, eip != null);
    } on APIError {
      return (chainId, false);
    }
  }

  Future<BigInt> gasPrice() async {
    final historical = await provider.request(EthereumRequestGetGasPrice());
    return historical;
  }

  Future<BigInt> estimateGasLimit(Map<String, dynamic> estimateDetails) async {
    final estimate =
        await provider.request(EthereumRequestEstimateGas(transaction: estimateDetails));
    return estimate;
  }

  Future<int> getAccountNonce(ETHAddress account) async {
    final nonce = await provider
        .request(EthereumRequestGetTransactionCount(address: account.address));
    return nonce;
  }

  Future<String> sendRawTransaction(String digest) async {
    final txID =
        await provider.request(EthereumRequestSendRawTransaction(transaction: digest));
    return txID;
  }

  Future<bool> isContract(SolidityAddress address) async {
    final code =
        await provider.request(EthereumRequestGetCode(address: address.toSolidityHex()));
    return code != null;
  }

  Future<dynamic> dynamicCall({required String method, dynamic params}) async {
    return await provider
        .requestDynamic(EthereumRequestDynamic(methodName: method, params: params));
  }

  Future<Token?> getErc20Details(SolidityAddress contractAddress) async {
    try {
      final decimal = await provider.request(
          RPCERC20Decimal(contractAddress, blockNumber: BlockTagOrNumber.latest));
      if (decimal == null) return null;
      String? name;
      String? symbol;

      final symbolQuery = await IResult.call(() async => await provider.request(
          RPCERC20Symbol(contractAddress, blockNumber: BlockTagOrNumber.latest)));
      symbol = symbolQuery.ok();
      final nameQuery = await IResult.call(() async => await provider
          .request(RPCERC20Name(contractAddress, blockNumber: BlockTagOrNumber.latest)));
      name = nameQuery.ok();
      name ??= symbol;
      symbol ??= name;
      return Token(
          name: name ?? "Unknown", symbol: symbol ?? "Unknown", decimal: decimal);
    } on APIError {
      return null;
    }
  }

  Future<SolidityToken?> getAccountERC20Token(
      SolidityAddress account, SolidityAddress contractAddress) async {
    final token = await getErc20Details(contractAddress);
    if (token == null) return null;
    final balance = await provider
        .request(RPCERC20TokenBalance(contractAddress.toSolidityHex(), account));
    if (contractAddress is TronAddress) {
      return TronTRC20Token.create(
          balance: balance, token: token, contractAddress: contractAddress);
    }
    return ETHERC20Token.create(
        balance: balance, token: token, contractAddress: contractAddress as ETHAddress);
  }

  Future<BigInt> getChainId() async {
    return await provider.request(EthereumRequestGetChainId());
  }

  Future<BigInt> getAllowance(
      {required ETHAddress contract,
      required ETHAddress owner,
      required ETHAddress spender}) async {
    final function = EthereumAbiCons.getAllowance;
    final result = await provider.request(EthereumRequestFunctionCall(
        contractAddress: contract.address, function: function, params: [owner, spender]));
    return result[0];
  }

  Future<BigInt> getBalance(ETHAddress address) async {
    return await provider.request(EthereumRequestGetBalance(address: address.address));
  }

  Future<BigInt> getTokenBalance(
      {required SolidityAddress address, required SolidityAddress contract}) async {
    return await provider
        .request(RPCERC20TokenBalance(contract.toSolidityHex(), address));
  }

  Future<WalletTransactionStatus> transactionStatus(
      EthWalletTransaction transaction) async {
    final receipt = await provider
        .request(EthereumRequestGetTransactionReceipt(transactionHash: transaction.txId));
    if (receipt == null) return WalletTransactionStatus.unknown;
    final status = receipt.status;
    if (status != null && !status) {
      return WalletTransactionStatus.failed;
    }
    return WalletTransactionStatus.block;
  }

  Future<TransactionReceipt> trackTransaction(
      {required String transactionId,
      Duration timeout = const Duration(minutes: 5),
      Duration periodicTimeOut = const Duration(seconds: 3)}) async {
    Timer? timer;
    try {
      final Completer<TransactionReceipt> completer = Completer<TransactionReceipt>();
      timer = Timer.periodic(periodicTimeOut, (t) async {
        final receipt = await provider
            .request(EthereumRequestGetTransactionReceipt(transactionHash: transactionId))
            .catchError((e, s) {
          return null;
        });
        if (receipt != null && !completer.isCompleted) {
          completer.complete(receipt);
        }
      });
      final receipt = await completer.future.timeout(timeout);
      return receipt;
    } on TimeoutException {
      throw AppException("transaction_confirmation_failed");
    } finally {
      timer?.cancel();
      timer = null;
    }
  }

  Future<SwapEthereumAccountAssetBalance> getAccountsAssetBalance(
      ETHSwapAsset asset, ETHAddress account) async {
    if (asset.isContract && asset.contractAddress == null) {
      throw APIErrorConst.unexpectedRequestData;
    }

    return SwapEthereumAccountAssetBalance(
        address: account,
        balance: asset.isNative
            ? await getBalance(account)
            : await getTokenBalance(address: account, contract: asset.contractAddress!),
        asset: asset);
  }

  Stream<List<EthereumNetworkToken>> getAccountTokensStream(ETHAddress address) {
    final controller = SafeStreamController<List<EthereumNetworkToken>>(
        name: "EthereumClientMethods.getAccountTokensStream");

    void close() {
      if (!controller.isClosed) controller.close();
    }

    controller.onListenListener(close);
    controller.onCancelListener(close);
    return controller.stream();
  }

  Future<BigInt?> getBlockHeight() async {
    final block = await provider.request(EthereumRequestGetBlockNumber());
    return BigInt.from(block);
  }
}

class EthereumNetworkClient extends NetworkClient<
    EthWalletTransaction,
    EthereumNetworkToken,
    ETHAddress,
    WalletEthereumNetwork> with EthereumClientMethods implements BaseSwapEthereumClient {
  @override
  final EthereumNetworkProvider networkProvider;
  EthereumNetworkClient._(
      {required this.provider, required super.network, required this.networkProvider});

  factory EthereumNetworkClient.fromProvider({
    required EthereumNetworkProvider provider,
    required WalletEthereumNetwork network,
    required INetApi netApi,
  }) {
    return EthereumNetworkClient._(
      network: network,
      networkProvider: provider,
      provider: DefaultProvider(EthereumProvider(MultiChainServiceClient.fromProvider(
          provider: provider.provider, netApi: netApi))),
    );
  }
  factory EthereumNetworkClient.fromService({
    required EthereumNetworkProvider provider,
    required WalletEthereumNetwork network,
    required MultiChainServiceClient service,
  }) {
    assert(service.provider == provider.provider);
    return EthereumNetworkClient._(
        network: network,
        networkProvider: provider,
        provider: DefaultProvider(EthereumProvider(service)));
  }
  @override
  final DefaultProvider<EthereumProvider<MultiChainServiceClient>, EthereumRequestDetails>
      provider;

  Future<bool> checkNetworkChainId() async {
    if (network.type != NetworkType.ethereum) return false;
    final networkChainId = network.cast<WalletEthereumNetwork>().coinParam.chainId;
    final chainId = await getChainId();
    return chainId == networkChainId;
  }

  @override
  Future<bool> verifyService(DefaultAPIProvider provider) async {
    if (provider == this.provider.service.provider) {
      final BigInt chainId = await this.provider.request(EthereumRequestGetChainId());
      return chainId == network.coinParam.chainId;
    }
    return false;
  }

  @override
  List<MultiChainServiceClient> services() {
    return [provider.service];
  }
}

class EthereumClient with EthereumClientMethods {
  EthereumClient({required this.provider});
  factory EthereumClient.fromService(MultiChainServiceClient service) {
    return EthereumClient(provider: DefaultProvider(EthereumProvider(service)));
  }

  factory EthereumClient.fromProviders({
    required DefaultAPIProvider provider,
    required INetApi netApi,
  }) {
    return EthereumClient(
      provider: DefaultProvider(EthereumProvider(
          MultiChainServiceClient.fromProvider(provider: provider, netApi: netApi))),
    );
  }

  @override
  final DefaultProvider<EthereumProvider<MultiChainServiceClient>, EthereumRequestDetails>
      provider;

  void dispose() {
    provider.service.dispose();
  }
}
