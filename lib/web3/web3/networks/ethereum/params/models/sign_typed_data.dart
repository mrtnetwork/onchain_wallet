import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/networks/ethereum/models/typed_data.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain/solidity/solidity.dart';

class Web3EthreumTypdedData extends Web3EthereumRequestParam<String> {
  final EIP712Base typedData;
  BigInt? get chainId => domain?.chainId;
  final EIP712Domain? domain;

  final Web3EthereumChainAccount accessAccount;

  Web3EthreumTypdedData._(
      {required this.accessAccount, required this.typedData, this.domain});

  late final Map<String, dynamic> typedDataJson = typedData.toJson();

  factory Web3EthreumTypdedData(EIP712Base typedData, Web3EthereumChainAccount account) {
    EIP712Domain? domain;
    if (typedData.version != EIP712Version.v1) {
      domain = EIP712Domain.fromJson((typedData as Eip712TypedData).domain);
    }
    return Web3EthreumTypdedData._(
        accessAccount: account, typedData: typedData, domain: domain);
  }
  factory Web3EthreumTypdedData.fromJson(
      {required Map<String, dynamic> json,
      required Web3EthereumChainAccount account,
      EIP712Version? version}) {
    if (json["typedData"] is List) {
      final typedData = EIP712Legacy.fromJson(json["typedData"]);
      return Web3EthreumTypdedData(typedData, account);
    }
    final typedData = Eip712TypedData.fromJson(json["typedData"], version: version);
    final domain = EIP712Domain.fromJson(typedData.domain);
    return Web3EthreumTypdedData._(
        accessAccount: account, typedData: typedData, domain: domain);
  }

  factory Web3EthreumTypdedData.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: Web3MessageTypes.walletRequest.tag,
    );
    final typedData = EIP712Base.fromJson(StringUtils.toJson(values.rawValueAt(2)));
    EIP712Domain? domain;
    if (typedData.version != EIP712Version.v1) {
      domain = EIP712Domain.fromJson((typedData as Eip712TypedData).domain);
    }
    return Web3EthreumTypdedData._(
        accessAccount: Web3EthereumChainAccount.deserialize(
            object: values.objectAt<CborTagValue>(1)),
        typedData: typedData,
        domain: domain);
  }

  @override
  Web3EthereumRequestMethods get method => Web3EthereumRequestMethods.typedData;

  late String content = StringUtils.fromJson(typedData.toJson());

  @override
  Future<IResult<Web3EthereumRequest<String, Web3EthreumTypdedData>>> toRequest(
      {required Web3RequestInformation request,
      required Web3RequestAuthentication authenticated,
      required WEB3REQUESTNETWORKCONTROLLER<IEthereumAddress, EthereumChain,
              Web3EthereumChainAccount>
          chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map((chain) => Web3EthereumRequest<String, Web3EthreumTypdedData>(
          params: this,
          authenticated: authenticated,
          chain: chain.$1,
          info: request,
          accounts: chain.$2,
        ));
  }

  @override
  List<Web3EthereumChainAccount> get requiredAccounts => [accessAccount];

  @override
  List<CborObject?> get serializationItems => [
        method.methodInfos,
        accessAccount.toCbor(),
        CborStringValue(StringUtils.fromJson(typedData.toJson())),
        chainId?.toCbor()
      ];
}
