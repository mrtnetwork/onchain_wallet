import 'dart:ffi';
import 'dart:typed_data';
import 'package:blockchain_utils/blockchain_utils.dart' hide Pointer;
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/native/database/fifi/fifi.dart';
import 'package:on_chain_bridge/native/utils/utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/crypto_libs/cross/io/native/types.dart';
import 'package:on_chain_wallet/crypto/crypto_libs/types/types.dart';

class MoneroLib {
  final DynamicLibrary library;
  MoneroLib({required this.library});
  static MoneroLib? findLiberary(String libname) {
    final path = OnChainBridgeIoUtils.getDynamicLiberaryPath(libname);
    if (path == null) return null;
    try {
      return MoneroLib(library: DynamicLibrary.open(path));
    } catch (e) {
      Logging.error(
        fn: () => AppLogData(function: "findLiberary", runtime: "MoneroLib", err: e),
      );
      return null;
    }
  }

  late final _generateKeyDerivation = library.lookupFunction<MONEROGENERATEKEYDERIVATIONC,
      MONEROGENERATEKEYDERIVATIONDART>('generate_key_derivation_var');
  late final _generatePublicKey =
      library.lookupFunction<MONEROGENERATEPUBLICKKEYC, MONEROGENERATEPUBLICKKEYDART>(
          'derive_public_key_var');

  late final _generatePublicKeyBatch = library.lookupFunction<
      MONEROGENERATEKEYDERIVATIONBATCHC,
      MONEROGENERATEKEYDERIVATIONBATCHDART>('generate_key_derivation_batch');

  late final _generatePublicKeyBatch2 = library.lookupFunction<
      MONEROGENERATEKEYDERIVATIONBATCH2C,
      MONEROGENERATEKEYDERIVATIONBATCH2DART>('monero_generate_key_derivation_batch');

  late final MONEROUNLOCKOUTPUTBATCHDART _unlockMoneroOutputs = library
      .lookup<NativeFunction<MONEROUNLOCKOUTPUTBATCHC>>(
          "monero_unlock_outputs_batch_compact")
      .asFunction();

  late final MONEROUNLOCKRESULTFREEDART _unlockMoneroResultPointer = library
      .lookup<NativeFunction<MONEROUNLOCKRESULTFREEC>>("monero_unlock_result_free")
      .asFunction();

  List<int> moneroGenerateKeyDerivation(
      {required MoneroPrivateKey viewSecretKey, required List<int> txPubkey}) {
    final resultPtr = malloc<Uint8>(Ed25519KeysConst.pubKeyByteLen);
    final skPtr = malloc<Uint8>(Ed25519KeysConst.privKeyByteLen);
    final pkPtr = malloc<Uint8>(Ed25519KeysConst.pubKeyByteLen);
    try {
      final skBytes = skPtr.asTypedList(Ed25519KeysConst.privKeyByteLen);
      skBytes.setAll(0, Uint8List.fromList(viewSecretKey.privateKey.key));

      final pk2Bytes = pkPtr.asTypedList(Ed25519KeysConst.pubKeyByteLen);
      pk2Bytes.setAll(0, txPubkey);
      final result = _generateKeyDerivation(pkPtr, skPtr, resultPtr);
      assert(result == 0);
      final derivation =
          resultPtr.asTypedList(Ed25519KeysConst.pubKeyByteLen).asImmutableBytes;

      return derivation;
    } finally {
      malloc.free(resultPtr);
      malloc.free(skPtr);
      malloc.free(pkPtr);
    }
  }

  List<int> moneroGeneratePublicKey(
      {required List<int> scalar, required List<int> basePublicKey}) {
    final resultPtr = malloc<Uint8>(Ed25519KeysConst.pubKeyByteLen);
    final skPtr = malloc<Uint8>(Ed25519KeysConst.privKeyByteLen);
    final pkPtr = malloc<Uint8>(Ed25519KeysConst.pubKeyByteLen);
    try {
      final skBytes = skPtr.asTypedList(Ed25519KeysConst.privKeyByteLen);
      skBytes.setAll(0, Uint8List.fromList(scalar));

      final pk2Bytes = pkPtr.asTypedList(Ed25519KeysConst.pubKeyByteLen);
      pk2Bytes.setAll(0, basePublicKey);
      final result = _generatePublicKey(skPtr, pkPtr, resultPtr);
      assert(result == 0);
      final derivation =
          resultPtr.asTypedList(Ed25519KeysConst.pubKeyByteLen).asImmutableBytes;

      return derivation;
    } finally {
      malloc.free(resultPtr);
      malloc.free(skPtr);
      malloc.free(pkPtr);
    }
  }

  List<List<int>> moneroGenerateKeyDerivationBatch(
      {required List<MoneroPrivateKey> viewSecretKey,
      required List<List<int>> txPubkey}) {
    assert(viewSecretKey.length == txPubkey.length);
    assert(viewSecretKey.isNotEmpty);
    final resultPtr =
        malloc<Uint8>(Ed25519KeysConst.pubKeyByteLen * viewSecretKey.length);
    final skPtr = malloc<Uint8>(Ed25519KeysConst.privKeyByteLen * viewSecretKey.length);
    final pkPtr = malloc<Uint8>(Ed25519KeysConst.pubKeyByteLen * viewSecretKey.length);
    try {
      final skBytes =
          skPtr.asTypedList(Ed25519KeysConst.privKeyByteLen * viewSecretKey.length);
      skBytes.setAll(0, viewSecretKey.expand((e) => e.privateKey.key));

      final pk2Bytes =
          pkPtr.asTypedList(Ed25519KeysConst.pubKeyByteLen * viewSecretKey.length);
      pk2Bytes.setAll(0, txPubkey.expand((e) => e));
      final result =
          _generatePublicKeyBatch(pkPtr, skPtr, resultPtr, viewSecretKey.length);
      assert(result == 0);
      final derivation = resultPtr
          .asTypedList(Ed25519KeysConst.pubKeyByteLen * viewSecretKey.length)
          .asImmutableBytes;
      assert(derivation.length ~/ viewSecretKey.length == Ed25519KeysConst.pubKeyByteLen);
      return List.generate(
          viewSecretKey.length,
          (i) => derivation.sublist(i * Ed25519KeysConst.pubKeyByteLen,
              i * Ed25519KeysConst.pubKeyByteLen + Ed25519KeysConst.pubKeyByteLen));
    } finally {
      malloc.free(resultPtr);
      malloc.free(skPtr);
      malloc.free(pkPtr);
    }
  }

  List<List<List<int>>> moneroGenerateKeyDerivationBatch2(
      {required List<MoneroPrivateKey> viewSecretKey, required List<List<int>> pubKeys}) {
    // assert(viewSecretKey.length == pubKeys.length);
    assert(viewSecretKey.isNotEmpty);
    assert(pubKeys.isNotEmpty);
    final resultPtr = malloc<Uint8>(
        Ed25519KeysConst.pubKeyByteLen * (viewSecretKey.length * pubKeys.length));

    final skPtr = malloc<Uint8>(Ed25519KeysConst.privKeyByteLen * viewSecretKey.length);
    final pkPtr = malloc<Uint8>(Ed25519KeysConst.pubKeyByteLen * pubKeys.length);
    try {
      final skBytes =
          skPtr.asTypedList(Ed25519KeysConst.privKeyByteLen * viewSecretKey.length);
      skBytes.setAll(0, viewSecretKey.expand((e) => e.privateKey.key));

      final pk2Bytes = pkPtr.asTypedList(Ed25519KeysConst.pubKeyByteLen * pubKeys.length);
      pk2Bytes.setAll(0, pubKeys.expand((e) => e));

      final result = _generatePublicKeyBatch2(
          pkPtr, skPtr, resultPtr, viewSecretKey.length, pubKeys.length);
      assert(result == 0);
      final derivation = resultPtr
          .asTypedList(
              Ed25519KeysConst.pubKeyByteLen * (viewSecretKey.length * pubKeys.length))
          .asImmutableBytes;

      return List.generate(viewSecretKey.length, (sc) {
        return List.generate(pubKeys.length, (pk) {
          final index = (sc * pubKeys.length + pk) * Ed25519KeysConst.pubKeyByteLen;
          return derivation.sublist(index, index + Ed25519KeysConst.pubKeyByteLen);
        });
      });
    } finally {
      malloc.free(resultPtr);
      malloc.free(skPtr);
      malloc.free(pkPtr);
    }
  }

  List<MoneroCryptoUnlockOutput> moneroUnlockOutput(
      {required List<MoneroAccountKeys> accounts,
      required MoneroTransaction transaction}) {
    final txPubkey = transaction.txPubkeyBytes();
    if (txPubkey == null) return [];
    final viewKeys = accounts.map((e) => e.account.privateViewKey.key).toList();
    final viewKeysPtr = calloc<Uint8>(viewKeys.length * Ed25519KeysConst.privKeyByteLen)
      ..asTypedList(
        viewKeys.length * Ed25519KeysConst.privKeyByteLen,
      ).setAll(0, viewKeys.expand((e) => e));

    final spendPublicKeys = accounts
        .map(
          (e) => e.indexes.indexed.map((i) => e.getSpendPublicKey(i.$2).key).toList(),
        )
        .toList();
    final spendPubkeysLength = spendPublicKeys.fold<int>(
        0, (p, c) => p + c.length * Ed25519KeysConst.pubKeyByteLen);
    final spendPublicKeysPtr = calloc<Uint8>(spendPubkeysLength);
    spendPublicKeysPtr
        .asTypedList(spendPubkeysLength)
        .setAll(0, spendPublicKeys.expand((e) => e.expand((e) => e)));

    final outPublicKeys = calloc<Uint8>(
        transaction.vout.length * Ed25519KeysConst.pubKeyByteLen)
      ..asTypedList(transaction.vout.length * Ed25519KeysConst.pubKeyByteLen).setAll(
          0, transaction.vout.expand((e) => e.target.getPublicKeyBytes() ?? RCTConst.z));

    final spendIndexCount = accounts.map((e) => e.indexes.length).toList();
    final spendIndexPtr = calloc<Int32>(spendIndexCount.length)
      ..asTypedList(spendIndexCount.length).setAll(0, spendIndexCount);

    final additionalPubKeys = transaction.additionalPubKeys?.pubKeys;
    final List<int> viewTags =
        transaction.vout.map((e) => e.target.getViewTag() ?? -1).toList();
    final txPubKeyPtr = calloc<Uint8>(txPubkey.length)
      ..asTypedList(txPubkey.length).setAll(0, txPubkey);
    Pointer<Uint8>? additionalPubKeysPtr;
    if (additionalPubKeys != null) {
      additionalPubKeysPtr = calloc<Uint8>(additionalPubKeys.length * 32)
        ..asTypedList(
          additionalPubKeys.length * 32,
        ).setAll(0, additionalPubKeys.expand((e) => e));
    }
    final viewTagsPtr = calloc<Int32>(viewTags.length)
      ..asTypedList(viewTags.length).setAll(0, viewTags);
    final result = _unlockMoneroOutputs(
      viewKeysPtr,
      spendPublicKeysPtr,
      outPublicKeys,
      spendIndexPtr,
      txPubKeyPtr,
      additionalPubKeysPtr ?? nullptr,
      viewTagsPtr,
      transaction.vout.length,
      accounts.length,
    );
    try {
      final totalItems = result.ref.count;
      if (totalItems == 0) {
        return [];
      }
      List<MoneroCryptoUnlockOutput> items = [];
      for (int i = 0; i < totalItems; i++) {
        final item = result.ref.items[i];
        final derivation =
            List.generate(Ed25519KeysConst.privKeyByteLen, (i) => item.derivation[i]);
        final publicKey =
            List.generate(Ed25519KeysConst.pubKeyByteLen, (i) => item.derivedPk[i]);
        final account = accounts[item.accountIndex];
        final index = account.indexes[item.addressIndex];
        final realIndex = item.outIndex;
        final output = transaction.vout[realIndex];
        final isAccountTx =
            BytesUtils.bytesEqual(publicKey, output.target.getPublicKeyBytes());
        assert(isAccountTx);
        if (isAccountTx) {
          final sharedSec = MoneroCrypto.derivationToScalarVar(
              derivation: derivation, outIndex: realIndex);
          final coinbase = transaction.isCoinbase();
          final amount = switch (coinbase) {
            false => RCTGeneratorUtils.decodeRctVar(
                sig: transaction.signature.cast(),
                secretKey: sharedSec,
                outputIndex: realIndex),
            true => (output.amount, RCT.identity(clone: false))
          };
          if (amount == null) continue;
          final out = MoneroLockedOutput(
              amount: amount.$1,
              mask: amount.$2,
              derivation: derivation,
              coinbase: coinbase,
              outputPublicKey: publicKey,
              accountIndex: index,
              unlockTime: transaction.unlockTime,
              realIndex: realIndex);
          items.add(MoneroCryptoUnlockOutput(account: account, output: out));
        }
      }
      return items;
    } finally {
      malloc.free(viewKeysPtr);
      malloc.free(spendPublicKeysPtr);
      malloc.free(outPublicKeys);
      malloc.free(spendIndexPtr);
      malloc.free(txPubKeyPtr);
      if (additionalPubKeysPtr != null) {
        malloc.free(additionalPubKeysPtr);
      }
      malloc.free(viewTagsPtr);
      _unlockMoneroResultPointer(result);
    }
  }

  void close() {
    library.close();
  }
}
