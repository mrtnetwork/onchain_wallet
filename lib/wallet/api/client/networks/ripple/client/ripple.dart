import 'dart:async';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/api/client/core/client.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/ripple/methods/methods.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/ripple/types/types.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/ripple/utils/utils.dart';
import 'package:on_chain_wallet/wallet/api/provider/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/services/default.dart';
import 'package:on_chain_wallet/wallet/api/service/types/network_providers.dart';
import 'package:on_chain_wallet/wallet/models/network/network.dart';
import 'package:on_chain_wallet/wallet/models/networks/ripple/ripple.dart';
import 'package:on_chain_wallet/wallet/models/token/token.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/xrp.dart';
import 'package:xrpl_dart/xrpl_dart.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class _RippleApiProviderConst {
  static const int accountNotFound = 19;
  static const int avarageDayLedger = 200000;
  static const int rippleEpochTime = 946684800;
}

class XRPNetworkClient extends NetworkClient<XRPWalletTransaction, RippleNetworkToken,
    XRPBaseAddress, WalletXRPNetwork> {
  @override
  final XRPNetworkProvider networkProvider;
  XRPNetworkClient._(
      {required this.provider, required super.network, required this.networkProvider});
  final DefaultProvider<XRPProvider<MultiChainServiceClient>, XRPRequestDetails> provider;

  factory XRPNetworkClient.fromProvider({
    required XRPNetworkProvider provider,
    required WalletXRPNetwork network,
    required INetApi netApi,
  }) {
    return XRPNetworkClient._(
      network: network,
      networkProvider: provider,
      provider: DefaultProvider(XRPProvider(MultiChainServiceClient.fromProvider(
          provider: provider.provider, netApi: netApi))),
    );
  }
  factory XRPNetworkClient.fromService(
      {required XRPNetworkProvider provider,
      required WalletXRPNetwork network,
      required MultiChainServiceClient service}) {
    assert(service.provider == provider.provider);
    return XRPNetworkClient._(
        network: network,
        networkProvider: provider,
        provider: DefaultProvider(XRPProvider(service)));
  }

  Future<BigInt> getAccountBalance(XRPBaseAddress address) async {
    final accountInfo = await getAccountInfo(address.classicAddress);
    if (accountInfo == null) return BigInt.zero;
    return BigintUtils.parse(accountInfo.accountData.balance);
  }

  Future<int> getAccountSequence(XRPBaseAddress address) async {
    final accountInfo = await provider.request(XRPRequestAccountInfo(
        account: address.classicAddress, ledgerIndex: XRPLLedgerIndex.current));
    return accountInfo.accountData.sequence;
  }

  Future<int> getLedgerIndex() async {
    final index = await provider.request(XRPRequestLedgerCurrent());
    return index;
  }

  Future<SimulateResult> simulateTx(SubmittableTransaction transaction) async {
    return await provider
        .request(XRPRequestSimulateTx(txBlob: transaction.toTransactionBlob()));
  }

  Future<List<XRPIssueToken>> getAccountTokens(XRPBaseAddress address) async {
    return await provider.request(XRPRPCFetchTokens(account: address));
  }

  Future<int> getCurrentLedger() async {
    return await provider.request(XRPRequestLedgerCurrent());
  }

  Future<int> getLedgerDateTime(int index) async {
    final ledger = await provider
        .request(XRPRequestLedger(ledgerIndex: XRPLLedgerIndex.index(index.toString())));
    return ledger.closeTime;
  }

  Future<XRPLAccountTxs> getAccountTxes(
      {required XRPBaseAddress address, int? ledger}) async {
    dynamic marker;
    if (ledger == null) {
      final current = await getCurrentLedger();
      ledger = current - _RippleApiProviderConst.avarageDayLedger;
      assert(ledger > 0);
    }
    List<XRPLAccountTx> transactions = [];
    int ledgerIndexMax = ledger;
    while (true) {
      final txes = await provider.request(XRPRequestAccountTx(
          account: address.classicAddress,
          binary: false,
          ledgerIndexMin: ledger,
          marker: marker));
      ledgerIndexMax = txes.ledgerIndexMax;
      for (final i in txes.transactions) {
        if (i.txJson == null) continue;
        final validate = i.validated ?? false;
        final int? date = i.txJson!.date;
        assert(i.txJson?.hash != null);
        if (validate && date == null || i.txJson!.hash == null) continue;
        transactions.add(XRPLAccountTx(
            transaction: i.txJson!,
            txId: i.txJson!.hash!,
            ledgerTime: date == null
                ? null
                : DateTimeUtils.fromSecondsSinceEpoch(
                    date + _RippleApiProviderConst.rippleEpochTime)));
      }
      if (txes.marker == null) break;
      marker = txes.marker;
    }
    return XRPLAccountTxs(
        txes: transactions, latestLedger: ledgerIndexMax, address: address);
  }

  Future<List<XRPNFToken>> getAccountNtfs({required XRPBaseAddress address}) async {
    final nfts =
        await provider.request(XRPRPCAccountNFTs(account: address.classicAddress));
    return nfts;
  }

  Future<XRPAccountObjectEntry?> getAccountSignerList(String address) async {
    try {
      return await provider.request(XRPRPCSignerAccountObject(account: address));
    } on APIError catch (e) {
      if (e.errorCode == _RippleApiProviderConst.accountNotFound) {
        return null;
      }
      rethrow;
    }
  }

  Future<BaseAccountInfoResponse?> getAccountInfo(String address) async {
    try {
      return await provider.request(XRPRequestAccountInfo(account: address));
    } on APIError catch (e) {
      if (e.errorCode == _RippleApiProviderConst.accountNotFound) {
        return null;
      }
      rethrow;
    }
  }

  Future<(String?, XRPAccountObjectEntry?)?> getAccountRegularAndSignerList(
      String address) async {
    final account = await getAccountInfo(address);
    if (account == null) return null;
    final signers = await getAccountSignerList(address);
    if (signers == null && account.accountData.regularKey == null) {
      return null;
    }
    final signerObject = (signers?.signerEntries.isEmpty ?? true) ? null : signers!;
    return (account.accountData.regularKey, signerObject);
  }

  Future<List<RippleIssueToken>> accountTokens(IXRPAddress address) async {
    final tokens =
        await provider.request(XRPRPCFetchTokens(account: address.networkAddress));
    return tokens
        .map((e) => RippleIssueToken.create(
            balance: e.balance,
            token: NonDecimalToken(name: e.currency, symbol: e.currency),
            issuer: e.issuer.classicAddress,
            assetCode: e.currency))
        .toList();
  }

  Future<List<RippleIssueToken>> _accountTokens(XRPBaseAddress address) async {
    final tokens = await provider
        .request(XRPRPCFetchTokens(account: address, allowObligations: false));
    return tokens
        .map((e) => RippleIssueToken.create(
            balance: e.balance,
            token: NonDecimalToken(name: e.currency, symbol: e.currency),
            issuer: e.issuer.classicAddress,
            assetCode: e.currency))
        .toList();
  }

  Future<ServerInfoResult> getServerInfo() async {
    return await provider.request(XRPRequestServerInfo());
  }

  Future<SubmitResult> sendTransaction(String blob) async {
    return await provider.request(XRPRequestSubmit(txBlob: blob));
  }

  @override
  Future<WalletTransactionStatus> transactionStatus(
      XRPWalletTransaction transaction) async {
    return await provider
        .request(XRPRequestTransactionStatus(transaction: transaction.txId));
  }

  Future<void> _fetchTokenMetadata(RippleNetworkToken token) async {
    if (!token.status.allowRetry) return;
    if (!network.coinParam.chainType.isMainnet) {
      token.setSuccess();
      return;
    }
    token.setPending();
    final metadataJson = await provider.netApi.httpGet<Map<String, dynamic>>(
        RippleClientUtils.buildXrplMetaUrl(token.token.assetCode, token.token.issuer),
        headers: HttpConst.applicationJsonContentType,
        responseType: StreamEncoding.map);
    final result =
        await metadataJson.mapCatchAsync((metadata) => XRPLMetaAsset.fromJson(metadata));
    final metadata = result.ok();
    if (metadata == null) {
      token.setSuccess();
      return;
    }
    final updateToken = Token(
        name: token.token.token.name,
        symbol: token.token.token.symbol,
        decimal: 0,
        assetLogo: APPImage.network(metadata.meta.token.icon));
    token.updaetTokenMetadata(updateToken);
  }

  @override
  Stream<List<RippleNetworkToken>> getAccountTokensStream(XRPBaseAddress address) {
    final controller = SafeStreamController<List<RippleNetworkToken>>(
        name: "XRPNetworkClient.getAccountTokensStream");
    void add(List<RippleIssueToken> splTokens) {
      final tokens = splTokens.map((e) => RippleNetworkToken(token: e)).toList();
      if (!controller.isClosed) {
        controller.add(tokens);
        for (final i in tokens) {
          _fetchTokenMetadata(i);
        }
      }
    }

    void error(Object err) {
      if (!controller.isClosed) controller.addError(err);
    }

    void close() {
      if (!controller.isClosed) controller.close();
    }

    Future<void> fetchTokens() async {
      final tokens = await IResult.call(() async {
        return _accountTokens(address);
      });
      if (tokens.isErr) {
        error(tokens.unwrapErr().exception);
        close();
        return;
      }
      add(tokens.unwrap());
      close();
    }

    controller.onListenListener(fetchTokens);
    controller.onCancelListener(close);

    return controller.stream();
  }

  Future<bool> validateNetworkId() async {
    final server = await getServerInfo();
    return server.info.networkId == network.coinParam.networkId;
  }

  @override
  List<MultiChainServiceClient> services() {
    return [provider.service];
  }

  @override
  Future<bool> verifyService(DefaultAPIProvider provider) async {
    if (provider == this.provider.service.provider) {
      return validateNetworkId();
    }
    return false;
  }
}
