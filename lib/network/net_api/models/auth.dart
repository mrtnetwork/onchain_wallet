import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/service/models/params.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/net_sdk/authenticated/authenticated.dart';
import 'package:on_chain_wallet/app/error/exception/app_exception.dart';
import 'package:on_chain_wallet/app/error/exception/wallet_ex.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/serialization/serialization.dart';

enum ProviderAuthType {
  header(AppSerializationIdentifier.headerAuth),
  query(AppSerializationIdentifier.queryAuth),
  digest(AppSerializationIdentifier.digestAuth);

  final AppSerializationIdentifier tag;
  const ProviderAuthType(this.tag);

  static ProviderAuthType frimIdentifier(int id) {
    return values.firstWhere((e) => e.tag.isValidIdentifier(id),
        orElse: () => throw AppInternalError.internalError("ProviderAuthType"));
  }

  bool get isHeader => this == ProviderAuthType.header;
  bool get isDigest => this == ProviderAuthType.digest;

  static List<ProviderAuthType> byProtocol(ServiceProtocol protocol) {
    return switch (protocol) {
      ServiceProtocol.http => [
          ProviderAuthType.query,
          ProviderAuthType.header,
          ProviderAuthType.digest
        ],
      ServiceProtocol.ssl => [],
      ServiceProtocol.tcp => [],
      ServiceProtocol.websocket => [ProviderAuthType.query, ProviderAuthType.header],
      ServiceProtocol.grpc => [ProviderAuthType.header],
    };
  }
}

sealed class ProviderAuthenticated
    with AppSerialization, Equality
    implements HttpAuthenticated {
  final ProviderAuthType type;
  const ProviderAuthenticated({required this.type});

  factory ProviderAuthenticated.deserialize({List<int>? bytes, CborObject? object}) {
    final decoode = AppSerialization.decodeTaggedValueWithInfo(
        cborBytes: bytes,
        cborObject: object,
        expectedTags: ProviderAuthType.values.map((e) => e.tag).toList());
    final type = ProviderAuthType.frimIdentifier(decoode.identifier.id);
    return switch (type) {
      ProviderAuthType.header ||
      ProviderAuthType.query =>
        BasicProviderAuthenticated.deserialize(object: decoode.tag),
      ProviderAuthType.digest =>
        DigestProviderAuthenticated.deserialize(object: decoode.tag)
    };
  }

  T cast<T extends ProviderAuthenticated>() {
    if (this is! T) {
      throw AppInternalError.internalError("ProviderAuthenticated");
    }
    return this as T;
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;
}

class BasicProviderAuthenticated extends ProviderAuthenticated {
  final String key;
  final String value;
  const BasicProviderAuthenticated.unsafe(
      {required super.type, required this.key, required this.value});
  factory BasicProviderAuthenticated(
      {required String key, required String value, required ProviderAuthType type}) {
    switch (type) {
      case ProviderAuthType.header:
      case ProviderAuthType.query:
        return BasicProviderAuthenticated.unsafe(type: type, key: key, value: value);
      case ProviderAuthType.digest:
        throw WalletExceptionConst.invalidProviderAuthenticationConfiguration;
    }
  }

  Map<String, String> get auth => {key: value};

  factory BasicProviderAuthenticated.deserialize({List<int>? bytes, CborObject? object}) {
    final decode = AppSerialization.decodeTaggedValueWithInfo(
        cborBytes: bytes,
        cborObject: object,
        expectedTags: [
          AppSerializationIdentifier.headerAuth,
          AppSerializationIdentifier.queryAuth
        ]);
    final type = ProviderAuthType.frimIdentifier(decode.identifier.id);
    switch (type) {
      case ProviderAuthType.header:
      case ProviderAuthType.query:
        return BasicProviderAuthenticated(
            type: type,
            key: decode.values.rawValueAt(0),
            value: decode.values.rawValueAt(1));
      case ProviderAuthType.digest:
        throw AppInternalError.internalError("BasicProviderAuthenticated");
    }
  }

  @override
  Uri toUri(Uri uri) {
    if (type != ProviderAuthType.query) {
      return uri;
    }
    return uri.replace(queryParameters: {...uri.queryParameters, ...auth});
  }

  @override
  Map<String, String>? toHeaders(Map<String, String>? headers) {
    if (type != ProviderAuthType.header) {
      return headers;
    }
    return {...headers ?? {}, ...auth};
  }

  @override
  List get variables => [type, key, value];

  @override
  HttpDigestAuthenticated? digestAuthenticated() {
    return null;
  }

  @override
  List<CborObject?> get serializationItems => [key.toCbor(), value.toCbor()];
}

class DigestProviderAuthenticated extends ProviderAuthenticated {
  final String password;
  final String username;

  DigestProviderAuthenticated({
    required this.password,
    required this.username,
  }) : super(type: ProviderAuthType.digest);

  factory DigestProviderAuthenticated.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: ProviderAuthType.digest.tag);
    return DigestProviderAuthenticated(
        password: values.rawValueAt(0), username: values.rawValueAt(1));
  }

  @override
  Uri toUri(Uri uri) {
    return uri;
  }

  @override
  Map<String, String>? toHeaders(Map<String, String>? headers) {
    if (type != ProviderAuthType.header) {
      return headers;
    }
    return headers ?? {};
  }

  @override
  List get variables => [type, username, password];

  @override
  HttpDigestAuthenticated? digestAuthenticated() {
    return HttpDigestAuthenticated(username, password);
  }

  @override
  List<CborObject?> get serializationItems => [password.toCbor(), username.toCbor()];
}
