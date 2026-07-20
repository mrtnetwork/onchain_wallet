part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

enum CustomKeyType {
  privateKey(0),
  extendedKey(1),
  orchardSpendKey(2),
  saplingExtendedSpandingKey(3),
  wif(4),
  saplingSpendKey(5);

  final int value;
  const CustomKeyType(this.value);

  static CustomKeyType fromValue(int? value) {
    return values.firstWhere((e) => e.value == value,
        orElse: () => throw AppInternalError.internalError("CustomKeyType"));
  }

  bool get isPrivateKey => this == CustomKeyType.privateKey || this == wif;
}
