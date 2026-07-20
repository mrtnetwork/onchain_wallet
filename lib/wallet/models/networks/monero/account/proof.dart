import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:monero_dart/monero_dart.dart';

final class MoneroProofTxParams {
  final String txId;
  final String? message;
  final List<List<int>>? txKeys;
  final MoneroAddress? receiverAddress;
  MoneroProofTxParams(
      {required String txId,
      required this.message,
      List<List<int>>? txKeys,
      this.receiverAddress})
      : txId = StringUtils.normalizeHex(txId),
        txKeys = txKeys?.emptyAsNull?.immutable;

  MoneroProofTxParams copyWith({
    String? txId,
    String? message,
    List<List<int>>? txKeys,
    MoneroAddress? receiverAddress,
  }) {
    return MoneroProofTxParams(
        txId: txId ?? this.txId,
        message: message ?? this.message,
        receiverAddress: receiverAddress ?? this.receiverAddress,
        txKeys: txKeys ?? this.txKeys);
  }
}

final class MoneroVerifyProofTxParams {
  final String txId;
  final String? message;
  final MoneroAddress address;
  final String proof;
  MoneroVerifyProofTxParams(
      {required String txId,
      required this.message,
      required this.address,
      required this.proof})
      : txId = StringUtils.normalizeHex(txId);
}
