import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/api/client/core/client.dart';
import 'package:on_chain_wallet/wallet/api/provider/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/services/default.dart';
import 'package:on_chain_wallet/wallet/api/service/types/network_providers.dart';
import 'package:on_chain_wallet/wallet/constant/networks/solana.dart';
import 'package:on_chain_wallet/wallet/models/network/network.dart';
import 'package:on_chain_wallet/wallet/models/networks/solana/models/solana_account_tokens_info.dart';
import 'package:on_chain_wallet/wallet/models/token/token.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/solana.dart';
import 'package:on_chain/solana/solana.dart';
import 'package:on_chain_swap/on_chain_swap.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class SolanaNetworkClient extends NetworkClient<SolanaWalletTransaction,
    SolanaNetworkToken, SolAddress, WalletSolanaNetwork> implements BaseSwapSolanaClient {
  @override
  final SolanaNetworkProvider networkProvider;
  SolanaNetworkClient._(
      {required this.provider, required super.network, required this.networkProvider});
  final DefaultProvider<SolanaProvider<MultiChainServiceClient>, SolanaRequestDetails>
      provider;

  factory SolanaNetworkClient.fromProvider({
    required SolanaNetworkProvider provider,
    required WalletSolanaNetwork network,
    required INetApi netApi,
  }) {
    return SolanaNetworkClient._(
      network: network,
      networkProvider: provider,
      provider: DefaultProvider(SolanaProvider(MultiChainServiceClient.fromProvider(
          provider: provider.provider, netApi: netApi))),
    );
  }
  factory SolanaNetworkClient.fromService(
      {required SolanaNetworkProvider provider,
      required WalletSolanaNetwork network,
      required MultiChainServiceClient service}) {
    assert(service.provider == provider.provider);
    return SolanaNetworkClient._(
        network: network,
        networkProvider: provider,
        provider: DefaultProvider(SolanaProvider(service)));
  }

  List<SolanaTokenInfo>? _tokenLists;

  Future<BigInt> getAccountBalance(SolAddress address) async {
    final accountInfo = await getAccountInfo(address);
    return accountInfo?.lamports ?? BigInt.zero;
  }

  @override
  Future<SolanaAccountInfo?> getAccountInfo(SolAddress account) async {
    final info = await provider.request(SolanaRequestGetAccountInfo(account: account));
    return info;
  }

  Future<SolanaTokenAccount?> getTokenAccount(SolAddress account) async {
    final info = await provider.request(SolanaRPCGetTokenAccount(account: account));
    return info;
  }

  Future<BigInt> getRent(int space) async {
    final lamports = await provider
        .request(SolanaRequestGetMinimumBalanceForRentExemption(size: space));
    return lamports;
  }

  Future<BigInt?> getFee(SolanaTransaction transaction) async {
    return await provider.request(SolanaRequestGetFeeForMessage(
        encodedMessage: StringUtils.decode(transaction.message.serialize(),
            encoding: StringEncoding.base64),
        commitment: Commitment.processed));
  }

  @override
  Future<SimulateTranasctionResponse> simulate(
      {required SolanaTransaction transaction,
      SolAddress? account,
      bool replaceRecentBlockhash = true,
      bool sigVerify = false,
      Commitment? commitment = Commitment.processed,
      MinContextSlot? minContextSlot}) async {
    return await provider.request(
      SolanaRequestSimulateTransaction(
          encodedTransaction:
              transaction.serializeString(encoding: TransactionSerializeEncoding.base64),
          sigVerify: sigVerify,
          replaceRecentBlockhash: replaceRecentBlockhash,
          encoding: SolanaRequestEncoding.base64,
          commitment: Commitment.processed,
          minContextSlot: minContextSlot,
          accounts: account == null
              ? null
              : RPCAccountConfig(
                  addresses: [account], encoding: SolanaRequestEncoding.base64)),
    );
  }

  Future<List<SolanaTokenInfo>> getTokenList() async {
    if (_tokenLists != null) return _tokenLists!;
    final tokenListJson = await provider.netApi.httpGet<Map<String, dynamic>>(
        SolanaConst.tokenListUri,
        responseType: StreamEncoding.map);
    final result = await tokenListJson.mapCatchAsync((json) {
      final tokenJson = json.valueEnsureAsList<Map<String, dynamic>>("tokens");
      final List<SolanaTokenInfo> tokenList = [];
      for (final i in tokenJson) {
        if (i["chainId"] != network.coinParam.chainId) continue;
        tokenList.add(SolanaTokenInfo.fromJson(i));
      }
      return tokenList;
    });
    return result.fold(
      onErr: (error) => [],
      onOk: (tokenLists) {
        final tokens = _tokenLists = tokenLists;
        return tokens;
      },
    );
  }

  @override
  Future<SolAddress> getBlockHash() async {
    final blockHash = await provider.request(const SolanaRequestGetLatestBlockhash());
    return blockHash.blockhash;
  }

  Future<String> getGenesisHash() async {
    final gnesisHash = await provider.request(SolanaRequestGetGenesisHash());
    return gnesisHash;
  }

  Future<List<ContactInfo>> clusterNodes() async {
    final gnesisHash = await provider.request(SolanaRequestGetClusterNodes());
    return gnesisHash;
  }

  Future<BigInt> getTokenAddressBalance(SolAddress address) async {
    final account = await provider.request(SolanaRPCGetTokenAccount(account: address));
    return account?.amount ?? BigInt.zero;
  }

  Future<SolanaMintAccount?> getMintAccount(SolAddress mintAddress) async {
    try {
      return await provider.request(SolanaRPCGetMintAccount(account: mintAddress));
    } on SolanaPluginException {
      return null;
    }
  }

  Future<List<SolanaAccountSPLTokenInfo>> getAccountTokens(SolAddress account,
      {SolAddress tokenProgram = SPLTokenProgramConst.tokenProgramId}) async {
    final List<SolanaAccountSPLTokenInfo> tokens = [];
    final tokenAccounts = await provider.request(SolanaRequestGetTokenAccountsByOwner(
        account: account,
        programId: tokenProgram,
        encoding: SolanaRequestEncoding.base64));
    if (tokenAccounts.isEmpty) return [];
    for (final i in tokenAccounts) {
      final mint =
          await provider.request(SolanaRPCGetMintAccount(account: i.tokenAccount.mint));
      final splToken = await _createSplTokenInfo(mintAccount: mint!, tokenAccount: i);
      tokens.add(splToken);
    }
    return tokens;
  }

  Future<SolanaAccountSPLTokenInfo> _createSplTokenInfo(
      {required SolanaMintAccount mintAccount,
      required TokenAccountResponse tokenAccount}) async {
    final mintAddress = tokenAccount.tokenAccount.mint;
    SolanaTokenInfo? tokenInfo;
    final metadatPda =
        MetaplexTokenMetaDataProgramUtils.findMetadataPda(mint: mintAddress);
    final tokenMetadata = await IResult.call(() async =>
        provider.request(SolanaRPCGetMetadataAccount(account: metadatPda.address)));

    if (tokenMetadata.ok() != null) {
      tokenInfo = SolanaTokenInfo.fromOnChainMetadata(tokenMetadata.unwrap()!);
    } else {
      final metadatas = await getTokenList();
      tokenInfo = metadatas.firstWhereOrNull((e) => e.address == mintAddress.address);
    }
    APPImage? image = APPImage.network(tokenInfo?.logoURI);
    final token = Token(
        assetLogo: image,
        decimal: mintAccount.decimals,
        name: tokenInfo?.name ?? mintAddress.address,
        symbol: tokenInfo?.symbol ?? mintAddress.address);
    return SolanaAccountSPLTokenInfo(
        amount: tokenAccount.tokenAccount.amount,
        mintAddress: mintAddress,
        token: token,
        pubkey: tokenAccount.pubkey,
        tokenOwner: tokenAccount.account.owner);
  }

  @override
  Future<String> sendTransaction(SolanaTransaction transaction,
      {int? maxRetries,
      bool skipPreflight = false,
      int? minContextSlot,
      Commitment? commitment,
      SolanaRequestEncoding encoding = SolanaRequestEncoding.base64}) async {
    return await provider.request(SolanaRequestSendTransaction(
        encodedTransaction: transaction.serializeString(
          encoding: encoding == SolanaRequestEncoding.base64
              ? TransactionSerializeEncoding.base64
              : TransactionSerializeEncoding.base58,
        ),
        encoding: encoding,
        skipPreflight: skipPreflight,
        maxRetries: maxRetries,
        commitment: skipPreflight ? Commitment.processed : commitment,
        minContextSlot:
            minContextSlot == null ? null : MinContextSlot(slot: minContextSlot)));
  }

  Future<bool> validateNetworkGenesis() async {
    final result = await getGenesis();
    return result == network.genesisBlock;
  }

  @override
  Future<BigInt> getBalance(SolAddress address) async {
    final accountInfo = await getAccountInfo(address);
    return accountInfo?.lamports ?? BigInt.zero;
  }

  @override
  Future<String> getGenesis() async {
    return await provider.request(SolanaRequestGetGenesisHash());
  }

  @override
  Future<SignatureStatus?> getSignatureStatuses(String signature) async {
    final statuses = await provider
        .request(SolanaRequestGetSignatureStatuses(signatures: [signature]));
    return statuses.elementAtOrNull(0);
  }

  @override
  Future<SolanaTokenPDAInfo> getTokenAccountAddress(
      {required SolAddress account,
      required SolAddress mint,
      SolAddress? tokenProgramId}) async {
    if (tokenProgramId == null) {
      final mintAccount = await getAccountInfo(mint);
      if (mintAccount == null) {
        throw AppException("mint_account_not_found");
      }
      tokenProgramId = mintAccount.owner;
      if (tokenProgramId != SPLTokenProgramConst.token2022ProgramId &&
          tokenProgramId != SPLTokenProgramConst.tokenProgramId) {
        throw AppException("invalid_mint_account_owner");
      }
    }
    final pda = AssociatedTokenAccountProgramUtils.associatedTokenAccount(
        mint: mint,
        owner: account,
        tokenProgramId: tokenProgramId,
        allowOwnerOffCurve: true);
    return SolanaTokenPDAInfo(
        address: account, pdaAddress: pda.address, tokenProgramId: tokenProgramId);
  }

  @override
  Future<TransactionConfirmationStatus> trackTransaction(
      {required String transactionId,
      Duration timeout = const Duration(minutes: 1),
      Duration periodicTimeOut = const Duration(seconds: 2)}) async {
    Timer? timer;
    try {
      final Completer<TransactionConfirmationStatus> completer =
          Completer<TransactionConfirmationStatus>();
      timer = Timer.periodic(periodicTimeOut, (t) async {
        final receipt = await getSignatureStatuses(transactionId);
        if (receipt != null) {
          if (receipt.err != null) {
            completer.completeError(AppException("transaction_confirmation_failed"));
          } else {
            final status = receipt.confirmationStatus;
            if (status == TransactionConfirmationStatus.finalized) {
              completer.complete(status);
            }
          }
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

  @override
  Future<BigInt> getTokenBalance(
      {required SolAddress account,
      required SolAddress mint,
      SolAddress? tokenProgramId}) async {
    final address = await getTokenAccountAddress(
        account: account, mint: mint, tokenProgramId: tokenProgramId);
    return await getTokenAddressBalance(address.pdaAddress);
  }

  @override
  Future<WalletTransactionStatus> transactionStatus(
      SolanaWalletTransaction transaction) async {
    final status = await getSignatureStatuses(transaction.txId);
    if (status == null) return WalletTransactionStatus.unknown;
    if (status.err != null) return WalletTransactionStatus.failed;
    if (status.confirmationStatus == TransactionConfirmationStatus.finalized) {
      return WalletTransactionStatus.block;
    }
    return WalletTransactionStatus.pending;
  }

  @override
  Future<BigInt> getBlockHeight() async {
    final block = await provider
        .request(SolanaRequestGetBlockHeight(commitment: Commitment.finalized));
    return BigInt.from(block);
  }

  Future<void> _fetchTokenMetadata(SolanaNetworkToken token) async {
    if (!token.status.allowRetry) return;
    token.setPending();
    final mintAddress = token.token.mint;
    final mintAccount = await IResult.call(() async {
      return await provider.request(SolanaRPCGetMintAccount(account: mintAddress));
    });
    if (mintAccount.ok() == null) {
      token.setError();
      return;
    }
    token.updaetTokenDecimals(mintAccount.unwrap()!.decimals);
    SolanaTokenInfo? tokenInfo;
    final metadatPda =
        MetaplexTokenMetaDataProgramUtils.findMetadataPda(mint: mintAddress);
    final tokenMetadata = await IResult.call(() async =>
        provider.request(SolanaRPCGetMetadataAccount(account: metadatPda.address)));
    if (tokenMetadata.ok() != null) {
      tokenInfo = SolanaTokenInfo.fromOnChainMetadata(tokenMetadata.unwrap()!);
      final url = tokenInfo.logoURI;
      final IResult<Map<String, dynamic>?> data = url == null
          ? ResultOk(null)
          : await provider.netApi.httpGet<Map<String, dynamic>>(
              StrUtils.stripControlChars(url),
              responseType: StreamEncoding.map,
              headers: HttpConst.applicationJsonContentType);
      final offChainMetadata = data.map((data) {
        if (data == null) return null;
        return tokenInfo?.copyWith(
            symbol: data.valueAs("symbol"),
            name: data.valueAs("name"),
            logoURI: data.valueAs("image"));
      });
      tokenInfo = offChainMetadata.ok() ?? tokenInfo;
    } else {
      final metadatas = await getTokenList();
      tokenInfo = metadatas.firstWhereOrNull((e) => e.address == mintAddress.address);
    }
    if (tokenInfo == null) {
      token.setError();
      return;
    }

    APPImage? image = APPImage.network(tokenInfo.logoURI);
    final updateToken = Token(
        assetLogo: image,
        decimal: mintAccount.unwrap()!.decimals,
        name: tokenInfo.name,
        symbol: tokenInfo.symbol);
    token.updaetTokenMetadata(updateToken);
  }

  @override
  Stream<List<SolanaNetworkToken>> getAccountTokensStream(SolAddress address) {
    final controller = SafeStreamController<List<SolanaNetworkToken>>(
        name: "SolanaNetworkClient.getAccountTokensStream");
    void add(List<SolanaSPLToken> splTokens) {
      final tokens = splTokens.map((e) => SolanaNetworkToken(token: e)).toList();
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

    Future<List<SolanaSPLToken>> fetchSplTokens(
        {SolAddress programId = SPLTokenProgramConst.tokenProgramId}) async {
      final tokenAccounts = await provider.request(SolanaRequestGetTokenAccountsByOwner(
          account: address,
          programId: programId,
          encoding: SolanaRequestEncoding.base64));
      return tokenAccounts
          .map((e) => SolanaSPLToken.create(
              balance: e.tokenAccount.amount,
              token: Token(
                  name: e.tokenAccount.mint.address,
                  symbol: e.tokenAccount.mint.address,
                  decimal: 0),
              mint: e.tokenAccount.mint,
              tokenAccount: e.pubkey,
              tokenOwner: e.tokenAccount.owner))
          .toList();
    }

    Future<void> fetchTokens() async {
      final splTokens = await IResult.call(() async {
        return await fetchSplTokens();
      });
      if (splTokens.isErr) {
        error(splTokens.unwrapErr().exception);
        close();
        return;
      }
      add(splTokens.unwrap());

      close();
    }

    controller.onListenListener(fetchTokens);
    controller.onCancelListener(close);

    return controller.stream();
  }

  @override
  void dispose() {
    super.dispose();
    _tokenLists = null;
  }

  @override
  List<MultiChainServiceClient> services() {
    return [provider.service];
  }

  @override
  Future<bool> verifyService(DefaultAPIProvider provider) async {
    if (provider == this.provider.service.provider) {
      return validateNetworkGenesis();
    }
    return false;
  }
}
