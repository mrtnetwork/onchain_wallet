import 'dart:isolate';

import 'package:on_chain_wallet/app/utils/bytes/quick_bytes.dart';
import 'package:on_chain_wallet/app/utils/method/result.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/cross/native/types.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';

class NativeCryptoApiUtils {
  static IIsolateCryptoMessageNative resolveMessage(
      IResult<IIsolateCryptoMessageNative> message, int id) {
    return message.fold(
      onOk: (value) => value,
      onErr: (error) => IsolateCryptoMessageNative(
          message: TransferableTypedData.fromList([
            QuickBytesUtils.asUint8List(
                MessageArgsException(error.exception).toCbor().encode())
          ]),
          id: id),
    );
  }
}
