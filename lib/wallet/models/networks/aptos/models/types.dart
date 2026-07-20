import 'package:blockchain_utils/bip/bip/conf/bip44/bip44_coins.dart';
import 'package:blockchain_utils/bip/ecc/bip_ecc.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/wallet/models/transaction/types/types.dart';

enum AptosSupportKeyScheme {
  ed25519(value: 0, name: "ED25519"),
  signleKeyEd25519(value: 1, name: "ED25519 SingleKey"),
  signleKeySecp256k1(value: 2, name: "Secp256k1 SingleKey"),
  multiEd25519(value: 3, name: "Multi ED25519"),
  multiKey(value: 4, name: "MultiKey");

  final int value;
  final String name;
  bool get isMultisig => this == multiEd25519 || this == multiKey;

  const AptosSupportKeyScheme({required this.value, required this.name});
  static AptosSupportKeyScheme fromValue(int? value) {
    return values.firstWhere((e) => e.value == value,
        orElse: () => throw AppInternalError.internalError("AptosSupportKeyScheme"));
  }

  AptosSigningScheme get toSigningScheme {
    return switch (this) {
      AptosSupportKeyScheme.ed25519 => AptosSigningScheme.ed25519,
      AptosSupportKeyScheme.signleKeyEd25519 ||
      AptosSupportKeyScheme.signleKeySecp256k1 =>
        AptosSigningScheme.signleKey,
      AptosSupportKeyScheme.multiEd25519 => AptosSigningScheme.multiEd25519,
      AptosSupportKeyScheme.multiKey => AptosSigningScheme.multikey,
    };
  }

  EllipticCurveTypes get curve {
    return switch (this) {
      AptosSupportKeyScheme.signleKeySecp256k1 => EllipticCurveTypes.secp256k1,
      _ => EllipticCurveTypes.ed25519
    };
  }

  static AptosSupportKeyScheme fromCoin(Bip44Coins coin) {
    return switch (coin) {
      Bip44Coins.aptos => AptosSupportKeyScheme.ed25519,
      Bip44Coins.aptosEd25519SingleKey => AptosSupportKeyScheme.signleKeyEd25519,
      Bip44Coins.aptosSecp256k1SingleKey => AptosSupportKeyScheme.signleKeySecp256k1,
      _ => throw AppCryptoExceptionConst.invalidCoin
    };
  }
}

class AptosAccountTokenInfo with AppSerialization {
  final BigInt balance;
  final bool frozen;
  final String assetType;
  const AptosAccountTokenInfo(
      {required this.balance, required this.frozen, required this.assetType});
  factory AptosAccountTokenInfo.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return AptosAccountTokenInfo(
        balance: values.rawValueAt(0),
        frozen: values.rawValueAt(1),
        assetType: values.rawValueAt(2));
  }
  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [balance.toCbor(), frozen.toCbor(), assetType.toCbor()];
}

class AptosTransferDetails extends TransferOutputDetails<AptosAddress> {
  AptosTransferDetails({
    required super.recipient,
    required Token token,
  }) : super(amount: IntegerBalance.zero(token, allowNegative: false));

  AptosTransactionEntryFunction createFTAssetTransfer(String assetType) {
    return AptosTransactionEntryFunction(
        moduleId: AptosConstants.primaryFungibleStoreModule,
        functionName: AptosConstants.transferFunctionName,
        typeArgs: [
          AptosConstants.fungibleAssetMetadataTypeTag
        ],
        args: [
          AptosAddress(assetType),
          recipient.networkAddress,
          MoveU64(amount.balance)
        ]);
  }

  AptosTransferParams createNativeTransfer() {
    return AptosTransferParams.apt(
        apt: amount.balance, destination: recipient.networkAddress);
  }

  @override
  List get variables => [recipient];
}
