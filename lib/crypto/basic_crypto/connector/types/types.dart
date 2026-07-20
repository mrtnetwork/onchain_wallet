import 'dart:async';

import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/argruments/argruments.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';

import 'response.dart';

enum SyncWorkerMode {
  zcash(0),
  monero(1),
  sync1(2),
  sync2(3),
  sync3(4),
  sync4(5),
  sync5(6),
  sync6(7);

  final int value;
  const SyncWorkerMode(this.value);
  static List<SyncWorkerMode> getAvailableSyncWokers(int total) {
    assert(total > 0 && total <= 6);
    return List.generate(total, (index) => SyncWorkerMode.values.elementAt(index + 2));
  }

  static SyncWorkerMode fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw AppInternalError.internalError("SyncWorkerMode"),
    );
  }
}

typedef SENDSTREAMMSG = Future<IResult<MessageArgsComplete>> Function(
    MessageArgsStream msg, List<int>? encryptedPart);

class StreamCryptoRequestController<RESPONE, REQUEST> {
  final IsolateStreamRequest<RESPONE, REQUEST> message;
  final String streamId;
  final Stream<RESPONE> stream;
  final SENDSTREAMMSG _sendMsg;
  StreamCryptoRequestController(
      {required this.message,
      required this.streamId,
      required this.stream,
      required SENDSTREAMMSG sendMessage})
      : _sendMsg = sendMessage;

  Future<IResult<MessageArgsComplete>> add(REQUEST event, List<int>? encryptedPart) =>
      _sendMsg(message.toRequest(message: event, streamId: streamId), encryptedPart);
}

enum SyncWorkerStatus {
  busy,
  idle;

  bool get isIdle => this == idle;
}

class PendingConnectorRequest {
  final StreamArgsRequestable request;
  final List<int>? encryptPart;
  final SyncWorkerMode? mode;
  PendingConnectorRequest({required this.request, required this.encryptPart, this.mode});
  final Completer<IResult<PendingConnectorResponse>> _completer = Completer();
  bool get isComplete => _completer.isCompleted;
  Future<IResult<PendingConnectorResponse>> getConnection() => _completer.future;

  bool complete(IResult<PendingConnectorResponse> result) {
    if (isComplete) return false;
    _completer.complete(result);
    return true;
  }
}

class PendingConnectorResponse {
  final MessageArgsStreamId id;
  final SyncWorkerMode mode;
  final Stream<MessageArgsStreamResponse> stream;
  const PendingConnectorResponse(
      {required this.id, required this.mode, required this.stream});
}

class ActiveStreamConnectorData {
  final String streamId;
  final SafeStreamController<MessageArgsStreamResponse> controller;
  const ActiveStreamConnectorData({required this.streamId, required this.controller});

  void addMessage(MessageArgsStreamResponse message) {
    controller.add(message);
  }

  void close() {
    controller.close();
  }
}

enum CryptoProcessLevel {
  normal,
  high;

  bool get isHigh => this == high;
}

abstract class RequestableMessage with AppSerialization {
  RequestableMessage({required CancelableListener? cancelable})
      : cancelable = cancelable ?? CancelableListener();
  bool get isEncrypted;

  final CancelableListener cancelable;
  CryptoProcessLevel get level => CryptoProcessLevel.normal;
  Duration get processTimeout => Duration(minutes: 1);

  void cancel() => cancelable.cancel();
}
