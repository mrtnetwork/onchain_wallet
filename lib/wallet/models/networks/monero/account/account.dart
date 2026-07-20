import 'package:blockchain_utils/bip/address/xmr_addr.dart';
import 'package:blockchain_utils/bip/ecc/keys/ed25519_monero_keys.dart';
import 'package:blockchain_utils/bip/monero/monero_base.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

class MoneroAccountIndex with Equality, AppSerialization {
  final Bip32DerivationIndex masterIndex;
  final MoneroSubIndex index;
  bool get isPrimary => !index.isSubaddress;
  bool get isSubAddresss => index.isSubaddress;
  XmrAddressType get addrType =>
      isSubAddresss ? XmrAddressType.subaddress : XmrAddressType.primaryAddress;

  const MoneroAccountIndex._({required this.masterIndex, required this.index});
  factory MoneroAccountIndex(
      {required Bip32DerivationIndex masterIndex, required MoneroSubIndex index}) {
    return MoneroAccountIndex._(masterIndex: masterIndex, index: index);
  }
  factory MoneroAccountIndex.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.moneroAccountIndex);

    return MoneroAccountIndex(
        masterIndex: Bip32DerivationIndex.deserialize(object: values.objectAt(0)),
        index: MoneroSubIndex.deserializeCbor(obj: values.objectAt(1)));
  }

  @override
  List get variables => [
        masterIndex,
        index.toCbor(),
      ];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.moneroAccountIndex;

  @override
  List<CborObject?> get serializationItems => [masterIndex.toCbor(), index.toCbor()];
}

class MoneroAccountIndexWithPrimaryKey with AppSerialization {
  final MoneroViewPrimaryAccountDetails viewKey;
  final MoneroAccountIndex index;
  const MoneroAccountIndexWithPrimaryKey({required this.viewKey, required this.index});

  factory MoneroAccountIndexWithPrimaryKey.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);

    return MoneroAccountIndexWithPrimaryKey(
        viewKey: MoneroViewPrimaryAccountDetails.deserialize(object: values.objectAt(0)),
        index: MoneroAccountIndex.deserialize(object: values.objectAt(1)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [viewKey.toCbor(), index.toCbor()];
}

class MoneroViewPrimaryAccountDetails with AppSerialization, Equality {
  final List<int> viewPrivateKey;
  final List<int> spendPublicKey;
  final DerivableIndex index;
  final MoneroNetwork network;
  late final account =
      MoneroAccount.fromWatchOnly(viewPrivateKey, spendPublicKey, coinType: network.coin);
  late final primaryAddress = MoneroAccountAddress(account.primaryAddress,
      network: network, type: XmrAddressType.primaryAddress);
  final Map<MoneroSubIndex, MoneroAddress> _cachedAddresses = {};
  MoneroAddress getAddress(MoneroSubIndex index) {
    final addr = _cachedAddresses[index] ??=
        MoneroAddress(account.subaddress(index.minor, majorIndex: index.major));
    return addr;
  }

  MoneroViewPrimaryAccountDetails._(
      {required List<int> viewPrivateKey,
      required List<int> spendPublicKey,
      required this.network,
      required this.index})
      : viewPrivateKey = viewPrivateKey.asImmutableBytes,
        spendPublicKey = spendPublicKey.asImmutableBytes;
  factory MoneroViewPrimaryAccountDetails({
    required MoneroPrivateKey viewPrivateKey,
    required MoneroPublicKey spendPublicKey,
    required MoneroNetwork network,
    required DerivableIndex index,
  }) {
    return MoneroViewPrimaryAccountDetails._(
        viewPrivateKey: viewPrivateKey.key,
        spendPublicKey: spendPublicKey.key,
        network: network,
        index: index);
  }

  factory MoneroViewPrimaryAccountDetails.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.moneroViewPrimaryAccountDetails);

    return MoneroViewPrimaryAccountDetails._(
        viewPrivateKey: values.rawValueAt(0),
        spendPublicKey: values.rawValueAt(1),
        network: MoneroNetwork.fromValue(values.rawValueAt(2)),
        index: DerivableIndex.deserialize(object: values.objectAt(3)));
  }

  @override
  List get variables => [index, network];

  @override
  String toString() {
    return primaryAddress.toString();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.moneroViewPrimaryAccountDetails;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(viewPrivateKey),
        CborBytesValue(spendPublicKey),
        CborIntValue(network.index),
        index.toCbor()
      ];
}

class MoneroWalletRPCAddress {
  final MoneroAddress address;
  final MoneroSubIndex index;
  const MoneroWalletRPCAddress({required this.address, required this.index});
}
