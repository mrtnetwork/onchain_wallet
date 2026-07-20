part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

enum NewAccountParamsType {
  bitcoinCashNewAddressParams(AppSerializationIdentifier.bitcoinCashNewAddressParams),
  bitcoinCashMultiSigNewAddressParams(
      AppSerializationIdentifier.bitcoinCashMultiSigNewAddressParams),
  bitcoinNewAddressParams(AppSerializationIdentifier.bitcoinNewAddressParams),
  bitcoinMultiSigNewAddressParams(
      AppSerializationIdentifier.bitcoinMultiSigNewAddressParams),
  cardanoNewAddressParams(AppSerializationIdentifier.cardanoNewAddressParams),
  cardanoMultisigNewAddressParams(
      AppSerializationIdentifier.cardanoNewMultisigAddressParams),
  cosmosNewAddressParams(AppSerializationIdentifier.cosmosNewAddressParams),
  ethereumNewAddressParamss(AppSerializationIdentifier.ethereumNewAddressParamss),
  solanaNewAddressParams(AppSerializationIdentifier.solanaNewAddressParams),
  substrateNewAddressParams(AppSerializationIdentifier.substrateNewAddressParams),
  substrateMultisigNewAddressParams(
      AppSerializationIdentifier.substrateMultisigNewAddressParams),
  tronNewAddressParams(AppSerializationIdentifier.tronNewAddressParams),
  tronMultisigNewAddressParams(AppSerializationIdentifier.tronMultisigNewAddressParams),
  tonNewAddressParams(AppSerializationIdentifier.tonNewAddressParams),
  rippleNewAddressParams(AppSerializationIdentifier.rippleNewAddressParams),
  rippleMultiSigNewAddressParams(
      AppSerializationIdentifier.rippleMultiSigNewAddressParams),
  stellarNewAddressParams(AppSerializationIdentifier.stellarNewAddressParams),
  moneroNewAddressParams(AppSerializationIdentifier.moneroNewAddressParams),

  suiNewAddressParams(AppSerializationIdentifier.suiNewAddressParams),
  suiMultisigNewAddressParams(AppSerializationIdentifier.suiMultisigNewAddressParams),
  aptosNewAddressParams(AppSerializationIdentifier.aptosNewAddressParams),
  aptosMultisigNewAddressParams(AppSerializationIdentifier.aptosMultisigNewAddressParams),
  zcashNewAddressParams(AppSerializationIdentifier.zcashAddressParams),
  ;

  final AppSerializationIdentifier tag;
  const NewAccountParamsType(this.tag);
  static NewAccountParamsType fromTag(List<int>? tags) {
    return values.firstWhere((e) => e.tag.isValidTags(tags),
        orElse: () => throw AppInternalError.internalError("NewAccountParamsType"));
  }
}

sealed class NewAccountParams<ACCOUNT extends ChainAccount> with AppSerialization {
  const NewAccountParams();
  abstract final CryptoCoins coin;
  abstract final NewAccountParamsType type;
  CryptoProcessLevel get level => CryptoProcessLevel.normal;

  bool get isDerivable => false;
  ACCOUNT toAccount(WalletNetwork network, CryptoPublicKeyData? publicKey, String? id,
      IAppDatabaseApi? database);

  static String toIdentifier(String address, {List<int> multisigAddress = const []}) {
    final hash =
        QuickCrypto.sha256Hash([...StringUtils.encode(address), ...multisigAddress]);
    return StringUtils.decode(hash, encoding: StringEncoding.base64UrlSafe);
  }

  factory NewAccountParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborTagValue decode = AppSerialization.decode(
      cborBytes: bytes,
      cborObject: object,
    );
    final type = NewAccountParamsType.fromTag(decode.tags);
    final NewAccountParams params;
    switch (type) {
      case NewAccountParamsType.bitcoinCashNewAddressParams:
        params = BitcoinCashNewAddressParams.deserialize(object: decode);
        break;
      case NewAccountParamsType.bitcoinCashMultiSigNewAddressParams:
        params = BitcoinCashMultiSigNewAddressParams.deserialize(object: decode);
        break;
      case NewAccountParamsType.bitcoinNewAddressParams:
        params = BitcoinNewAddressParams.deserialize(object: decode);
        break;
      case NewAccountParamsType.bitcoinMultiSigNewAddressParams:
        params = BitcoinMultiSigNewAddressParams.deserialize(object: decode);
        break;
      case NewAccountParamsType.cardanoNewAddressParams:
        params = CardanoNewAddressParams.deserialize(object: decode);
        break;
      case NewAccountParamsType.cardanoMultisigNewAddressParams:
        params = CardanoMultisigNewAddressParams.deserialize(object: decode);
        break;
      case NewAccountParamsType.cosmosNewAddressParams:
        params = CosmosNewAddressParams.deserialize(object: decode);
        break;
      case NewAccountParamsType.ethereumNewAddressParamss:
        params = EthereumNewAddressParams.deserialize(object: decode);
        break;
      case NewAccountParamsType.solanaNewAddressParams:
        params = SolanaNewAddressParams.deserialize(object: decode);
        break;
      case NewAccountParamsType.substrateNewAddressParams:
        params = SubstrateNewAddressParams.deserialize(object: decode);
        break;
      case NewAccountParamsType.substrateMultisigNewAddressParams:
        params = SubstrateMultiSigNewAddressParams.deserialize(object: decode);
        break;
      case NewAccountParamsType.tronNewAddressParams:
        params = TronNewAddressParams.deserialize(object: decode);
        break;
      case NewAccountParamsType.tronMultisigNewAddressParams:
        params = TronMultisigNewAddressParams.deserialize(object: decode);
        break;
      case NewAccountParamsType.tonNewAddressParams:
        params = TonNewAddressParams.deserialize(object: decode);
        break;
      case NewAccountParamsType.rippleNewAddressParams:
        params = RippleNewAddressParams.deserialize(object: decode);
        break;
      case NewAccountParamsType.rippleMultiSigNewAddressParams:
        params = RippleMultiSigNewAddressParams.deserialize(object: decode);
        break;
      case NewAccountParamsType.stellarNewAddressParams:
        params = StellarNewAddressParams.deserialize(object: decode);
        break;
      case NewAccountParamsType.moneroNewAddressParams:
        params = MoneroNewAddressParams.deserialize(object: decode);
        break;
      case NewAccountParamsType.aptosNewAddressParams:
        params = AptosNewAddressParams.deserialize(object: decode);
        break;
      case NewAccountParamsType.suiNewAddressParams:
        params = SuiNewAddressParams.deserialize(object: decode);
        break;
      case NewAccountParamsType.suiMultisigNewAddressParams:
        params = SuiMultiSigNewAddressParams.deserialize(object: decode);
        break;
      case NewAccountParamsType.aptosMultisigNewAddressParams:
        params = AptosMultiSigNewAddressParams.deserialize(object: decode);
        break;
      case NewAccountParamsType.zcashNewAddressParams:
        params = ZcashNewAddressParams.deserialize(object: decode);
        break;
      // case NewAccountParamsType.zcashMultisignatureNewAddressParams:
      //   params =
      //       ZcashNewAddressParamsTransparentMultisignature.deserialize(object: decode);
      //   break;
    }
    if (params is! NewAccountParams<ACCOUNT>) {
      throw AppInternalError.internalError("NewAccountParams.deserialize");
    }
    return params;
  }
  T cast<T extends NewAccountParams>() {
    final v = this;
    if (v is T) return v as T;
    throw AppInternalError.internalError("NewDerivableAccountParams");
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;
}

sealed class NewDerivableAccountParams<ACCOUNT extends ChainAccount>
    extends NewAccountParams<ACCOUNT> {
  const NewDerivableAccountParams();
  abstract final DerivableIndex deriveIndex;
  @override
  bool get isDerivable => true;
}
