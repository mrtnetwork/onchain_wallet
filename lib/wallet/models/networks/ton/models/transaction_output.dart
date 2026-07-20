import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/jetton.dart';

class TonOutputJettonWithBalance {
  final TonJettonToken token;
  final IntegerBalance balance;
  final IntegerBalance forwardBalance;
  BigInt _queryId = BigInt.zero;
  BigInt get queryId => _queryId;
  TonOutputJettonWithBalance._(this.token, this.balance, this.forwardBalance);
  factory TonOutputJettonWithBalance(TonJettonToken token, Token native) {
    return TonOutputJettonWithBalance._(
        token, IntegerBalance.zero(token.token), IntegerBalance.zero(native));
  }

  void updateBalance(BigInt val) {
    balance.updateBalance(val);
  }

  void updateForwardAmount(BigInt val) {
    forwardBalance.updateBalance(val);
  }

  void updateQueryId(BigInt val) {
    _queryId = val;
  }
}
