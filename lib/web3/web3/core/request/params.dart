import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/messages.dart';
import 'package:on_chain_wallet/web3/web3/core/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/permission.dart';
import 'package:on_chain_wallet/web3/web3/networks/aptos/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin_cash/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/params/params.dart';
import 'package:on_chain_wallet/web3/web3/networks/cosmos/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/global/global.dart';
import 'package:on_chain_wallet/web3/web3/networks/monero/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/solana/solana.dart';
import 'package:on_chain_wallet/web3/web3/networks/stellar/stellar.dart';
import 'package:on_chain_wallet/web3/web3/networks/substrate/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/sui/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/ton/ton.dart';
import 'package:on_chain_wallet/web3/web3/networks/tron/tron.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/params/core/request.dart';

import 'web_request.dart';

abstract class Web3WalletRequestParams<RESPONSE> extends Web3MessageCore {
  abstract final Web3RequestMethods method;
  const Web3WalletRequestParams();

  Object? toJsWalletResponse(RESPONSE response) {
    return response;
  }

  Object? toWalletConnectResponse(RESPONSE response) {
    return response;
  }

  Object? toPageResponse(RESPONSE response) {
    return response;
  }
}

abstract class Web3GlobalRequestParams<RESPONSE>
    extends Web3WalletRequestParams<RESPONSE> {
  @override
  Web3MessageTypes get type => Web3MessageTypes.walletGlobalRequest;
  const Web3GlobalRequestParams();
  @override
  abstract final Web3GlobalRequestMethods method;

  factory Web3GlobalRequestParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletGlobalRequest.tag);
    final method = Web3GlobalRequestMethods.fromIdentifier(values.rawValueAt(0));
    final Web3GlobalRequestParams param;
    switch (method) {
      case Web3GlobalRequestMethods.disconnect:
        param = Web3DisconnectApplication.deserialize(bytes: bytes, object: object);
        break;
      case Web3GlobalRequestMethods.connect:
        param = Web3ConnectApplication.deserialize(bytes: bytes, object: object);
        break;
      case Web3GlobalRequestMethods.connectSilent:
        param = Web3SilentConnectApplication.deserialize(bytes: bytes, object: object);
        break;
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }

    return param.cast<Web3GlobalRequestParams<RESPONSE>>();
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;
}

typedef WEB3REQUESTPARAMSRESPONSE<RESPONSE> = Web3RequestParams<RESPONSE, IAddress,
    ACCOUNTADDRESS<IAddress>, Chain, Web3ChainAccount>;
typedef WEB3REQUESTNETWORKCONTROLLER<
        WALLETACCOUNT extends ChainAccount,
        CHAIN extends APPCHAINACCOUNT<WALLETACCOUNT>,
        CHAINACCOUNT extends Web3ChainAccount>
    = NetworkController<WALLETACCOUNT, CHAIN, CHAINACCOUNT, Web3InternalChain,
        ChainConfig>;

abstract class Web3RequestParams<
        RESPONSE,
        NETWORKADDRESS extends IAddress,
        WALLETACCOUNT extends ACCOUNTADDRESS<NETWORKADDRESS>,
        CHAIN extends APPCHAINACCOUNT<WALLETACCOUNT>,
        CHAINACCOUNT extends Web3ChainAccount<NETWORKADDRESS>>
    extends Web3WalletRequestParams<RESPONSE> {
  @override
  abstract final Web3NetworkRequestMethods method;
  List<CHAINACCOUNT> get requiredAccounts;

  Web3RequestParams();

  @override
  Web3MessageTypes get type => Web3MessageTypes.walletRequest;
  Future<IResult<Web3NetworkRequest>> toRequest(
      {required Web3RequestInformation request,
      required Web3RequestAuthentication authenticated,
      required WEB3REQUESTNETWORKCONTROLLER<WALLETACCOUNT, CHAIN, CHAINACCOUNT>
          chainController});
  Future<IResult<(CHAIN, List<WALLETACCOUNT>)>> findRequestChain(
      {required Web3RequestInformation request,
      required Web3RequestAuthentication authenticated,
      required WEB3REQUESTNETWORKCONTROLLER<WALLETACCOUNT, CHAIN, CHAINACCOUNT>
          chainController}) async {
    final networkChains = chainController.web3Networks;
    if (authenticated is Web3ApplicationAuthentication) {
      final accounts = await chainController.getWeb3AuthenticatedAccounts(
          authenticated, requiredAccounts);
      return accounts.andThen((accounts) {
        if (accounts == null) {
          return ResultErr.fromException(Web3RequestExceptionConst.missingPermission);
        }
        return ResultOk(accounts);
      });
    }
    if (requiredAccounts.isEmpty) {
      return ResultErr.fromException(Web3RequestExceptionConst.missingPermission);
    }
    final accountChain = requiredAccounts.map((e) => e.id).toSet();
    if (accountChain.length != 1) {
      return ResultErr.fromException(Web3RequestExceptionConst.invalidRequest);
    }
    final networkId = accountChain.elementAt(0);
    final chain = networkChains.firstWhereOrNull((e) => e.network.value == networkId);
    if (chain == null) {
      return ResultErr.fromException(Web3RequestExceptionConst.networkDoesNotExists);
    }
    final result = await chain.initAsMainNetwork();
    return result.andThen((_) {
      final walletAccounts = requiredAccounts.map((e) {
        final acc = chain.getAddressSync(address: e.addressStr);
        if (acc == null) {
          return ResultErr.fromException(Web3RequestExceptionConst.missingPermission);
        }
        return acc;
      }).toList();

      return ResultOk((chain, walletAccounts.cast<WALLETACCOUNT>()));
    });
  }

  factory Web3RequestParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    final network = Web3NetworkRequestMethods.findMethod(values.objectAt(0)).network;
    final Web3RequestParams param;
    switch (network) {
      case NetworkType.ethereum:
        param = Web3EthereumRequestParam.deserialize(bytes: bytes, object: object);
        break;
      case NetworkType.zcash:
        param = Web3ZcashRequestParam.deserialize(bytes: bytes, object: object);
        break;
      case NetworkType.tron:
        param = Web3TronRequestParam.deserialize(bytes: bytes, object: object);
        break;
      case NetworkType.solana:
        param = Web3SolanaRequestParam.deserialize(bytes: bytes, object: object);
        break;
      case NetworkType.xrpl:
        param = Web3XRPRequestParam.deserialize(bytes: bytes, object: object);
        break;
      case NetworkType.monero:
        param = Web3MoneroRequestParam.deserialize(bytes: bytes, object: object);
        break;
      case NetworkType.cardano:
        param = Web3ADARequestParam.deserialize(bytes: bytes, object: object);
        break;
      case NetworkType.ton:
        param = Web3TonRequestParam.deserialize(bytes: bytes, object: object);
        break;
      case NetworkType.stellar:
        param = Web3StellarRequestParam.deserialize(bytes: bytes, object: object);
        break;
      case NetworkType.substrate:
        param = Web3SubstrateRequestParam.deserialize(bytes: bytes, object: object);
        break;
      case NetworkType.aptos:
        param = Web3AptosRequestParam.deserialize(bytes: bytes, object: object);
        break;
      case NetworkType.sui:
        param = Web3SuiRequestParam.deserialize(bytes: bytes, object: object);
        break;
      case NetworkType.cosmos:
        param = Web3CosmosRequestParam.deserialize(bytes: bytes, object: object);
        break;
      case NetworkType.bitcoinAndForked:
        param = Web3BitcoinRequestParam.deserialize(bytes: bytes, object: object);
        break;
      case NetworkType.bitcoinCash:
        param = Web3BitcoinCashRequestParam.deserialize(bytes: bytes, object: object);
        break;
    }
    return param.cast<
        Web3RequestParams<RESPONSE, NETWORKADDRESS, WALLETACCOUNT, CHAIN,
            CHAINACCOUNT>>();
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;
}
