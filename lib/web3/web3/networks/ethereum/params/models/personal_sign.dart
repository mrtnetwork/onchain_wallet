import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/permission/models/account.dart';

class Web3EthreumPersonalSign extends Web3EthereumRequestParam<String> {
  final Web3EthereumChainAccount accessAccount;
  final String message;
  final String? content;

  Web3EthreumPersonalSign._(
      {required this.accessAccount,
      required this.message,
      required this.method,
      this.content});

  factory Web3EthreumPersonalSign(
      {required String message,
      required Web3EthereumChainAccount account,
      required Web3NetworkRequestMethods method}) {
    switch (method) {
      case Web3EthereumRequestMethods.ethSign:
      case Web3EthereumRequestMethods.persoalSign:
        break;
      default:
        throw Web3RequestExceptionConst.invalidRequest;
    }
    String? content = StringUtils.tryDecode(BytesUtils.fromHexString(message));
    if (content != null) {
      content = StrUtils.toRawString(content);
    }
    return Web3EthreumPersonalSign._(
        accessAccount: account,
        message: message,
        content: content,
        method: method.cast());
  }

  factory Web3EthreumPersonalSign.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: Web3MessageTypes.walletRequest.tag,
    );
    final method = Web3NetworkRequestMethods.findMethod<Web3EthereumRequestMethods>(
            values.objectAt(0))
        .method;
    final List<int> challeng = values.rawValueAt(2);
    return Web3EthreumPersonalSign._(
        accessAccount: Web3EthereumChainAccount.deserialize(
            object: values.objectAt<CborTagValue>(1)),
        message: BytesUtils.toHexString(challeng, prefix: "0x"),
        content: values.rawValueAt(3),
        method: method);
  }

  @override
  final Web3EthereumRequestMethods method;

  List<int> chalengBytes() {
    return BytesUtils.fromHexString(message);
  }

  @override
  Future<IResult<Web3EthereumRequest<String, Web3EthreumPersonalSign>>> toRequest(
      {required Web3RequestInformation request,
      required Web3RequestAuthentication authenticated,
      required WEB3REQUESTNETWORKCONTROLLER<IEthereumAddress, EthereumChain,
              Web3EthereumChainAccount>
          chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map((chain) => Web3EthereumRequest<String, Web3EthreumPersonalSign>(
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
        CborBytesValue(BytesUtils.fromHexString(message)),
        content?.toCbor()
      ];
}
