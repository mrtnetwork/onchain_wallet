part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

class DecimalBalance implements BalanceCore<BigRational, NonDecimalToken> {
  @override
  final NonDecimalToken token;
  final bool immutable;
  factory DecimalBalance.zero(NonDecimalToken token,
      {int amoutDecimal = 4, bool immutable = false}) {
    return DecimalBalance.fromRational(token, BigRational.zero,
        amoutDecimal: amoutDecimal, immutable: immutable);
  }
  factory DecimalBalance.fromString(String balance, NonDecimalToken token,
      {int amoutDecimal = 4, bool immutable = false}) {
    final inRetional = BigRational.tryParse(balance);
    if (inRetional == null) {
      throw WalletExceptionConst.invalidBalance;
    }
    return DecimalBalance.fromRational(token, inRetional,
        amoutDecimal: amoutDecimal, immutable: immutable);
  }
  factory DecimalBalance.fromRational(NonDecimalToken token, BigRational rational,
      {int amoutDecimal = 4, bool immutable = false}) {
    final String toString = rational.toDecimal(digits: amoutDecimal);
    return DecimalBalance._(token, rational, rational.toDecimal(digits: amoutDecimal),
        amoutDecimal, StrUtils.to3Digits(toString, separator: ","), immutable);
  }

  DecimalBalance._(this.token, this._balance, this._price, this.showDecimal,
      this._viewPrice, this.immutable);
  BigRational _balance;
  @override
  BigRational get balance => _balance;

  late String _price;
  @override
  String get price => _price;
  late final int showDecimal;

  void _updateBalance(BigRational updateBalance) {
    _balance = updateBalance;
    _price = _balance.toDecimal(digits: showDecimal);
    _viewPrice = StrUtils.to3Digits(_price, separator: ",");
  }

  @override
  bool _internalUpdateBalance(BigRational? updateBalance) {
    if (updateBalance == null) return false;
    if (_balance == updateBalance) return false;
    _updateBalance(updateBalance);
    return true;
  }

  @override
  bool updateBalance([BigRational? updateBalance]) {
    assert(!immutable, "Imutable balance");
    if (updateBalance == null || immutable) return false;
    if (_balance == updateBalance) return false;
    _updateBalance(updateBalance);
    return true;
  }

  @override
  bool get isZero => _balance.isZero;
  @override
  bool get isNegative => _balance.isNegative;

  @override
  String toString() {
    return _price;
  }

  String _viewPrice;

  @override
  String get viewPrice => _viewPrice;
  @override
  bool get largerThanZero => !_balance.isZero && !balance.isNegative;
}
