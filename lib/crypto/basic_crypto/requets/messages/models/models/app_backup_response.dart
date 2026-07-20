import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

final class AppBackupResponse with AppSerialization {
  final String backup;

  AppBackupResponse(this.backup);

  factory AppBackupResponse.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return AppBackupResponse(values.rawValueAt(0));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [backup.toCbor()];
}
