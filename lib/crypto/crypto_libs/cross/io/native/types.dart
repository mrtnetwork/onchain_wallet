import 'dart:ffi';

// import 'package:on_chain_bridge/native/database/fifi/fifi.dart';
typedef MONEROGENERATEKEYDERIVATIONC = Int Function(
    Pointer<Uint8> publicKey, Pointer<Uint8> scalar, Pointer<Uint8> out);
typedef MONEROGENERATEKEYDERIVATIONDART = int Function(
    Pointer<Uint8> publicKey, Pointer<Uint8> scalar, Pointer<Uint8> out);

typedef MONEROGENERATEKEYDERIVATIONBATCHC = Int Function(
    Pointer<Uint8> publicKey, Pointer<Uint8> scalar, Pointer<Uint8> out, Int count);
typedef MONEROGENERATEKEYDERIVATIONBATCHDART = int Function(
    Pointer<Uint8> publicKey, Pointer<Uint8> scalar, Pointer<Uint8> out, int count);

typedef MONEROGENERATEPUBLICKKEYC = Int Function(
    Pointer<Uint8> scalar, Pointer<Uint8> publicKey, Pointer<Uint8> out);
typedef MONEROGENERATEPUBLICKKEYDART = int Function(
    Pointer<Uint8> scalar, Pointer<Uint8> publicKey, Pointer<Uint8> out);

typedef MONEROGENERATEKEYDERIVATIONBATCH2C = Int Function(
    Pointer<Uint8> publicKeyBytesBatch,
    Pointer<Uint8> scalarBatch,
    Pointer<Uint8> outBatch,
    Int sCount,
    Int pCount);

typedef MONEROGENERATEKEYDERIVATIONBATCH2DART = int Function(
    Pointer<Uint8> publicKeyBytesBatch,
    Pointer<Uint8> scalarBatch,
    Pointer<Uint8> outBatch,
    int sCount,
    int pCount);

final class MoneroMatchedOutputC extends Struct {
  @Int32()
  external int outIndex;

  @Array<Uint8>(32)
  external Array<Uint8> derivation;

  @Array<Uint8>(32)
  external Array<Uint8> derivedPk;

  @Int32()
  external int accountIndex;
  @Int32()
  external int addressIndex;
}

final class MoneroUnlockResultC extends Struct {
  @Int32()
  external int count;

  external Pointer<MoneroMatchedOutputC> items;
}

typedef MONEROUNLOCKRESULTFREEC = Void Function(Pointer<MoneroUnlockResultC>);
typedef MONEROUNLOCKRESULTFREEDART = void Function(Pointer<MoneroUnlockResultC>);

typedef MONEROUNLOCKOUTPUTBATCHC = Pointer<MoneroUnlockResultC> Function(
  Pointer<Uint8> viewSecretKeys,
  Pointer<Uint8> spendPublicKeys,
  Pointer<Uint8> outPublicKeys,
  Pointer<Int32> spendIndexCounts,
  Pointer<Uint8> txPubKeys,
  Pointer<Uint8> additionalPubKeys, // nullable
  Pointer<Int32> viewTags,
  Int32 outCount,
  Int32 accCount,
);

typedef MONEROUNLOCKOUTPUTBATCHDART = Pointer<MoneroUnlockResultC> Function(
  Pointer<Uint8> viewSecretKeys,
  Pointer<Uint8> spendPublicKeys,
  Pointer<Uint8> outPublicKeys,
  Pointer<Int32> spendIndexCounts,
  Pointer<Uint8> txPubKeys,
  Pointer<Uint8> additionalPubKeys,
  Pointer<Int32> viewTags,
  int outCount,
  int accCount,
);
