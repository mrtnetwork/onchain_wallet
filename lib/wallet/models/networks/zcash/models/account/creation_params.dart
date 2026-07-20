import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/bip/bip/conf/core/coins.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:zcash_dart/zcash.dart';
import 'account.dart';

sealed class ZcashAccountCreationParams<DERIVATION extends DerivationIndex>
    with Equality, AppSerialization {
  final DERIVATION index;
  final ZcashAccountInfoType type;
  int? get activationHeight => null;
  const ZcashAccountCreationParams({required this.index, required this.type});
  DiversifierIndex? get diversifierIndex => null;
  factory ZcashAccountCreationParams.deserialize({CborObject? object, List<int>? bytes}) {
    final CborTagValue tagValue = AppSerialization.decode(
      cborBytes: bytes,
      cborObject: object,
    );
    final type = ZcashAccountInfoType.fromTag(tagValue.tags);
    final ZcashAccountCreationParams info = switch (type) {
      ZcashAccountInfoType.orchard =>
        ZcashAccountCreationParamsUnified.deserialize(object: tagValue),
      ZcashAccountInfoType.sapling =>
        ZcashAccountCreationParamsSapling.deserialize(object: tagValue),
      ZcashAccountInfoType.p2pkh =>
        ZcashAccountCreationParamsP2pkh.deserialize(object: tagValue),
      ZcashAccountInfoType.p2sh =>
        ZcashAccountCreationParamsP2shStandard.deserialize(object: tagValue),
      ZcashAccountInfoType.p2shMsig =>
        ZcashAccountCreationParamsP2shMultisig.deserialize(object: tagValue),
    };
    return info.cast();
  }
  T cast<T extends ZcashAccountCreationParams>() {
    final value = this;
    if (value is T) return value as T;
    throw AppInternalError.internalError("ZcashAccountCreationParams");
  }

  @override
  List<dynamic> get variables => [index, type];

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;
}

class ZcashAccountCreationParamsSapling
    extends ZcashAccountCreationParams<Bip32DerivationIndex> {
  final Bip44Changes change;
  @override
  final DiversifierIndex diversifierIndex;
  final bool exactDiversifier;
  @override
  final int activationHeight;
  const ZcashAccountCreationParamsSapling._(
      {required super.index,
      required this.diversifierIndex,
      required this.change,
      required this.exactDiversifier,
      required this.activationHeight})
      : super(type: ZcashAccountInfoType.sapling);
  factory ZcashAccountCreationParamsSapling(
      {required Bip32DerivationIndex index,
      required DiversifierIndex diversifierIndex,
      required Bip44Changes change,
      required bool exactDiversifier,
      required int activationHeight}) {
    if (index.currencyCoin.proposal != CoinProposal.zip32) {
      throw WalletExceptionConst.invalidAccountData("Invalid  coin proposal.");
    }
    return ZcashAccountCreationParamsSapling._(
        index: index,
        diversifierIndex: diversifierIndex,
        change: change,
        exactDiversifier: exactDiversifier,
        activationHeight: activationHeight);
  }
  factory ZcashAccountCreationParamsSapling.deserialize(
      {CborObject? object, List<int>? bytes}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: ZcashAccountInfoType.sapling.tag,
    );
    return ZcashAccountCreationParamsSapling(
        index: Bip32DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        diversifierIndex: DiversifierIndex(values.rawValueAt(1)),
        change: Bip44Changes.fromValue(values.rawValueAt(2)),
        exactDiversifier: values.rawValueAt(3),
        activationHeight: values.rawValueAt(4));
  }

  @override
  List<CborObject?> get serializationItems => [
        index.toCbor(),
        CborBytesValue(diversifierIndex.toBytes()),
        change.value.toCbor(),
        exactDiversifier.toCbor(),
        activationHeight.toCbor()
      ];
}

class ZcashAccountCreationParamsUnified
    extends ZcashAccountCreationParams<Bip32DerivationIndex> {
  final Bip44Changes change;
  @override
  final DiversifierIndex? diversifierIndex;
  @override
  final int activationHeight;

  const ZcashAccountCreationParamsUnified._(
      {required super.index,
      required this.diversifierIndex,
      required this.change,
      required this.activationHeight})
      : super(type: ZcashAccountInfoType.orchard);
  factory ZcashAccountCreationParamsUnified({
    required Bip32DerivationIndex index,
    required DiversifierIndex? diversifierIndex,
    required Bip44Changes change,
    required int activationHeight,
  }) {
    if (index.currencyCoin.proposal != CoinProposal.zip32) {
      throw WalletExceptionConst.invalidAccountData("Invalid coin proposal.");
    }
    return ZcashAccountCreationParamsUnified._(
        index: index,
        diversifierIndex: diversifierIndex,
        change: change,
        activationHeight: activationHeight);
  }
  factory ZcashAccountCreationParamsUnified.deserialize(
      {CborObject? object, List<int>? bytes}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: ZcashAccountInfoType.orchard.tag,
    );
    return ZcashAccountCreationParamsUnified(
        index: Bip32DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        diversifierIndex: values.maybeRawValueAt<DiversifierIndex, List<int>>(
            1, (i) => DiversifierIndex(i)),
        change: Bip44Changes.fromValue(values.rawValueAt(2)),
        activationHeight: values.rawValueAt(3));
  }

  @override
  List<CborObject?> get serializationItems => [
        index.toCbor(),
        diversifierIndex?.toBytes().toCborBytes(),
        change.value.toCbor(),
        activationHeight.toCbor()
      ];
}

sealed class ZcashAccountCreationParamsTransparent<DERIVATION extends DerivationIndex>
    extends ZcashAccountCreationParams<DERIVATION> {
  const ZcashAccountCreationParamsTransparent(
      {required super.index, required super.type});
}

class ZcashAccountCreationParamsP2pkh
    extends ZcashAccountCreationParamsTransparent<Bip32DerivationIndex> {
  final bool followingSaplingRole;
  const ZcashAccountCreationParamsP2pkh(
      {required super.index, required this.followingSaplingRole})
      : super(type: ZcashAccountInfoType.p2pkh);
  factory ZcashAccountCreationParamsP2pkh.deserialize(
      {CborObject? object, List<int>? bytes}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: ZcashAccountInfoType.p2pkh.tag,
    );
    return ZcashAccountCreationParamsP2pkh(
        index: Bip32DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        followingSaplingRole: values.rawValueAt(1));
  }

  @override
  List<CborObject?> get serializationItems =>
      [index.toCbor(), followingSaplingRole.toCbor()];
}

class ZcashAccountCreationParamsP2shStandard
    extends ZcashAccountCreationParamsTransparent<Bip32DerivationIndex> {
  final P2shAddressType p2shType;
  final bool followingSaplingRole;
  const ZcashAccountCreationParamsP2shStandard._({
    required super.index,
    required this.p2shType,
    required this.followingSaplingRole,
  }) : super(type: ZcashAccountInfoType.p2sh);
  factory ZcashAccountCreationParamsP2shStandard({
    required P2shAddressType p2shType,
    required Bip32DerivationIndex index,
    required bool followingSaplingRole,
  }) {
    switch (p2shType) {
      case P2shAddressType.p2pkhInP2sh:
      case P2shAddressType.p2pkInP2sh:
        break;
      default:
        throw WalletExceptionConst.invalidAccountData("Unsupported p2sh address type.");
    }
    return ZcashAccountCreationParamsP2shStandard._(
        index: index, p2shType: p2shType, followingSaplingRole: followingSaplingRole);
  }
  factory ZcashAccountCreationParamsP2shStandard.deserialize(
      {CborObject? object, List<int>? bytes}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: ZcashAccountInfoType.p2sh.tag,
    );
    return ZcashAccountCreationParamsP2shStandard(
        index: Bip32DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        p2shType: BitcoinAddressType.fromTag(values.rawValueAt<int?>(1))
            .cast<P2shAddressType>(),
        followingSaplingRole: values.rawValueAt(2));
  }

  @override
  List<CborObject?> get serializationItems =>
      [index.toCbor(), p2shType.id.toCbor(), followingSaplingRole.toCbor()];
}

class ZcashAccountCreationParamsP2shMultisig
    extends ZcashAccountCreationParamsTransparent<MultiSigAddressIndex> {
  final TransparentMultiSignatureAddressDetails multisig;
  const ZcashAccountCreationParamsP2shMultisig({
    required this.multisig,
  }) : super(type: ZcashAccountInfoType.p2shMsig, index: const MultiSigAddressIndex());

  factory ZcashAccountCreationParamsP2shMultisig.deserialize(
      {CborObject? object, List<int>? bytes}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: ZcashAccountInfoType.p2shMsig.tag,
    );
    return ZcashAccountCreationParamsP2shMultisig(
      multisig: TransparentMultiSignatureAddressDetails.deserialize(
          object: values.objectAt<CborTagValue>(0)),
    );
  }

  @override
  List<CborObject?> get serializationItems => [multisig.toCbor()];
}
