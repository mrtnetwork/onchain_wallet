import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/sui/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/sui/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/sui/permission/models/account.dart';

class Web3SuiSignMessageResponse with AppSerialization {
  final List<int> messageBytes;
  final List<int> signature;
  Web3SuiSignMessageResponse(
      {required List<int> messageBytes, required List<int> signature})
      : messageBytes = messageBytes.asImmutableBytes,
        signature = signature.asImmutableBytes;

  factory Web3SuiSignMessageResponse.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return Web3SuiSignMessageResponse(
        messageBytes: values.rawValueAt(0), signature: values.rawValueAt(1));
  }
  String get messageAsBase64 =>
      StringUtils.decode(messageBytes, encoding: StringEncoding.base64);
  String get signatureAsBase64 =>
      StringUtils.decode(signature, encoding: StringEncoding.base64);
  Map<String, dynamic> toWalletConnectJson() {
    return {"messageBytes": messageAsBase64, "signature": signatureAsBase64};
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(messageBytes),
        CborBytesValue(signature),
      ];
}

class Web3SuiSignMessage extends Web3SuiRequestParam<Web3SuiSignMessageResponse> {
  final String challeng;
  final String? content;
  Web3SuiSignMessage._({
    required this.accessAccount,
    required this.challeng,
    required this.content,
    required this.method,
  });
  factory Web3SuiSignMessage({
    required Web3SuiChainAccount account,
    required String challeng,
    required Web3NetworkRequestMethods method,
    String? content,
  }) {
    switch (method) {
      case Web3SuiRequestMethods.signMessage:
      case Web3SuiRequestMethods.signPersonalMessage:
        break;
      default:
        throw Web3RequestExceptionConst.invalidRequest;
    }
    return Web3SuiSignMessage._(
        accessAccount: account,
        challeng: challeng,
        content: content,
        method: method as Web3SuiRequestMethods);
  }

  factory Web3SuiSignMessage.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: Web3MessageTypes.walletRequest.tag,
    );
    final method = Web3NetworkRequestMethods.findMethod(values.objectAt(0)).method;

    return Web3SuiSignMessage(
        account:
            Web3SuiChainAccount.deserialize(object: values.objectAt<CborTagValue>(1)),
        challeng: values.rawValueAt(2),
        content: values.rawValueAt(3),
        method: method);
  }

  @override
  final Web3SuiRequestMethods method;

  final Web3SuiChainAccount accessAccount;
  @override
  Future<IResult<Web3SuiRequest<Web3SuiSignMessageResponse, Web3SuiSignMessage>>>
      toRequest(
          {required Web3RequestInformation request,
          required Web3RequestAuthentication authenticated,
          required WEB3REQUESTNETWORKCONTROLLER<ISuiAddress, SuiChain,
                  Web3SuiChainAccount>
              chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain
        .map((chain) => Web3SuiRequest<Web3SuiSignMessageResponse, Web3SuiSignMessage>(
              params: this,
              authenticated: authenticated,
              chain: chain.$1,
              info: request,
              accounts: chain.$2,
            ));
  }

  @override
  Object? toJsWalletResponse(Web3SuiSignMessageResponse response) {
    return response.toCbor().encode();
  }

  @override
  List<Web3SuiChainAccount> get requiredAccounts => [accessAccount];

  @override
  List<CborObject?> get serializationItems =>
      [method.methodInfos, accessAccount.toCbor(), challeng.toCbor(), content?.toCbor()];
}
