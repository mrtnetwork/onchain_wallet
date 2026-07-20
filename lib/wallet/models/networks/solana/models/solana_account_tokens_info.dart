import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain/solana/solana.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/spl_token.dart';

class SolanaAccountSPLTokenInfo {
  final SolAddress mintAddress;
  final BigInt amount;
  final Token token;
  final SolAddress pubkey;
  final SolAddress tokenOwner;
  const SolanaAccountSPLTokenInfo(
      {required this.mintAddress,
      required this.amount,
      required this.pubkey,
      required this.tokenOwner,
      required this.token});
  SolanaAccountSPLTokenInfo copyWith({
    SolAddress? mintAddress,
    BigInt? amount,
    Token? token,
    SolAddress? pubkey,
    SolAddress? tokenOwner,
  }) {
    return SolanaAccountSPLTokenInfo(
      mintAddress: mintAddress ?? this.mintAddress,
      amount: amount ?? this.amount,
      token: token ?? this.token,
      pubkey: pubkey ?? this.pubkey,
      tokenOwner: tokenOwner ?? this.tokenOwner,
    );
  }

  SolanaSPLToken get toSplToken {
    return SolanaSPLToken.create(
        balance: amount,
        token: token,
        mint: mintAddress,
        tokenAccount: pubkey,
        tokenOwner: tokenOwner);
  }
}

class SolanaTokenInfo {
  final int? chainId;
  final String address;
  final String name;
  final int? decimal;
  final String symbol;
  final String? logoURI;
  SolanaTokenInfo copyWith({
    int? chainId,
    String? address,
    String? name,
    int? decimal,
    String? symbol,
    String? logoURI,
  }) {
    return SolanaTokenInfo(
      chainId: chainId ?? this.chainId,
      address: address ?? this.address,
      name: name ?? this.name,
      decimal: decimal ?? this.decimal,
      symbol: symbol ?? this.symbol,
      logoURI: logoURI ?? this.logoURI,
    );
  }

  factory SolanaTokenInfo.fromJson(Map<String, dynamic> json) {
    return SolanaTokenInfo(
        chainId: json["chainId"],
        address: json["address"],
        name: json["name"],
        logoURI: json["logoURI"],
        symbol: json["symbol"]);
  }
  factory SolanaTokenInfo.fromOnChainMetadata(Metadata metadata) {
    return SolanaTokenInfo(
        chainId: null,
        address: metadata.mint.address,
        name: metadata.data.name,
        logoURI: metadata.data.uri,
        symbol: metadata.data.symbol);
  }
  const SolanaTokenInfo(
      {this.chainId,
      required this.address,
      required this.name,
      this.decimal,
      required this.symbol,
      this.logoURI});
}
