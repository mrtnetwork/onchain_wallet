import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain/solana/src/rpc/models/models/commitment.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/solana/constant/constants/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/solana/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/solana/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/solana/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/utils/web3_validator_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

class Web3SolanaSendTransactionOptions with AppSerialization {
  final String? preflightCommitment;
  final int? minContextSlot;
  final bool? skipPreflight;
  final String? commitment;
  final int? maxRetries;
  const Web3SolanaSendTransactionOptions(
      {this.maxRetries,
      this.skipPreflight = false,
      this.commitment,
      this.minContextSlot,
      this.preflightCommitment});
  factory Web3SolanaSendTransactionOptions.fromJson(
      {required Map<String, dynamic> json, required Web3SolanaRequestMethods method}) {
    final bool isSignTx = method == Web3SolanaRequestMethods.signTransaction ||
        method == Web3SolanaRequestMethods.signAllTransactions;
    return Web3SolanaSendTransactionOptions(
        skipPreflight: isSignTx
            ? null
            : Web3ValidatorUtils.parseBool(
                key: "skipPreflight", method: method, json: json),
        maxRetries: isSignTx
            ? null
            : Web3ValidatorUtils.parseInt(key: "maxRetries", method: method, json: json),
        minContextSlot: Web3ValidatorUtils.parseInt(
            key: "minContextSlot", method: method, json: json),
        preflightCommitment: Web3ValidatorUtils.parseParams2(() {
          if (json["preflightCommitment"] == null) return null;
          return Commitment.values
              .firstWhere((e) => e.value == json["preflightCommitment"])
              .value;
        },
            errorOnNull: false,
            error: Web3SolanaExceptionConstant.invalidCommitmentOptions),
        commitment: Web3ValidatorUtils.parseParams2(() {
          if (isSignTx || json["commitment"] == null) return null;
          return Commitment.values.firstWhere((e) => e.value == json["commitment"]).value;
        },
            errorOnNull: false,
            error: Web3SolanaExceptionConstant.invalidCommitmentOptions));
  }
  factory Web3SolanaSendTransactionOptions.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return Web3SolanaSendTransactionOptions(
      preflightCommitment: values.rawValueAt(0),
      maxRetries: values.rawValueAt(1),
      skipPreflight: values.rawValueAt(2),
      commitment: values.rawValueAt(3),
      minContextSlot: values.rawValueAt(4),
    );
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        preflightCommitment?.toCbor(),
        maxRetries?.toCbor(),
        skipPreflight?.toCbor(),
        commitment?.toCbor(),
        minContextSlot?.toCbor()
      ];
}

class Web3SolanaSendTransactionData with AppSerialization {
  final Web3SolanaChainAccount account;
  final List<int> messageBytes;
  final Web3SolanaSendTransactionOptions? sendConfig;

  Web3SolanaSendTransactionData({
    required this.account,
    required List<int> messageByte,
    required this.sendConfig,
  }) : messageBytes = messageByte.asImmutableBytes;
  factory Web3SolanaSendTransactionData.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return Web3SolanaSendTransactionData(
        account:
            Web3SolanaChainAccount.deserialize(object: values.objectAt<CborTagValue>(0)),
        messageByte: values.rawValueAt(1),
        sendConfig: values.maybeObjectAt<Web3SolanaSendTransactionOptions, CborTagValue>(
            2, (e) => Web3SolanaSendTransactionOptions.deserialize(object: e)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [account.toCbor(), CborBytesValue(messageBytes), sendConfig?.toCbor()];
}

enum SolanaSignAndSendAllTransactionMode {
  parallel,
  serial;

  factory SolanaSignAndSendAllTransactionMode.fromName(String? name) {
    return values.firstWhere((e) => e.name == name,
        orElse: () => throw Web3SolanaExceptionConstant.invalidModeOptions);
  }
}

class Web3SolanaTransactionResponse with AppSerialization {
  final List<int> signature;
  final List<int> signedTx;
  Web3SolanaTransactionResponse({
    required List<int> signature,
    required List<int> signedTx,
  })  : signature = signature.asImmutableBytes,
        signedTx = signedTx.asImmutableBytes;
  factory Web3SolanaTransactionResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return Web3SolanaTransactionResponse(
        signature: values.rawValueAt(0), signedTx: values.rawValueAt(1));
  }

  Map<String, dynamic> toWalletConnectJson() {
    return {
      "signature": Base58Encoder.encode(signature),
      "signedTransaction": StringUtils.decode(signedTx, encoding: StringEncoding.base64),
    };
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(signature),
        CborBytesValue(signedTx),
      ];
}

class Web3SolanaSendTransaction
    extends Web3SolanaRequestParam<List<Web3SolanaTransactionResponse>> {
  final List<Web3SolanaSendTransactionData> messages;
  final SolanaSignAndSendAllTransactionMode? mode;

  Web3SolanaSendTransaction._({required this.messages, required this.method, this.mode});

  factory Web3SolanaSendTransaction(
      {required List<Web3SolanaSendTransactionData> messages,
      required Web3NetworkRequestMethods method,
      SolanaSignAndSendAllTransactionMode? mode}) {
    switch (method) {
      case Web3SolanaRequestMethods.signAndSendAllTransactions:
      case Web3SolanaRequestMethods.signAllTransactions:
      case Web3SolanaRequestMethods.sendTransaction:
      case Web3SolanaRequestMethods.signTransaction:
        break;
      default:
        throw Web3RequestExceptionConst.invalidRequest;
    }
    if (messages.isEmpty) {
      throw Web3RequestExceptionConst.invalidTransaction;
    }
    if (messages.map((e) => e.account.id).toSet().length != 1) {
      throw Web3RequestExceptionConst.multipleBatchRequestNetwork;
    }
    return Web3SolanaSendTransaction._(
        messages: messages, method: method as Web3SolanaRequestMethods, mode: mode);
  }

  factory Web3SolanaSendTransaction.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    final method = Web3NetworkRequestMethods.findMethod(values.objectAt(0)).method;

    return Web3SolanaSendTransaction(
        messages: values
            .objectAt<CborListValue>(1)
            .value
            .cast<CborTagValue>()
            .map((e) => Web3SolanaSendTransactionData.deserialize(object: e))
            .toList(),
        method: method,
        mode: values.maybeObjectAt<SolanaSignAndSendAllTransactionMode, CborStringValue>(
            2, (e) => SolanaSignAndSendAllTransactionMode.fromName(e.value)));
  }

  @override
  final Web3SolanaRequestMethods method;

  late final bool isSend = method == Web3SolanaRequestMethods.sendTransaction ||
      method == Web3SolanaRequestMethods.signAndSendAllTransactions;
  late final bool isBatchRequest = messages.length > 1;

  @override
  Future<
      IResult<
          Web3SolanaRequest<List<Web3SolanaTransactionResponse>,
              Web3SolanaSendTransaction>>> toRequest(
      {required Web3RequestInformation request,
      required Web3RequestAuthentication authenticated,
      required WEB3REQUESTNETWORKCONTROLLER<ISolanaAddress, SolanaChain,
              Web3SolanaChainAccount>
          chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map((chain) =>
        Web3SolanaRequest<List<Web3SolanaTransactionResponse>, Web3SolanaSendTransaction>(
          params: this,
          authenticated: authenticated,
          chain: chain.$1,
          info: request,
          accounts: chain.$2,
        ));
  }

  @override
  List<Web3SolanaChainAccount> get requiredAccounts =>
      messages.map((e) => e.account).toList();

  @override
  Object? toJsWalletResponse(List<Web3SolanaTransactionResponse> response) {
    return response.map((e) => e.toCbor().encode()).toList();
  }

  @override
  List<CborObject?> get serializationItems => [
        method.methodInfos,
        AppSerialization.listFromObjects(messages.map((e) => e.toCbor()).toList()),
        mode?.name.toCbor()
      ];
}
