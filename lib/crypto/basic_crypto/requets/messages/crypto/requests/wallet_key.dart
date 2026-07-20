// import 'package:blockchain_utils/blockchain_utils.dart';
// import 'package:on_chain_bridge/serialization/serialization.dart';
// import 'package:on_chain_wallet/crypto/requets/argruments/argruments.dart';
// import 'package:on_chain_wallet/crypto/requets/messages/core/message.dart';
// import 'package:on_chain_wallet/crypto/utils/crypto/utils.dart';

// class CryptoRequestWalletKey extends CryptoRequest<AppSerializationBinary> {
//   final List<int> key;
//   final List<int> checksum;
//   CryptoRequestWalletKey._({required List<int> key, required List<int> checksum})
//       : key = key.asImmutableBytes,
//         checksum = checksum.asImmutableBytes;
//   factory CryptoRequestWalletKey.fromString(
//       {required String key, required List<int> checksum, int version = 2}) {
//     final keyBytes = StringUtils.encode(key);
//     return CryptoRequestWalletKey._(key: keyBytes, checksum: checksum);
//   }

//   factory CryptoRequestWalletKey.deserialize(
//       {List<int>? bytes, CborObject? object}) {
//     final CborListValue values = AppSerialization.decodeTaggedValue(
//         cborBytes: bytes,
//         cborObject: object,
//
//         identifier: CryptoRequestMethod.walletKey.tag);
//     return CryptoRequestWalletKey._(
//         key: values.rawValueAt(0), checksum: values.rawValueAt(1));
//   }

//   @override
//   CryptoRequestMethod get method => CryptoRequestMethod.walletKey;

//   @override
//   AppSerializationBinary parsResult(MessageArgsComplete result) {
//     return AppSerializationBinary.deserialize(object: result.result);
//   }

//   @override
//   AppSerializationBinary result() {
//     return AppSerializationBinary(
//         WorkerCryptoUtils.hashKeyNew(key: key, checksum: checksum));
//   }

//   @override
//   SerializationIdentifier get serializationIdentifier => method.tag;

//   @override
//   List<CborObject?> get serializationItems => [CborBytesValue(key), CborBytesValue(checksum)];
// }
