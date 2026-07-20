import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/token_core.dart';

enum NetworkTokenFetchingStatus {
  success,
  failed,
  pending,
  idle,
  close;

  bool get isSuccess => this == success;
  bool get isFailed => this == failed;
  bool get isPending => this == pending;
  bool get isIdle => this == idle;
  bool get isClose => this == close;
  bool get allowRetry => this == failed || this == idle;
}

abstract class BaseNetworkToken with DisposableMixin, StreamStateController {
  TokenCore get token;
  NetworkTokenFetchingStatus _status = NetworkTokenFetchingStatus.idle;
  NetworkTokenFetchingStatus get status => _status;
  BaseNetworkToken({NetworkTokenFetchingStatus status = NetworkTokenFetchingStatus.idle})
      : _status = status;
  void updaetTokenMetadata(Token token);
  void setPending() {
    if (_status.isClose) return;
    _status = NetworkTokenFetchingStatus.pending;
    notify();
  }

  void setError() {
    if (_status.isClose) return;
    _status = NetworkTokenFetchingStatus.failed;
    notify();
  }

  @override
  void dispose() {
    _status = NetworkTokenFetchingStatus.close;
    super.dispose();
    token.streamBalance.dispose();
  }

  @override
  void notify() {
    if (closed) return;
    super.notify();
  }
}

class SuiNetworkToken extends BaseNetworkToken {
  SuiToken _token;
  @override
  SuiToken get token => _token;
  SuiNetworkToken({required SuiToken token}) : _token = token;
  void setSuccess(SuiToken tokenWithMetadata) {
    if (_status.isClose) return;
    _status = NetworkTokenFetchingStatus.success;
    final token = _token;
    _token = tokenWithMetadata;
    notify();
    token.streamBalance.dispose();
  }

  @override
  void updaetTokenMetadata(Token token) {
    setSuccess(_token.updateToken(token));
  }
}

class AptosNetworkToken extends BaseNetworkToken {
  AptosFATokens _token;
  @override
  AptosFATokens get token => _token;
  AptosNetworkToken(
      {required AptosFATokens token, super.status = NetworkTokenFetchingStatus.idle})
      : _token = token;
  void setSuccess(AptosFATokens tokenWithMetadata) {
    if (_status.isClose) return;
    _status = NetworkTokenFetchingStatus.success;
    final token = _token;
    _token = tokenWithMetadata;
    notify();
    token.streamBalance.dispose();
  }

  @override
  void updaetTokenMetadata(Token token) {
    setSuccess(_token.updateToken(token));
  }
}

class StellarNetworkToken extends BaseNetworkToken {
  StellarIssueToken _token;
  @override
  StellarIssueToken get token => _token;
  StellarNetworkToken(
      {required StellarIssueToken token, super.status = NetworkTokenFetchingStatus.idle})
      : _token = token;
  void setSuccess(StellarIssueToken tokenWithMetadata) {
    if (_status.isClose) return;
    _status = NetworkTokenFetchingStatus.success;
    final token = _token;
    _token = tokenWithMetadata;
    notify();
    token.streamBalance.dispose();
  }

  @override
  void updaetTokenMetadata(Token token) {
    setSuccess(_token.updateToken(token));
  }
}

class TonNetworkToken extends BaseNetworkToken {
  TonJettonToken _token;
  @override
  TonJettonToken get token => _token;
  TonNetworkToken(
      {required TonJettonToken token, super.status = NetworkTokenFetchingStatus.idle})
      : _token = token;
  void setSuccess(TonJettonToken tokenWithMetadata) {
    if (_status.isClose) return;
    _status = NetworkTokenFetchingStatus.success;
    final token = _token;
    _token = tokenWithMetadata;
    notify();
    token.streamBalance.dispose();
  }

  @override
  void updaetTokenMetadata(Token token) {
    setSuccess(_token.updateToken(token));
  }
}

class SolanaNetworkToken extends BaseNetworkToken {
  SolanaSPLToken _token;
  @override
  SolanaSPLToken get token => _token;
  SolanaNetworkToken(
      {required SolanaSPLToken token, super.status = NetworkTokenFetchingStatus.idle})
      : _token = token;
  void setSuccess(SolanaSPLToken tokenWithMetadata) {
    if (_status.isClose) return;
    _status = NetworkTokenFetchingStatus.success;
    final token = _token;
    _token = tokenWithMetadata;
    notify();
    token.streamBalance.dispose();
  }

  @override
  void updaetTokenMetadata(Token token) {
    setSuccess(_token.updateToken(token));
  }

  void updaetTokenDecimals(int decimals) {
    if (_status.isClose) return;
    final token = _token;
    _token = _token.updateToken(_token.token.copyWith(decimal: decimals));
    notify();
    token.streamBalance.dispose();
  }
}

class CosmosNetworkToken extends BaseNetworkToken {
  CW20Token _token;
  @override
  CW20Token get token => _token;
  CosmosNetworkToken(
      {required CW20Token token, super.status = NetworkTokenFetchingStatus.idle})
      : _token = token;
  void setSuccess(CW20Token tokenWithMetadata) {
    if (_status.isClose) return;
    _status = NetworkTokenFetchingStatus.success;
    final token = _token;
    _token = tokenWithMetadata;
    notify();
    token.streamBalance.dispose();
  }

  @override
  void updaetTokenMetadata(Token token) {
    setSuccess(_token.updateToken(token));
  }
}

class TronNetworkToken extends BaseNetworkToken {
  TronToken _token;
  @override
  TronToken get token => _token;
  TronNetworkToken(
      {required TronToken token, super.status = NetworkTokenFetchingStatus.idle})
      : _token = token;
  void setSuccess(TronToken tokenWithMetadata) {
    if (_status.isClose) return;
    _status = NetworkTokenFetchingStatus.success;
    final token = _token;
    _token = tokenWithMetadata;
    notify();
    token.streamBalance.dispose();
  }

  @override
  void updaetTokenMetadata(Token token) {
    setSuccess(_token.updateToken(token));
  }
}

class RippleNetworkToken extends BaseNetworkToken {
  RippleIssueToken _token;
  @override
  RippleIssueToken get token => _token;
  RippleNetworkToken(
      {required RippleIssueToken token, super.status = NetworkTokenFetchingStatus.idle})
      : _token = token;
  void setSuccess({RippleIssueToken? tokenWithMetadata}) {
    if (_status.isClose) return;
    if (tokenWithMetadata == null) {
      _status = NetworkTokenFetchingStatus.success;
      notify();
      return;
    }

    final token = _token;
    _token = tokenWithMetadata;
    _status = NetworkTokenFetchingStatus.success;
    notify();
    token.streamBalance.dispose();
  }

  @override
  void updaetTokenMetadata(Token token) {
    setSuccess(tokenWithMetadata: _token.updateToken(token));
  }
}

class EthereumNetworkToken extends BaseNetworkToken {
  ETHERC20Token _token;
  @override
  ETHERC20Token get token => _token;
  EthereumNetworkToken(
      {required ETHERC20Token token, super.status = NetworkTokenFetchingStatus.idle})
      : _token = token;
  void setSuccess({ETHERC20Token? tokenWithMetadata}) {
    if (_status.isClose) return;
    if (tokenWithMetadata == null) {
      _status = NetworkTokenFetchingStatus.success;
      notify();
      return;
    }

    final token = _token;
    _token = tokenWithMetadata;
    _status = NetworkTokenFetchingStatus.success;
    notify();
    token.streamBalance.dispose();
  }

  @override
  void updaetTokenMetadata(Token token) {
    setSuccess(tokenWithMetadata: _token.updateToken(token));
  }
}

class SubstrateNetworkToken extends BaseNetworkToken {
  SubstrateToken _token;
  @override
  SubstrateToken get token => _token;
  SubstrateNetworkToken(
      {required SubstrateToken token, super.status = NetworkTokenFetchingStatus.idle})
      : _token = token;
  void setSuccess({SubstrateToken? tokenWithMetadata}) {
    if (_status.isClose) return;
    if (tokenWithMetadata == null) {
      _status = NetworkTokenFetchingStatus.success;
      notify();
      return;
    }

    final token = _token;
    _token = tokenWithMetadata;
    _status = NetworkTokenFetchingStatus.success;
    notify();
    token.streamBalance.dispose();
  }

  @override
  void updaetTokenMetadata(Token token) {
    setSuccess(tokenWithMetadata: _token.updateToken(token));
  }
}
