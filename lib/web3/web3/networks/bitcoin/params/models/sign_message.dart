import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/permission/models/account.dart';

class Web3BitcoinSignMessageResponse with AppSerialization {
  final List<int> signature;
  // final String address;
  final List<int> digest;
  Web3BitcoinSignMessageResponse({
    required List<int> signature,
    required List<int> digest,
  })  : digest = digest.asImmutableBytes,
        signature = signature.asImmutableBytes;

  factory Web3BitcoinSignMessageResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return Web3BitcoinSignMessageResponse(
      signature: values.rawValueAt(0),
      digest: values.rawValueAt(1),
    );
  }
  String signatureAsBase64() {
    return StringUtils.decode(signature, encoding: StringEncoding.base64);
  }

  Map<String, dynamic> toWalletConnectJson() {
    return {
      "signature": BytesUtils.toHexString(signature),
      "digest": BytesUtils.toHexString(digest)
    };
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(signature), CborBytesValue(digest)];
}

abstract class BaseWeb3BitcoinSignMessage<
        WEB3CHAINACCOUNT extends Web3BitcoinChainAccount>
    extends BaseWeb3BitcoinRequestParam<Web3BitcoinSignMessageResponse,
        WEB3CHAINACCOUNT> {
  abstract final String message;
  abstract final String? messagePrefix;
  abstract final String? content;
}

class Web3BitcoinSignMessage
    extends Web3BitcoinRequestParam<Web3BitcoinSignMessageResponse>
    implements BaseWeb3BitcoinSignMessage<Web3BitcoinChainAccount> {
  @override
  final String message;
  @override
  final String? messagePrefix;
  @override
  final String? content;
  Web3BitcoinSignMessage._(
      {required this.accessAccount,
      required this.message,
      required this.content,
      required this.messagePrefix,
      required this.method});
  factory Web3BitcoinSignMessage(
      {required Web3BitcoinChainAccount account,
      required String message,
      required String? content,
      required String? messagePrefix,
      required Web3NetworkRequestMethods method}) {
    switch (method) {
      case Web3BitcoinRequestMethods.signMessage:
      case Web3BitcoinRequestMethods.signPersonalMessage:
        break;
      default:
        throw Web3RequestExceptionConst.invalidRequest;
    }
    return Web3BitcoinSignMessage._(
        accessAccount: account,
        message: message,
        content: content,
        messagePrefix: messagePrefix,
        method: method.cast());
  }

  factory Web3BitcoinSignMessage.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    final method = Web3NetworkRequestMethods.findMethod(values.objectAt(0)).method;
    return Web3BitcoinSignMessage(
        method: method,
        account:
            Web3BitcoinChainAccount.deserialize(object: values.objectAt<CborTagValue>(1)),
        message: values.rawValueAt(2),
        content: values.rawValueAt(3),
        messagePrefix: values.rawValueAt(4));
  }

  @override
  final Web3BitcoinRequestMethods method;

  final Web3BitcoinChainAccount accessAccount;

  @override
  Future<
          IResult<
              Web3BitcoinRequest<Web3BitcoinSignMessageResponse, Web3BitcoinSignMessage>>>
      toRequest(
          {required Web3RequestInformation request,
          required Web3RequestAuthentication authenticated,
          required WEB3REQUESTNETWORKCONTROLLER<IBitcoinAddress, BitcoinChain,
                  Web3BitcoinChainAccount>
              chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map((chain) =>
        Web3BitcoinRequest<Web3BitcoinSignMessageResponse, Web3BitcoinSignMessage>(
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
  List<Web3BitcoinChainAccount> get requiredAccounts => [accessAccount];

  @override
  List<CborObject?> get serializationItems => [
        method.methodInfos,
        accessAccount.toCbor(),
        message.toCbor(),
        content?.toCbor(),
        messagePrefix?.toCbor()
      ];
}
