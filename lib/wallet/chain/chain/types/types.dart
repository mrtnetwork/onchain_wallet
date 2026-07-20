part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

// enum _WalletChainStatus {
//   init,
//   ready,
//   dispose;

//   bool get isInit => this == init;
// }

// enum _WalletAddressStatus {
//   init,
//   ready;

//   bool get isInit => this == init;
//   bool get isReady => this == ready;
// }

abstract class ChainStorageId extends StorageId {}

/// maximum value 999
class DefaultNetworkStorageId implements StorageId {
  static const DefaultNetworkStorageId contacts = DefaultNetworkStorageId(0);
  static const DefaultNetworkStorageId transaction = DefaultNetworkStorageId(1);
  static const DefaultNetworkStorageId token = DefaultNetworkStorageId(2);
  static const DefaultNetworkStorageId nft = DefaultNetworkStorageId(3);
  static const DefaultNetworkStorageId web3 = DefaultNetworkStorageId(4);
  static const DefaultNetworkStorageId address =
      DefaultNetworkStorageId(5, allowInBackup: false);
  static const DefaultNetworkStorageId providers = DefaultNetworkStorageId(6);
  static const DefaultNetworkStorageId addressIndex = DefaultNetworkStorageId(7);
  static const DefaultNetworkStorageId serviceIdentifier = DefaultNetworkStorageId(8);
  static const DefaultNetworkStorageId addressInfo = DefaultNetworkStorageId(9);
  static const DefaultNetworkStorageId accountTotalBalances = DefaultNetworkStorageId(10);
  static const DefaultNetworkStorageId account =
      DefaultNetworkStorageId(1000, allowInBackup: false);
  static const List<DefaultNetworkStorageId> values = [
    contacts,
    transaction,
    token,
    nft,
    web3,
    address,
    providers,
    account,
    addressIndex,
    serviceIdentifier,
    addressInfo,
    accountTotalBalances
  ];
  static List<DefaultNetworkStorageId> fromNetwork(NetworkType type) {
    switch (type) {
      case NetworkType.bitcoinAndForked:
      case NetworkType.bitcoinCash:
        return BitcoinNetworkStorageId.values;
      case NetworkType.cardano:
        return ADANetworkStorageId.values;
      case NetworkType.cosmos:
        return CosmosNetowkStorageId.values;
      case NetworkType.monero:
        return MoneroNetworkStorageId.values;
      case NetworkType.substrate:
        return SubstrateNetworkStorageId.values;
      case NetworkType.tron:
        return TronNetworkStorageId.values;
      case NetworkType.zcash:
        return ZcashNetworkStorageId.values;
      default:
        return values;
    }
  }

  @override
  final int storageId;
  final bool allowInBackup;
  const DefaultNetworkStorageId(this.storageId, {this.allowInBackup = true});
}

class DefaultChainStorageId implements ChainStorageId {
  static const DefaultChainStorageId web3 = DefaultChainStorageId(2);
  static const DefaultChainStorageId config = DefaultChainStorageId(3);
  @override
  final int storageId;
  const DefaultChainStorageId(this.storageId);

  static const List<DefaultChainStorageId> values = [web3, config];

  static List<DefaultChainStorageId> fromNetwork(NetworkType type) {
    return switch (type) {
      NetworkType.monero => MoneroChainStorageId.values,
      NetworkType.zcash => ZcashChainStorageId.values,
      _ => values
    };
  }
}

abstract class ChainNotify {
  abstract final int value;
}

enum DefaultChainNotify implements ChainNotify {
  address(0),
  account(1),
  client(2),
  config(3),
  contacts(4),
  transaction(5),
  token(6),
  nft(7),
  updateProvider(8);

  @override
  final int value;
  const DefaultChainNotify(this.value);
}

enum ChainNotifyStatus {
  progress,
  complete;

  bool get isComplete => this == complete;
  bool get isProgress => this == progress;
}

class ChainEvent {
  final ChainNotify type;
  final ChainNotifyStatus status;
  final int chainId;
  const ChainEvent({required this.type, required this.status, required this.chainId});
  factory ChainEvent.progress({required ChainNotify type, required int chainId}) {
    return ChainEvent(type: type, status: ChainNotifyStatus.progress, chainId: chainId);
  }
  factory ChainEvent.complete({required ChainNotify type, required int chainId}) {
    return ChainEvent(type: type, status: ChainNotifyStatus.complete, chainId: chainId);
  }

  bool isProgressOf(ChainNotify type) => status.isProgress && type == this.type;

  @override
  String toString() {
    return "ChainEvent{type:$type, status:$status, chainId: $chainId}";
  }
}

enum ChainWalletEventType {
  ping,
  connection,
  chainChanged,
  walletUnlocked,
  walletLocked;
}

abstract final class ChainWalletEvent {
  final ChainWalletEventType type;
  const ChainWalletEvent({required this.type});
  T cast<T extends ChainWalletEvent>() {
    if (this is T) return this as T;
    throw AppInternalError.internalError("ChainWalletEvent");
  }
}

final class ChainWalletPingEvent extends ChainWalletEvent {
  const ChainWalletPingEvent() : super(type: ChainWalletEventType.ping);
}

final class ChainWalletConnectionEvent extends ChainWalletEvent {
  final bool isOnline;
  const ChainWalletConnectionEvent(this.isOnline)
      : super(type: ChainWalletEventType.connection);
}

final class ChainWalletChainChangeEvent extends ChainWalletEvent {
  final Chain? prv;
  final Chain current;
  const ChainWalletChainChangeEvent({required this.prv, required this.current})
      : super(type: ChainWalletEventType.chainChanged);
}

final class ChainWalletWalletUnlockedEvent extends ChainWalletEvent {
  const ChainWalletWalletUnlockedEvent()
      : super(type: ChainWalletEventType.walletUnlocked);
}

final class ChainWalletWalletLockedEvent extends ChainWalletEvent {
  const ChainWalletWalletLockedEvent() : super(type: ChainWalletEventType.walletLocked);
}

typedef ONSTREAMVALUEDISPOSE = bool Function();

final class InternalStreamValue<T> implements StreamValue<T> {
  bool _allowDispose;
  T _value;
  // InternalStreamValue(T val, {this.immutable = false}) : _value = val;
  InternalStreamValue.immutable(T val, {required bool allowDispose, required String name})
      : _value = val,
        immutable = true,
        _allowDispose = allowDispose,
        _controller = SafeStreamController.broadcast(name: name);
  @override
  final bool immutable;
  @override
  bool get isClosed => _controller.isClosed;
  void _logImmutable() {
    Logging.error(
      when: () => immutable,
      fn: () => AppLogData(
          runtime: runtimeType,
          function: "add",
          msg: "Cannot add event to stream '${{
            _controller.name ?? 'unnamed'
          }}': the stream controller is immutable."),
    );
  }

  late final SafeStreamController<T> _controller;
  @override
  Stream<T> get stream => _controller.stream();

  @override
  T get value {
    return _value;
  }

  @override
  set silent(T newValue) {
    _logImmutable();
    if (_value == newValue || immutable) return;
    _value = newValue;
  }

  @override
  set value(T newValue) {
    _logImmutable();
    if (_value == newValue || immutable) return;
    _value = newValue;
    _controller.addIfListener(newValue);
  }

  @override
  set updateValue(T newValue) {
    _logImmutable();
    if (immutable) return;
    _value = newValue;
    _controller.addIfListener(newValue);
  }

  @override
  void notify({T? value}) {
    _controller.addIfListener(_value);
  }

  void _disposeInternal() {
    _controller.close();
  }

  @override
  void dispose() {
    if (!_allowDispose) return;
    _disposeInternal();
  }

  @override
  bool get hasListener => _controller.hasListener;
}

abstract class ChainConfig with AppSerialization, Equality {
  const ChainConfig();
  NetworkType get network;
  @override
  List get variables => [];
  factory ChainConfig.deserialize({List<int>? cborBytes, CborObject? cborObject}) {
    final CborTagValue tag =
        AppSerialization.decode(cborBytes: cborBytes, cborObject: cborObject);
    final network = NetworkType.fromTags(tag.tags);
    return switch (network) {
      NetworkType.substrate => SubstrateChainConfig.deserialize(cborObject: tag),
      _ => throw AppInternalError.internalError("ChainConfig.deserialize")
    };
  }
  factory ChainConfig.create(NetworkType network) {
    return switch (network) {
      NetworkType.substrate => SubstrateChainConfig(),
      _ => throw AppInternalError.internalError("ChainConfig.deserialize")
    };
  }
  T cast<T extends ChainConfig>() {
    if (this is! T) {
      throw AppInternalError.internalError("ChainConfig.cast");
    }
    return this as T;
  }

  @override
  SerializationIdentifier get serializationIdentifier => network.identifier;
}

// class NetworkProviderConfig with AppSerialization, Equality {
//   final bool autoConnect;
//   final bool enableProvider;
//   final NetworkProviderIdentifier? identifier;
//   final NetMode mode;
//   const NetworkProviderConfig(
//       {this.autoConnect = true,
//       this.enableProvider = true,
//       this.identifier,
//       this.mode = NetMode.clearnet});
//   factory NetworkProviderConfig.deserialize(
//       {List<int>? cborBytes,  CborObject? cborObject}) {
//     final values = AppSerialization.decodeTaggedValue(
//         cborBytes: cborBytes,
//
//         cborObject: cborObject,
//         identifier: AppSerializationIdentifier.networkServiceProvider);
//     return NetworkProviderConfig(
//         autoConnect: values.rawValueAt(0),
//         enableProvider: values.rawValueAt(1),
//         identifier: values.maybeObjectAt<NetworkProviderIdentifier, CborTagValue>(
//             2, (e) => NetworkProviderIdentifier.deserialize(cbor: e)),
//         mode: values.maybeRawValueAt<NetMode, int>(3, (e) => NetMode.fromValue(e)) ??
//             NetMode.clearnet);
//   }

//   @override
//   SerializationIdentifier get serializationIdentifier =>
//       AppSerializationIdentifier.networkServiceProvider;

//   @override
//   List<CborObject?> get serializationItems =>
//       [autoConnect, enableProvider, identifier?.toCbor(), mode.value];
//   @override
//   List<dynamic> get variables => [autoConnect, enableProvider, identifier];

//   NetworkProviderConfig copyWith({
//     bool? autoConnect,
//     bool? enableProvider,
//     NetworkProviderIdentifier? identifier,
//     NetMode? mode,
//   }) {
//     return NetworkProviderConfig(
//         autoConnect: autoConnect ?? this.autoConnect,
//         enableProvider: enableProvider ?? this.enableProvider,
//         identifier: identifier ?? this.identifier,
//         mode: mode ?? this.mode);
//   }
// }

sealed class AccountDerivationIndexRequest {}

class AccountDerivationIndexRequestSigners implements AccountDerivationIndexRequest {
  const AccountDerivationIndexRequestSigners();
}

class AccountDerivationIndexRequestAddress implements AccountDerivationIndexRequest {
  const AccountDerivationIndexRequestAddress();
}

class ZcashAccountDerivationIndexRequestAddressProtocol
    implements AccountDerivationIndexRequest {
  final ZcashProtocol protocol;
  const ZcashAccountDerivationIndexRequestAddressProtocol(this.protocol);
}

abstract mixin class TokenBalanceUpdater<AMOUNT extends Object, TOKEN extends APPToken> {
  abstract final InternalStreamValue<BalanceCore<AMOUNT, TOKEN>> streamBalance;

  void onBalanceUpdated() {}
  bool _updateBalance([AMOUNT? updateBalance]) {
    if (streamBalance.value._internalUpdateBalance(updateBalance)) {
      // _updated = DateTime.now().toLocal();
      streamBalance.notify();
      onBalanceUpdated();
      return true;
    }
    return false;
  }
}

class NetworkClientConfig with AppSerialization, Equality {
  final bool auto;
  final bool enableProvider;
  final bool runtimeAuto;
  final List<DefaultAPIProvider> providers;
  NetworkClientConfig({
    this.auto = true,
    this.enableProvider = true,
    this.runtimeAuto = true,
    List<DefaultAPIProvider> providers = const [],
  }) : providers = providers.immutable;
  factory NetworkClientConfig.deserialize(
      {List<int>? cborBytes, CborObject? cborObject}) {
    final values = AppSerialization.decodeTaggedValue(
        cborBytes: cborBytes,
        cborObject: cborObject,
        identifier: AppSerializationIdentifier.networkServiceProvider);
    return NetworkClientConfig(
      auto: values.rawValueAt(0),
      enableProvider: values.rawValueAt(1),
      providers: values
          .listAt<CborTagValue>(2)
          .map((e) => DefaultAPIProvider.deserialize(object: e))
          .toList(),
    );
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.networkServiceProvider;

  @override
  List<CborObject?> get serializationItems => [
        auto.toCbor(),
        enableProvider.toCbor(),
        AppSerialization.listFromObjects(providers.map((e) => e.toCbor()).toList())
      ];
  @override
  List<dynamic> get variables => [auto, enableProvider, providers];

  NetworkClientConfig copyWith({
    bool? autoConnect,
    bool? enableProvider,
    List<DefaultAPIProvider>? providers,
    bool? runtimeAuto,
  }) {
    return NetworkClientConfig(
        auto: autoConnect ?? auto,
        enableProvider: enableProvider ?? this.enableProvider,
        providers: providers ?? this.providers,
        runtimeAuto: runtimeAuto ?? this.runtimeAuto);
  }

  bool get allowAutoConnect => auto && runtimeAuto;
}
