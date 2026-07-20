import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/cbor/serialization/cbor/tag.dart'
    show SerializationIdentifier;
import 'package:blockchain_utils/cbor/types/cbor_tag.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain/solidity/address/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/aptos.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/cw20.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/erc20.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/issue.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/jetton.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/spl_token.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/stellar_issue.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/substrate.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/sui.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/trc10.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/trc20.dart';

enum TokenCoreType {
  aptos(AppSerializationIdentifier.fats),
  cw20(AppSerializationIdentifier.cw20),
  erc20(AppSerializationIdentifier.erc20Token),
  ripple(AppSerializationIdentifier.rippleIssueToken),
  jetton(AppSerializationIdentifier.jettonToken),
  spl(AppSerializationIdentifier.spltoken),
  stellar(AppSerializationIdentifier.stellarIssueToken),
  sui(AppSerializationIdentifier.suiToken),
  trc10(AppSerializationIdentifier.trc10Token),
  trc20(AppSerializationIdentifier.trc20Token),
  substrate(AppSerializationIdentifier.substrateToken);

  final AppSerializationIdentifier tag;
  const TokenCoreType(this.tag);
  static TokenCoreType fromTag(List<int>? tags) {
    return values.firstWhere((e) => e.tag.isValidTags(tags),
        orElse: () => throw AppInternalError.internalError("TokenCoreType"));
  }
}

abstract class TokenCore<AMOUNT extends Object, TOKEN extends APPToken>
    with AppSerialization, Equality, TokenBalanceUpdater<AMOUNT, TOKEN> {
  static String toIdentifier(String data) {
    final hash = QuickCrypto.sha256Hash(StringUtils.encode(data));
    return StringUtils.decode(hash, encoding: StringEncoding.base64UrlSafe);
  }

  final TOKEN token;
  @override
  abstract final InternalStreamValue<BalanceCore<AMOUNT, TOKEN>> streamBalance;
  final DateTime _updated;
  DateTime get updated => _updated;
  TokenCore._({required this.token, required DateTime updated}) : _updated = updated;
  BalanceCore<AMOUNT, TOKEN> get balance => streamBalance.value;
  String? get issuer;
  String? get type;
  TokenCore clone({AMOUNT? balance});
  TokenCore updateToken(Token updateToken);
  TokenCoreType get tokenType;
  String get identifier;

  static T deserialize<T extends TokenCore>({List<int>? bytes, CborObject? object}) {
    final CborTagValue tag =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    final type = TokenCoreType.fromTag(tag.tags);
    final TokenCore tokenCore = switch (type) {
      TokenCoreType.aptos => AptosFATokens.deserialize(bytes: bytes, object: object),
      TokenCoreType.cw20 => CW20Token.deserialize(bytes: bytes, object: object),
      TokenCoreType.erc20 => ETHERC20Token.deserialize(bytes: bytes, object: object),
      TokenCoreType.ripple => RippleIssueToken.deserialize(bytes: bytes, object: object),
      TokenCoreType.jetton => TonJettonToken.deserialize(bytes: bytes, object: object),
      TokenCoreType.spl => SolanaSPLToken.deserialize(bytes: bytes, object: object),
      TokenCoreType.stellar =>
        StellarIssueToken.deserialize(bytes: bytes, object: object),
      TokenCoreType.sui => SuiToken.deserialize(bytes: bytes, object: object),
      TokenCoreType.trc10 => TronTRC10Token.deserialize(bytes: bytes, object: object),
      TokenCoreType.trc20 => TronTRC20Token.deserialize(bytes: bytes, object: object),
      TokenCoreType.substrate => SubstrateToken.deserialize(bytes: bytes, object: object),
    };
    if (tokenCore is! T) {
      throw AppInternalError.internalError("TokenCore");
    }
    return tokenCore;
  }

  @override
  SerializationIdentifier get serializationIdentifier => tokenType.tag;
}

abstract class TokenCoreInteger extends TokenCore<BigInt, Token> {
  @override
  final InternalStreamValue<IntegerBalance> streamBalance;
  @override
  IntegerBalance get balance => streamBalance.value;
  TokenCoreInteger(
      {required super.token, required IntegerBalance balance, required super.updated})
      : streamBalance = InternalStreamValue<IntegerBalance>.immutable(balance,
            name: "TokenCoreInteger.balance", allowDispose: true),
        super._();
}

abstract class TokenCoreDecimal extends TokenCore<BigRational, NonDecimalToken> {
  @override
  final InternalStreamValue<DecimalBalance> streamBalance;
  @override
  DecimalBalance get balance => streamBalance.value;
  TokenCoreDecimal(
      {required super.token, required DecimalBalance balance, required super.updated})
      : streamBalance = InternalStreamValue<DecimalBalance>.immutable(balance,
            name: "TokenCoreDecimal.balance", allowDispose: true),
        super._();
}

abstract class SolidityToken extends TokenCoreInteger {
  SolidityToken({required super.token, required super.balance, required super.updated})
      : super();
  SolidityAddress get contractAddress;
  String toHexAddress();
}

enum TronTokenTypes {
  trc20(AppSerializationIdentifier.trc20Token),
  trc10(AppSerializationIdentifier.trc10Token);

  final AppSerializationIdentifier tag;
  const TronTokenTypes(this.tag);
  static TronTokenTypes fromTag(List<int>? tags) {
    return values.firstWhere((e) => e.tag.isValidTags(tags),
        orElse: () => throw AppInternalError.internalError("TronTokenTypes"));
  }

  static TronTokenTypes fromName(String? name) {
    return values.firstWhere((e) => e.name == name,
        orElse: () => throw AppInternalError.internalError("TronTokenTypes"));
  }

  bool get isTrc10 => this == TronTokenTypes.trc10;
}

abstract class TronToken extends TokenCoreInteger {
  @override
  TronToken clone({BigInt? balance});
  @override
  TronToken updateToken(Token updateToken);
  @override
  String get issuer;
  TronTokenTypes get tronTokenType;
  TronToken({required super.token, required super.balance, required super.updated})
      : super();
  factory TronToken.deserialize({List<int>? bytes, CborObject? object}) {
    final CborTagValue decode = AppSerialization.decode(
      cborBytes: bytes,
      cborObject: object,
    );
    final type = TronTokenTypes.fromTag(decode.tags);
    return switch (type) {
      TronTokenTypes.trc10 => TronTRC10Token.deserialize(object: decode),
      TronTokenTypes.trc20 => TronTRC20Token.deserialize(object: object)
    };
  }
}
