part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

abstract final class IChainClientContext<
    NETWORKADDRESS extends IAddress,
    TOKEN extends TokenCore,
    NFT extends NFTCore,
    NETWORK extends WalletNetwork,
    TRANSACTION extends ChainTransaction,
    ADDRESS extends ChainAccount<NETWORKADDRESS, TOKEN, NFT, TRANSACTION, NETWORK>,
    CLIENT extends NetworkClient<TRANSACTION, BaseNetworkToken, NETWORKADDRESS, NETWORK>,
    NETWORKPROVIDER extends NetworkApiProvider<NETWORK, CLIENT>> {
  Future<IResult<CLIENT>> client();
  INetworkServiceNotify get serviceStatus;
  NetworkClientRequirment get clientRequiredServices;
}

abstract final class IChainContext<
        NETWORKADDRESS extends IAddress,
        TOKEN extends TokenCore,
        NFT extends NFTCore,
        NETWORK extends WalletNetwork,
        TRANSACTION extends ChainTransaction,
        ADDRESS extends ChainAccount<NETWORKADDRESS, TOKEN, NFT, TRANSACTION, NETWORK>,
        CLIENT extends NetworkClient<TRANSACTION, BaseNetworkToken, NETWORKADDRESS, NETWORK>,
        NETWORKPROVIDER extends NetworkApiProvider<NETWORK, CLIENT>>
    with
        AppSerialization
    implements
        IChainClientContext<NETWORKADDRESS, TOKEN, NFT, NETWORK, TRANSACTION, ADDRESS,
            CLIENT, NETWORKPROVIDER> {
  final NetworkStorageManager storage;
  final NETWORK network;
  final String id;
  List<ADDRESS> get addresses;
  final InChainWalletController controller;
  final InternalStreamValue<IntegerBalance> totalBalance;
  List<NetworkContact<NETWORKADDRESS>> get contacts;
  int get index;
  ADDRESS get addressSync;
  ADDRESS? get addressSyncOrNull;
  bool get haveAddress;
  const IChainContext(
      {required this.storage,
      required this.network,
      required this.id,
      required this.controller,
      required this.totalBalance});
  NetDerivation nextDerive(
      {required CryptoCoins coin,
      required SeedTypes seedGeneration,
      required int? subId});
  Future<IResult<List<NetworkContact<NETWORKADDRESS>>>> getAccountContacts();
  Future<IResult<List<ADDRESS>>> getAccountAddressesInternal();
  Future<IResult<List<ADDRESS>>> getAccountAddresses();
  Future<IResult<ADDRESS>> beforeImportAddress(ADDRESS address);
  Future<IResult<ADDRESS>> importAddress(
      CryptoPublicKeyData? publicKey, NewAccountParams<ADDRESS> accountParams);
  Future<IResult<ADDRESS>> afterImportAddress(
      NewAccountParams<ADDRESS> params, ADDRESS address);
  ADDRESS? getAddressSync({String? address, NETWORKADDRESS? networkAddress});
  ReceiptAddress<NETWORKADDRESS> getOrCreateReceiptFromNetworkAddressSync(
      {NETWORKADDRESS? address, ADDRESS? account});
  Future<IResult<List<TOKEN>>> tokens();
  Future<IResult<void>> removeContact(NetworkContact<NETWORKADDRESS> contact);
  Future<IResult<void>> importContact(NetworkContact<NETWORKADDRESS> contact);
  Future<IResult<void>> switchAccount(ADDRESS address);
  Future<IResult<T>> isAccountAddress<T extends ADDRESS>(T address,
      {bool validate = true});
  Future<IResult<void>> beforeRemoveAccount(ADDRESS address);
  Future<IResult<void>> removeAccount(ADDRESS address);
  Future<IResult<void>> afterRemoveAccount(ADDRESS address);
  Future<IResult<void>> setupAccountName({String? name, required ADDRESS address});
  Future<IResult<TOKEN>> addNewToken({required TOKEN token, required ADDRESS address});
  Future<IResult<void>> removeToken({required TOKEN token, required ADDRESS address});
  Future<IResult<void>> updateToken(
      {required TOKEN token, required ADDRESS address, required Token updatedToken});
  Future<IResult<void>> saveTransaction(
      {required ADDRESS address, required TRANSACTION transaction});
  Future<IResult<void>> removeTransaction(
      {required ADDRESS address, required TRANSACTION transaction});
  Future<IResult<void>> updateAddressBalance(ADDRESS address, {bool tokens = true});

  /// return true if  balance updated.
  Future<IResult<bool>> updateAddressBalanceInternal(ADDRESS address,
      {bool tokens = true});
  Future<IResult<void>> updateAddressIndex(ADDRESS? address);
  Future<IResult<void>> updateAccountBalances(
      {List<ADDRESS>? addresses, bool tokens = true});
  Future<IResult<void>> updateCurrentAddressBalance({bool tokens = true});
  Future<IResult<NetworkContact<NETWORKADDRESS>>> getContactFromIdentifier(
      String identifier);
  Future<IResult<ADDRESS>> getAddressFromIdentifier(String identifier);
  Future<IResult<void>> updateTotalAccountBalance();
  Future<IResult<void>> updateTokenBalance(
      {required ADDRESS address,
      required List<TOKEN> tokens,
      bool isAccountAddress = false});
  Future<IResult<void>> setup({List<DefaultAPIProvider> providers = const []});
  AppPlatform get platform;
  AppPlatform get walletPlatform;
  List<String> get services;
  bool addressSupportedByWalletPlatform(NETWORKADDRESS addr);
  Future<IResult<WalletNetworkBackup>> toBackup();
  Future<IResult<NETWORKPROVIDER?>> getActiveService({bool web3 = false});
  Future<IResult<void>> setServiceProvider(NetworkClientConfig service);
  IResult<NETWORKPROVIDER?> buildProviderNetworkIdentifier({
    required List<DefaultAPIProvider> providers,
    List<NETWORKPROVIDER> exclude = const [],
  });
  Future<IResult<NetworkClientConfig>> getServiceConfig();
  Future<IResult<void>> saveServiceConfig(NetworkClientConfig config);
  Future<IResult<void>> updateNetworkProvider(DefaultAPIProvider provider);
  Future<IResult<void>> removeNetworkProvider(DefaultAPIProvider provider);
  Stream<ChainEvent> get stream;
  Future<IResult<void>> initAsMainWallet({bool client = true});
  Future<IResult<void>> getTotalAccountBalance();
  Future<IResult<void>> trackPendingTxes();
  Future<IResult<void>> dispose();

  Future<IResult<void>> disconnectChain();
  Future<IResult<void>> verifyBackup();

  /// storages

  Future<IResult<List<NetworkContact<NETWORKADDRESS>>>> storageGetContacts();
  Future<IResult<List<DefaultAPIProvider>>> storageGetProviders();
  Future<IResult<void>> storageSaveProvider(DefaultAPIProvider provider);
  Future<IResult<void>> storageSaveContact(NetworkContact<NETWORKADDRESS> contact);
  Future<IResult<void>> storageRemoveContact(NetworkContact<NETWORKADDRESS> contact);
  Future<IResult<List<ADDRESS>>> storageGetAddresses();
  Future<IResult<int>> storageGetAddressIndex();
  Future<IResult<void>> storageSaveAddressIndex(int index);
  Future<IResult<BigInt>> storageGetTotalBalance();
  Future<IResult<void>> storageSaveTotalBalance(BigInt amount);
  Future<IResult<void>> storageSaveAccount();
  Future<IResult<void>> storageSaveServiceConfig(NetworkClientConfig config);
  Future<IResult<NetworkClientConfig>> storageGetServiceConfig();
  Future<IResult<void>> storageRemoveProvider(DefaultAPIProvider provider);
}
