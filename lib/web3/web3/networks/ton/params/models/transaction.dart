import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/utils/web3_validator_utils.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';
import 'package:ton_dart/ton_dart.dart';

class Web3TonTransactionMessage with AppSerialization {
  final TonAddress address;
  final BigInt amount;
  final Cell? stateInit;
  final Cell? payload;

  const Web3TonTransactionMessage(
      {required this.address,
      required this.amount,
      required this.stateInit,
      required this.payload});
  factory Web3TonTransactionMessage.fromJson(Map<String, dynamic> json) {
    const method = Web3TonRequestMethods.sendTransaction;
    final TonAddress address = Web3ValidatorUtils.parseAddress(
        onParse: (e) => TonAddress(e),
        key: "address",
        method: method,
        json: json,
        network: method.network.name);
    final BigInt amount = Web3ValidatorUtils.parseBigInt(
        key: "amount", method: method, json: json, sign: false);
    final List<int>? stateInitBytes =
        Web3ValidatorUtils.parseBase64(key: "stateInit", method: method, json: json);
    final List<int>? payloadBytes =
        Web3ValidatorUtils.parseBase64(key: "payload", method: method, json: json);
    final Cell? stateInit = Web3ValidatorUtils.parseParams2(
        () => stateInitBytes == null ? null : Cell.fromBytes(stateInitBytes),
        errorOnNull: false);
    final Cell? payload = Web3ValidatorUtils.parseParams2(
        () => payloadBytes == null ? null : Cell.fromBytes(payloadBytes),
        errorOnNull: false);
    return Web3TonTransactionMessage(
        address: address, amount: amount, stateInit: stateInit, payload: payload);
  }

  factory Web3TonTransactionMessage.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    final List<int>? stateInitBytes = values.rawValueAt(2);
    final List<int>? payloadBytes = values.rawValueAt(3);
    return Web3TonTransactionMessage(
        address: TonAddress(values.rawValueAt(0)),
        amount: values.rawValueAt(1),
        stateInit: stateInitBytes == null ? null : Cell.fromBytes(stateInitBytes),
        payload: payloadBytes == null ? null : Cell.fromBytes(payloadBytes));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        address.address.toCbor(),
        amount.toCbor(),
        stateInit?.toBoc().toCborBytes(),
        payload?.toBoc().toCborBytes(),
      ];
}

class Web3TonSendTransactionResponse with AppSerialization {
  final String message;
  final String? txHash;
  const Web3TonSendTransactionResponse({required this.message, this.txHash});
  factory Web3TonSendTransactionResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return Web3TonSendTransactionResponse(
        message: values.rawValueAt(0), txHash: values.rawValueAt(1));
  }

  Map<String, dynamic> toWalletConnectJson() {
    if (txHash == null) return {"externalMessage": message};
    return {"boc": message, if (txHash != null) "txId": txHash};
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [message.toCbor(), txHash?.toCbor()];
}

class Web3TonSendTransaction extends Web3TonRequestParam<Web3TonSendTransactionResponse> {
  final Web3TonChainAccount accessAccount;

  final int validUntil;
  final List<Web3TonTransactionMessage> messages;

  Web3TonSendTransaction._(
      {required this.accessAccount,
      required this.validUntil,
      required this.method,
      required List<Web3TonTransactionMessage> messages})
      : messages = messages.immutable;
  factory Web3TonSendTransaction(
      {required Web3TonChainAccount account,
      required int validUntil,
      required Web3TonRequestMethods method,
      required List<Web3TonTransactionMessage> messages}) {
    switch (method) {
      case Web3TonRequestMethods.sendTransaction:
      case Web3TonRequestMethods.signTransaction:
        break;
      default:
        throw Web3RequestExceptionConst.invalidRequest;
    }

    return Web3TonSendTransaction._(
        accessAccount: account,
        validUntil: validUntil,
        method: method,
        messages: messages);
  }

  factory Web3TonSendTransaction.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    final method =
        Web3NetworkRequestMethods.findMethod<Web3TonRequestMethods>(values.objectAt(0))
            .method;
    return Web3TonSendTransaction(
        account:
            Web3TonChainAccount.deserialize(object: values.objectAt<CborTagValue>(1)),
        messages: values
            .objectAt<CborListValue>(2)
            .value
            .cast<CborTagValue>()
            .map((e) => Web3TonTransactionMessage.deserialize(object: e))
            .toList(),
        validUntil: values.rawValueAt(3),
        method: method);
  }

  @override
  final Web3TonRequestMethods method;

  bool get isExcute => method == Web3TonRequestMethods.sendTransaction;

  @override
  Object? toJsWalletResponse(Web3TonSendTransactionResponse response) {
    return response.toCbor().encode();
  }

  @override
  Future<IResult<Web3TonRequest<Web3TonSendTransactionResponse, Web3TonSendTransaction>>>
      toRequest(
          {required Web3RequestInformation request,
          required Web3RequestAuthentication authenticated,
          required WEB3REQUESTNETWORKCONTROLLER<ITonAddress, TonChain,
                  Web3TonChainAccount>
              chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map(
        (chain) => Web3TonRequest<Web3TonSendTransactionResponse, Web3TonSendTransaction>(
              params: this,
              authenticated: authenticated,
              chain: chain.$1,
              info: request,
              accounts: chain.$2,
            ));
  }

  @override
  List<Web3TonChainAccount> get requiredAccounts => [accessAccount];

  @override
  List<CborObject?> get serializationItems => [
        method.methodInfos,
        accessAccount.toCbor(),
        AppSerialization.listFromObjects(messages.map((e) => e.toCbor()).toList()),
        validUntil.toCbor()
      ];
}
