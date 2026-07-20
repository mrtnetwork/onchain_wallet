import 'package:xrpl_dart/xrpl_dart.dart';

class XRPIssueToken {
  final XRPBaseAddress account;
  final XRPBaseAddress issuer;
  final String currency;
  final String balance;
  const XRPIssueToken(
      {required this.issuer,
      required this.currency,
      required this.balance,
      required this.account});
  XRPIssueToken.fromJson(Map<String, dynamic> json)
      : issuer = XRPBaseAddress(json["issuer"]),
        balance = json["value"],
        currency = json["currency"],
        account = XRPBaseAddress(json["issuer"]);
  @override
  String toString() {
    return "{name: $currency, issuer: $issuer, balance: $balance}";
  }
}

class XRPNFToken {
  final String nftokenId;
  final int flags;
  final String issuer;
  final String? uri;
  final int serial;
  final int nftokenTaxon;
  XRPNFToken.fromJson(Map<String, dynamic> json)
      : flags = json["Flags"],
        nftokenId = json["NFTokenID"],
        issuer = json["Issuer"],
        nftokenTaxon = json["NFTokenTaxon"],
        serial = json["nft_serial"],
        uri = json["URI"];
}

class AccountObjectSignerEntry {
  final String account;
  final int signerWeight;

  const AccountObjectSignerEntry(
      {required this.account, required this.signerWeight});

  factory AccountObjectSignerEntry.fromJson(Map<String, dynamic> json) {
    return AccountObjectSignerEntry(
        account: json['Account'], signerWeight: json['SignerWeight']);
  }
}

class XRPAccountObjectEntry {
  final int flags;
  final String ledgerEntryType;
  final String ownerNode;
  final String previousTxnID;
  final int previousTxnLgrSeq;
  final List<AccountObjectSignerEntry> signerEntries;
  final int signerListID;
  final int signerQuorum;
  final String index;

  XRPAccountObjectEntry({
    required this.flags,
    required this.ledgerEntryType,
    required this.ownerNode,
    required this.previousTxnID,
    required this.previousTxnLgrSeq,
    required this.signerEntries,
    required this.signerListID,
    required this.signerQuorum,
    required this.index,
  });

  factory XRPAccountObjectEntry.fromJson(Map<String, dynamic> json) {
    return XRPAccountObjectEntry(
        flags: json['Flags'],
        ledgerEntryType: json['LedgerEntryType'],
        ownerNode: json['OwnerNode'],
        previousTxnID: json['PreviousTxnID'],
        previousTxnLgrSeq: json['PreviousTxnLgrSeq'],
        signerEntries: List<AccountObjectSignerEntry>.from(
            (json['SignerEntries'] as List).map(
                (x) => AccountObjectSignerEntry.fromJson(x['SignerEntry']))),
        signerListID: json['SignerListID'],
        signerQuorum: json['SignerQuorum'],
        index: json['index']);
  }
}
