part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

class TronMultiSigSignerDetais with Equality, AppSerialization {
  TronMultiSigSignerDetais._(
      {required this.publicKey, required this.weight, required this.derivationIndex});

  factory TronMultiSigSignerDetais(
      {required List<int> publicKey,
      required Bip32DerivationIndex derivationIndex,
      required BigInt weight}) {
    return TronMultiSigSignerDetais._(
        publicKey: BytesUtils.toHexString(publicKey),
        weight: weight,
        derivationIndex: derivationIndex);
  }
  factory TronMultiSigSignerDetais.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.tronMultiSigSignerAddress);

    final List<int> publicKey = cbor.rawValueAt(0);
    final BigInt weight = cbor.rawValueAt(1);
    final derivationIndex =
        Bip32DerivationIndex.deserialize(object: cbor.objectAt<CborTagValue>(2));
    return TronMultiSigSignerDetais(
        publicKey: publicKey, weight: weight, derivationIndex: derivationIndex);
  }

  final String publicKey;
  final BigInt weight;

  final Bip32DerivationIndex derivationIndex;
  String get path => derivationIndex.toString();

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.tronMultiSigSignerAddress;
  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(BytesUtils.fromHexString(publicKey)),
        weight.toCbor(),
        derivationIndex.toCbor()
      ];
  @override
  List get variables => [publicKey, weight, derivationIndex];
}

class TronMultiSignatureAddress with Equality, AppSerialization {
  final List<TronMultiSigSignerDetais> signers;
  final BigInt threshold;
  final int? permissionID;

  TronMultiSignatureAddress._(
      {required this.signers, required this.threshold, required this.permissionID});

  factory TronMultiSignatureAddress(
      {required BigInt threshold,
      required List<TronMultiSigSignerDetais> signers,
      required int? permissionID}) {
    final sumWeight = signers.fold(BigInt.zero, (sum, signer) => sum + signer.weight);

    if (sumWeight < threshold) {
      throw WalletExceptionConst.invalidAccountData(
          "TronMultiSignatureAddress.toAccount");
    }
    final sortedSigners = signers.clone()
      ..sort((a, b) => a.publicKey.compareTo(b.publicKey));
    return TronMultiSignatureAddress._(
        signers: sortedSigners, threshold: threshold, permissionID: permissionID);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.tronMultiSignaturAddress;
  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(signers.map((e) => e.toCbor()).toList()),
        threshold.toCbor(),
        permissionID?.toCbor(),
      ];
  factory TronMultiSignatureAddress.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.tronMultiSignaturAddress);
    final List<TronMultiSigSignerDetais> signers = cbor
        .listAt<CborTagValue>(0)
        .map<TronMultiSigSignerDetais>(
            (e) => TronMultiSigSignerDetais.deserialize(object: e))
        .toList();
    final BigInt threshHold = cbor.rawValueAt(1);
    final int? permissionID = cbor.rawValueAt(2);
    return TronMultiSignatureAddress._(
        signers: signers, threshold: threshHold, permissionID: permissionID);
  }

  @override
  List get variables => [threshold, signers, permissionID];
}
