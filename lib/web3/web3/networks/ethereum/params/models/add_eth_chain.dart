import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/permission/models/account.dart';

class Web3EthereumAddNewChain extends Web3EthereumRequestParam<String> {
  final BigInt newChainId;
  final String chainName;
  final String name;
  final String symbol;
  final List<String> rpcUrls;
  final List<String>? blockExplorerUrls;
  final List<String>? iconUrls;
  final int decimals;

  Web3EthereumAddNewChain._(
      {required this.newChainId,
      required this.chainName,
      required this.name,
      required this.symbol,
      required this.decimals,
      required List<String> rpcUrls,
      required List<String>? blockExplorerUrls,
      required List<String>? iconUrls})
      : rpcUrls = rpcUrls.immutable,
        blockExplorerUrls = blockExplorerUrls?.immutableAndNullOnEmpty,
        iconUrls = iconUrls?.immutableAndNullOnEmpty;
  factory Web3EthereumAddNewChain(
      {required BigInt newChainId,
      required String chainName,
      required String name,
      required String symbol,
      required int decimals,
      required List<String> rpcUrls,
      required List<String>? blockExplorerUrls,
      required List<String>? iconUrls}) {
    return Web3EthereumAddNewChain._(
        newChainId: newChainId,
        chainName: chainName,
        name: name,
        symbol: symbol,
        decimals: decimals,
        rpcUrls: rpcUrls,
        blockExplorerUrls:
            (blockExplorerUrls?.isEmpty ?? true) ? null : blockExplorerUrls,
        iconUrls: (iconUrls?.isEmpty ?? true) ? null : iconUrls);
  }

  factory Web3EthereumAddNewChain.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    return Web3EthereumAddNewChain(
        newChainId: values.rawValueAt(1),
        chainName: values.rawValueAt(2),
        name: values.rawValueAt(3),
        symbol: values.rawValueAt(4),
        rpcUrls: values.objectAt<CborListValue>(5).allRawValuesAs<String>(),
        blockExplorerUrls: values.objectAt<CborListValue?>(6)?.allRawValuesAs<String>(),
        iconUrls: values.objectAt<CborListValue?>(7)?.allRawValuesAs<String>(),
        decimals: values.rawValueAt(8));
  }

  @override
  Web3EthereumRequestMethods get method => Web3EthereumRequestMethods.addEthereumChain;

  @override
  Future<IResult<Web3EthereumRequest<String, Web3EthereumAddNewChain>>> toRequest(
      {required Web3RequestInformation request,
      required Web3RequestAuthentication authenticated,
      required WEB3REQUESTNETWORKCONTROLLER<IEthereumAddress, EthereumChain,
              Web3EthereumChainAccount>
          chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map((chain) => Web3EthereumRequest<String, Web3EthereumAddNewChain>(
          params: this,
          authenticated: authenticated,
          chain: chain.$1,
          info: request,
          accounts: chain.$2,
        ));
  }

  @override
  List<CborObject?> get serializationItems => [
        method.methodInfos,
        newChainId.toCbor(),
        chainName.toCbor(),
        name.toCbor(),
        symbol.toCbor(),
        rpcUrls.toCbor(),
        blockExplorerUrls?.toCbor(),
        iconUrls?.toCbor(),
        decimals.toCbor()
      ];
}
