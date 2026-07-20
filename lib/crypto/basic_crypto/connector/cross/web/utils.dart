import 'package:on_chain_wallet/app/utils/method/result.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/messages.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';

class WebCryptoApiUtils {
  static IIsolateCryptoSerializableMessage resolveMessage(
      IResult<IIsolateCryptoSerializableMessage> message, int id) {
    return message.fold(
      onOk: (value) => value,
      onErr: (error) => IsolateCryptoSerializableMessage(
          message: MessageArgsException(error.exception).toCbor().encode(), id: id),
    );
  }
}
