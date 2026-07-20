import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/jetton.dart';
import 'package:ton_dart/ton_dart.dart';

class TonAccountJettonResponse {
  final TonAddress tokenAddress;
  final TonAddress owner;
  final TonAddress jettonWalletAddress;
  final BigInt balance;
  final Token token;
  final Token? metadata;
  TonAccountJettonResponse._(
      {required this.tokenAddress,
      required this.balance,
      required this.owner,
      required this.jettonWalletAddress,
      this.metadata})
      : token = metadata ??
            Token(name: tokenAddress.address, decimal: 0, symbol: tokenAddress.address);
  factory TonAccountJettonResponse(
      {required TonAddress tokenAddress,
      required BigInt balance,
      required TonAddress owner,
      required TonAddress jettonWalletAddress,
      Token? metadata}) {
    return TonAccountJettonResponse._(
        tokenAddress: tokenAddress,
        balance: balance,
        owner: owner,
        jettonWalletAddress: jettonWalletAddress,
        metadata: metadata);
  }
  TonAccountJettonResponse copyWith(
      {TonAddress? tokenAddress,
      BigInt? balance,
      TonAddress? owner,
      TonAddress? jettonWalletAddress,
      TonJettonToken? jettonToken}) {
    return TonAccountJettonResponse._(
        tokenAddress: tokenAddress ?? this.tokenAddress,
        balance: balance ?? this.balance,
        owner: owner ?? this.owner,
        jettonWalletAddress: jettonWalletAddress ?? this.jettonWalletAddress);
  }

  @override
  bool operator ==(other) {
    if (other is! TonAccountJettonResponse) return false;
    return other.balance == balance && other.tokenAddress == tokenAddress;
  }

  @override
  int get hashCode => Object.hash(tokenAddress, balance);

  // late final Token token = jettonToken?.token ??
  //     Token(
  //         name: tokenAddress.toFriendlyAddress(),
  //         decimal: 0,
  //         symbol: tokenAddress.toFriendlyAddress());

  // late final IntegerBalance viewBalance = IntegerBalance.token(balance, token);
}
