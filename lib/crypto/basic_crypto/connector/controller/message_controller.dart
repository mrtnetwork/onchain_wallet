import 'dart:async';
import 'package:blockchain_utils/cbor/serialization/cbor/tag.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/controller/controller.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/argruments/argruments.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';

typedef OnStreamMessage = Function(CborMessageResponseArgs message, int id);

class EncryptedIsolateMessageController
    implements IsolateCryptoController<CryptoMessageArgs> {
  EncryptedIsolateMessageController();

  @override
  Future<IResult<CborMessageResponseArgs>> handleMessage(
      {required CryptoMessageArgs args,
      required AppContext context,
      required int id,
      List<int>? encryptedPart}) async {
    return await IResult.call(() async {
      switch (args.method.type) {
        case CryptoArgsType.crypto:
          final CryptoRequest msg = args as CryptoRequest;
          final CborTagSerializable data =
              await msg.result(context, encryptedPart: encryptedPart);
          return MessageArgsComplete(data.toCbor());
        case CryptoArgsType.wallet:
          final WalletArgs msg = args as WalletArgs;
          final data = await msg.result(context);
          return MessageArgsComplete(data.toCbor());
      }
    });
  }

  @override
  void close() {}
}
