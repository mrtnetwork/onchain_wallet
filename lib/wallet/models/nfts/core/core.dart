import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/models/nfts/networks/ripple.dart';

enum NFTType {
  ripple(AppSerializationIdentifier.rippleNfts);

  final AppSerializationIdentifier tag;
  const NFTType(this.tag);

  static NFTType fromTag(List<int>? tags) {
    return values.firstWhere(
      (e) => e.tag.isValidTags(tags),
      orElse: () => throw WalletExceptionConst.invalidNftInformation,
    );
  }
}

abstract class NFTCore with AppSerialization {
  abstract final String? uri;
  NFTType get type;
  String get identifier;
  const NFTCore();

  static T deserialize<T extends NFTCore>({List<int>? bytes, CborObject? object}) {
    final CborTagValue tag =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    final type = NFTType.fromTag(tag.tags);
    final NFTCore nft = switch (type) {
      NFTType.ripple => RippleNFToken.deserialize(bytes: bytes, object: object),
    };
    if (nft is! T) {
      throw AppInternalError.internalError("NFTCore");
    }
    return nft;
  }
}
