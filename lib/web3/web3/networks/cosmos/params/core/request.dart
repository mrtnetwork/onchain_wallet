import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/cosmos/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/cosmos/params/models/add_new_chain.dart';
import 'package:on_chain_wallet/web3/web3/networks/cosmos/params/models/sign_message.dart';
import 'package:on_chain_wallet/web3/web3/networks/cosmos/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/cosmos/permission/models/account.dart';

abstract class Web3CosmosRequestParam<RESPONSE> extends Web3RequestParams<RESPONSE,
    CosmosBaseAddress, ICosmosAddress, CosmosChain, Web3CosmosChainAccount> {
  @override
  abstract final Web3CosmosRequestMethods method;

  Web3CosmosRequestParam();
  @override
  List<Web3CosmosChainAccount> get requiredAccounts => [];

  factory Web3CosmosRequestParam.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    final method = Web3NetworkRequestMethods.findMethod(values.objectAt(0)).method;
    final Web3CosmosRequestParam param;
    switch (method) {
      case Web3CosmosRequestMethods.signTransactionAmino:
      case Web3CosmosRequestMethods.signTransactionDirect:
        param = Web3CosmosSignTransaction.deserialize(bytes: bytes, object: object);
        break;
      case Web3CosmosRequestMethods.addNewChain:
        param = Web3CosmosAddNewChain.deserialize(bytes: bytes, object: object);
        break;
      case Web3CosmosRequestMethods.signMessage:
        param = Web3CosmosSignMessage.deserialize(bytes: bytes, object: object);
        break;

      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    return param.cast<Web3CosmosRequestParam<RESPONSE>>();
  }
}

class Web3CosmosRequest<RESPONSE, PARAMS extends Web3CosmosRequestParam<RESPONSE>>
    extends Web3NetworkRequest<RESPONSE, CosmosBaseAddress, ICosmosAddress, CosmosChain,
        Web3CosmosChainAccount, PARAMS> {
  Web3CosmosRequest(
      {required super.params,
      required super.info,
      required super.authenticated,
      required super.chain,
      required super.accounts});

  Web3CosmosRequest<R, P> cast<R, P extends Web3CosmosRequestParam<R>>() {
    return this as Web3CosmosRequest<R, P>;
  }
}
