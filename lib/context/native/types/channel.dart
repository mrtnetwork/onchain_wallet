import 'package:on_chain_wallet/app/utils/method/result.dart';
import 'package:on_chain_wallet/context/native/types/types.dart';
import 'package:on_chain_wallet/context/types/channels.dart';
import 'package:on_chain_wallet/context/types/messages.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/cross/native/types.dart';

abstract class NativeIsolateContextRequestMessageEncoder<MESSAGE extends Object>
    extends ISolateMessageEncoder<MESSAGE,
        ISolateMessageRequest<AppContextMessageRequest>> {}

class NativeCryptoIsolateContextMessageEncoder
    extends NativeIsolateContextRequestMessageEncoder<IIsolateCryptoMessageNative> {
  @override
  IResult<ISolateMessageRequest<AppContextMessageRequest>?> encode(
      IIsolateCryptoMessageNative message) {
    return ResultOk(ISolateMessageRequest<AppContextMessageCryptoRequestNative>(
        id: message.id, message: AppContextMessageCryptoRequestNative(message)));
  }
}

abstract class NativeIsolateMessagDecoder<W extends Object>
    extends ISolateMessageDecoder<W, ISolateMessageResponse<AppContextMessageResponse>> {}

class NativeCryptoIsolateContextMessageDecoder
    extends NativeIsolateMessagDecoder<IIsolateCryptoMessageNative> {
  @override
  IResult<IIsolateCryptoMessageNative?> decode(
      ISolateMessageResponse<AppContextMessageResponse> message) {
    switch (message.message) {
      case AppContextMessageCryptoResponseNative msg:
        return ResultOk(msg.message);
      default:
        break;
    }
    return ResultOk(null);
  }
}

// class DefaultMessageChannelPortNative<WRITE extends Object>
//     implements IMesageChannelSink<WRITE> {
//   final SendPort port;
//   final NativeIsolateContextMessageEncoder<WRITE> encoder;
//   bool _closed = false;
//   DefaultMessageChannelPortNative({required this.port, required this.encoder});

//   @override
//   IResult<void> send(WRITE message) {
//     if (_closed) {
//       return ResultErr.fromException(AppExceptionConst.connectionAlreadyClosed);
//     }
//     final toMessage = encoder.encode(message);
//     return toMessage.map((e) {
//       if (e != null) {
//         port.send(message);
//       }
//     });
//   }

//   @override
//   IResult<void> close() {
//     if (_closed) {
//       return ResultErr.fromException(AppExceptionConst.connectionAlreadyClosed);
//     }
//     _closed = true;
//     return ResultOk.okVoid;
//   }
// }
