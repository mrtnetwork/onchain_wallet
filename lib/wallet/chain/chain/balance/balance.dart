part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

abstract class BalanceCore<T, TOKEN extends APPToken> {
  abstract final String price;
  abstract final String viewPrice;
  abstract final TOKEN token;
  bool updateBalance();
  bool _internalUpdateBalance(T? updateBalance);
  bool get isZero;
  bool get isNegative;
  bool get largerThanZero;
  abstract final T balance;
}
