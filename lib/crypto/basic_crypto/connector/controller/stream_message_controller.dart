import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/controller/controller.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/argruments/argruments.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';

typedef OnStreamMessage = Function(
    CborMessageResponseArgs message, bool encrypted, int id);

class StreamIsolateMessageController
    implements IsolateCryptoController<CryptoStreamMessageArgs> {
  StreamIsolateMessageController(this.onStreamCallBack);
  final OnStreamMessage onStreamCallBack;

  final Map<String, IsolateStreamRequest> streams = {};

  @override
  Future<IResult<CborMessageResponseArgs>> handleMessage(
      {required CryptoStreamMessageArgs args,
      required int id,
      required AppContext context,
      List<int>? encryptedPart}) async {
    return await IResult.call(() async {
      switch (args.method) {
        case StreamIsolateMethod.streamArgs:
          final MessageArgsStream msg = args as MessageArgsStream;
          final streamId = msg.streamId;
          final controller = streams[streamId];
          if (controller == null) {
            return MessageArgsException(AppInternalError.internalError(
                "StreamIsolateMessageController.handleMessage",
                reason: "Invalid stream request. controller missing."));
          }
          controller.add(msg, encryptedPart);
          return MessageArgsComplete.empty();
        default:
          final streamId = UUID.generateUUIDv4();
          final IsolateStreamRequest msg = args as IsolateStreamRequest;
          msg.getIsolateResult(streamId, context).listen(
            (e) {
              onStreamCallBack(e.message, e.encrypted, id);
            },
            onDone: () {
              streams.remove(streamId);
              final message = MessageArgsStreamResponse.close(streamId);
              onStreamCallBack(message, false, id);
            },
          );
          streams[streamId] = msg;
          return MessageArgsStreamId(streamId);
      }
    });
  }

  @override
  void close() {
    final streams = this.streams.clone();
    streams.clear();
    for (final stream in streams.entries) {
      stream.value.add(MessageArgsStream.close(stream.key), null);
    }
  }
}
