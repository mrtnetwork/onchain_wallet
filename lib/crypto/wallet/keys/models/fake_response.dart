part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

class FakeKeyData extends CryptoKeyData {
  const FakeKeyData._() : super._();
  factory FakeKeyData() {
    return FakeKeyData._();
  }

  @override
  SerializationIdentifier get serializationIdentifier => throw UnimplementedError();

  @override
  List<CborObject?> get serializationItems => throw UnimplementedError();
}
