part of 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

final class PublicKeysView {
  final String? extendKey;
  final String comprossed;
  final String? uncomprossed;
  final String? chainCode;
  final String? inNetworkStyle;
  // final String keyName;
  final CryptoPublicKeyDataType keyType;
  const PublicKeysView._(
      {required this.extendKey,
      required this.comprossed,
      required this.uncomprossed,
      required this.chainCode,
      this.inNetworkStyle,
      // required this.keyName,
      required this.keyType});

  PublicKeysView copyWith({
    String? extendKey,
    String? comprossed,
    String? uncomprossed,
    String? chainCode,
    String? inNetworkStyle,
    // String? keyName,
  }) {
    return PublicKeysView._(
        extendKey: extendKey ?? this.extendKey,
        comprossed: comprossed ?? this.comprossed,
        uncomprossed: uncomprossed ?? this.uncomprossed,
        chainCode: chainCode ?? this.chainCode,
        inNetworkStyle: inNetworkStyle ?? this.inNetworkStyle,
        // keyName: keyName ?? this.keyName,
        keyType: keyType);
  }

  T cast<T extends PublicKeysView>() {
    if (this is! T) {
      throw AppInternalError.internalError("PublicKeysView");
    }
    return this as T;
  }

  PublicKeysView withNetworkKeyStyle(NetworkType network) {
    return copyWith(
        inNetworkStyle: MethodUtils.fallbackOnException(
      () => switch (network) {
        NetworkType.xrpl => RippleUtils.toRipplePublicKey(comprossed),
        NetworkType.stellar => XlmAddrEncoder().encodeKey(
            BytesUtils.fromHexString(comprossed),
            addrType: XlmAddrTypes.pubKey,
          ),
        _ => null
      },
      onError: (exception, trace) => AppLogData(
          runtime: runtimeType,
          function: "withNetworkKeyStyle",
          err: exception,
          trace: trace.toString()),
    ));
  }
}

final class MoneroPublicKeysView extends PublicKeysView {
  final String spendPublicKey;
  final String viewPublicKey;
  const MoneroPublicKeysView._(
      {required super.extendKey,
      required super.comprossed,
      required super.uncomprossed,
      required this.spendPublicKey,
      required this.viewPublicKey,
      required super.chainCode,
      // required super.keyName,
      required super.keyType})
      : super._();
  @override
  MoneroPublicKeysView copyWith({
    String? extendKey,
    String? comprossed,
    String? uncomprossed,
    String? chainCode,
    String? spendPublicKey,
    String? viewPublicKey,
    String? inNetworkStyle,
    // String? keyName,
  }) {
    return MoneroPublicKeysView._(
        extendKey: extendKey ?? this.extendKey,
        comprossed: comprossed ?? this.comprossed,
        uncomprossed: uncomprossed ?? this.uncomprossed,
        chainCode: chainCode ?? this.chainCode,
        spendPublicKey: spendPublicKey ?? this.spendPublicKey,
        viewPublicKey: viewPublicKey ?? this.viewPublicKey,
        keyType: keyType);
  }

  @override
  MoneroPublicKeysView withNetworkKeyStyle(NetworkType network) => this;
}

final class PrivateKeysView {
  final String? extendKey;
  final String privateKey;
  final String? wif;
  final String? inNetworkStyle;
  final CryptoPrivateKeyDataType keyType;
  final EllipticCurveTypes curve;
  List<int> privateKeyBytes() {
    return BytesUtils.fromHexString(privateKey);
  }

  const PrivateKeysView._(
      {required this.extendKey,
      required this.privateKey,
      required this.wif,
      // required this.keyName,
      required this.keyType,
      required this.curve,
      required this.inNetworkStyle});

  PrivateKeysView copyWith(
      {String? extendKey,
      String? privateKey,
      String? wif,
      String? chainCode,
      // String? keyName,
      String? inNetworkStyle}) {
    return PrivateKeysView._(
        extendKey: extendKey ?? this.extendKey,
        privateKey: privateKey ?? this.privateKey,
        wif: wif ?? this.wif,
        // keyName: keyName ?? this.keyName,
        keyType: keyType,
        curve: curve,
        inNetworkStyle: inNetworkStyle);
  }

  T cast<T extends PrivateKeysView>() {
    if (this is! T) {
      throw AppInternalError.internalError("PublicKeysView");
    }
    return this as T;
  }

  PrivateKeysView withNetworkKeyStyle(NetworkType network) {
    return copyWith(
        inNetworkStyle: MethodUtils.fallbackOnException(
      () => switch (network) {
        NetworkType.xrpl => RippleUtils.toRipplePrivateKey(privateKey, curve),
        NetworkType.sui =>
          SuiCryptoUtils.encodeSuiSecretKey(privateKeyBytes(), type: curve),
        NetworkType.aptos =>
          AptosCryptoUtils.encodeAptosPrivateKey(privateKeyBytes(), type: curve),
        NetworkType.stellar => XlmAddrEncoder().encodeKey(
            privateKeyBytes(),
            addrType: XlmAddrTypes.privKey,
          ),
        _ => null
      },
      onError: (exception, trace) => AppLogData(
          runtime: runtimeType,
          function: "withNetworkKeyStyle",
          err: exception,
          trace: trace.toString()),
    ));
  }
}

final class MoneroPrivateKeysView extends PrivateKeysView {
  final String spendPrivateKey;
  final String viewPrivateKey;
  const MoneroPrivateKeysView._(
      {required super.extendKey,
      required super.privateKey,
      required super.wif,
      required this.spendPrivateKey,
      required this.viewPrivateKey,
      // required super.keyName,
      required super.keyType,
      required super.curve})
      : super._(inNetworkStyle: null);
  @override
  MoneroPrivateKeysView copyWith({
    String? extendKey,
    String? privateKey,
    String? wif,
    String? chainCode,
    String? spendPrivateKey,
    String? viewPrivateKey,
    // String? keyName,
    String? inNetworkStyle,
  }) {
    return MoneroPrivateKeysView._(
        extendKey: extendKey ?? this.extendKey,
        privateKey: privateKey ?? this.privateKey,
        wif: wif ?? this.wif,
        spendPrivateKey: spendPrivateKey ?? this.spendPrivateKey,
        viewPrivateKey: viewPrivateKey ?? this.viewPrivateKey,
        // keyName: keyName ?? this.keyName,
        keyType: keyType,
        curve: curve);
  }

  @override
  MoneroPrivateKeysView withNetworkKeyStyle(NetworkType network) => this;
}

final class ViewExternalWalletConnectionInfo with AppSerialization, Equality {
  final String topic;
  final int clientId;
  // final String targetPublicKey;
  final List<int> sharedKey;
  ViewExternalWalletConnectionInfo(
      {required this.topic, required List<int> sharedKey, required this.clientId})
      : sharedKey = sharedKey.asImmutableBytes;
  factory ViewExternalWalletConnectionInfo.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.viewExternalWalletConnectionInfo);
    return ViewExternalWalletConnectionInfo(
        topic: values.rawValueAt(0),
        sharedKey: values.rawValueAt(1),
        clientId: values.rawValueAt(2));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.viewExternalWalletConnectionInfo;

  @override
  List<CborObject?> get serializationItems =>
      [topic.toCbor(), CborBytesValue(sharedKey), clientId.toCbor()];

  @override
  List<dynamic> get variables => [topic, CborBytesValue(sharedKey), clientId];

  @override
  String toString() => "topic: $topic, shared_key: ${BytesUtils.toHexString(sharedKey)}";
}
