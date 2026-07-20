import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:cosmos_sdk/proto_messages/cosmos/base/v1beta1/src/coin.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/constant/networks/cosmos.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/networks/cosmos/extension/extension.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/cw20.dart';
import 'network_types.dart';

class CosmosFeeToken with AppSerialization {
  final Token token;
  final String denom;
  final String? low;
  final String average;
  final String? hight;
  IntegerBalance getFee() {
    return getAverageGasPrice();
  }

  IntegerBalance? getLowGasPrice() {
    final low = this.low;
    if (low == null) return null;
    final decimals = token.decimal;
    final networkDecimals = BigRational(BigInt.from(10).pow(decimals));
    return IntegerBalance.token(
        (BigRational.parseDecimal(low) * networkDecimals).toBigInt(), token);
  }

  IntegerBalance getAverageGasPrice() {
    final decimals = token.decimal;
    final networkDecimals = BigRational(BigInt.from(10).pow(decimals));
    return IntegerBalance.token(
        (BigRational.parseDecimal(average) * networkDecimals).toBigInt(), token);
  }

  IntegerBalance? getHightGasPrice() {
    final hight = this.hight;
    if (hight == null) return null;
    final decimals = token.decimal;
    final networkDecimals = BigRational(BigInt.from(10).pow(decimals));
    return IntegerBalance.token(
        (BigRational.parseDecimal(hight) * networkDecimals).toBigInt(), token);
  }

  const CosmosFeeToken.unsafe(
      {required this.token,
      required this.denom,
      this.low,
      required this.average,
      this.hight});
  factory CosmosFeeToken(
      {required Token token,
      required String denom,
      BigRational? lowGasPrice,
      required BigRational averageGasPrice,
      BigRational? highGasPrice}) {
    final e = token.decimal;
    if (e > CosmosConst.maxTokenExponent) {
      throw WalletExceptionConst.invalidTokenInformation;
    }
    return CosmosFeeToken.unsafe(
      token: token,
      denom: denom,
      low: lowGasPrice?.toDecimal(),
      average: averageGasPrice.toDecimal(),
      hight: highGasPrice?.toDecimal(),
    );
  }
  factory CosmosFeeToken.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.cosmosNativeToken);
    final token = Token.deserialize(object: values.objectAt<CborTagValue>(0));
    return CosmosFeeToken.unsafe(
      token: token,
      denom: values.rawValueAt(1),
      low: values.rawValueAt(2),
      average: values.rawValueAt(3),
      hight: values.rawValueAt(4),
    );
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.cosmosNativeToken;

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        CborStringValue(denom),
        low?.toCbor(),
        average.toCbor(),
        hight?.toCbor()
      ];
}

class CosmosNetworkInfo {
  final String? transactionExplorer;
  final String? addressExplorer;
  final String? networkName;
  final List<DefaultAPIProvider> providers;
  final CosmosFeeToken? nativeToken;
  final int slip44;
  final String? hrp;
  final CosmosNetworkTypes networkType;
  final String? chainId;
  final List<CosmosKeysAlgs> keysAlgs;
  final List<CosmosFeeToken> feeTokens;

  CosmosNetworkInfo({
    this.transactionExplorer,
    this.addressExplorer,
    required this.nativeToken,
    required this.providers,
    this.hrp,
    required this.feeTokens,
    required this.networkType,
    required this.chainId,
    required this.keysAlgs,
    required this.slip44,
    required this.networkName,
  });
}

class CosmosChainAsset {
  final Coin coin;
  final CW20Token? cw20token;
  final Token token;
  final IntegerBalance balance;
  const CosmosChainAsset._(
      {required this.coin,
      required this.token,
      required this.cw20token,
      required this.balance});
  factory CosmosChainAsset.unknown({required Coin coin, BigInt? balance}) {
    final token = Token(
        name: StrUtils.toCamelCase(coin.getDenom()),
        symbol: StrUtils.toCamelCase(coin.getDenom()),
        decimal: 0);
    return CosmosChainAsset._(
        coin: coin,
        token: token,
        cw20token: null,
        balance: IntegerBalance.token(balance ?? BigInt.zero, token));
  }
  factory CosmosChainAsset.ccrAsset(
      {required Coin coin, required CCRAsset asset, BigInt? balance}) {
    final decimal = asset.denomUnits.firstWhereOrNull((e) => e.denom == asset.display);
    if (decimal == null) {
      return CosmosChainAsset.unknown(coin: coin, balance: balance);
    }
    final denom = StrUtils.toCamelCase(coin.getDenom());
    final token = Token(name: denom, symbol: denom, decimal: decimal.exponent);
    return CosmosChainAsset._(
        coin: coin,
        token: token,
        cw20token: CW20Token.create(
            balance: balance ?? BigInt.zero, token: token, denom: coin.getDenom()),
        balance: IntegerBalance.token(balance ?? BigInt.zero, token));
  }
  factory CosmosChainAsset.cw20Token(CW20Token token) {
    return CosmosChainAsset._(
        coin: Coin(denom: token.denom, amount: "${token.balance.balance}"),
        token: token.token,
        cw20token: token,
        balance: token.balance);
  }
}

class CosmosIbcChainData {
  final CCRChainData? ccrChainData;
  final List<CCRIbcTransition> ibcConnections;
  final CosmosChain chain;
  CosmosIbcChainData(
      {required this.ccrChainData,
      required this.chain,
      required List<CCRIbcTransition> ibcConnections})
      : token = chain.network.coinParam.nativeToken,
        ibcConnections = ibcConnections.immutable;
  final CW20Token token;
}
