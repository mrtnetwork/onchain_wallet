import 'dart:async';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/api/client/core/client.dart';
import 'package:on_chain_wallet/wallet/api/provider/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/services/default.dart';
import 'package:on_chain_wallet/wallet/api/service/types/network_providers.dart';
import 'package:on_chain_wallet/wallet/constant/networks/stellar.dart';
import 'package:on_chain_wallet/wallet/models/network/network.dart';
import 'package:on_chain_wallet/wallet/models/networks/stellar/stellar.dart';
import 'package:on_chain_wallet/wallet/models/token/network/token.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/stellar.dart';
import 'package:stellar_dart/stellar_dart.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class StellarClient extends NetworkClient<StellarWalletTransaction, StellarNetworkToken,
    StellarAddress, WalletStellarNetwork> {
  @override
  final StellarNetworkProvider networkProvider;
  StellarClient._(
      {required this.horizonProvider,
      required this.sorobanProvider,
      required super.network,
      required this.networkProvider});
  final DefaultProvider<StellarProvider<MultiChainServiceClient>, StellarRequestDetails>
      horizonProvider;
  final DefaultProvider<StellarProvider<MultiChainServiceClient>, StellarRequestDetails>
      sorobanProvider;

  factory StellarClient.fromProvider({
    required StellarNetworkProvider provider,
    required WalletStellarNetwork network,
    required INetApi netApi,
  }) {
    return StellarClient._(
        networkProvider: provider,
        horizonProvider: DefaultProvider(StellarProvider(
            MultiChainServiceClient.fromProvider(
                provider: provider.horizon, netApi: netApi))),
        sorobanProvider: DefaultProvider(StellarProvider(
            MultiChainServiceClient.fromProvider(
                provider: provider.soroban, netApi: netApi))),
        network: network);
  }
  factory StellarClient.fromService({
    required StellarNetworkProvider provider,
    required WalletStellarNetwork network,
    required MultiChainServiceClient horizon,
    required MultiChainServiceClient soroban,
  }) {
    assert(provider.horizon == horizon.provider);
    assert(provider.soroban == soroban.provider);
    return StellarClient._(
        networkProvider: provider,
        horizonProvider: DefaultProvider(StellarProvider(horizon)),
        sorobanProvider: DefaultProvider(StellarProvider(soroban)),
        network: network);
  }

  Future<StellarAccountResponse?> getAccount(StellarAddress address) async {
    try {
      return await horizonProvider.request(HorizonRequestAccount(address.baseAddress));
    } on APIError catch (e) {
      if (e.statusCode == APIErrorConst.notFoundStatusCode) return null;
      rethrow;
    }
  }

  Future<StellarAllTransactionResponse?> submitTx(String envelopeXdr) async {
    final r = await horizonProvider
        .requestDynamic(HorizonRequestSubmitTransaction(envelopeXdr));
    try {
      return StellarAllTransactionResponse.fromJson(r);
    } catch (e) {
      return null;
    }
  }

  Future<int> getBaseReserve() async {
    final result = await horizonProvider.request(const HorizonRequestLedgers());
    return result.first.baseReserveInStroops;
  }

  Future<bool> validateHorizon() async {
    final result = await horizonProvider.request(const HorizonRequestNodeInfo());
    return result.networkPassphrase == network.coinParam.stellarChainType.passphrase;
  }

  Future<StellarFeeStatsResponse> feeState() async {
    final result = await horizonProvider.request(const HorizonRequestFeeStats());
    return result;
  }

  Future<String> passphrase() async {
    final result = await sorobanProvider.request(SorobanRequestGetNetwork());
    return result.passphrase;
  }

  Future<bool> validateSoroban() async {
    final passphrase = await this.passphrase();
    return passphrase == network.coinParam.stellarChainType.passphrase;
  }

  @override
  Future<WalletTransactionStatus> transactionStatus(
      StellarWalletTransaction transaction) async {
    final r =
        await horizonProvider.requestDynamic(HorizonRequestTransaction(transaction.txId));
    final tx = MethodUtils.fallbackOnException(
      () => StellarTransactionResponse.fromJson(r),
      mode: LoggerMode.danger,
      onError: (exception, trace) => AppLogData(
          runtime: runtimeType,
          function: "transactionStatus",
          err: exception,
          trace: trace.toString(),
          msg: "Failed to decode stellar transaction."),
    );
    if (tx != null && !tx.successful) {
      return WalletTransactionStatus.failed;
    }
    return WalletTransactionStatus.block;
  }

  Future<void> _fetchTokenMetadata(StellarNetworkToken token) async {
    if (!token.status.allowRetry) return;
    token.setPending();
    final metadat = await IResult.block<StellarAssetMetadata?>(() async {
      final tokenData = await horizonProvider.request(HorizonRequestAssets(
          assetCode: token.token.assetCode, assetIssuer: token.token.issuer));
      final currentToken = tokenData.firstWhereOrNull((e) =>
          e.assetCode == token.token.assetCode && e.assetIssuer == token.token.issuer);
      final tomlUrl = currentToken?.link.toml.href;
      if (tomlUrl == null) {
        return ResultOk(null);
      }
      final tomlData = await horizonProvider.netApi.httpGet<String>(tomlUrl);
      return tomlData.mapCatchAsync((tomlData) {
        final metadata = StellarAssetMetadata.fromToml(tomlData);
        return metadata.firstWhere((e) =>
            e.code == token.token.assetCode && e.issuer.address == token.token.issuer);
      });
    });
    final result = metadat.ok();
    if (result == null) {
      token.setError();
      return;
    }
    final updatedToken = token.token.updateToken(Token(
        name: result.name,
        symbol: result.code,
        decimal: StellarConst.decimal,
        assetLogo: APPImage.network(result.image)));
    token.setSuccess(updatedToken);
  }

  @override
  Stream<List<StellarNetworkToken>> getAccountTokensStream(StellarAddress address) {
    final controller = SafeStreamController<List<StellarNetworkToken>>(
        name: "StellarClient.getAccountTokensStream");

    Future<void> fetchTokens() async {
      final account = await IResult.call(() async {
        return await getAccount(address);
      });

      if (account.isErr) {
        controller.addError(account.unwrapErr().exception);
        controller.close();
        return;
      }
      final result = account.ok();
      if (result == null) {
        controller.close();
        return;
      }
      final tokens = result.balances
          .whereType<StellarAssetBalanceResponse>()
          .map((e) => e.toIssueToken())
          .map((e) => StellarNetworkToken(token: e))
          .toList();
      controller.add(tokens);
      for (final i in tokens) {
        _fetchTokenMetadata(i);
      }
      controller.close();
    }

    fetchTokens();

    return controller.stream();
  }

  @override
  Future<bool> verifyService(DefaultAPIProvider provider) async {
    if (provider == horizonProvider.service.provider) {
      return validateHorizon();
    }
    if (provider == sorobanProvider.service.provider) {
      return validateSoroban();
    }
    return false;
  }

  @override
  List<MultiChainServiceClient> services() {
    return [horizonProvider.service, sorobanProvider.service];
  }
}
