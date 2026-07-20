part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

abstract final class IChain<
    NETWORKADDRESS extends IAddress,
    TOKEN extends TokenCore,
    NFT extends NFTCore,
    NETWORK extends WalletNetwork,
    TRANSACTION extends ChainTransaction,
    ADDRESS extends ChainAccount<NETWORKADDRESS, TOKEN, NFT, TRANSACTION, NETWORK>,
    CLIENT extends NetworkClient<TRANSACTION, BaseNetworkToken, NETWORKADDRESS, NETWORK>,
    NETWORKPROVIDER extends NetworkApiProvider<NETWORK, CLIENT>> {
  List<ADDRESS> get addresses;
  Future<IResult<void>> updateTokenBalance(
      {required ADDRESS address, required List<TOKEN> tokens});
  Future<IResult<ADDRESS>> importAddress(
      CryptoPublicKeyData? publicKey, NewAccountParams<ADDRESS> accountParams);
  Future<IResult<ADDRESS>> getAddressFromIdentifier(String identifier);
  Future<IResult<List<ADDRESS>>> getAccountAddresses();
  ADDRESS? getAddressSync({String? address, NETWORKADDRESS? networkAddress});
  ReceiptAddress<NETWORKADDRESS> getOrCreateReceiptFromNetworkAddressSync(
      {NETWORKADDRESS? address, ADDRESS? account});
  Future<IResult<void>> removeContact(NetworkContact<NETWORKADDRESS> contact);
  Future<IResult<void>> switchAccount(ADDRESS address);
  Future<IResult<void>> removeAccount(ADDRESS address);
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
  Future<IResult<void>> updateCurrentAddressBalance({bool tokens = true});
  Future<IResult<CLIENT>> client();
  Future<IResult<void>> setupAccount({List<DefaultAPIProvider> providers = const []});
  Future<IResult<WalletNetworkBackup>> toBackup();
  bool addressSupportedByWalletPlatform(NETWORKADDRESS addr);
  Future<IResult<List<DefaultAPIProvider>>> getProviders();

  Future<IResult<NETWORKPROVIDER?>> getActiveService({bool web3 = false});
  Future<IResult<void>> updateNetworkProvider(DefaultAPIProvider provider);
  Future<IResult<List<NetworkContact<NETWORKADDRESS>>>> getAccountContacts();
  Future<IResult<NetworkClientConfig>> getServiceConfig();
  Future<IResult<void>> setServiceProvider(NetworkClientConfig service);
  Future<IResult<void>> importContact(NetworkContact contact);
  Future<IResult<void>> getTotalAccountBalance();

  /// must called when wallet have many works with this account.
  Future<IResult<void>> initAsMainNetwork();

  /// must called after wallet create or deserialized chains
  Future<IResult<void>> init();

  /// chain must not be used after dispose.
  Future<IResult<void>> dispose();

  /// must called after switchChain
  Future<IResult<void>> disconnectChain();

  /// must called after restore backup
  Future<IResult<void>> verifyBackup();

  Stream<ChainEvent> get stream;
  Stream<ChainEvent> filterStream(List<ChainNotify> events, {ChainNotifyStatus? status});
  ADDRESS get addressSync;
  ADDRESS? get addressSyncOrNull;
  INetworkServiceNotify get clientStatus;
  Future<IResult<NetworkContact<NETWORKADDRESS>>> getContactFromIdentifier(
      String identifier);
  bool get haveAddress;
  List<String> get services;
  NETWORK get network;
  InternalStreamValue<IntegerBalance> get totalBalance;
  String get id;
  NetworkClientRequirment get clientRequiredServices;
  int get networkId;
}

abstract final class Chain<
    NETWORKADDRESS extends IAddress,
    TOKEN extends TokenCore,
    NFT extends NFTCore,
    NETWORK extends WalletNetwork,
    TRANSACTION extends ChainTransaction,
    ADDRESS extends ChainAccount<NETWORKADDRESS, TOKEN, NFT, TRANSACTION, NETWORK>,
    CLIENT extends NetworkClient<TRANSACTION, BaseNetworkToken, NETWORKADDRESS, NETWORK>,
    NETWORKPROVIDER extends NetworkApiProvider<NETWORK, CLIENT>,
    CONTEXT extends IChainContext<NETWORKADDRESS, TOKEN, NFT, NETWORK, TRANSACTION,
        ADDRESS, CLIENT, NETWORKPROVIDER>> extends IChain<NETWORKADDRESS, TOKEN, NFT,
    NETWORK, TRANSACTION, ADDRESS, CLIENT, NETWORKPROVIDER> with AppSerialization {
  final CONTEXT _context;

  Chain._({
    required CONTEXT context,
  }) : _context = context;

  factory Chain.deserialize(InChainWalletController controller,
      {CborObject? object, List<int>? bytes}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.iAccount);
    WalletNetwork network =
        WalletNetwork.deserialize(object: values.objectAt<CborTagValue>(1));
    return Chain._fromNetwork(network: network, values: values, controller: controller);
  }
  static Chain setup(
      {required WalletNetwork network,
      required String id,
      required InChainWalletController controller}) {
    switch (network.type) {
      case NetworkType.ethereum:
        return EthereumChain.setup(
            network: network.cast(), id: id, controller: controller);
      case NetworkType.zcash:
        return ZcashChain.setup(network: network.cast(), id: id, controller: controller);
      case NetworkType.tron:
        return TronChain.setup(network: network.cast(), id: id, controller: controller);
      case NetworkType.xrpl:
        return XRPChain.setup(network: network.cast(), id: id, controller: controller);
      case NetworkType.solana:
        return SolanaChain.setup(network: network.cast(), id: id, controller: controller);
      case NetworkType.stellar:
        return StellarChain.setup(
            network: network.cast(), id: id, controller: controller);
      case NetworkType.cardano:
        return ADAChain.setup(network: network.cast(), id: id, controller: controller);
      case NetworkType.cosmos:
        return CosmosChain.setup(network: network.cast(), id: id, controller: controller);
      case NetworkType.ton:
        return TonChain.setup(network: network.cast(), id: id, controller: controller);
      case NetworkType.monero:
        return MoneroChain.setup(network: network.cast(), id: id, controller: controller);
      case NetworkType.substrate:
        return SubstrateChain.setup(
            network: network.cast(), id: id, controller: controller);
      case NetworkType.bitcoinAndForked:
      case NetworkType.bitcoinCash:
        return BitcoinChain.setup(
            network: network.cast(), id: id, controller: controller);
      case NetworkType.sui:
        return SuiChain.setup(network: network.cast(), id: id, controller: controller);
      case NetworkType.aptos:
        return AptosChain.setup(network: network.cast(), id: id, controller: controller);
    }
  }

  factory Chain._fromNetwork(
      {required WalletNetwork network,
      required CborListValue values,
      required InChainWalletController controller}) {
    final Chain chain;
    switch (network.type) {
      case NetworkType.bitcoinCash:
      case NetworkType.bitcoinAndForked:
        chain = BitcoinChain.deserialize(
            network: network.cast(), cbor: values, controller: controller);
        break;
      case NetworkType.substrate:
        chain = SubstrateChain.deserialize(
            network: network.cast(), cbor: values, controller: controller);
        break;
      case NetworkType.ethereum:
        chain = EthereumChain.deserialize(
            network: network.cast(), cbor: values, controller: controller);
        break;
      case NetworkType.zcash:
        chain = ZcashChain.deserialize(
            network: network.cast(), cbor: values, controller: controller);
        break;
      case NetworkType.cosmos:
        chain = CosmosChain.deserialize(
            network: network.cast(), cbor: values, controller: controller);
        break;
      case NetworkType.ton:
        chain = TonChain.deserialize(
            network: network.cast(), cbor: values, controller: controller);
        break;
      case NetworkType.tron:
        chain = TronChain.deserialize(
            network: network.cast(), cbor: values, controller: controller);
        break;
      case NetworkType.xrpl:
        chain = XRPChain.deserialize(
            network: network.cast(), cbor: values, controller: controller);
        break;
      case NetworkType.solana:
        chain = SolanaChain.deserialize(
            network: network.cast(), cbor: values, controller: controller);
        break;
      case NetworkType.stellar:
        chain = StellarChain.deserialize(
            network: network.cast(), cbor: values, controller: controller);
        break;
      case NetworkType.monero:
        chain = MoneroChain.deserialize(
            network: network.cast(), cbor: values, controller: controller);
        break;

      case NetworkType.cardano:
        chain = ADAChain.deserialize(
            network: network.cast(), cbor: values, controller: controller);
        break;
      case NetworkType.sui:
        chain = SuiChain.deserialize(
            network: network.cast(), cbor: values, controller: controller);
        break;
      case NetworkType.aptos:
        chain = AptosChain.deserialize(
            network: network.cast(), cbor: values, controller: controller);
        break;
    }
    return chain.cast();
  }

  // Chain copyWith(
  //     {NETWORK? network,
  //     List<ChainAccount>? addresses,
  //     String? id,
  //     InChainWalletController? controller});

  @override
  Future<IResult<void>> updateTokenBalance(
      {required ADDRESS address, required List<TOKEN> tokens}) {
    return _context.updateTokenBalance(address: address, tokens: tokens);
  }

  @override
  Future<IResult<List<ADDRESS>>> getAccountAddresses() {
    return _context.getAccountAddresses();
  }

  @override
  Future<IResult<ADDRESS>> importAddress(
      CryptoPublicKeyData? publicKey, NewAccountParams<ADDRESS> accountParams) {
    return _context.importAddress(publicKey, accountParams);
  }

  @override
  ADDRESS? getAddressSync({String? address, NETWORKADDRESS? networkAddress}) {
    return _context.getAddressSync(address: address, networkAddress: networkAddress);
  }

  @override
  ReceiptAddress<NETWORKADDRESS> getOrCreateReceiptFromNetworkAddressSync(
      {NETWORKADDRESS? address, ADDRESS? account}) {
    return _context.getOrCreateReceiptFromNetworkAddressSync(
        address: address, account: account);
  }

  Future<IResult<List<TOKEN>>> tokens() async {
    return _context.tokens();
  }

  @override
  Future<IResult<void>> removeContact(NetworkContact<NETWORKADDRESS> contact) {
    return _context.removeContact(contact);
  }

  @override
  Future<IResult<void>> switchAccount(ADDRESS address) {
    return _context.switchAccount(address);
  }

  @override
  Future<IResult<void>> removeAccount(ADDRESS address) {
    return _context.removeAccount(address);
  }

  @override
  Future<IResult<void>> setupAccountName({String? name, required ADDRESS address}) {
    return _context.setupAccountName(name: name, address: address);
  }

  @override
  Future<IResult<TOKEN>> addNewToken({required TOKEN token, required ADDRESS address}) {
    return _context.addNewToken(token: token, address: address);
  }

  @override
  Future<IResult<void>> removeToken({required TOKEN token, required ADDRESS address}) {
    return _context.removeToken(token: token, address: address);
  }

  @override
  Future<IResult<void>> updateToken(
      {required TOKEN token, required ADDRESS address, required Token updatedToken}) {
    return _context.updateToken(
        token: token, address: address, updatedToken: updatedToken);
  }

  @override
  Future<IResult<void>> saveTransaction(
      {required ADDRESS address, required TRANSACTION transaction}) {
    return _context.saveTransaction(address: address, transaction: transaction);
  }

  @override
  Future<IResult<void>> removeTransaction(
      {required ADDRESS address, required TRANSACTION transaction}) {
    return _context.removeTransaction(address: address, transaction: transaction);
  }

  @override
  Future<IResult<void>> updateAddressBalance(ADDRESS address, {bool tokens = true}) {
    return _context.updateAddressBalance(address, tokens: tokens);
  }

  @override
  Future<IResult<void>> updateCurrentAddressBalance({bool tokens = true}) {
    return _context.updateCurrentAddressBalance(tokens: tokens);
  }

  @override
  Future<IResult<void>> importContact(NetworkContact contact) async {
    final addr = contact.addressObject;
    if (addr is! NETWORKADDRESS) {
      return ResultErr.fromException(WalletExceptionConst.invalidContactDetails);
    }
    return _context.importContact(
        NetworkContact<NETWORKADDRESS>(addressObject: addr, name: contact.name));
  }

  Future<IResult<void>> updateAccountBalances(
      {List<ADDRESS>? addresses, bool tokens = true}) {
    return _context.updateAccountBalances(addresses: addresses, tokens: tokens);
  }

  @override
  Future<IResult<CLIENT>> client() {
    return _context.client();
  }

  @override
  Future<IResult<void>> setupAccount({List<DefaultAPIProvider> providers = const []}) {
    return _context.setup(providers: providers);
  }

  @override
  Future<IResult<void>> verifyBackup() {
    return _context.verifyBackup();
  }

  @override
  Future<IResult<WalletNetworkBackup>> toBackup() async {
    return _context.toBackup();
  }

  @override
  bool addressSupportedByWalletPlatform(NETWORKADDRESS addr) {
    return _context.addressSupportedByWalletPlatform(addr);
  }

  @override
  Future<IResult<List<DefaultAPIProvider>>> getProviders() {
    return _context.storageGetProviders();
  }

  @override
  Future<IResult<NETWORKPROVIDER?>> getActiveService({bool web3 = false}) {
    return _context.getActiveService(web3: web3);
  }

  @override
  Future<IResult<void>> updateNetworkProvider(DefaultAPIProvider provider) {
    return _context.updateNetworkProvider(provider);
  }

  Future<IResult<void>> removeNetworkProvider(DefaultAPIProvider provider) {
    return _context.removeNetworkProvider(provider);
  }

  @override
  Future<IResult<List<NetworkContact<NETWORKADDRESS>>>> getAccountContacts() {
    return _context.getAccountContacts();
  }

  @override
  Future<IResult<NetworkClientConfig>> getServiceConfig() {
    return _context.getServiceConfig();
  }

  @override
  Future<IResult<void>> setServiceProvider(NetworkClientConfig service) {
    return _context.setServiceProvider(service);
  }

  @override
  Future<IResult<void>> getTotalAccountBalance() {
    return _context.getTotalAccountBalance();
  }

  @override
  Future<IResult<void>> init() {
    return _context.getTotalAccountBalance();
  }

  @override
  Future<IResult<void>> dispose() async {
    return _context.dispose();
  }

  @override
  Future<IResult<void>> disconnectChain() async {
    return _context.disconnectChain();
  }

  @override
  NetworkClientRequirment get clientRequiredServices => _context.clientRequiredServices;

  @override
  Stream<ChainEvent> get stream => _context.stream;

  @override
  Stream<ChainEvent> filterStream(List<ChainNotify> events, {ChainNotifyStatus? status}) {
    if (status == null) {
      return stream.where((e) => events.contains(e.type));
    }
    return stream.where((e) => e.status == status && events.contains(e.type));
  }

  @override
  List<ADDRESS> get addresses => _context.addresses;

  @override
  ADDRESS get addressSync => _context.addressSync;
  @override
  ADDRESS? get addressSyncOrNull => _context.addressSyncOrNull;

  @override
  bool get haveAddress => addresses.isNotEmpty;

  @override
  List<String> get services => _context.services;

  @override
  INetworkServiceNotify get clientStatus => _context.serviceStatus;

  @override
  NETWORK get network => _context.network;

  @override
  int get networkId => network.value;

  @override
  InternalStreamValue<IntegerBalance> get totalBalance => _context.totalBalance;

  @override
  String get id => _context.id;

  @override
  Future<IResult<ADDRESS>> getAddressFromIdentifier(String identifier) {
    return _context.getAddressFromIdentifier(identifier);
  }

  @override
  Future<IResult<NetworkContact<NETWORKADDRESS>>> getContactFromIdentifier(
      String identifier) async {
    return _context.getContactFromIdentifier(identifier);
  }

  @override
  Future<IResult<void>> initAsMainNetwork() async {
    return _context.initAsMainWallet();
  }

  NetDerivation nextDerive(
      {required CryptoCoins coin,
      required SeedTypes seedGeneration,
      required int? subId}) {
    return _context.nextDerive(coin: coin, seedGeneration: seedGeneration, subId: subId);
  }

  @override
  String toString() {
    return "Chain: ${network.networkName}";
  }

  T cast<T extends APPCHAIN>() {
    if (this is! T) {
      throw AppInternalError.internalError("Chain");
    }
    return this as T;
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.iAccount;
  @override
  List<CborObject?> get serializationItems => [
        network.value.toCbor(),
        network.toCbor(),
        _context.id.toCbor(),
      ];
}
