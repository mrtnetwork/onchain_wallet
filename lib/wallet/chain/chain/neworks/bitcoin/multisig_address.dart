part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

mixin BitcoinMultiSigBase {
  abstract final BitcoinMultiSignatureAddress multiSignatureAddress;
}

class BitcoinMultiSigSignerDetails
    with Equality, AppSerialization
    implements MultiSignatureSigner {
  BitcoinMultiSigSignerDetails.unsafe(
      {required this.publicKey, required this.weight, required this.derivationIndex});

  factory BitcoinMultiSigSignerDetails(
      {required List<int> publicKey,
      required DerivableIndex derivationIndex,
      int weight = 1}) {
    if (derivationIndex.derivationType == AddressDerivationType.multisig ||
        derivationIndex.currencyCoin.conf.type != EllipticCurveTypes.secp256k1) {
      throw WalletExceptionConst.invalidAccountData("BitcoinMultiSigSignerDetails");
    }
    if (!IPublicKey.isValidBytes(publicKey, EllipticCurveTypes.secp256k1)) {
      throw WalletExceptionConst.invalidAccountData("BitcoinMultiSigSignerDetails");
    }
    if (weight < 1 || weight > 16) {
      throw WalletExceptionConst.invalidAccountData("BitcoinMultiSigSignerDetails");
    }
    return BitcoinMultiSigSignerDetails.unsafe(
        publicKey: BytesUtils.toHexString(publicKey),
        weight: weight,
        derivationIndex: derivationIndex);
  }
  factory BitcoinMultiSigSignerDetails.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.bitcoinMultiSigSignerAddress);

    final List<int> publicKey = cbor.rawValueAt(0);
    final int weight = cbor.rawValueAt(1);
    final derivationIndex =
        DerivableIndex.deserialize(object: cbor.objectAt<CborTagValue>(2));
    return BitcoinMultiSigSignerDetails(
        publicKey: publicKey, weight: weight, derivationIndex: derivationIndex);
  }
  @override
  final String publicKey;
  // int _wieght;
  @override
  final int weight;

  final DerivableIndex derivationIndex;
  String get path => derivationIndex.toString();

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.bitcoinMultiSigSignerAddress;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(BytesUtils.fromHexString(publicKey)),
        weight.toCbor(),
        derivationIndex.toCbor()
      ];
  @override
  List get variables => [publicKey, weight, derivationIndex];

  @override
  PubKeyModes get keyType => BtcUtils.determinatePubKeyModeHex(publicKey);
}

class BitcoinMultiSignatureAddress
    with AppSerialization
    implements MultiSignatureAddress {
  @override
  final List<BitcoinMultiSigSignerDetails> signers;

  /// Threshold is the minimum number of signatures required to spend the bitcoins associated
  /// with this address.
  @override
  final int threshold;

  /// ScriptDetails provides details about the multi-signature script used in transactions,
  /// including "OP_M", compressed public keys, "OP_N", and "OP_CHECKMULTISIG."
  @override
  final Script multiSigScript;

  BitcoinMultiSignatureAddress._(
      {required this.signers, required this.threshold, required this.multiSigScript});

  /// CreateMultiSignatureAddress creates a new instance of a MultiSignatureAddress, representing
  /// a multi-signature Bitcoin address configuration. It allows you to specify the minimum number
  /// of required signatures (threshold), provide the collection of signers participating in the
  /// multi-signature scheme, and specify the address type.
  factory BitcoinMultiSignatureAddress(
      {required int threshold, required List<BitcoinMultiSigSignerDetails> signers}) {
    final sumWeight = signers.fold(0, (sum, signer) => sum + signer.weight);
    if (threshold > 16 || threshold < 1) {
      throw WalletExceptionConst.invalidAccountData("BitcoinMultiSignatureAddress");
    }
    if (sumWeight > 16) {
      throw WalletExceptionConst.invalidAccountData("BitcoinMultiSignatureAddress");
    }
    if (sumWeight < threshold) {
      throw WalletExceptionConst.invalidAccountData("BitcoinMultiSignatureAddress");
    }
    final multiSigScript = <Object>['OP_$threshold'];
    for (final signer in signers) {
      for (var w = 0; w < signer.weight; w++) {
        multiSigScript.add(signer.publicKey);
      }
    }
    multiSigScript.addAll(['OP_$sumWeight', 'OP_CHECKMULTISIG']);
    final script = Script(script: multiSigScript);

    return BitcoinMultiSignatureAddress._(
        signers: signers, threshold: threshold, multiSigScript: script);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.bitcoinMultiSignaturAddress;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(signers.map((e) => e.toCbor()).toList()),
        threshold.toCbor(),
        CborListValue<CborStringValue>.definite(
            multiSigScript.script.cast<String>().map((e) => CborStringValue(e)).toList())
      ];
  factory BitcoinMultiSignatureAddress.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.bitcoinMultiSignaturAddress);

    final List<BitcoinMultiSigSignerDetails> signers = cbor
        .listAt<CborTagValue>(0)
        .map<BitcoinMultiSigSignerDetails>(
            (e) => BitcoinMultiSigSignerDetails.deserialize(object: e))
        .toList();
    final int threshHold = cbor.rawValueAt(1);
    final List<String> scriptsOpcode =
        cbor.listAt<CborStringValue>(2).map((e) => e.value).toList();
    final List<String> scriptDetails = scriptsOpcode.map<String>((e) => e).toList();

    return BitcoinMultiSignatureAddress._(
        multiSigScript: Script(script: scriptDetails),
        signers: signers,
        threshold: threshHold);
  }

  @override
  BitcoinBaseAddress toP2wshAddress({required BasedUtxoNetwork network}) {
    if (network is! LitecoinNetwork && network is! BitcoinNetwork) {
      throw WalletExceptionConst.unsuportedFeature;
    }
    if (!canSelectSegwit) {
      throw WalletExceptionConst.unsuportedFeature;
    }
    return P2wshAddress.fromScript(script: multiSigScript);
  }

  @override
  BitcoinBaseAddress toP2wshInP2shAddress({required BasedUtxoNetwork network}) {
    final p2wsh = toP2wshAddress(network: network);
    return P2shAddress.fromScript(
        script: p2wsh.toScriptPubKey(), type: P2shAddressType.p2wshInP2sh);
  }

  List get variables => [threshold, multiSigScript.toHex()];

  @override
  BitcoinBaseAddress toP2shAddress(
      {P2shAddressType addressType = P2shAddressType.p2pkhInP2sh}) {
    if (!MultiSignatureAddress.legacySupportP2shTypes.contains(addressType)) {
      throw WalletExceptionConst.invalidAccountData(
          "BitcoinMultiSignatureAddress.toP2shAddress");
    }

    if (addressType.hashLength == 32) {
      return P2shAddress.fromHash160(
          addrHash: BytesUtils.toHexString(
              QuickCrypto.sha256DoubleHash(multiSigScript.toBytes())),
          type: addressType);
    }
    return P2shAddress.fromScript(script: multiSigScript, type: addressType);
  }

  @override
  BitcoinBaseAddress fromType(
      {required BasedUtxoNetwork network, required BitcoinAddressType addressType}) {
    switch (addressType) {
      case SegwitAddressType.p2wsh:
        return toP2wshAddress(network: network);
      case P2shAddressType.p2wshInP2sh:
        return toP2wshInP2shAddress(network: network);
      case P2shAddressType.p2pkhInP2sh:
      case P2shAddressType.p2pkhInP2sh32:
      case P2shAddressType.p2pkhInP2shwt:
      case P2shAddressType.p2pkhInP2sh32wt:
        return toP2shAddress(addressType: addressType.cast());
      default:
        throw ArgumentError(
            "invalid multisig address type. use of of them [BitcoinAddressType.p2wsh, BitcoinAddressType.p2wshInP2sh, BitcoinAddressType.p2pkhInP2sh]");
    }
  }

  @override
  bool get canSelectSegwit => signers.every((e) => e.keyType.isCompressed);
}
