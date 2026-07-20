part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

class RippleMultiSigSignerDetails with Equality, AppSerialization {
  const RippleMultiSigSignerDetails._(
      {required this.publicKey, required this.weight, required this.derivationIndex});

  factory RippleMultiSigSignerDetails(
      {required List<int> publicKey,
      required Bip32DerivationIndex derivationIndex,
      required int weight}) {
    return RippleMultiSigSignerDetails._(
        publicKey: BytesUtils.toHexString(publicKey),
        weight: weight,
        derivationIndex: derivationIndex);
  }
  factory RippleMultiSigSignerDetails.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.rippleMultiSigSignerAddress);

    final List<int> publicKey = cbor.rawValueAt(0);
    final int weight = cbor.rawValueAt(1);
    final derivationIndex =
        Bip32DerivationIndex.deserialize(object: cbor.objectAt<CborTagValue>(2));
    return RippleMultiSigSignerDetails(
        publicKey: publicKey, weight: weight, derivationIndex: derivationIndex);
  }

  final String publicKey;
  final int weight;

  final Bip32DerivationIndex derivationIndex;
  String get path => derivationIndex.toString();

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.rippleMultiSigSignerAddress;
  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(BytesUtils.fromHexString(publicKey)),
        weight.toCbor(),
        derivationIndex.toCbor()
      ];
  @override
  List get variables => [publicKey, weight, derivationIndex];
}

class RippleMultiSignatureAddress with Equality, AppSerialization {
  final List<RippleMultiSigSignerDetails> signers;

  final int threshold;
  final bool isRegular;

  RippleMultiSignatureAddress._(
      {required this.signers, required this.threshold, required this.isRegular});

  factory RippleMultiSignatureAddress(
      {required int threshold,
      required List<RippleMultiSigSignerDetails> signers,
      required bool isRegularKey}) {
    final sumWeight = signers.fold(0, (sum, signer) => sum + signer.weight);

    if (sumWeight < threshold) {
      throw WalletExceptionConst.invalidAccountData("RippleMultiSignatureAddress");
    }
    if (isRegularKey && (threshold != 1 || signers.length != 1)) {
      throw WalletExceptionConst.invalidAccountData("RippleMultiSignatureAddress");
    }

    /// make sure signers is sorted because of account identifier
    final sortedSigners = signers.clone()
      ..sort((a, b) => a.publicKey.compareTo(b.publicKey));
    return RippleMultiSignatureAddress._(
        signers: sortedSigners, threshold: threshold, isRegular: isRegularKey);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.rippleMultiSignaturAddress;
  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(signers.map((e) => e.toCbor()).toList()),
        threshold.toCbor(),
        CborBoleanValue(isRegular)
      ];
  factory RippleMultiSignatureAddress.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.rippleMultiSignaturAddress);
    final List<RippleMultiSigSignerDetails> signers = cbor
        .listAt<CborTagValue>(0)
        .map<RippleMultiSigSignerDetails>(
            (e) => RippleMultiSigSignerDetails.deserialize(object: e))
        .toList();
    final int threshHold = cbor.rawValueAt(1);
    final bool isRegularKey = cbor.rawValueAt(2);
    return RippleMultiSignatureAddress._(
        signers: signers, threshold: threshHold, isRegular: isRegularKey);
  }

  @override
  List get variables => [threshold, signers];
}
