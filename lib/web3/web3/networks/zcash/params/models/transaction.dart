import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/constant/constants/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/permission/models/account.dart';
import 'package:zcash_dart/zcash.dart';

enum Web3ZcashTransferPrivacy {
  shieldedOnly(0, "shielded_only"),
  auto(1, "auto");

  final int value;
  final String name;
  const Web3ZcashTransferPrivacy(this.value, this.name);
  static Web3ZcashTransferPrivacy fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw AppInternalError.internalError("Web3ZcashTransferPrivacy"),
    );
  }

  static Web3ZcashTransferPrivacy? fromName(String? name) {
    if (name == null) return Web3ZcashTransferPrivacy.auto;
    return values.firstWhereNullable((e) => e.name == name);
  }
}

final class Web3ZcashTransactionResponse with AppSerialization {
  final String txId;
  Web3ZcashTransactionResponse(this.txId);
  factory Web3ZcashTransactionResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return Web3ZcashTransactionResponse(values.rawValueAt(0));
  }

  Map<String, dynamic> toJson() {
    return {"txId": txId};
  }

  Map<String, dynamic> toWalletConnectJson() {
    return toJson();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [txId.toCbor()];
}

final class Web3ZcashTransactionParams with AppSerialization {
  final ZcashAddress destination;
  final BigInt amount;
  final ZcashProtocol protocol;
  final String? memo;
  const Web3ZcashTransactionParams._(
      {required this.destination,
      required this.amount,
      required this.protocol,
      required this.memo});
  factory Web3ZcashTransactionParams(
      {required ZcashAddress address,
      required BigInt amount,
      required ZcashProtocol protocol,
      required List<int>? memo}) {
    final destination = address.toProtocolAddress(protocol);
    if (destination == null) {
      throw Web3ZcashExceptionConstant.invalidProtocolAddress(protocol.name);
    }
    if (memo != null) {
      if (!protocol.sheilded) {
        throw Web3ZcashExceptionConstant.unsupportedRecipientMemo;
      }
      if (memo.length > NoteEncryptionConst.memoLength) {
        throw Web3ZcashExceptionConstant.invalidShieldMemo;
      }
    }
    // StrUtils.
    // StringUtils.f
    return Web3ZcashTransactionParams._(
        destination: destination,
        amount: amount,
        protocol: protocol,
        memo: memo == null ? null : StrUtils.fromBytes(memo));
  }
  factory Web3ZcashTransactionParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return Web3ZcashTransactionParams._(
        destination: ZcashAddress(values.rawValueAt(0)),
        amount: values.rawValueAt(1),
        protocol: ZcashProtocol.fromValue(values.rawValueAt(2)),
        memo: values.rawValueAt(3));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        destination.address.toCbor(),
        amount.toCbor(),
        protocol.value.toCbor(),
        memo?.toCbor()
      ];
}

final class Web3ZcashSendTransaction
    extends Web3ZcashRequestParam<Web3ZcashTransactionResponse> {
  final List<Web3ZcashTransactionParams> destintions;
  final List<Web3ZcashChainAccount> accounts;
  final Web3ZcashTransferPrivacy privacy;
  final List<Script> transparentMemos;
  @override
  List<Web3ZcashChainAccount> get requiredAccounts => accounts;

  Web3ZcashSendTransaction._({
    required List<Web3ZcashTransactionParams> destintions,
    required List<Web3ZcashChainAccount> accounts,
    required List<Script> transparentMemos,
    required this.privacy,
  })  : destintions = destintions.immutable,
        accounts = accounts.immutable,
        transparentMemos = transparentMemos.immutable;
  factory Web3ZcashSendTransaction(
      {required List<Web3ZcashTransactionParams> destintions,
      required List<Web3ZcashChainAccount> accounts,
      required Web3ZcashTransferPrivacy privacy,
      required List<Script> transparentMemos}) {
    if (destintions.isEmpty) {
      throw Web3ZcashExceptionConstant.noRecipients;
    }
    final addresses = destintions.map((e) => e.destination.network).toSet().length;
    if (addresses != 1) {
      throw Web3ZcashExceptionConstant.mismatchPaymentAddresses;
    }
    if (transparentMemos.any((e) => !BitcoinScriptUtils.isOpReturn(e))) {
      throw Web3ZcashExceptionConstant.invalidMemos;
    }
    return Web3ZcashSendTransaction._(
        accounts: accounts,
        destintions: destintions,
        privacy: privacy,
        transparentMemos: transparentMemos);
  }

  factory Web3ZcashSendTransaction.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    return Web3ZcashSendTransaction(
        destintions: values
            .listAt<CborTagValue>(1)
            .map((e) => Web3ZcashTransactionParams.deserialize(object: e))
            .toList(),
        accounts: values
            .listAt<CborTagValue>(2)
            .map((e) => Web3ZcashChainAccount.deserialize(object: e))
            .toList(),
        privacy: Web3ZcashTransferPrivacy.fromValue(values.rawValueAt(3)),
        transparentMemos: values
            .listAt<CborBytesValue>(4)
            .map((e) => Script.deserialize(bytes: e.value))
            .toList());
  }

  @override
  Web3ZcashRequestMethods get method => Web3ZcashRequestMethods.sendTransaction;

  @override
  Future<
          IResult<
              Web3ZcashRequest<Web3ZcashTransactionResponse, Web3ZcashSendTransaction>>>
      toRequest(
          {required Web3RequestInformation request,
          required Web3RequestAuthentication authenticated,
          required WEB3REQUESTNETWORKCONTROLLER<IZcashAddress, ZcashChain,
                  Web3ZcashChainAccount>
              chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map((chain) =>
        Web3ZcashRequest<Web3ZcashTransactionResponse, Web3ZcashSendTransaction>(
            params: this,
            authenticated: authenticated,
            chain: chain.$1,
            info: request,
            accounts: chain.$2));
  }

  @override
  Object? toJsWalletResponse(Web3ZcashTransactionResponse response) {
    return response.toCbor().encode();
  }

  @override
  List<CborObject?> get serializationItems => [
        method.methodInfos,
        AppSerialization.listFromObjects(destintions.map((e) => e.toCbor()).toList()),
        AppSerialization.listFromObjects(accounts.map((e) => e.toCbor()).toList()),
        privacy.value.toCbor(),
        AppSerialization.listFromObjects(
            transparentMemos.map((e) => CborBytesValue(e.toBytes())).toList()),
      ];
}
