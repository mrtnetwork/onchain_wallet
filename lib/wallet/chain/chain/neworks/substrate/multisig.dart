part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

class SubstrateMultisigAccountInfo with AppSerialization {
  final List<BaseSubstrateAddress> signers;
  final int threshold;
  final BaseSubstrateAddress address;
  SubstrateMultisigAccountInfo._(
      {required List<BaseSubstrateAddress> signers,
      required this.threshold,
      required this.address})
      : signers = signers.immutable;
  factory SubstrateMultisigAccountInfo.create(
      {required List<BaseSubstrateAddress> signers,
      required int threshold,
      required int maxSigntories}) {
    if (threshold <= 0 || signers.length < threshold || signers.length > maxSigntories) {
      throw WalletExceptionConst.invalidAccountData(
          "SubstrateMultisigAccountInfo.create");
    }
    final address = BaseSubstrateAddress.createMultiSigAddress(
        addresses: signers, threshold: threshold, maxSignatories: maxSigntories);
    return SubstrateMultisigAccountInfo._(
        signers: signers, threshold: threshold, address: address);
  }
  factory SubstrateMultisigAccountInfo.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.suiMultisigAccountInfo);
    return SubstrateMultisigAccountInfo._(
        signers: values
            .listAt<CborBytesValue>(0)
            .map((e) => BaseSubstrateAddress.fromBytes(e.value))
            .toList(),
        threshold: values.rawValueAt(1),
        address: BaseSubstrateAddress.fromBytes(values.rawValueAt(2)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.suiMultisigAccountInfo;
  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(
            signers.map((e) => CborBytesValue(e.toBytes())).toList()),
        CborIntValue(threshold),
        CborBytesValue(address.toBytes())
      ];
  List<BaseSubstrateAddress> addresses({int ss58Format = SS58Const.genericSubstrate}) {
    return signers.map((e) {
      if (e.type.isSubstrate) {
        return e.cast<SubstrateAddress>().toSS58(ss58Format);
      }
      return e;
    }).toList();
  }

  BaseSubstrateAddress toAddress({int ss58Format = SS58Const.genericSubstrate}) {
    final address = this.address;
    if (address.type.isSubstrate) {
      return address.cast<SubstrateAddress>().toSS58(ss58Format);
    }
    return address;
  }
}
