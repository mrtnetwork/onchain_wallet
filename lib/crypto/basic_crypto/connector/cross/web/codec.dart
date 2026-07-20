import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/web/web.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/types/worker.dart';
import 'package:on_chain_wallet/context/web/types/port.dart';
import 'package:on_chain_wallet/context/web/worker/types.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/messages.dart';

class JSIsolateCryptoMessageDecoder
    extends JSIsolateMessagDecoder<IIsolateCryptoSerializableMessage> {
  @override
  IResult<IIsolateCryptoSerializableMessage> decode(
      MessageEvent<JSWorkerMessage?> message) {
    return exportEventData(message).andThenCatch((message) {
      final bytes = message.buffer;
      if (bytes != null) {
        return ResultOk(IIsolateCryptoSerializableMessage.deserialize(bytes: bytes));
      }
      return ResultErr.fromException(AppInternalError.internalError(
        "JSIsolateCryptoMessageDecoder.decode",
        reason: "Missing message buffer.",
      ));
    });
  }
}

class JSIsolateCryptoMessageEncoder
    extends JSIsolateMessageEncoder<IIsolateCryptoSerializableMessage> {
  @override
  IResult<WebIsolateEncodedMessage> encode(IIsolateCryptoSerializableMessage message) {
    return ResultOk(WebIsolateEncodedMessage.bytes(
        bytes: message.toCbor().encode(),
        type: IsolateMessageTypes.crypto,
        id: message.id));
  }
}

abstract mixin class WebIsolateCryptoMessageEncoder {
  ChaCha20Poly1305 get chacha;
  IsolateCryptoSerializableEncryptedMessage toEncryptedMessage(
      List<int> message, int id) {
    final nonce = QuickCrypto.generateRandom(16);
    final enc = chacha.encrypt(nonce, message);
    return IsolateCryptoSerializableEncryptedMessage(message: enc, nonce: nonce, id: id);
  }

  IIsolateCryptoSerializableMessage encodeMessage(
      {required List<int> request,
      required bool encrypted,
      required int requestId,
      List<int>? encryptedPart}) {
    if (encrypted) {
      return toEncryptedMessage(request, requestId);
    }
    return IsolateCryptoSerializableMessage(
        message: request,
        id: requestId,
        encryptedPart:
            encryptedPart == null ? null : toEncryptedMessage(encryptedPart, requestId));
  }
}
