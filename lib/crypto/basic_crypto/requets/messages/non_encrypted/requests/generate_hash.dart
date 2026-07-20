import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/crypto/requests/hash.dart';

final class NoneEncryptedRequestHashing extends CryptoRequest<AppSerializationBinary> {
  final CryptoRequestHashingType hashingType;
  final String? dataHex;
  final List<int>? dataBytes;
  NoneEncryptedRequestHashing._(
      {required this.hashingType, this.dataHex, List<int>? dataBytes})
      : dataBytes = BytesUtils.tryToBytes(dataBytes, unmodifiable: true);
  factory NoneEncryptedRequestHashing.string(
      {required CryptoRequestHashingType type, required String data}) {
    return NoneEncryptedRequestHashing._(
        hashingType: type, dataBytes: StringUtils.encode(data));
  }
  factory NoneEncryptedRequestHashing(
      {required CryptoRequestHashingType type, String? dataHex, List<int>? dataBytes}) {
    if (dataHex != null && dataBytes != null) {
      throw AppInternalError.internalError("NoneEncryptedRequestHashing");
    }
    if ((dataHex == null && dataBytes == null) &&
        type != CryptoRequestHashingType.generateUuid) {
      throw AppInternalError.internalError("NoneEncryptedRequestHashing");
    }
    return NoneEncryptedRequestHashing._(
        hashingType: type, dataBytes: dataBytes, dataHex: dataHex);
  }
  factory NoneEncryptedRequestHashing.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CryptoRequestMethod.noEncryptHashing.tag);
    return NoneEncryptedRequestHashing._(
        hashingType: CryptoRequestHashingType.fromName(values.rawValueAt(0)),
        dataBytes: values.rawValueAt(1),
        dataHex: values.rawValueAt(2));
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.noEncryptHashing;

  static List<int> generateHash(
      {required CryptoRequestHashingType type, List<int>? dataBytes, String? dataHex}) {
    if (type == CryptoRequestHashingType.generateUuid) {
      final rand = QuickCrypto.generateRandom(16);
      final uuid = UUID.fromBuffer(rand);
      return StringUtils.encode(uuid);
    }
    List<int>? bytes = dataBytes;
    if (bytes == null) {
      if (type == CryptoRequestHashingType.uuid) {
        bytes = StringUtils.toBytes(dataHex!);
      } else {
        bytes = BytesUtils.fromHexString(dataHex!);
      }
    }
    switch (type) {
      case CryptoRequestHashingType.md4:
        return MD4.hash(bytes);
      case CryptoRequestHashingType.md5:
        return MD5.hash(bytes);
      case CryptoRequestHashingType.sha256:
        return SHA256.hash(bytes);
      case CryptoRequestHashingType.sha3:
        return SHA3.hash(bytes);
      case CryptoRequestHashingType.sha3256:
        return SHA3256.hash(bytes);
      case CryptoRequestHashingType.sha512:
        return SHA512.hash(bytes);
      case CryptoRequestHashingType.keccack256:
        return Keccack.hash(bytes);
      case CryptoRequestHashingType.uuid:
        final hash = MD4.hash(bytes);
        return StringUtils.encode(UUID.fromBuffer(hash));
      default:
        throw AppInternalError.internalError("NoneEncryptedRequestHashing");
    }
  }

  @override
  AppSerializationBinary parsResult(MessageArgsComplete result) {
    return AppSerializationBinary.deserialize(obj: result.result);
  }

  @override
  Future<AppSerializationBinary> result(AppContext context,
      {List<int>? encryptedPart}) async {
    return AppSerializationBinary(
        generateHash(type: hashingType, dataBytes: dataBytes, dataHex: dataHex));
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems =>
      [hashingType.name.toCbor(), dataBytes?.toCborBytes(), dataHex?.toCbor()];
}
