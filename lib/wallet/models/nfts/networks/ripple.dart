import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/wallet/models/nfts/core/core.dart';

class RippleNFToken extends NFTCore with Equality {
  factory RippleNFToken.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: NFTType.ripple.tag);
    final int flags = cbor.rawValueAt(0);
    final String nftokenId = cbor.rawValueAt(1);
    final int nftokenTaxon = cbor.rawValueAt(2);
    final String issuer = cbor.rawValueAt(3);
    final int serial = cbor.rawValueAt(4);
    final String? uri = cbor.rawValueAt(5);

    return RippleNFToken(
        flags: flags,
        issuer: issuer,
        nftokenId: nftokenId,
        nftokenTaxon: nftokenTaxon,
        serial: serial,
        uri: uri);
  }
  const RippleNFToken({
    required this.flags,
    required this.nftokenId,
    required this.issuer,
    required this.nftokenTaxon,
    required this.serial,
    required this.uri,
  });

  @override
  final String? uri;
  final String nftokenId;
  final int flags;
  final String issuer;
  final int serial;
  final int nftokenTaxon;

  @override
  List get variables => [uri, nftokenId, flags, issuer, serial, nftokenTaxon];

  @override
  NFTType get type => NFTType.ripple;

  @override
  String get identifier => nftokenId;

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems => [
        flags.toCbor(),
        nftokenId.toCbor(),
        nftokenTaxon.toCbor(),
        issuer.toCbor(),
        serial.toCbor(),
        uri?.toCbor()
      ];
}
