import 'package:blockchain_utils/bip/bip.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/constant/networks/cosmos.dart';
import 'package:on_chain_wallet/wallet/models/network/core/params/params.dart';
import 'package:on_chain_wallet/wallet/models/networks/networks.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/cw20.dart';

class CosmosNetworkParams extends NetworkCoinParams {
  final String hrp;
  final String denom;
  final CosmosNetworkTypes networkType;
  final String chainId;
  final String? networkConstantUri;
  final List<CosmosKeysAlgs> keysAlgs;
  final List<CosmosFeeToken> feeTokens;
  final String? chainRegisteryName;
  final bool ibcEnabled;
  List<Bip44Coins> coins() {
    return keysAlgs.map((e) => e.coin(chainType)).toList();
  }

  CosmosFeeToken getFeeToken({String? denom}) {
    if (denom == null) {
      return feeTokens.firstWhere((e) => e.denom == this.denom,
          orElse: () => feeTokens.first);
    }
    return feeTokens.firstWhere((e) => e.denom == denom);
  }

  CosmosFeeToken? findFeeToken(String denom) {
    return feeTokens.firstWhereOrNull((e) => e.denom == denom);
  }

  CW20Token get nativeToken {
    return CW20Token.create(balance: BigInt.zero, token: token, denom: denom);
  }

  const CosmosNetworkParams.unsafe({
    super.transactionExplorer,
    super.addressExplorer,
    required super.token,
    required super.chainType,
    required this.hrp,
    required this.denom,
    required this.feeTokens,
    required this.networkType,
    required this.chainId,
    required this.keysAlgs,
    required this.chainRegisteryName,
    this.ibcEnabled = true,
    this.networkConstantUri,
    super.bip32CoinType,
  });
  factory CosmosNetworkParams(
      {String? transactionExplorer,
      String? addressExplorer,
      required Token token,
      required ChainType chainType,
      required String hrp,
      required String denom,
      required List<CosmosFeeToken> feeTokens,
      required CosmosNetworkTypes networkType,
      required String chainId,
      required List<CosmosKeysAlgs> keysAlgs,
      required String? chainRegisteryName,
      String? networkConstantUri,
      int? bip32CoinType,
      bool ibcEnabled = true}) {
    if (feeTokens.isEmpty) {
      throw WalletException.message("at_least_one_fee_token_required");
    }
    if (token.decimal > CosmosConst.maxTokenExponent) {
      throw WalletException.message("invalid_token_exponent");
    }
    return CosmosNetworkParams.unsafe(
        token: token,
        chainType: chainType,
        hrp: hrp,
        denom: denom,
        feeTokens: feeTokens,
        networkType: networkType,
        chainId: chainId,
        keysAlgs: keysAlgs,
        bip32CoinType: bip32CoinType,
        addressExplorer: addressExplorer,
        networkConstantUri: networkConstantUri,
        transactionExplorer: transactionExplorer,
        chainRegisteryName: chainRegisteryName,
        ibcEnabled: ibcEnabled);
  }

  factory CosmosNetworkParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: NetworkType.cosmos.identifier);

    return CosmosNetworkParams(
        token: Token.deserialize(object: values.objectAt<CborTagValue>(0)),
        chainType: ChainType.fromValue(values.rawValueAt(1)),
        hrp: values.rawValueAt(2),
        denom: values.rawValueAt(3),
        feeTokens: values
            .listAt<CborTagValue>(4)
            .map((e) => CosmosFeeToken.deserialize(object: e))
            .toList(),
        networkType: CosmosNetworkTypes.fromValue(values.rawValueAt(5)),
        bip32CoinType: values.rawValueAt(6),
        chainId: values.rawValueAt(7),
        networkConstantUri: values.rawValueAt(8),
        keysAlgs: values
            .listAt<CborIntValue>(9)
            .map((e) => CosmosKeysAlgs.fromValue(e.value))
            .toList(),
        transactionExplorer: values.rawValueAt(10),
        addressExplorer: values.rawValueAt(11),
        chainRegisteryName: values.rawValueAt(12),
        ibcEnabled: values.rawValueAt<bool?>(13) ?? true);
  }

  @override
  SerializationIdentifier get serializationIdentifier => NetworkType.cosmos.identifier;

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        chainType.value.toCbor(),
        hrp.toCbor(),
        denom.toCbor(),
        AppSerialization.listFromObjects(feeTokens.map((e) => e.toCbor()).toList()),
        networkType.value.toCbor(),
        bip32CoinType?.toCbor(),
        chainId.toCbor(),
        networkConstantUri?.toCbor(),
        AppSerialization.listFromObjects(
            keysAlgs.map((e) => CborIntValue(e.value)).toList()),
        transactionExplorer?.toCbor(),
        addressExplorer?.toCbor(),
        chainRegisteryName?.toCbor(),
        ibcEnabled.toCbor()
      ];
  CosmosNetworkParams copyWith(
      {String? transactionExplorer,
      String? addressExplorer,
      Token? token,
      ChainType? chainType,
      String? hrp,
      String? denom,
      CosmosNetworkTypes? networkType,
      List<CosmosFeeToken>? feeTokens,
      String? chainId,
      int? bip32CoinType,
      String? networkConstantUri,
      List<CosmosKeysAlgs>? keysAlgs,
      String? chainRegisteryName,
      bool? ibcEnabled}) {
    return CosmosNetworkParams(
        transactionExplorer: transactionExplorer ?? this.transactionExplorer,
        addressExplorer: addressExplorer ?? this.addressExplorer,
        token: token ?? this.token,
        chainType: chainType ?? this.chainType,
        hrp: hrp ?? this.hrp,
        denom: denom ?? this.denom,
        networkType: networkType ?? this.networkType,
        chainId: chainId ?? this.chainId,
        bip32CoinType: bip32CoinType ?? this.bip32CoinType,
        networkConstantUri: networkConstantUri ?? this.networkConstantUri,
        keysAlgs: keysAlgs ?? this.keysAlgs,
        feeTokens: feeTokens ?? this.feeTokens,
        chainRegisteryName: chainRegisteryName ?? this.chainRegisteryName,
        ibcEnabled: ibcEnabled ?? this.ibcEnabled);
  }

  String get identifier => chainId;

  @override
  NetworkCoinParams updateParams(
      {Token? token,
      String? transactionExplorer,
      String? addressExplorer,
      int? bip32CoinType}) {
    return CosmosNetworkParams(
        transactionExplorer: transactionExplorer,
        addressExplorer: addressExplorer,
        token:
            NetworkCoinParams.validateUpdateParams(token: this.token, updateToken: token),
        chainType: chainType,
        hrp: hrp,
        feeTokens: feeTokens,
        denom: denom,
        networkType: networkType,
        chainId: chainId,
        bip32CoinType: bip32CoinType,
        networkConstantUri: networkConstantUri,
        keysAlgs: keysAlgs,
        chainRegisteryName: chainRegisteryName);
  }
}
