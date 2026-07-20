import 'package:on_chain_wallet/wallet/models/networks/networks.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class XRPRPCFetchTokens
    extends XRPLedgerRequest<List<XRPIssueToken>, Map<String, dynamic>> {
  XRPRPCFetchTokens(
      {required this.account,
      this.hotWallet,
      this.strict = false,
      this.allowObligations = true,
      XRPLLedgerIndex? ledgerIndex = XRPLLedgerIndex.validated});
  @override
  String get method => XRPRequestMethod.gatewayBalances;

  final XRPBaseAddress account;
  final bool strict;
  final bool allowObligations;

  /// should be string or list String
  final dynamic hotWallet;

  @override
  Map<String, dynamic> toJson() {
    return {
      "account": account.classicAddress,
      "strict": strict,
      "hotWallet": hotWallet
    };
  }

  @override
  List<XRPIssueToken> onResonse(Map<String, dynamic> result) {
    final List<XRPIssueToken> tokens = [];
    if (result["assets"] != null) {
      final Map<String, dynamic> assets = (result["assets"] as Map).cast();
      final issuers = assets.keys.toList();
      for (final i in issuers) {
        final List<Map<String, dynamic>> currencies =
            (assets[i] as List).cast();
        for (final c in currencies) {
          tokens.add(XRPIssueToken(
              issuer: XRPBaseAddress(i),
              currency: c["currency"],
              balance: c["value"],
              account: account));
        }
      }
    }
    if (allowObligations && result["obligations"] != null) {
      final obligations = (result["obligations"] as Map).cast<String, String>();
      tokens.addAll(obligations.entries.map((e) => XRPIssueToken(
          issuer: account,
          currency: e.key,
          balance: e.value,
          account: account)));
    }
    return tokens;
  }
}
