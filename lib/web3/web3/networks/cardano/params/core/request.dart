import 'package:on_chain/ada/src/ada.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/params/models/get_accout_pub_key.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/params/models/get_collateral.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/params/models/sign_data.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/params/models/sign_message.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/permission/models/account.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';

abstract class Web3ADARequestParam<RESPONSE> extends Web3RequestParams<RESPONSE,
    ADAAddress, ICardanoAddress, ADAChain, Web3ADAChainAccount> {
  @override
  abstract final Web3ADARequestMethods method;

  Web3ADARequestParam();

  factory Web3ADARequestParam.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    final method = Web3NetworkRequestMethods.findMethod(values.objectAt(0)).method;
    final Web3ADARequestParam param;
    switch (method) {
      case Web3ADARequestMethods.signTransaction:
      case Web3ADARequestMethods.signTx:
      case Web3ADARequestMethods.signAndSendTransaction:
      case Web3ADARequestMethods.submitTx:
      case Web3ADARequestMethods.submitUnsignedTx:
      case Web3ADARequestMethods.submitTxs:
      case Web3ADARequestMethods.signTxs:
        param = Web3ADASignTransaction.deserialize(bytes: bytes, object: object);
        break;
      case Web3ADARequestMethods.signMessage:
        param = Web3ADASignMessage.deserialize(bytes: bytes, object: object);
        break;
      case Web3ADARequestMethods.getCollateral:
        param = Web3ADAGetCollateral.deserialize(bytes: bytes, object: object);
        break;
      case Web3ADARequestMethods.getAccountPub:
        param = Web3ADAGetAccountPub.deserialize(bytes: bytes, object: object);
        break;
      case Web3ADARequestMethods.signData:
        param = Web3ADASignData.deserialize(bytes: bytes, object: object);
        break;
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }

    return param.cast<Web3ADARequestParam<RESPONSE>>();
  }
}

class Web3ADARequest<RESPONSE, PARAMS extends Web3ADARequestParam<RESPONSE>>
    extends Web3NetworkRequest<RESPONSE, ADAAddress, ICardanoAddress, ADAChain,
        Web3ADAChainAccount, PARAMS> {
  Web3ADARequest(
      {required super.params,
      required super.info,
      required super.authenticated,
      required super.chain,
      required super.accounts});

  Web3ADARequest<R, P> cast<R, P extends Web3ADARequestParam<R>>() {
    return this as Web3ADARequest<R, P>;
  }
}
