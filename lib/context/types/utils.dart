// import 'package:blockchain_utils/cbor/cbor.dart';
// import 'package:on_chain_bridge/database/database.dart';
// import 'package:on_chain_bridge/serialization/src/serialization.dart';
// import 'package:on_chain_wallet/app/serialization/serialization.dart';

// class RuntimeResourceLocation with AppSerialization {
//   final String fileLocation;
//   final TableStructAColums tableColumn;
//   final int? checksum;
//   const RuntimeResourceLocation(
//       {required this.fileLocation, required this.tableColumn, this.checksum});
//   factory RuntimeResourceLocation.deserialize({List<int>? bytes, CborObject? object}) {
//     final values = AppSerialization.decodeTaggedValue(
//         identifier: AppSerializationIdentifier.runtimeResourceLocation,
//         cborBytes: bytes,
//         cborObject: object);
//     return RuntimeResourceLocation(
//         fileLocation: values.rawValueAt(0),
//         tableColumn: TableStructAColums.deserialize(obj: values.objectAt(1)),
//         checksum: values.rawValueAt(1));
//   }
//   @override
//   SerializationIdentifier get serializationIdentifier =>
//       AppSerializationIdentifier.runtimeResourceLocation;

//   @override
//   List<CborObject<Object?>?> get serializationItems =>
//       [fileLocation.toCbor(), tableColumn.toCbor(), checksum?.toCbor()];
// }
