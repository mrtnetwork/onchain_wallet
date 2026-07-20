part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

final class MultiSigAddressIndex extends DerivationIndex {
  const MultiSigAddressIndex();

  @override
  AddressDerivationType get derivationType => AddressDerivationType.multisig;

  @override
  String get name => "multi_signature";

  @override
  String toString() {
    return name;
  }

  @override
  List get variables => [];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.multiSigAccountKeyIndex;

  @override
  List<CborObject?> get serializationItems => [];
}
