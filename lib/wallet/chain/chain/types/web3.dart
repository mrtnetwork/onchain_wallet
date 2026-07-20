part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

abstract class Web3InternalNetworkAccount with AppSerialization, Equality {
  final DerivationIndex derivationIndex;
  final String identifier;
  const Web3InternalNetworkAccount(
      {required this.derivationIndex, required this.identifier});
}

abstract class Web3InternalNetwork<ACCOUNT extends Web3InternalNetworkAccount>
    with AppSerialization, Equality {
  final List<ACCOUNT> accounts;
  final ACCOUNT? defaultAccount;
  final int networkId;
  Web3InternalNetwork._(
      {required List<ACCOUNT> accounts, required this.networkId, this.defaultAccount})
      : accounts = accounts.immutable;
}

abstract class Web3InternalChain<T extends Web3InternalNetwork>
    with AppSerialization, Equality {
  final List<T> networks;
  final int defaultChain;
  final NetworkType type;

  bool hasAnyChainPermission() {
    return networks.any((e) => e.accounts.isNotEmpty);
  }

  bool hasAnyNetworkPermission(int networkId) {
    final network = networks.firstWhereOrNull((e) => e.networkId == networkId);
    assert(network != null, "invalid network id");
    return network?.accounts.isNotEmpty ?? false;
  }

  E cast<E extends Web3InternalChain>() {
    if (this is! E) {
      throw AppInternalError.internalError("Web3InternalChain");
    }
    return this as E;
  }

  const Web3InternalChain._(
      {required this.networks, required this.defaultChain, required this.type});

  factory Web3InternalChain.deserialize({List<int>? bytes, CborObject? object}) {
    final CborTagValue tag =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    final type = NetworkType.fromTags(tag.tags);
    final chain = switch (type) {
      NetworkType.cardano => Web3InternalADAChain.deserialize(object: tag),
      _ => Web3InternalDefaultChain.deserialize(object: tag),
    };
    if (chain is! Web3InternalChain<T>) {
      throw AppInternalError.internalError("Web3InternalChain");
    }
    return chain;
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.identifier;
}

class Web3InternalDefaultNetworkAccount extends Web3InternalNetworkAccount {
  const Web3InternalDefaultNetworkAccount(
      {required super.derivationIndex, required super.identifier});
  factory Web3InternalDefaultNetworkAccount.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.web3InternalNetworkAccount);
    return Web3InternalDefaultNetworkAccount(
        derivationIndex: DerivationIndex.deserialize(object: values.objectAt(0)),
        identifier: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3InternalNetworkAccount;

  @override
  List<CborObject?> get serializationItems =>
      [derivationIndex.toCbor(), CborStringValue(identifier)];
  @override
  List get variables => [derivationIndex, identifier];
}

enum Web3InternalADANetworkAccountType {
  payment(0),
  reward(1);

  bool get isReward => this == reward;
  bool get isPayment => this == payment;

  final int value;
  const Web3InternalADANetworkAccountType(this.value);
  static Web3InternalADANetworkAccountType fromValue(int? value) {
    return values.firstWhere((e) => e.value == value,
        orElse: () =>
            throw AppInternalError.internalError("Web3InternalADANetworkAccountType"));
  }
}

class Web3InternalADANetworkAccount extends Web3InternalNetworkAccount {
  final Web3InternalADANetworkAccountType type;
  const Web3InternalADANetworkAccount(
      {required super.derivationIndex, required super.identifier, required this.type});
  factory Web3InternalADANetworkAccount.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.web3InternalNetworkAccount);
    return Web3InternalADANetworkAccount(
        derivationIndex: DerivationIndex.deserialize(object: values.objectAt(0)),
        identifier: values.rawValueAt(1),
        type: Web3InternalADANetworkAccountType.fromValue(values.rawValueAt(2)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3InternalNetworkAccount;

  @override
  List<CborObject?> get serializationItems =>
      [derivationIndex.toCbor(), CborStringValue(identifier), CborIntValue(type.value)];
  @override
  List get variables => [derivationIndex, identifier, type];
}

class Web3InternalDefaultNetwork
    extends Web3InternalNetwork<Web3InternalDefaultNetworkAccount> {
  Web3InternalDefaultNetwork._(
      {required super.accounts, required super.networkId, super.defaultAccount})
      : super._();
  factory Web3InternalDefaultNetwork(
      {required List<Web3InternalDefaultNetworkAccount> accounts,
      required int networkId,
      Web3InternalDefaultNetworkAccount? defaultAccount}) {
    if ((accounts.isNotEmpty && !accounts.contains(defaultAccount)) ||
        (accounts.isEmpty && defaultAccount != null)) {
      throw WalletExceptionConst.invalidWeb3AccountData;
    }
    return Web3InternalDefaultNetwork._(
        accounts: accounts.clone()..sort((a, b) => a.identifier.compareTo(b.identifier)),
        defaultAccount: defaultAccount,
        networkId: networkId);
  }

  factory Web3InternalDefaultNetwork.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.web3InternalNetwork);
    return Web3InternalDefaultNetwork(
        accounts: values
            .listAt<CborTagValue>(0)
            .map((e) => Web3InternalDefaultNetworkAccount.deserialize(object: e))
            .toList(),
        defaultAccount:
            values.maybeObjectAt<Web3InternalDefaultNetworkAccount, CborTagValue>(
                1, (e) => Web3InternalDefaultNetworkAccount.deserialize(object: e)),
        networkId: values.rawValueAt(2));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3InternalNetwork;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(accounts.map((e) => e.toCbor()).toImutableList),
        defaultAccount?.toCbor(),
        CborIntValue(networkId)
      ];
  @override
  List get variables => [accounts, defaultAccount, networkId];
}

class Web3InternalADANetwork extends Web3InternalNetwork<Web3InternalADANetworkAccount> {
  Web3InternalADANetwork._(
      {required super.accounts, required super.networkId, super.defaultAccount})
      : super._();
  factory Web3InternalADANetwork(
      {required List<Web3InternalADANetworkAccount> accounts,
      required int networkId,
      Web3InternalADANetworkAccount? defaultAccount}) {
    final paymentsAccounts = accounts.where((e) => e.type.isPayment);
    if ((paymentsAccounts.isNotEmpty && !paymentsAccounts.contains(defaultAccount)) ||
        (paymentsAccounts.isEmpty && defaultAccount != null)) {
      throw WalletExceptionConst.invalidWeb3AccountData;
    }
    return Web3InternalADANetwork._(
        accounts: accounts.clone()..sort((a, b) => a.identifier.compareTo(b.identifier)),
        defaultAccount: defaultAccount,
        networkId: networkId);
  }

  factory Web3InternalADANetwork.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.web3InternalNetwork);
    return Web3InternalADANetwork(
        accounts: values
            .listAt<CborTagValue>(0)
            .map((e) => Web3InternalADANetworkAccount.deserialize(object: e))
            .toList(),
        defaultAccount: values.maybeObjectAt<Web3InternalADANetworkAccount, CborTagValue>(
            1, (e) => Web3InternalADANetworkAccount.deserialize(object: e)),
        networkId: values.rawValueAt(2));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3InternalNetwork;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(accounts.map((e) => e.toCbor()).toImutableList),
        defaultAccount?.toCbor(),
        CborIntValue(networkId)
      ];
  @override
  List get variables => [accounts, defaultAccount, networkId];
}

class Web3InternalDefaultChain extends Web3InternalChain<Web3InternalDefaultNetwork> {
  const Web3InternalDefaultChain._(
      {required super.networks, required super.defaultChain, required super.type})
      : super._();
  factory Web3InternalDefaultChain(
      {required List<Web3InternalDefaultNetwork> networks,
      required int defaultChain,
      required NetworkType type}) {
    if (networks.map((e) => e.networkId).toSet().length != networks.length) {
      throw WalletExceptionConst.invalidWeb3AccountData;
    }
    return Web3InternalDefaultChain._(
        networks: networks.clone()..sort((a, b) => a.networkId.compareTo(b.networkId)),
        defaultChain: defaultChain,
        type: type);
  }
  factory Web3InternalDefaultChain.deserialize({List<int>? bytes, CborObject? object}) {
    final CborTagValue tag =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    final type = NetworkType.fromTags(tag.tags);
    final values = tag.asValue<CborListValue>();
    return Web3InternalDefaultChain(
        networks: values
            .listAt<CborTagValue>(0)
            .map((e) => Web3InternalDefaultNetwork.deserialize(object: e))
            .toList(),
        defaultChain: values.rawValueAt(1),
        type: type);
  }

  @override
  List get variables => [networks, defaultChain, type];

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(networks.map((e) => e.toCbor()).toList()),
        CborIntValue(defaultChain),
        CborIntValue(type.id),
      ];
}

class Web3InternalADAChain extends Web3InternalChain<Web3InternalADANetwork> {
  const Web3InternalADAChain._({
    required super.networks,
    required super.defaultChain,
  }) : super._(type: NetworkType.cardano);
  factory Web3InternalADAChain(
      {required List<Web3InternalADANetwork> networks, required int defaultChain}) {
    if (networks.map((e) => e.networkId).toSet().length != networks.length) {
      throw WalletExceptionConst.invalidWeb3AccountData;
    }
    return Web3InternalADAChain._(
        networks: networks.clone()..sort((a, b) => a.networkId.compareTo(b.networkId)),
        defaultChain: defaultChain);
  }
  factory Web3InternalADAChain.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: NetworkType.cardano.identifier);

    return Web3InternalADAChain(
      networks: values
          .listAt<CborTagValue>(0)
          .map((e) => Web3InternalADANetwork.deserialize(object: e))
          .toList(),
      defaultChain: values.rawValueAt(1),
    );
  }

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(networks.map((e) => e.toCbor()).toList()),
        CborIntValue(defaultChain),
        CborIntValue(type.id),
      ];

  @override
  List get variables => [networks, defaultChain, type];
}
