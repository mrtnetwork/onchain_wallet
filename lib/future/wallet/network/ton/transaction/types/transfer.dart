import 'package:on_chain_wallet/crypto/networks/ton/ton.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:ton_dart/ton_dart.dart';

import 'types.dart';

class TonTransferDetails extends TransferOutputDetails<TonAddress> {
  TonTransferDetails({
    required super.recipient,
    required Token token,
  })  : networkToken = token,
        super(amount: IntegerBalance.zero(token));
  final Token networkToken;

  bool get hasSetting => _bounce || _typeOfBoy.hasBody;
  TonOutputJettonWithBalance? _token;
  bool get hasToken => _token != null;
  IntegerBalance get tokenBalance => _token!.balance;
  TonJettonToken? get jetton => _token?.token;
  BigInt get queryId => _token!.queryId;

  IntegerBalance get forwardBalance => _token!.forwardBalance;

  bool _bounce = false;
  bool get bounce => _bounce;

  TonMessageBodyType _typeOfBoy = TonMessageBodyType.none;
  TonMessageBodyType get bodyType => _typeOfBoy;

  String? _body;
  String? get body => _body;

  @override
  bool get hasAmount => !amount.isZero;

  @override
  bool get isReady => hasAmount && (_token == null || hasTokenAmount);

  bool get hasTokenAmount => !_token!.balance.isZero;

  bool get hasForwardBalance => !_token!.forwardBalance.isZero;

  void onUpdateForwardBalance(BigInt val) {
    _token?.updateForwardAmount(val);
    notify();
  }

  void onUpdateJettonBalance(BigInt val) {
    _token?.updateBalance(val);
    notify();
  }

  void onUpdateBounce(bool useBounce) {
    _bounce = useBounce;
    notify();
  }

  void onUpdateTransferToken(TonJettonToken? jetton) {
    _token = jetton == null ? null : TonOutputJettonWithBalance(jetton, networkToken);
    notify();
  }

  void onUpdateQueryId(BigInt? val) {
    if (val == null) return;
    _token?.updateQueryId(val);
    notify();
  }

  bool onUpdateMessageBody(TonMessageBodyType type, String? messageBody) {
    if (type == TonMessageBodyType.none) {
      _body = null;
      _typeOfBoy = type;
      return true;
    }
    if (type.isValid(messageBody)) {
      _typeOfBoy = type;
      _body = messageBody;
      return true;
    }
    return false;
  }

  OutActionSendMsg toMessage(TonAddress owner) {
    final Cell? payload = bodyType.hasBody ? bodyType.toValue(body!) : null;
    if (hasToken) {
      return OutActionSendMsg(
          outMessage: TonUtils.createJettonTransaferBody(
              walletAddress: jetton!.walletAddress,
              amount: amount.balance,
              jettonAmount: tokenBalance.balance,
              forwardTonAmount: forwardBalance.balance,
              responseAddress: owner,
              destination: recipient.networkAddress,
              payload: payload,
              bounce: bounce,
              queryId: queryId));
    }
    return OutActionSendMsg(
        outMessage: TonHelper.internal(
            destination: recipient.networkAddress,
            amount: amount.balance,
            bounce: bounce,
            body: payload));
  }

  List<ITonTransactionDataTokenTransfer> toPaymentInfo() {
    final token = _token;
    return [
      ITonTransactionDataTokenTransfer(
          recipient: recipient.networkAddress, amount: amount.balance),
      if (token != null)
        ITonTransactionDataTokenTransfer(
            recipient: recipient.networkAddress,
            amount: tokenBalance.balance,
            token: token.token),
    ];
  }
}
