import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/web3/web3/networks/monero/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/monero/params/models/sign_message.dart';
import 'package:on_chain_wallet/web3/web3/networks/monero/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/monero/permission/models/account.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';

abstract class Web3MoneroRequestParam<RESPONSE> extends Web3RequestParams<RESPONSE,
    MoneroAddress, IMoneroAddress, MoneroChain, Web3MoneroChainAccount> {
  @override
  abstract final Web3MoneroRequestMethods method;

  Web3MoneroRequestParam();

  factory Web3MoneroRequestParam.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    final method = Web3NetworkRequestMethods.findMethod(values.objectAt(0)).method;
    final Web3MoneroRequestParam param;
    switch (method) {
      case Web3MoneroRequestMethods.sendTransaction:
        param = Web3MoneroSendTransaction.deserialize(bytes: bytes, object: object);
      case Web3MoneroRequestMethods.signMessage:
        param = Web3MoneroSignMessage.deserialize(bytes: bytes, object: object);
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    return param.cast<Web3MoneroRequestParam<RESPONSE>>();
  }
}

class Web3MoneroRequest<RESPONSE, PARAMS extends Web3MoneroRequestParam<RESPONSE>>
    extends Web3NetworkRequest<RESPONSE, MoneroAddress, IMoneroAddress, MoneroChain,
        Web3MoneroChainAccount, PARAMS> {
  Web3MoneroRequest(
      {required super.params,
      required super.info,
      required super.authenticated,
      required super.chain,
      required super.accounts});

  Web3MoneroRequest<R, P> cast<R, P extends Web3MoneroRequestParam<R>>() {
    return this as Web3MoneroRequest<R, P>;
  }
}
