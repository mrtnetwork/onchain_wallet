import 'package:blockchain_utils/cbor/serialization/cbor/tag.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/types.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/argruments/argruments.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

abstract mixin class AppBasicCryptoApi {
  int get maxSyncThread;
  Future<IResult<StreamCryptoRequestController<T, S>>> excuteStreamRequest<T, S>(
    IsolateStreamRequest<T, S> message, {
    SyncWorkerMode? mode,
  }) async =>
      ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  Future<IResult<T>> excuteSync<T extends CborTagSerializable>(
          {required CryptoArgsCompleter<T> message, required AppContext context}) async =>
      ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  Future<IResult<T>> excute<T extends CborTagSerializable>(
    CryptoArgsCompleter<T> message, {
    List<int>? encryptionPart,
    CryptoProcessLevel? level,
  }) async =>
      ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  Future<IResult<T>> excuteWallet<T extends CborTagSerializable>({
    required WalletArgsCompleter<T> message,
    required TransfableMemoryWallet memoryWallet,
    CryptoProcessLevel? level,
  }) async =>
      ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
}
