import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/crypto/crypto/crc32/crc32.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/read_account_private_key.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/read_account_public_keys_response.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/creation_params.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/utxos.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:zcash_dart/zcash.dart';

enum ZcashAccountInfoType {
  orchard(AppSerializationIdentifier.zcashAccountInfoOrchard, "unified"),
  sapling(AppSerializationIdentifier.zcashAccountInfoSapling, "sapling"),
  p2pkh(AppSerializationIdentifier.zcashAccountInfoP2pkh, "transparent_p2pkh"),
  p2sh(AppSerializationIdentifier.zcashAccountInfoP2sh, "transparent_p2sh"),
  p2shMsig(AppSerializationIdentifier.zcashAccountInfoP2shMsig, "transparent_p2ms");

  ZcashProtocol get protocol => switch (this) {
        ZcashAccountInfoType.orchard => ZcashProtocol.orchard,
        ZcashAccountInfoType.sapling => ZcashProtocol.sapling,
        _ => ZcashProtocol.transparent
      };
  const ZcashAccountInfoType(this.tag, this.tr);
  final AppSerializationIdentifier tag;
  final String tr;
  bool get isShielded => this == orchard || this == sapling;
  bool get isOrchard => this == orchard;
  bool get isSapling => this == sapling;
  bool get isStandardTransparent => this == p2pkh || this == p2sh;
  bool get isTransparent => !isShielded;
  static ZcashAccountInfoType fromTag(List<int>? tags) {
    return values.firstWhere(
      (e) => e.tag.isValidTags(tags),
      orElse: () {
        throw AppInternalError.internalError("ZcashAccountInfoType");
      },
    );
  }

  static ZcashAccountInfoType fromIdentifier(int? id) {
    return values.firstWhere(
      (e) => e.tag.isValidIdentifier(id),
      orElse: () {
        throw AppInternalError.internalError("ZcashAccountInfoType");
      },
    );
  }
}

sealed class ZcashAccountInfo<DERIVATION extends DerivationIndex,
    R extends ZUnifiedReceiver> with Equality, AppSerialization {
  final DERIVATION index;
  final ZcashAccountInfoType type;
  ZcashProtocol get protocol => type.protocol;
  const ZcashAccountInfo({
    required this.index,
    required this.type,
  });
  factory ZcashAccountInfo.deserialize({CborObject? object, List<int>? bytes}) {
    final CborTagValue tagValue = AppSerialization.decode(
      cborBytes: bytes,
      cborObject: object,
    );
    final type = ZcashAccountInfoType.fromTag(tagValue.tags);
    final ZcashAccountInfo info = switch (type) {
      ZcashAccountInfoType.orchard =>
        ZcsahAccountInfoOrchard.deserialize(object: tagValue),
      ZcashAccountInfoType.sapling =>
        ZcsahAccountInfoSapling.deserialize(object: tagValue),
      ZcashAccountInfoType.p2pkh => ZcsahAccountInfoP2pkh.deserialize(object: tagValue),
      ZcashAccountInfoType.p2sh =>
        ZcsahAccountInfoP2shStandard.deserialize(object: tagValue),
      ZcashAccountInfoType.p2shMsig =>
        ZcsahAccountInfoP2shMultisig.deserialize(object: tagValue),
    };
    return info.cast();
  }

  T cast<T extends ZcashAccountInfo>() {
    final value = this;
    if (value is T) return value as T;
    throw AppInternalError.internalError("ProviderAuthenticated");
  }

  @override
  List<dynamic> get variables => [type, index];

  List<DerivableIndex> accountDerivationIndexes({AccountDerivationIndexRequest? request});

  ReadAccountPublicKeyRequestZcashReceivers createViewKeyRequest(
      {AccountDerivationIndexRequest? request =
          const AccountDerivationIndexRequestAddress()});

  ReadAccountPrivateKeyRequestZcashReceivers createSecretKeyRequest(
      {AccountDerivationIndexRequest? request =
          const AccountDerivationIndexRequestAddress()});

  ZcashAccountCreationParams<DERIVATION> toCreationParam();

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;
}

sealed class ZcashAccountInfoShield<R extends ZUnifiedReceiver>
    extends ZcashAccountInfo<Bip32DerivationIndex, R> {
  final Bip44Changes scope;
  final DiversifierIndex diversifierIndex;
  final int activationHeight;
  ZcashAccountInfoShield({
    required super.index,
    required super.type,
    required this.diversifierIndex,
    required this.scope,
    required this.activationHeight,
  });
  factory ZcashAccountInfoShield.deserialize({CborObject? object, List<int>? bytes}) {
    final CborTagValue tagValue = AppSerialization.decode(
      cborBytes: bytes,
      cborObject: object,
    );
    final type = ZcashAccountInfoType.fromTag(tagValue.tags);
    final ZcashAccountInfoShield info = switch (type) {
      ZcashAccountInfoType.orchard =>
        ZcsahAccountInfoOrchard.deserialize(object: tagValue),
      ZcashAccountInfoType.sapling =>
        ZcsahAccountInfoSapling.deserialize(object: tagValue),
      _ => throw AppInternalError.internalError("ZcashAccountInfoType")
    };
    return info.cast();
  }

  @override
  ReadAccountPublicKeyRequestZcashReceivers createViewKeyRequest(
      {AccountDerivationIndexRequest? request =
          const AccountDerivationIndexRequestAddress()}) {
    return ReadAccountPublicKeyRequestZcashReceivers.sheilded(
        indexes: accountDerivationIndexes(request: request),
        type: type,
        change: scope,
        index: diversifierIndex);
  }

  @override
  ReadAccountPrivateKeyRequestZcashReceivers createSecretKeyRequest(
      {AccountDerivationIndexRequest? request =
          const AccountDerivationIndexRequestAddress()}) {
    return ReadAccountPrivateKeyRequestZcashReceivers.sheilded(
        indexes: accountDerivationIndexes(request: request),
        type: type,
        change: scope,
        index: diversifierIndex);
  }

  @override
  List<dynamic> get variables => [type, index, scope, diversifierIndex];

  @override
  String toString() {
    return "ZcashAccountInfoShield {scope:${scope.name}, diversifierIndex:${diversifierIndex.toU128()}, protocol:${protocol.name} }";
  }
}

class ZcsahAccountInfoSapling extends ZcashAccountInfoShield<ReceiverSapling> {
  ZcsahAccountInfoSapling({
    required super.index,
    required super.diversifierIndex,
    required super.scope,
    required super.activationHeight,
  }) : super(
          type: ZcashAccountInfoType.sapling,
        );
  factory ZcsahAccountInfoSapling.deserialize({CborObject? object, List<int>? bytes}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: ZcashAccountInfoType.sapling.tag,
    );
    return ZcsahAccountInfoSapling(
        index: Bip32DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        diversifierIndex: DiversifierIndex(values.rawValueAt(1)),
        scope: Bip44Changes.fromValue(values.rawValueAt(2)),
        activationHeight: values.rawValueAt(3));
  }

  @override
  List<DerivableIndex> accountDerivationIndexes(
      {AccountDerivationIndexRequest? request}) {
    return [index];
  }

  @override
  List<CborObject?> get serializationItems => [
        index.toCbor(),
        CborBytesValue(diversifierIndex.toBytes()),
        scope.value.toCbor(),
        activationHeight.toCbor()
      ];

  @override
  ZcashAccountCreationParams<Bip32DerivationIndex> toCreationParam() {
    return ZcashAccountCreationParamsSapling(
        index: index,
        diversifierIndex: diversifierIndex,
        change: scope,
        exactDiversifier: true,
        activationHeight: activationHeight);
  }
}

class ZcsahAccountInfoOrchard extends ZcashAccountInfoShield<ReceiverOrchard> {
  ZcsahAccountInfoOrchard({
    required super.index,
    required super.diversifierIndex,
    required super.scope,
    required super.activationHeight,
  }) : super(
          type: ZcashAccountInfoType.orchard,
        );
  factory ZcsahAccountInfoOrchard.deserialize({CborObject? object, List<int>? bytes}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: ZcashAccountInfoType.orchard.tag,
    );
    return ZcsahAccountInfoOrchard(
        index: Bip32DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        diversifierIndex: DiversifierIndex(values.rawValueAt(1)),
        scope: Bip44Changes.fromValue(values.rawValueAt(2)),
        activationHeight: values.rawValueAt(3));
  }

  @override
  List<DerivableIndex> accountDerivationIndexes(
      {AccountDerivationIndexRequest? request}) {
    return [index];
  }

  @override
  List<CborObject?> get serializationItems => [
        index.toCbor(),
        CborBytesValue(diversifierIndex.toBytes()),
        scope.value.toCbor(),
        activationHeight.toCbor()
      ];

  @override
  ZcashAccountCreationParams<Bip32DerivationIndex> toCreationParam() {
    return ZcashAccountCreationParamsUnified(
        index: index,
        diversifierIndex: diversifierIndex,
        change: scope,
        activationHeight: activationHeight);
  }
}

sealed class ZcashAccountInfoTransparent<DERIVATION extends DerivationIndex,
    R extends ZUnifiedReceiver> extends ZcashAccountInfo<DERIVATION, R> {
  BitcoinAddressType get transparentType;
  Script? get redeemScript;

  TransparentUtxoOwner toUtxoOwner(ZcashNetwork network, {List<int>? publicKey});
  const ZcashAccountInfoTransparent({
    required super.index,
    required super.type,
  });
  @override
  ReadAccountPublicKeyRequestZcashReceivers createViewKeyRequest(
      {AccountDerivationIndexRequest? request =
          const AccountDerivationIndexRequestAddress()}) {
    return ReadAccountPublicKeyRequestZcashReceivers.transparent(
        indexes: accountDerivationIndexes(request: request), type: type);
  }

  @override
  ReadAccountPrivateKeyRequestZcashReceivers createSecretKeyRequest(
      {AccountDerivationIndexRequest? request =
          const AccountDerivationIndexRequestAddress()}) {
    return ReadAccountPrivateKeyRequestZcashReceivers.transparent(
        indexes: accountDerivationIndexes(request: request), type: type);
  }

  @override
  List<dynamic> get variables => [type, index, redeemScript];
}

class ZcsahAccountInfoP2pkh
    extends ZcashAccountInfoTransparent<Bip32DerivationIndex, ReceiverP2pkh> {
  const ZcsahAccountInfoP2pkh({
    required super.index,
  }) : super(type: ZcashAccountInfoType.p2pkh);
  factory ZcsahAccountInfoP2pkh.deserialize({CborObject? object, List<int>? bytes}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: ZcashAccountInfoType.p2pkh.tag,
    );
    return ZcsahAccountInfoP2pkh(
      index: Bip32DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
    );
  }

  @override
  List<DerivableIndex> accountDerivationIndexes(
      {AccountDerivationIndexRequest? request}) {
    return [index];
  }

  @override
  List<CborObject?> get serializationItems => [index.toCbor()];

  @override
  BitcoinAddressType get transparentType => P2pkhAddressType.p2pkh;

  @override
  ZcashAccountCreationParams<Bip32DerivationIndex> toCreationParam() {
    return ZcashAccountCreationParamsP2pkh(index: index, followingSaplingRole: false);
  }

  @override
  Script? get redeemScript => null;

  @override
  TransparentUtxoOwner toUtxoOwner(ZcashNetwork network, {List<int>? publicKey}) {
    if (publicKey == null) {
      throw AppInternalError.internalError("Missing public key.");
    }
    final publickKey = ZECPublic.fromBytes(publicKey);
    return TransparentUtxoOwner(
        publicKey: publickKey, address: publickKey.toAddress(network: network));
  }
}

class ZcsahAccountInfoP2shStandard
    extends ZcashAccountInfoTransparent<Bip32DerivationIndex, ReceiverP2sh> {
  @override
  final P2shAddressType transparentType;
  @override
  final Script redeemScript;
  const ZcsahAccountInfoP2shStandard({
    required super.index,
    required this.transparentType,
    required this.redeemScript,
  }) : super(type: ZcashAccountInfoType.p2sh);
  factory ZcsahAccountInfoP2shStandard.deserialize(
      {CborObject? object, List<int>? bytes}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: ZcashAccountInfoType.p2sh.tag,
    );
    return ZcsahAccountInfoP2shStandard(
        index: Bip32DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        transparentType: BitcoinAddressType.fromTag(values.rawValueAt<int?>(1))
            .cast<P2shAddressType>(),
        redeemScript: Script.deserialize(bytes: values.rawValueAt(2)));
  }

  @override
  List<DerivableIndex> accountDerivationIndexes(
      {AccountDerivationIndexRequest? request}) {
    return [index];
  }

  @override
  List<CborObject?> get serializationItems =>
      [index.toCbor(), transparentType.id.toCbor(), redeemScript.toBytes().toCborBytes()];

  @override
  ZcashAccountCreationParams<Bip32DerivationIndex> toCreationParam() {
    return ZcashAccountCreationParamsP2shStandard(
        p2shType: transparentType, index: index, followingSaplingRole: false);
  }

  @override
  TransparentUtxoOwner toUtxoOwner(ZcashNetwork network, {List<int>? publicKey}) {
    return TransparentUtxoOwner.nonStandardP2sh(
        redeemScript: redeemScript,
        address: ZcashP2shAddress.fromScript(
            script: redeemScript, network: network, type: transparentType));
  }
}

class ZcsahAccountInfoP2shMultisig
    extends ZcashAccountInfoTransparent<MultiSigAddressIndex, ReceiverP2sh> {
  final TransparentMultiSignatureAddressDetails multisig;
  const ZcsahAccountInfoP2shMultisig({
    required this.multisig,
  }) : super(type: ZcashAccountInfoType.p2shMsig, index: const MultiSigAddressIndex());

  factory ZcsahAccountInfoP2shMultisig.deserialize(
      {CborObject? object, List<int>? bytes}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: ZcashAccountInfoType.p2shMsig.tag,
    );
    return ZcsahAccountInfoP2shMultisig(
      multisig: TransparentMultiSignatureAddressDetails.deserialize(
          object: values.objectAt<CborTagValue>(0)),
    );
  }

  @override
  List<DerivableIndex> accountDerivationIndexes(
      {AccountDerivationIndexRequest? request}) {
    switch (request) {
      case null:
      case AccountDerivationIndexRequestSigners():
        return multisig.signers.map((e) => e.derivationIndex).toList();
      case AccountDerivationIndexRequestAddress():
      case ZcashAccountDerivationIndexRequestAddressProtocol():
        return [];
    }
  }

  @override
  List<CborObject?> get serializationItems => [multisig.toCbor()];

  @override
  P2shAddressType get transparentType => P2shAddressType.p2pkhInP2sh;

  @override
  ZcashAccountCreationParams<MultiSigAddressIndex> toCreationParam() {
    return ZcashAccountCreationParamsP2shMultisig(multisig: multisig);
  }

  @override
  TransparentUtxoOwner toUtxoOwner(ZcashNetwork network, {List<int>? publicKey}) {
    return TransparentUtxoOwner.nonStandardP2sh(
        redeemScript: redeemScript,
        address: ZcashP2shAddress.fromScript(
            script: redeemScript, network: network, type: transparentType));
  }

  @override
  Script get redeemScript => multisig.multiSigScript;
}

class ZcashDerivedAccountInfo with Equality, AppSerialization {
  final List<ZcashAccountInfo> receivers;
  final ZcashAddress address;
  ZcashDerivedAccountInfo({required this.receivers, required this.address});
  factory ZcashDerivedAccountInfo.deserialize({CborObject? object, List<int>? bytes}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.zcashDerivedAccountInfo);
    return ZcashDerivedAccountInfo(
        receivers: values
            .listAt<CborTagValue>(0)
            .map((e) => ZcashAccountInfo.deserialize(object: e))
            .toList(),
        address: ZcashAddress.deserializeIAddress(bytes: values.rawValueAt(1)));
  }

  late final ZcashAccountInfoType addressType = (() {
    {
      if (receivers.length == 1) {
        return receivers.first.type;
      }
      return ZcashAccountInfoType.orchard;
    }
  }());

  List<DerivableIndex> accountDerivationIndexes(
      {AccountDerivationIndexRequest? request =
          const AccountDerivationIndexRequestAddress()}) {
    switch (request) {
      case AccountDerivationIndexRequestSigners():
      case AccountDerivationIndexRequestAddress():
      case null:
        return receivers
            .expand((e) => e.accountDerivationIndexes(request: request))
            .toList();
      case ZcashAccountDerivationIndexRequestAddressProtocol(:final protocol):
        return receivers
            .where((e) => e.type.protocol == protocol)
            .expand((e) => e.accountDerivationIndexes(request: request))
            .toList();
    }
  }

  ReadAccountPublicKeyRequest createViewKeyRequest(
      {AccountDerivationIndexRequest? request =
          const AccountDerivationIndexRequestAddress()}) {
    return ReadAccountPublicKeyRequestZcash(
        receivers:
            receivers.map((e) => e.createViewKeyRequest(request: request)).toList(),
        network: address.network);
  }

  ReadAccountPrivateKeyRequest createSecretKeyRequest(
      {AccountDerivationIndexRequest? request =
          const AccountDerivationIndexRequestAddress()}) {
    return ReadAccountPrivateKeyRequestZcash(
        receivers:
            receivers.map((e) => e.createSecretKeyRequest(request: request)).toList(),
        network: address.network);
  }

  List<ZcashProtocol> get protocols => receivers.map((e) => e.protocol).toList();

  ZcashAccountInfo? getProtocolReceiver(ZcashProtocol protocol) {
    return receivers.firstWhereNullable((e) => e.type.protocol == protocol);
  }

  ZcashAccountInfoTransparent? getTransparentReceiver() =>
      getProtocolReceiver(ZcashProtocol.transparent)?.cast();
  TransparentUtxoOwner? toTransparentWatchOnlyUtxoOwner() {
    final addr = toTransparentAddress();
    if (addr == null) return null;
    return TransparentUtxoOwner.watchOnly(addr);
  }

  ZcashTransparentAddress? toTransparentAddress() {
    if (!address.supportedProtocols.contains(ZcashProtocol.transparent)) {
      return null;
    }
    final addr = address.tryToTransparentAddreses();
    if (addr == null) {
      throw WalletExceptionConst.invalidAccountData("tryToTransparentAddreses failed.");
    }
    return addr;
  }

  List<ZcashAccountInfoShield> shieldAccounts() =>
      receivers.where((e) => e.type.isShielded).toList().cast();

  bool hasPotocol(ZcashProtocol protocol) =>
      address.supportedProtocols.contains(protocol);

  bool hasSheildAccount() => address.supportedProtocols.any((e) => e.sheilded);

  List<ZcashAccountCreationParams> toCreationParams() {
    return receivers.map((e) => e.toCreationParam()).toList();
  }

  ZcashAddress? toProtocolAddress(ZcashProtocol protocol) {
    if (!hasPotocol(protocol)) return null;
    final addr = address.toProtocolAddress(protocol);
    if (addr == null) {
      throw WalletExceptionConst.invalidAccountData("toProtocolAddress.");
    }
    return addr;
  }

  List<ZcashAddress> protocolAddresses() {
    return ZcashProtocol.values
        .map((e) => toProtocolAddress(e))
        .whereType<ZcashAddress>()
        .toList();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.zcashDerivedAccountInfo;

  @override
  List<CborObject?> get serializationItems => [
        CborListValue.definite(receivers.map((e) => e.toCbor()).toList()),
        CborBytesValue(address.encodeAsIAddress())
      ];

  @override
  List<dynamic> get variables => [receivers, address];
}

class AccountWithIvkAndNullifiers {
  final IncomingViewingKey ivk;
  final ZcashAccountInfoShield account;
  final DiversifiableFullViewingKey derivationKey;
  const AccountWithIvkAndNullifiers(
      {required this.ivk, required this.account, required this.derivationKey});
  @override
  String toString() {
    return "AccountWithIvkAndNullifiers {ivk: ${ivk.runtimeType}/${ivk.protocol}/${Crc32().quickIntDigest(ivk.toBytes())} index: ${account.diversifierIndex.toU128()} changes: ${account.scope.name}}";
  }
}

class TransparentMultiSignatureSignerDefaultWithDerivationIndex {
  final DerivableIndex index;
  final TransparentMultiSignatureSignerDefault signer;
  const TransparentMultiSignatureSignerDefaultWithDerivationIndex(
      {required this.index, required this.signer});
  TransparentMultiSigSignerDetails toSignerDetails() =>
      TransparentMultiSigSignerDetails(derivationIndex: index, weight: signer.weight);
}

class TransparentMultiSigSignerDetails extends TransparentMultiSignatureSigner
    with Equality, AppSerialization {
  final int weight;
  TransparentMultiSigSignerDetails._(
      {required this.weight, required this.derivationIndex});

  factory TransparentMultiSigSignerDetails(
      {required DerivableIndex derivationIndex, int weight = 1}) {
    if (derivationIndex.currencyCoin.conf.type != EllipticCurveTypes.secp256k1) {
      throw WalletExceptionConst.invalidAccountData("TransparentMultiSigSignerDetails");
    }
    if (weight < 1 || weight > 16) {
      throw WalletExceptionConst.invalidAccountData("TransparentMultiSigSignerDetails");
    }
    return TransparentMultiSigSignerDetails._(
        weight: weight, derivationIndex: derivationIndex);
  }
  factory TransparentMultiSigSignerDetails.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.zcashMultiSigSignerAddress);

    final int weight = cbor.rawValueAt(0);
    final derivationIndex =
        DerivableIndex.deserialize(object: cbor.objectAt<CborTagValue>(1));
    return TransparentMultiSigSignerDetails._(
        weight: weight, derivationIndex: derivationIndex);
  }
  final DerivableIndex derivationIndex;
  String get path => derivationIndex.toString();

  @override
  List get variables => [weight, derivationIndex];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.zcashMultiSigSignerAddress;

  @override
  List<CborObject?> get serializationItems => [weight.toCbor(), derivationIndex.toCbor()];
}

class TransparentMultiSignatureAddressDetails
    with AppSerialization, Equality
    implements TransparentMultiSignatureAddress {
  @override
  final List<TransparentMultiSigSignerDetails> signers;

  @override
  final int threshold;

  @override
  final Script multiSigScript;
  TransparentMultiSignatureAddressDetails._(
      {required this.signers, required this.threshold, required this.multiSigScript});

  factory TransparentMultiSignatureAddressDetails(
      {required int threshold,
      required List<TransparentMultiSignatureSignerDefaultWithDerivationIndex> signers}) {
    try {
      final n = TransparentMultiSignatureAddress(
          threshold: threshold, signers: signers.map((e) => e.signer).toList());
      return TransparentMultiSignatureAddressDetails._(
          signers: signers.map((e) => e.toSignerDetails()).toList(),
          threshold: threshold,
          multiSigScript: n.multiSigScript);
    } catch (_) {
      throw WalletExceptionConst.invalidAccountData(
          "TransparentMultiSignatureAddressDetails");
    }
  }

  factory TransparentMultiSignatureAddressDetails.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.zcashMultiSignaturAddress);
    final List<TransparentMultiSigSignerDetails> signers = cbor
        .listAt<CborTagValue>(0)
        .map<TransparentMultiSigSignerDetails>(
            (e) => TransparentMultiSigSignerDetails.deserialize(object: e))
        .toList();
    final int threshHold = cbor.rawValueAt(1);
    final script = Script.deserialize(bytes: cbor.rawValueAt(2));
    return TransparentMultiSignatureAddressDetails._(
        multiSigScript: script, signers: signers, threshold: threshHold);
  }

  @override
  ZcashP2shAddress toTransparentAddress(
      {P2shAddressType addressType = P2shAddressType.p2pkhInP2sh,
      ZcashNetwork network = ZcashNetwork.mainnet}) {
    return ZcashP2shAddress.fromScript(
      script: multiSigScript,
      type: addressType,
      network: network,
    );
  }

  @override
  List<dynamic> get variables => [signers, threshold];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.zcashMultiSignaturAddress;

  @override
  List<CborObject?> get serializationItems => [
        CborListValue.definite(signers.map((e) => e.toCbor()).toList()),
        threshold.toCbor(),
        CborBytesValue(multiSigScript.toBytes()),
      ];
}

class ZcashProtocolAddressWithUtxos {
  final ZcashAddress address;
  final ZcashProtocol protocol;
  final List<ZcashUtxo> spendableUtxos;
  final List<ZcashUtxo> pendingUtxos;
  final IntegerBalance totalActiveBalance;
  final IntegerBalance totalPendingBalance;
  const ZcashProtocolAddressWithUtxos(
      {required this.address,
      required this.protocol,
      required this.spendableUtxos,
      required this.pendingUtxos,
      required this.totalActiveBalance,
      required this.totalPendingBalance});
}
