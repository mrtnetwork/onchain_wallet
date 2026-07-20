// import 'package:blockchain_utils/blockchain_utils.dart';
// import 'package:on_chain_bridge/serialization/serialization.dart';
// import 'package:on_chain_wallet/crypto/requets/argruments/argruments.dart';
// import 'package:on_chain_wallet/crypto/requets/messages/core/message.dart';

// class CryptoRequestRandomGenerator extends CryptoRequest<AppSerializationBinary> {
//   final int length;
//   final List<List<int>> existsKeys;
//   CryptoRequestRandomGenerator._({required this.length, required this.existsKeys});

//   factory CryptoRequestRandomGenerator({
//     required int length,
//     List<List<int>> existsKeys = const [],
//   }) {
//     return CryptoRequestRandomGenerator._(
//       length: length,
//       existsKeys: List<List<int>>.unmodifiable(
//         List.generate(existsKeys.length, (e) => List<int>.unmodifiable(existsKeys[e])),
//       ),
//     );
//   }
//   // CryptoRequestRandomGenerator(
//   //     {required this.length, List<List<int>> existsKeys = const []})
//   //     : existsKeys = List<List<int>>.unmodifiable(List.generate(
//   //           existsKeys.length, (e) => List<int>.unmodifiable(existsKeys[e])));
//   factory CryptoRequestRandomGenerator.deserialize(
//       {List<int>? bytes, CborObject? object}) {
//     final CborListValue values = AppSerialization.decodeTaggedValue(
//         cborBytes: bytes,
//         cborObject: object,
//
//         identifier: CryptoRequestMethod.randomGenerator.tag);
//     final existsKeys = values.listAt<CborBytesValue>(1).map((e) => e.value);
//     return CryptoRequestRandomGenerator(
//         length: values.rawValueAt(0), existsKeys: List<List<int>>.from(existsKeys));
//   }

//   @override
//   CryptoRequestMethod get method => CryptoRequestMethod.randomGenerator;

//   static List<int> generateRandm(
//       {required int length, required List<List<int>> existsKeys}) {
//     if (existsKeys.isEmpty) {
//       return QuickCrypto.generateRandom(length);
//     }
//     while (true) {
//       final rand = QuickCrypto.generateRandom(length);
//       bool hasEqual = false;
//       for (final i in existsKeys) {
//         if (BytesUtils.bytesEqual(rand, i)) {
//           hasEqual = true;
//           break;
//         }
//       }
//       if (!hasEqual) {
//         return rand;
//       }
//     }
//   }

//   @override
//   AppSerializationBinary result() {
//     return AppSerializationBinary(generateRandm(length: length, existsKeys: existsKeys));
//   }

//   @override
//   SerializationIdentifier get serializationIdentifier => method.tag;

//   @override
//   List<CborObject?> get serializationItems => [
//         length,
//         AppSerialization.listFromObjects(
//             existsKeys.map((e) => CborBytesValue(e)).toList())
//       ];

//   @override
//   AppSerializationBinary parsResult(MessageArgsComplete result) {
//     return AppSerializationBinary.deserialize(object: result.result);
//   }
// }
