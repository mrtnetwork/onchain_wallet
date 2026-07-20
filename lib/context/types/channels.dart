import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/types/messages.dart';

abstract class ISolateMessageEncoder<W extends Object?, E extends Object?> {
  IResult<E?> encode(W message);
}

abstract class ISolateMessageDecoder<R extends Object?, M extends Object?> {
  IResult<R?> decode(M message);
}

abstract class ISolateConnector<WRITE extends Object, READ extends Object>
    implements MessageChannel<WRITE, READ> {
  @override
  Future<IResult<void>> add(WRITE data);
  @override
  Stream<READ> get stream;
  const ISolateConnector();
  Future<IResult<void>> closeConnection();
}

abstract class MessageChannel<WRITE extends Object, READ extends Object> {
  Future<IResult<void>> add(WRITE data);
  Stream<READ> get stream;
  const MessageChannel();
  Future<IResult<void>> dispose();
}

class DartInitializedWorker<WRITE extends Object, READ extends Object,
    RESPONSE extends Object?, CONNECTOR extends ISolateConnector<WRITE, READ>> {
  final CONNECTOR connector;
  final RESPONSE response;
  const DartInitializedWorker({required this.connector, required this.response});
}

abstract class IMesageChannelStream<R extends Object?> {
  final Stream<R> stream;
  const IMesageChannelStream(this.stream);
  void close();
}

class DefaultMessageChannelStream<R extends Object?> extends IMesageChannelStream<R> {
  const DefaultMessageChannelStream(super.stream);
  factory DefaultMessageChannelStream.broadcast(Stream<dynamic> stream) {
    return DefaultMessageChannelStream(stream.asBroadcastStream().cast<R>());
  }

  @override
  void close() {}
}

abstract class IMesageChannelSink<WRITE extends Object> {
  IResult<void> send(WRITE message);
  IResult<void> close();
}

typedef MessageChannelSinkCallBack<T> = void Function(T msg);

class DefaultMessageChannelSink<WRITE extends Object>
    implements IMesageChannelSink<WRITE> {
  final MessageChannelSinkCallBack<WRITE> sinkCallBack;
  DefaultMessageChannelSink(this.sinkCallBack);
  bool _closed = false;
  @override
  IResult<void> send(WRITE message) {
    if (_closed) {
      return ResultErr.fromException(AppExceptionConst.connectionAlreadyClosed);
    }
    sinkCallBack(message);
    return ResultOk.okVoid;
  }

  @override
  IResult<void> close() {
    if (_closed) {
      return ResultErr.fromException(AppExceptionConst.connectionAlreadyClosed);
    }
    _closed = true;
    return ResultOk.okVoid;
  }
}

class SinkMessageTransform<WRITE extends Object, MESSAGE extends Object>
    implements IMesageChannelSink<WRITE> {
  final IMesageChannelSink<MESSAGE> sink;
  final ISolateMessageEncoder<WRITE, MESSAGE> encoder;
  SinkMessageTransform({required this.sink, required this.encoder});

  @override
  IResult<void> send(WRITE message) {
    final toMessage = encoder.encode(message);
    return toMessage.andThen((e) {
      if (e != null) {
        return sink.send(e);
      }
      return ResultOk(null);
    });
  }

  @override
  IResult<void> close() {
    return sink.close();
  }
}

class ISolateMessageChannel<WRITE extends ISolateMessage, READ extends ISolateMessage>
    implements MessageChannel<WRITE, READ> {
  final MessageChannel<ISolateMessage, ISolateMessage> connector;
  @override
  final Stream<READ> stream;
  const ISolateMessageChannel({required this.connector, required this.stream});

  @override
  Future<IResult<void>> add(WRITE data) {
    return connector.add(data);
  }

  @override
  Future<IResult<void>> dispose() {
    return connector.dispose();
  }
}

class PortMessageChannel<WRITE extends Object, READ extends Object>
    implements MessageChannel<WRITE, READ> {
  final IMesageChannelStream<READ> receive;
  final IMesageChannelSink<WRITE> sink;
  final _lock = SafeAtomicLock();
  bool _closed = false;
  PortMessageChannel({required this.receive, required this.sink});

  @override
  Future<IResult<void>> add(WRITE data) {
    return _lock.run(() async {
      if (_closed) return ResultErr.fromException(AppInternalError());
      sink.send(data);
      return ResultOk(null);
    });
  }

  @override
  Stream<READ> get stream => receive.stream.cast();

  @override
  Future<IResult<void>> dispose() async {
    return await _lock.run(() async {
      receive.close();
      sink.close();
      _closed = true;

      return ResultOk(null);
    });
  }
}

class StreamMessageTransform<READ extends Object, MESSAGE extends Object> {
  final SafeStreamController<READ> controller;
  final ISolateMessageDecoder<READ, MESSAGE> decoder;
  StreamMessageTransform({required this.decoder, required String name})
      : controller = SafeStreamController<READ>(name: name);
  StreamMessageTransform.from({required this.controller, required this.decoder});
  StreamMessageTransform.broadcast({required this.decoder, required String name})
      : controller = SafeStreamController<READ>.broadcast(name: name);
  void listen(MESSAGE msg) {
    final obj = decoder.decode(msg);
    obj.map((e) {
      if (e != null) {
        controller.add(e);
      }
    }).mapErr((e) {
      Logging.danger(
          fn: () => AppLogData(
              runtime: "$runtimeType/${decoder.runtimeType}",
              err: e.exception,
              trace: e.trace,
              msg: "Failed to decode isolate message. $msg"));
      return e.exception;
    });
  }

  Stream<READ> get stream {
    return controller.stream();
  }

  void close() {
    controller.close();
  }
}
