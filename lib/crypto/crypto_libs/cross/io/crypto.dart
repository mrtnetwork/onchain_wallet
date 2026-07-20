import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_bridge/native/utils/utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/crypto_libs/core/app_crypto.dart';
import 'package:on_chain_wallet/crypto/crypto_libs/cross/io/native/native_crypto.dart';
import 'package:on_chain_wallet/crypto/crypto_libs/types/zk_params_downloader.dart';
// import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:zcash_dart/zcash.dart';

AppCryptoLibs getAppCrypto() => AppCryptoIo._();

class AppCryptoIo extends AppCryptoLibs {
  AppCryptoIo._();
  @override
  Future<IResult<AppCryptoLibsMonero>> moneroCrypto(
      AppContext context, List<MoneroAccountKeys> accounts) async {
    final lib = context.resourceApi.moneroLibName().map((e) => MoneroLib.findLiberary(e));
    return lib.map((e) => AppCryptoMoneroIo(lib: e, accounts: accounts));
  }

  @override
  Future<IResult<AppCryptoLibsZcash>> zcashCrypto(AppContext context) async {
    final libName = context.resourceApi.zcashLibName().andThen((e) {
      final libName = OnChainBridgeIoUtils.getDynamicLiberaryPath(e);
      if (libName == null) {
        return ResultErr.fromException(AppExceptionConst.resourceNotSupported);
      }
      return ResultOk(libName);
    });
    return libName.andThenAsync((libName) async {
      final paramsLocation = context.resourceApi.zcashParamLocation();
      return paramsLocation.andThenAsync((params) async {
        final config = ZKLibConfig(
          libUri: libName,
          saplingParamsDownloader: ZcashParamDownloader(params: params, context: context),
        );
        final lib = await ZKLib.init(config);
        return ResultOk(AppCryptoLibsZcash(lib));
      });
    });
  }
}

class AppCryptoMoneroIo extends AppCryptoLibsMonero {
  AppCryptoMoneroIo({required MoneroLib? lib, required super.accounts}) : _lib = lib;
  MoneroLib? _lib;
  bool _closed = false;

  @override
  List<MoneroUnlockedOutputWithAccountKey> moneroUnlockOutput(
      {required MoneroTransaction transaction,
      required String txHash,
      required List<BigInt> outputIndices}) {
    assert(!_closed);
    if (_closed) return [];
    final lib = _lib;
    if (lib != null) {
      final unlock = lib.moneroUnlockOutput(accounts: accounts, transaction: transaction);
      List<MoneroUnlockedOutputWithAccountKey> outputs = [];
      if (unlock.isNotEmpty) {
        for (final output in unlock) {
          final globalIndex = outputIndices.elementAtOrNull(output.output.realIndex);
          if (globalIndex == null) {
            throw AppInternalError.internalError(
              "buildBlockState",
              reason: "Missing output global index.",
              details: {"txhash": txHash, "output": "${output.output.realIndex}"},
            );
          }
          outputs.add(
            MoneroUnlockedOutputWithAccountKey(
              account: output.account,
              output: output.output,
              globalIndex: globalIndex,
            ),
          );
        }
      }
      return outputs;
    }
    return super.moneroUnlockOutput(
        transaction: transaction, txHash: txHash, outputIndices: outputIndices);
  }

  @override
  void close() {
    _lib = null;
    _closed = true;
  }
}
