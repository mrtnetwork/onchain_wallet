part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

mixin CardanoMultiSigBase {
  abstract final CardanoMultiSignatureAddressDetails multiSignatureAddress;
}

class CardanoMultiSigSignerDetails with Equality, AppSerialization {
  CardanoMultiSigSignerDetails._(
      {required List<int> publicKey, required this.derivationIndex})
      : publicKey = publicKey.asImmutableBytes;

  factory CardanoMultiSigSignerDetails(
      {required List<int> publicKey, required Bip32DerivationIndex derivationIndex}) {
    if (derivationIndex.currencyCoin.conf.type != EllipticCurveTypes.ed25519Kholaw) {
      throw WalletExceptionConst.invalidAccountData("CardanoMultiSigSignerDetails");
    }
    final key = Ed25519KholawPublicKey.fromBytes(publicKey)
        .compressed
        .sublist(Ed25519KeysConst.pubKeyPrefix.length);

    return CardanoMultiSigSignerDetails._(
        publicKey: key, derivationIndex: derivationIndex);
  }
  factory CardanoMultiSigSignerDetails.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.cardanoMultiSigSigner);

    final List<int> publicKey = cbor.rawValueAt(0);
    final derivationIndex =
        Bip32DerivationIndex.deserialize(object: cbor.objectAt<CborTagValue>(1));
    return CardanoMultiSigSignerDetails._(
        publicKey: publicKey, derivationIndex: derivationIndex);
  }
  final List<int> publicKey;

  final Bip32DerivationIndex derivationIndex;
  String get path => derivationIndex.toString();

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.cardanoMultiSigSigner;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(publicKey), derivationIndex.toCbor()];
  late final Ed25519KeyHash keyHash =
      Ed25519KeyHash(QuickCrypto.blake2b224Hash(publicKey));

  @override
  List get variables => [publicKey, derivationIndex];
}

enum CardanoCredentialType {
  publicKey(tags: AppSerializationIdentifier.cardanoAccountPublicKey, name: 'public_key'),
  script(tags: AppSerializationIdentifier.cardanoAccountScript, name: 'script');

  bool get isPublicKey => this == publicKey;
  bool get isScript => this == script;

  final AppSerializationIdentifier tags;
  final String name;
  const CardanoCredentialType({required this.tags, required this.name});
  static CardanoCredentialType fromValue(List<int>? tags) {
    return values.firstWhere((e) => e.tags.isValidTags(tags),
        orElse: () => throw AppInternalError.internalError("CardanoCredentialType"));
  }
}

abstract class BaseCardanoMultiSignatureCredential with AppSerialization {
  final CardanoCredentialType type;
  NativeScript get script;
  List<Bip32DerivationIndex> get keyIndexes;
  int get threshold;
  abstract final PolicyID policyId;
  const BaseCardanoMultiSignatureCredential({required this.type});
  Credential get credential;
  factory BaseCardanoMultiSignatureCredential.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborTagValue tag =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    final type = CardanoCredentialType.fromValue(tag.tags);
    return switch (type) {
      CardanoCredentialType.publicKey =>
        CardanoMultiSignatureKey.deserialize(object: tag),
      CardanoCredentialType.script =>
        CardanoMultiSignatureScript.deserialize(object: tag),
    };
  }
  T cast<T extends BaseCardanoMultiSignatureCredential>() {
    if (this is! T) {
      throw AppInternalError.internalError("BaseCardanoMultiSignatureCredential");
    }
    return this as T;
  }
}

class CardanoMultiSignatureScript extends BaseCardanoMultiSignatureCredential {
  final List<CardanoMultiSigSignerDetails> signers;
  @override
  final int threshold;
  final List<int> scriptHash;
  @override
  late final CredentialScript credential = CredentialScript(scriptHash);
  @override
  late final NativeScriptScriptNOfK script = NativeScriptScriptNOfK(
      n: threshold,
      nativeScripts: signers.map((e) => NativeScriptScriptPubkey(e.keyHash)).toList());

  CardanoMultiSignatureScript._(
      {required this.signers, required this.threshold, required List<int> scriptHash})
      : scriptHash = scriptHash.asImmutableBytes,
        super(type: CardanoCredentialType.script);

  factory CardanoMultiSignatureScript(
      {required int threshold, required List<CardanoMultiSigSignerDetails> signers}) {
    final sumWeight = signers.length;
    if (threshold > CardanoUtils.maxMultisigThresholdInt || threshold < 1) {
      throw WalletExceptionConst.invalidAccountData("CardanoMultiSignatureScript");
    }
    if (sumWeight < threshold) {
      throw WalletExceptionConst.invalidAccountData("CardanoMultiSignatureScript");
    }

    final nOfK = NativeScriptScriptNOfK(
        n: threshold,
        nativeScripts: signers.map((e) => NativeScriptScriptPubkey(e.keyHash)).toList());
    return CardanoMultiSignatureScript._(
        signers: signers, threshold: threshold, scriptHash: nOfK.toHash().data);
  }

  factory CardanoMultiSignatureScript.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CardanoCredentialType.script.tags);

    final List<CardanoMultiSigSignerDetails> signers = values
        .listAt<CborTagValue>(0)
        .map<CardanoMultiSigSignerDetails>(
            (e) => CardanoMultiSigSignerDetails.deserialize(object: e))
        .toList();
    final int threshHold = values.rawValueAt(1);

    return CardanoMultiSignatureScript._(
        signers: signers, threshold: threshHold, scriptHash: values.rawValueAt(2));
  }

  List get variables => [threshold, scriptHash, type];

  @override
  List<Bip32DerivationIndex> get keyIndexes =>
      signers.map((e) => e.derivationIndex).toList();

  @override
  late final PolicyID policyId = PolicyID(scriptHash);

  @override
  SerializationIdentifier get serializationIdentifier =>
      CardanoCredentialType.script.tags;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(signers.map((e) => e.toCbor()).toList()),
        threshold.toCbor(),
        CborBytesValue(scriptHash)
      ];
}

class CardanoMultiSignatureKey extends BaseCardanoMultiSignatureCredential {
  final CardanoMultiSigSignerDetails signer;
  @override
  final int threshold = 1;
  @override
  late final CredentialKey credential = CredentialKey(signer.keyHash.data);

  CardanoMultiSignatureKey._({required this.signer})
      : super(type: CardanoCredentialType.publicKey);

  factory CardanoMultiSignatureKey({required CardanoMultiSigSignerDetails signer}) {
    return CardanoMultiSignatureKey._(signer: signer);
  }

  factory CardanoMultiSignatureKey.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CardanoCredentialType.publicKey.tags);
    return CardanoMultiSignatureKey._(
        signer: CardanoMultiSigSignerDetails.deserialize(
            object: values.objectAt<CborTagValue>(0)));
  }

  List get variables => [signer, type];

  @override
  List<Bip32DerivationIndex> get keyIndexes => [signer.derivationIndex];

  @override
  NativeScript get script => NativeScriptScriptPubkey(signer.keyHash);

  @override
  late final PolicyID policyId = () {
    final keyScript = NativeScriptScriptPubkey(signer.keyHash);
    return PolicyID(keyScript.toHash().data);
  }();

  @override
  SerializationIdentifier get serializationIdentifier => type.tags;
  @override
  List<CborObject?> get serializationItems => [signer.toCbor()];
}

class CardanoMultiSignatureAddressDetails extends BaseCardanoAddressDetails {
  final BaseCardanoMultiSignatureCredential credential;
  final BaseCardanoMultiSignatureCredential? stakeCredential;
  List<NativeScript> get scripts =>
      [credential.script, if (stakeCredential != null) stakeCredential!.script];
  List<Bip32DerivationIndex> get keyIndexes =>
      [...credential.keyIndexes, ...stakeCredential?.keyIndexes ?? []];

  CardanoMultiSignatureAddressDetails._({
    required super.addressType,
    required this.credential,
    required this.stakeCredential,
  });

  factory CardanoMultiSignatureAddressDetails(
      {required ADAAddressType addressType,
      required BaseCardanoMultiSignatureCredential credential,
      required BaseCardanoMultiSignatureCredential? stakeCredential}) {
    if (credential == stakeCredential) {
      throw WalletExceptionConst.invalidAccountData(
          "CardanoMultiSignatureAddressDetails");
    }
    switch (addressType) {
      case ADAAddressType.byron:
      case ADAAddressType.pointer:
        throw WalletExceptionConst.invalidAccountData(
            "CardanoMultiSignatureAddressDetails");
      case ADAAddressType.base:
        if (stakeCredential == null) {
          throw WalletExceptionConst.invalidAccountData(
              "CardanoMultiSignatureAddressDetails");
        }
        break;
      case ADAAddressType.enterprise:
      case ADAAddressType.reward:
        if (stakeCredential != null) {
          throw WalletExceptionConst.invalidAccountData(
              "CardanoMultiSignatureAddressDetails");
        }
    }

    return CardanoMultiSignatureAddressDetails._(
        addressType: addressType,
        credential: credential,
        stakeCredential: stakeCredential);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.cardanoMultiSignaturAddress;
  @override
  List<CborObject?> get serializationItems =>
      [credential.toCbor(), stakeCredential?.toCbor(), CborIntValue(addressType.header)];

  factory CardanoMultiSignatureAddressDetails.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.cardanoMultiSignaturAddress);

    return CardanoMultiSignatureAddressDetails._(
        credential:
            BaseCardanoMultiSignatureCredential.deserialize(object: values.objectAt(0)),
        stakeCredential:
            values.maybeObjectAt<BaseCardanoMultiSignatureCredential, CborTagValue>(
                1, (e) => BaseCardanoMultiSignatureCredential.deserialize(object: e)),
        addressType: ADAAddressType.fromHeader(values.rawValueAt(2)));
  }

  @override
  ADAAddress toAddress(ADANetwork network) {
    switch (addressType) {
      case ADAAddressType.enterprise:
        return ADAEnterpriseAddress.fromCredential(
            credential: credential.credential, network: network);
      case ADAAddressType.reward:
        return ADARewardAddress.fromCredential(
            credential: credential.credential, network: network);
      case ADAAddressType.base:
        final stake = stakeCredential;
        if (stake == null) {
          throw WalletExceptionConst.invalidAccountData(
              "CardanoMultiSignatureAddressDetails");
        }
        return ADABaseAddress.fromCredential(
            baseCredential: credential.credential,
            stakeCredential: stakeCredential!.credential,
            network: network);
      default:
        throw WalletExceptionConst.invalidAccountData(
            "CardanoMultiSignatureAddressDetails");
    }
  }

  @override
  bool get isLegacy => false;

  @override
  List<int>? get publicKey => switch (credential.type) {
        CardanoCredentialType.publicKey =>
          credential.cast<CardanoMultiSignatureKey>().signer.publicKey,
        _ => null,
      };

  @override
  List<int>? get stakePubkey => switch (stakeCredential?.type) {
        CardanoCredentialType.publicKey =>
          stakeCredential?.cast<CardanoMultiSignatureKey>().signer.publicKey,
        _ => null,
      };
  @override
  List get variables => [credential, stakeCredential, addressType];

  @override
  PolicyID get policyId => credential.policyId;

  @override
  PolicyID? get stakePolicyId => stakeCredential?.policyId;
}
