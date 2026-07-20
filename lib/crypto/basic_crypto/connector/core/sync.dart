import 'dart:async';
import 'package:blockchain_utils/cbor/serialization/cbor/tag.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/api/core.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/types.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/argruments/argruments.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

typedef AppContextCallBack = AppContext Function();

class SyncAppBasicCryptoApi implements AppBasicCryptoApi {
  final AppContextCallBack contextCallBack;
  @override
  int get maxSyncThread => 0;

  SyncAppBasicCryptoApi(this.contextCallBack);
  Future<IResult<T>> _call<T>(
      {required FutureOr<IResult<T>> Function() onMain, required String method}) async {
    return IResult.block<T>(
      () async => await onMain(),
      onError: (exception, trace) {
        return AppLogData(
            runtime: runtimeType,
            function: "_call",
            msg: "$method request failed: ",
            trace: trace.toString(),
            err: exception);
      },
    );
  }

  @override
  Future<IResult<T>> excute<T extends CborTagSerializable>(
    CryptoArgsCompleter<T> message, {
    List<int>? encryptionPart,
    CryptoProcessLevel? level,
  }) async {
    if (encryptionPart != null && message.isEncrypted) {
      return ResultErr.fromException(AppInternalError.internalError("Invalid request"));
    }
    return _call(
        method: message.method.tag.name,
        onMain: () async {
          final result = await message.result(contextCallBack());
          return ResultOk(result);
        });
  }

  @override
  Future<IResult<StreamCryptoRequestController<T, S>>> excuteStreamRequest<T, S>(
      IsolateStreamRequest<T, S> message,
      {SyncWorkerMode? mode}) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  Future<IResult<T>> excuteSync<T extends CborTagSerializable>(
      {required CryptoArgsCompleter<T> message, required AppContext context}) {
    return _call(
        method: message.method.tag.name,
        onMain: () async {
          final result = await message.result(context);
          return ResultOk(result);
        });
  }

  @override
  Future<IResult<T>> excuteWallet<T extends CborTagSerializable>({
    required WalletArgsCompleter<T> message,
    required TransfableMemoryWallet memoryWallet,
    CryptoProcessLevel? level,
  }) {
    return _call(
        method: message.method.tag.name,
        onMain: () async {
          final wallet = MemoryWalletContext.fromTransfableMemeoryWallet(memoryWallet);
          final result = await message.result(wallet, contextCallBack());
          return ResultOk(result);
        });
  }

  Future<IResult<MessageArgsComplete>> excuteEncodable(CryptoArgsCompleter message,
      {List<int>? encryptionPart}) async {
    if (encryptionPart != null && message.isEncrypted) {
      return ResultErr.fromException(AppInternalError.internalError("Invalid request"));
    }
    return _call(
      method: message.method.tag.name,
      onMain: () async {
        final result =
            await message.result(contextCallBack(), encryptedPart: encryptionPart);
        return ResultOk(MessageArgsComplete(result.toCbor()));
      },
    );
  }

  Future<IResult<MessageArgsComplete>> excuteWalletEncodable({
    required WalletArgsCompleter message,
    required TransfableMemoryWallet memoryWallet,
  }) async {
    return _call(
      method: message.method.tag.name,
      onMain: () async {
        final wallet = MemoryWalletContext.fromTransfableMemeoryWallet(memoryWallet);
        final result = await message.result(wallet, contextCallBack());
        return ResultOk(MessageArgsComplete(result.toCbor()));
      },
    );
  }
}
