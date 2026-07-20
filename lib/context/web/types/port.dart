import 'dart:js_interop';
import 'package:blockchain_utils/cbor/types/cbor_tag.dart';
import 'package:on_chain_bridge/web/types/file.dart';
import 'package:on_chain_bridge/web/web.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/types/channels.dart';
import 'package:on_chain_wallet/context/types/messages.dart';
import 'package:on_chain_wallet/context/types/worker.dart';
import 'package:on_chain_wallet/context/web/types/types.dart';
import 'package:on_chain_wallet/context/web/worker/types.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/messages.dart';

class JSMessageChannelSink implements IMesageChannelSink<WebIsolateEncodedMessage> {
  final IJSMessagePort port;
  bool _closed = false;
  JSMessageChannelSink({required this.port});

  @override
  IResult<void> send(WebIsolateEncodedMessage message) {
    if (_closed) {
      return ResultErr.fromException(AppExceptionConst.connectionAlreadyClosed);
    }
    final encode = message.encode();
    port.postMessageWithTransferables(encode.message, encode.transfableParams);
    return ResultOk.okVoid;
  }

  @override
  IResult<void> close() {
    if (_closed) {
      return ResultErr.fromException(AppExceptionConst.connectionAlreadyClosed);
    }
    _closed = true;
    if (port.close.isDefinedAndNotNull) {
      port.close?.callAsFunction(null);
    }
    return ResultOk.okVoid;
  }
}

abstract class JSIsolateMessageEncoder<W extends Object>
    extends ISolateMessageEncoder<W, WebIsolateEncodedMessage> {}

class JSIsolateContextMessageEncoder<MESSAGE extends ISolateMessage>
    extends JSIsolateMessageEncoder<MESSAGE> {
  @override
  IResult<WebIsolateEncodedMessage> encode(ISolateMessage message) {
    switch (message) {
      case ISolateMessageRequest<AppContextMessageRequest> request:
        final msg = request.message;
        switch (msg) {
          case AppContextMessageUtilsRequestStoreFile(:final file):
            if (file case WebFile(:final file)) {
              return ResultOk(WebIsolateEncodedMessage.message(
                  message: file,
                  type: msg.type,
                  buffer: message.toCbor().encode(),
                  id: request.id));
            }
            return ResultErr.fromException(AppInternalError.internalError(
              "JSIsolateMessageEncoder.encode",
              reason: "Unknown message file.",
            ));
        }
        break;
      case ISolateMessageResponse<AppContextMessageResponse> response:
        final result = response.message.ok();
        switch (result) {
          case AppContextMessageCreateConnectionResponse(:final port):
            return ResultOk(WebIsolateEncodedMessage.port(
                port: port, type: result.type, id: response.id));
          case AppContextMessageUtilsResponseGetData(:final data):
            JSFile? file;
            if (data case WebFile(file: final f)) {
              file = f;
            }
            return ResultOk(WebIsolateEncodedMessage.message(
                message: file, type: result.type, id: response.id));
        }
        break;
    }
    return ResultOk(WebIsolateEncodedMessage.bytes(
        bytes: message.toCbor().encode(), type: message.type, id: message.id));
  }
}

abstract class JSIsolateMessagDecoder<W extends Object>
    extends ISolateMessageDecoder<W, MessageEvent<JSWorkerMessage?>> {
  IResult<JSDartWorkerMessage> exportEventData(MessageEvent<JSWorkerMessage?> event) {
    if (event.data.isDefinedAndNotNull) {
      final data = event.data;
      if (data != null) return data.toDart();
    }
    return ResultErr.fromException(AppInternalError.internalError(
        "JSIsolateMessagDecoder.exportEventData",
        reason: "Invalid js event."));
  }
}

class JSIsolateContextResponseMessageDecoder
    extends JSIsolateMessagDecoder<ISolateMessageResponse<AppContextMessageResponse>> {
  @override
  IResult<ISolateMessageResponse<AppContextMessageResponse>> decode(
      MessageEvent<JSWorkerMessage?> message) {
    return exportEventData(message).andThenCatch((message) {
      final buffer = message.buffer;
      if (buffer != null) {
        return ResultOk(
            ISolateMessageResponse<AppContextMessageResponse>.deserialize(bytes: buffer));
      }
      final port = message.port;
      switch (message.type) {
        case IsolateMessageTypes.createConnection when port != null:
          return ResultOk(ISolateMessageResponse(
              id: message.id,
              type: message.type,
              message: ResultOk(AppContextMessageCreateConnectionResponse(port: port)),
              section: AppContextMessageSection.isolateConnection));
        case IsolateMessageTypes.utilsGetData:
          final f = message.message;
          return ResultOk(ISolateMessageResponse(
              id: message.id,
              type: message.type,
              message: ResultOk(AppContextMessageUtilsResponseGetData(
                  (f != null && f.isA<JSFile>()) ? WebFile(f as JSFile) : null)),
              section: AppContextMessageSection.utils));
        default:
          if (buffer != null) {
            return ResultOk(ISolateMessageResponse<AppContextMessageResponse>.deserialize(
                bytes: buffer));
          }
          return ResultErr.fromException(AppInternalError.internalError(
            "JSIsolateContextResponseMessageDecoder.decode",
            reason: "Invalid message.",
          ));
      }
    });
  }
}

class JSIsolateContextRequestMessageDecoder
    extends JSIsolateMessagDecoder<ISolateMessageRequest<AppContextMessageRequest>> {
  @override
  IResult<ISolateMessageRequest<AppContextMessageRequest>> decode(
      MessageEvent<JSWorkerMessage?> message) {
    return exportEventData(message).andThenCatch((message) {
      final bytes = message.buffer;
      if (bytes == null) {
        return ResultErr.fromException(AppInternalError.internalError(
          "JSIsolateContextRequestMessageDecoder.decode",
          reason: "Missing message buffer.",
        ));
      }
      AppContextMessageRequest? decodeMessage(CborTagValue object) {
        switch (message.type) {
          case IsolateMessageTypes.utilsStoreFile:
            final file = message.message;
            if (file == null || !file.isA<JSFile>()) {
              throw ResultErr.fromException(AppInternalError.internalError(
                "JSIsolateContextRequestMessageDecoder.decode",
                reason: "Missing message file.",
              ));
            }
            return AppContextMessageUtilsRequestStoreFile.deserialize(
                WebFile(file as JSFile),
                object: object);
          default:
            return null;
        }
      }

      return IResult.callSync(
        () => ISolateMessageRequest<AppContextMessageRequest>.deserialize(
            bytes: bytes, decode: decodeMessage),
      );
    });
  }
}

class JSIsolateBytesMessageDecoder extends JSIsolateMessagDecoder<List<int>> {
  @override
  IResult<List<int>> decode(MessageEvent<JSWorkerMessage?> message) {
    return exportEventData(message).andThen((message) {
      final bytes = message.buffer;
      if (bytes != null) {
        return ResultOk(bytes);
      }
      return ResultErr.fromException(AppInternalError.internalError(
        "JSIsolateBytesMessageDecoder.decode",
        reason: "Missing message buffer.",
      ));
    });
  }
}

class JSCryptoIsolateContextMessageEncoder extends ISolateMessageEncoder<
    IIsolateCryptoSerializableMessage,
    ISolateMessageRequest<AppContextMessageCryptoRequestDefault>> {
  @override
  IResult<ISolateMessageRequest<AppContextMessageCryptoRequestDefault>> encode(
      IIsolateCryptoSerializableMessage message) {
    return ResultOk(ISolateMessageRequest(
        id: message.id, message: AppContextMessageCryptoRequestDefault(message)));
  }
}
