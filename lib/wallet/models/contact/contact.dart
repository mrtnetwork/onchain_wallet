import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/networks/types/address.dart';
import 'package:blockchain_utils/networks/types/network.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/crypto/networks/address/utils.dart';

final class NetworkContact<T extends IAddress> with AppSerialization, Equality {
  final T addressObject;
  String get address => addressObject.address;
  final String name;
  final DateTime created;
  factory NetworkContact.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValueWithInfo(
        cborBytes: bytes,
        cborObject: object,
        expectedTags: BlockchainNetwork.values.map((e) => e.identifier).toList());
    final address = BlockchainAddressUtils.parseIAddress(
      bytes: values.values.rawValueAt(0),
    );
    if (address is! T) {
      throw WalletExceptionConst.invalidContactDetails;
    }
    return NetworkContact(
      addressObject: address,
      name: values.values.rawValueAt(1),
      created: values.values.rawValueAt(2),
    );
  }

  String get identifier => address;
  NetworkContact({required this.addressObject, required this.name, DateTime? created})
      : created = created ?? DateTime.now();

  @override
  SerializationIdentifier get serializationIdentifier =>
      addressObject.blockchainNetwork.identifier;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(addressObject.encodeAsIAddress()), name.toCbor(), created.toCbor()];
  @override
  List get variables => [address];

  String? get type => addressObject.viewType;
}
