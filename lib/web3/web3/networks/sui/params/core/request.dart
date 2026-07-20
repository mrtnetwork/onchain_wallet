import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/sui/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/sui/params/models/sign_message.dart';
import 'package:on_chain_wallet/web3/web3/networks/sui/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/sui/permission/models/account.dart';
import 'package:on_chain/sui/src/address/address/address.dart';

abstract class Web3SuiRequestParam<RESPONSE> extends Web3RequestParams<RESPONSE,
    SuiAddress, ISuiAddress, SuiChain, Web3SuiChainAccount> {
  @override
  abstract final Web3SuiRequestMethods method;

  Web3SuiRequestParam();

  factory Web3SuiRequestParam.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    final method = Web3NetworkRequestMethods.findMethod(values.objectAt(0)).method;
    final Web3SuiRequestParam param;
    switch (method) {
      case Web3SuiRequestMethods.signTransaction:
      case Web3SuiRequestMethods.signTransactionBlock:
      case Web3SuiRequestMethods.signAndExecuteTransaction:
      case Web3SuiRequestMethods.signAndExecuteTransactionBlock:
        param = Web3SuiSignOrExecuteTransaction.deserialize(bytes: bytes, object: object);
        break;
      case Web3SuiRequestMethods.signMessage:
      case Web3SuiRequestMethods.signPersonalMessage:
        param = Web3SuiSignMessage.deserialize(bytes: bytes, object: object);
        break;
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }

    return param.cast<Web3SuiRequestParam<RESPONSE>>();
  }
}

class Web3SuiRequest<RESPONSE, PARAMS extends Web3SuiRequestParam<RESPONSE>>
    extends Web3NetworkRequest<RESPONSE, SuiAddress, ISuiAddress, SuiChain,
        Web3SuiChainAccount, PARAMS> {
  Web3SuiRequest(
      {required super.params,
      required super.info,
      required super.authenticated,
      required super.chain,
      required super.accounts});

  Web3SuiRequest<R, P> cast<R, P extends Web3SuiRequestParam<R>>() {
    return this as Web3SuiRequest<R, P>;
  }
}
