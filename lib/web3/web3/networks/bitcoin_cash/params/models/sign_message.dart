import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/params/models/sign_message.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin_cash/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin_cash/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin_cash/permission/models/account.dart';

class Web3BitcoinCashSignMessage
    extends Web3BitcoinCashRequestParam<Web3BitcoinSignMessageResponse>
    implements BaseWeb3BitcoinSignMessage<Web3BitcoinCashChainAccount> {
  @override
  final String message;
  @override
  final String? messagePrefix;
  @override
  final String? content;
  Web3BitcoinCashSignMessage._(
      {required this.accessAccount,
      required this.message,
      required this.content,
      required this.messagePrefix,
      required this.method});
  factory Web3BitcoinCashSignMessage(
      {required Web3BitcoinCashChainAccount account,
      required String message,
      required String? content,
      required String? messagePrefix,
      required Web3NetworkRequestMethods method}) {
    switch (method) {
      case Web3BitcoinCashRequestMethods.signMessage:
      case Web3BitcoinCashRequestMethods.signPersonalMessage:
        break;
      default:
        throw Web3RequestExceptionConst.invalidRequest;
    }
    return Web3BitcoinCashSignMessage._(
        accessAccount: account,
        message: message,
        content: content,
        messagePrefix: messagePrefix,
        method: method.cast());
  }

  factory Web3BitcoinCashSignMessage.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    final method = Web3NetworkRequestMethods.findMethod(values.objectAt(0)).method;
    return Web3BitcoinCashSignMessage(
        method: method,
        account: Web3BitcoinCashChainAccount.deserialize(
            object: values.objectAt<CborTagValue>(1)),
        message: values.rawValueAt(2),
        content: values.rawValueAt(3),
        messagePrefix: values.rawValueAt(4));
  }

  @override
  final Web3BitcoinCashRequestMethods method;

  final Web3BitcoinCashChainAccount accessAccount;

  @override
  Future<
      IResult<
          Web3BitcoinCashRequest<Web3BitcoinSignMessageResponse,
              Web3BitcoinCashSignMessage>>> toRequest(
      {required Web3RequestInformation request,
      required Web3RequestAuthentication authenticated,
      required WEB3REQUESTNETWORKCONTROLLER<IBitcoinAddress, BitcoinChain,
              Web3BitcoinCashChainAccount>
          chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map((chain) => Web3BitcoinCashRequest<Web3BitcoinSignMessageResponse,
            Web3BitcoinCashSignMessage>(
          params: this,
          authenticated: authenticated,
          chain: chain.$1,
          info: request,
          accounts: chain.$2,
        ));
  }

  @override
  Object? toJsWalletResponse(Web3BitcoinSignMessageResponse response) {
    return response.toCbor().encode();
  }

  @override
  List<Web3BitcoinCashChainAccount> get requiredAccounts => [accessAccount];

  @override
  List<CborObject?> get serializationItems => [
        method.methodInfos,
        accessAccount.toCbor(),
        message.toCbor(),
        content?.toCbor(),
        messagePrefix?.toCbor()
      ];
}
