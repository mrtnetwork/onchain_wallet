import 'package:on_chain_wallet/app/utils/method/result.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';

abstract class IsolateCryptoController<ARGS extends Object> {
  Future<IResult<CborMessageResponseArgs>> handleMessage(
      {required ARGS args,
      required int id,
      required AppContext context,
      List<int>? encryptedPart});
  void close();
}
