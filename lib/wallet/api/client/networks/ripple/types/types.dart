import 'package:xrpl_dart/xrpl_dart.dart';

class XRPLMetaTokenInfo {
  final String? desc;
  final String? icon;
  final String? name;
  final int? trustLevel;
  final List<XRPLMetaIssuerMetaUrl>? urls;

  const XRPLMetaTokenInfo(
      {required this.desc,
      required this.icon,
      required this.name,
      required this.trustLevel,
      required this.urls});

  factory XRPLMetaTokenInfo.fromJson(Map<String, dynamic> json) =>
      XRPLMetaTokenInfo(
        desc: json['desc'],
        icon: json['icon'],
        name: json['name'],
        trustLevel: json['trust_level'],
        urls: (json['urls'] as List?)
            ?.map((e) => XRPLMetaIssuerMetaUrl.fromJson(e))
            .toList(),
      );
}

class XRPLMetaIssuerInfo {
  final String? domain;
  final String? icon;
  final bool? kyc;
  final String? name;
  final int? trustLevel;
  final List<XRPLMetaIssuerMetaUrl>? urls;

  const XRPLMetaIssuerInfo({
    required this.domain,
    required this.icon,
    required this.kyc,
    required this.name,
    required this.trustLevel,
    required this.urls,
  });

  factory XRPLMetaIssuerInfo.fromJson(Map<String, dynamic> json) =>
      XRPLMetaIssuerInfo(
        domain: json['domain'],
        icon: json['icon'],
        kyc: json['kyc'],
        name: json['name'],
        trustLevel: json['trust_level'],
        urls: (json['urls'] as List?)
            ?.map((e) => XRPLMetaIssuerMetaUrl.fromJson(e))
            .toList(),
      );
}

class XRPLMetaIssuerMetaUrl {
  final String? url;
  final String? type;

  const XRPLMetaIssuerMetaUrl({
    required this.url,
    required this.type,
  });

  factory XRPLMetaIssuerMetaUrl.fromJson(Map<String, dynamic> json) =>
      XRPLMetaIssuerMetaUrl(url: json['url'], type: json['type']);
}

class XRPLMetaIssuerMeta {
  final XRPLMetaTokenInfo token;
  final XRPLMetaIssuerInfo issuer;

  const XRPLMetaIssuerMeta({
    required this.token,
    required this.issuer,
  });

  factory XRPLMetaIssuerMeta.fromJson(Map<String, dynamic> json) =>
      XRPLMetaIssuerMeta(
        token: XRPLMetaTokenInfo.fromJson(json['token']),
        issuer: XRPLMetaIssuerInfo.fromJson(json['issuer']),
      );
}

class XRPLMetaIssuerMetrics {
  final int trustlines;
  final int holders;
  final String supply;
  final String marketcap;
  final String price;
  final String volume24h;
  final String volume7d;
  final String exchanges24h;
  final String exchanges7d;
  final String takers24h;
  final String takers7d;

  const XRPLMetaIssuerMetrics({
    required this.trustlines,
    required this.holders,
    required this.supply,
    required this.marketcap,
    required this.price,
    required this.volume24h,
    required this.volume7d,
    required this.exchanges24h,
    required this.exchanges7d,
    required this.takers24h,
    required this.takers7d,
  });

  factory XRPLMetaIssuerMetrics.fromJson(Map<String, dynamic> json) =>
      XRPLMetaIssuerMetrics(
        trustlines: json['trustlines'],
        holders: json['holders'],
        supply: json['supply'],
        marketcap: json['marketcap'],
        price: json['price'],
        volume24h: json['volume_24h'],
        volume7d: json['volume_7d'],
        exchanges24h: json['exchanges_24h'],
        exchanges7d: json['exchanges_7d'],
        takers24h: json['takers_24h'],
        takers7d: json['takers_7d'],
      );
}

class XRPLMetaAsset {
  final String currency;
  final String issuer;
  final XRPLMetaIssuerMeta meta;
  final XRPLMetaIssuerMetrics metrics;

  const XRPLMetaAsset({
    required this.currency,
    required this.issuer,
    required this.meta,
    required this.metrics,
  });

  factory XRPLMetaAsset.fromJson(Map<String, dynamic> json) => XRPLMetaAsset(
        currency: json['currency'],
        issuer: json['issuer'],
        meta: XRPLMetaIssuerMeta.fromJson(json['meta']),
        metrics: XRPLMetaIssuerMetrics.fromJson(json['metrics']),
      );
}

class XRPLAccountTx {
  final BaseTransactionWithInfoResult transaction;
  final DateTime? ledgerTime;
  final String txId;
  const XRPLAccountTx(
      {required this.transaction,
      required this.ledgerTime,
      required this.txId});
}

class XRPLAccountTxs {
  final XRPBaseAddress address;
  final List<XRPLAccountTx> txes;
  final int latestLedger;
  XRPLAccountTxs(
      {required this.txes, required this.latestLedger, required this.address});
}
