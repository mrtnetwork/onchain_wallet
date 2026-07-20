import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/ton/ton.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/others/others.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/jetton.dart';
import 'package:ton_dart/ton_dart.dart';

class _TonWeb3TransactionPayloadConst {
  static const String payloadKey = "payload";
  static const String operationKey = "operation";
  static const String commentKey = "comment";
}

enum TonWeb3TransactionPayloadType {
  unknown,
  jetton,
  minter,
  nft,
  transfer,
  comment,
  binaryComment,
  encryptedMessage,
  walletV5;

  /// 0x2167da4b
  bool get isUnknown => this == unknown;
  bool get isCommet =>
      this == comment || this == binaryComment || this == encryptedMessage;
  static TonWeb3TransactionPayloadType? fromCommentType(TonMessageBodyType? type) {
    assert(type != TonMessageBodyType.none, "invalid comment type.");
    return switch (type) {
      TonMessageBodyType.binaryComment => TonWeb3TransactionPayloadType.binaryComment,
      TonMessageBodyType.comment => TonWeb3TransactionPayloadType.comment,
      TonMessageBodyType.encryptedMessage =>
        TonWeb3TransactionPayloadType.encryptedMessage,
      _ => null
    };
  }
}

abstract class TonWeb3TransactionPayload {
  final Cell payload;
  final String base64;
  final Map<String, dynamic> contentJson;
  final BigInt tonAmount;
  abstract final TonWeb3TransactionPayloadType type;
  TonWeb3TransactionPayload(
      {required this.payload,
      required Map<String, dynamic> contentJson,
      BigInt? tonAmount})
      : contentJson = contentJson.immutable,
        base64 = payload.toBase64(),
        tonAmount = tonAmount ?? BigInt.zero;
  static TonWeb3TransactionPayload fromPayload(
      {required Cell payload,
      required TonAddress destination,
      required TonChainId chainId,
      Cell? code}) {
    final slice = payload.beginParse();
    final comment = TonUtils.deserializeComment(slice);
    final type = TonWeb3TransactionPayloadType.fromCommentType(comment?.$1);
    if (type != null) {
      return CommentTonTransactionPayload(
          payload: payload, type: type, content: comment!.$2);
    }
    if (code != null) {
      if (code == JettonMinterConst.code(workchain: destination.workchain)) {
        final jettonMinter = MethodUtils.fallbackOnException(
            () => JettonMinterOperation.deserialize(slice));
        if (jettonMinter != null) {
          return ContractTonTransactionPayload(
              payload: payload,
              content: jettonMinter.toJson(),
              type: TonWeb3TransactionPayloadType.minter,
              operation: jettonMinter.type.name);
        }
      } else if (code == JettonMinterConst.stableCode(workchain: destination.workchain)) {
        final stableJettonMinter = MethodUtils.fallbackOnException(
            () => StableJettonMinterOperation.deserialize(slice));
        if (stableJettonMinter != null) {
          return ContractTonTransactionPayload(
              payload: payload,
              content: stableJettonMinter.toJson(),
              type: TonWeb3TransactionPayloadType.minter,
              operation: stableJettonMinter.type.name);
        }
      } else if (code == JettonWalletConst.stableCode(workchain: destination.workchain)) {
        final stableJettonWallet = MethodUtils.fallbackOnException(
            () => StableJettonWalletOperation.deserialize(slice));
        if (stableJettonWallet != null) {
          BigInt? jettonAmount;
          if (stableJettonWallet.type == StableJettonWalletOperationType.transfer) {
            jettonAmount =
                stableJettonWallet.cast<StableJettonWalletTransfer>().jettonAmount;
          }
          return ContractTonTransactionPayload(
              payload: payload,
              content: stableJettonWallet.toJson(),
              type: stableJettonWallet.type == StableJettonWalletOperationType.transfer
                  ? TonWeb3TransactionPayloadType.transfer
                  : TonWeb3TransactionPayloadType.jetton,
              jettonAmount: jettonAmount,
              operation: stableJettonWallet.type.name);
        }
      } else if (code == JettonWalletConst.code(workchain: destination.workchain)) {
        final jettonWallet = MethodUtils.fallbackOnException(() {
          return JettonWalletOperation.deserialize(slice);
        });
        if (jettonWallet != null) {
          BigInt? jettonAmount;
          if (jettonWallet.type == JettonWalletOperationType.transfer) {
            jettonAmount = jettonWallet.cast<JettonWalletTransfer>().amount;
          }
          return ContractTonTransactionPayload(
              payload: payload,
              content: jettonWallet.toJson(),
              type: jettonWallet.type == JettonWalletOperationType.transfer
                  ? TonWeb3TransactionPayloadType.transfer
                  : TonWeb3TransactionPayloadType.jetton,
              operation: jettonWallet.type.name,
              jettonAmount: jettonAmount);
        }
      } else if (code ==
              TonNftConst.nftCollectionCode(workchain: destination.workchain) ||
          code ==
              TonNftConst.nftEditableCollectionCode(workchain: destination.workchain)) {
        final nftCollection = MethodUtils.fallbackOnException(
            () => NFTCollectionOperation.deserialize(slice));
        if (nftCollection != null) {
          return ContractTonTransactionPayload(
              payload: payload,
              content: nftCollection.toJson(),
              type: TonWeb3TransactionPayloadType.nft,
              operation: nftCollection.type.name);
        }
      } else if (code == TonNftConst.nftItemCode(workchain: destination.workchain)) {
        final nftItem =
            MethodUtils.fallbackOnException(() => NFTItemOperation.deserialize(slice));
        if (nftItem != null) {
          return ContractTonTransactionPayload(
              payload: payload,
              content: nftItem.toJson(),
              type: TonWeb3TransactionPayloadType.nft,
              operation: nftItem.type.name);
        }
      }
    }
    slice.reset();
    final walletV5 = MethodUtils.fallbackOnException(
        () => VersionedWalletV5Operaion.deserialize(slice: slice, chainId: chainId));
    if (walletV5 != null) {
      BigInt tonAmount = BigInt.zero;
      if (walletV5.type == VersionedWalletV5OperaionType.internal) {
        final internalMessage = walletV5 as VersionedWalletV5Internal;
        final sendMessageActions =
            internalMessage.message.actions.whereType<OutActionSendMsg>();
        tonAmount = sendMessageActions.fold(BigInt.zero, (p, c) {
          if (c.outMessage.info.type == CommonMessageInfoRelaxedType.internal) {
            final internalRelaxed =
                c.outMessage.info.cast<CommonMessageInfoRelaxedInternal>();
            return p + internalRelaxed.value.coins;
          }
          return p + BigInt.zero;
        });
      }
      return ContractTonTransactionPayload(
          payload: payload,
          content: walletV5.toJson(),
          type: TonWeb3TransactionPayloadType.walletV5,
          operation: walletV5.type.name,
          tonAmount: tonAmount);
    }
    slice.reset();
    final jettonWallet = MethodUtils.fallbackOnException(() {
      return JettonWalletOperation.deserialize(slice);
    });
    if (jettonWallet != null) {
      BigInt? jettonAmount;
      if (jettonWallet.type == JettonWalletOperationType.transfer) {
        jettonAmount = jettonWallet.cast<JettonWalletTransfer>().amount;
      }
      return ContractTonTransactionPayload(
          payload: payload,
          content: jettonWallet.toJson(),
          jettonAmount: jettonAmount,
          type: jettonWallet.type == JettonWalletOperationType.transfer
              ? TonWeb3TransactionPayloadType.transfer
              : TonWeb3TransactionPayloadType.jetton,
          operation: jettonWallet.type.name);
    }
    slice.reset();
    final stableJettonWallet = MethodUtils.fallbackOnException(
        () => StableJettonWalletOperation.deserialize(slice));
    if (stableJettonWallet != null) {
      BigInt? jettonAmount;
      if (stableJettonWallet.type == StableJettonWalletOperationType.transfer) {
        jettonAmount = stableJettonWallet.cast<StableJettonWalletTransfer>().jettonAmount;
      }
      return ContractTonTransactionPayload(
          payload: payload,
          content: stableJettonWallet.toJson(),
          jettonAmount: jettonAmount,
          type: stableJettonWallet.type == StableJettonWalletOperationType.transfer
              ? TonWeb3TransactionPayloadType.transfer
              : TonWeb3TransactionPayloadType.jetton,
          operation: stableJettonWallet.type.name);
    }
    slice.reset();
    final jettonMinter =
        MethodUtils.fallbackOnException(() => JettonMinterOperation.deserialize(slice));
    if (jettonMinter != null) {
      return ContractTonTransactionPayload(
          payload: payload,
          content: jettonMinter.toJson(),
          type: TonWeb3TransactionPayloadType.minter,
          operation: jettonMinter.type.name);
    }
    slice.reset();
    final stableJettonMinter = MethodUtils.fallbackOnException(
        () => StableJettonMinterOperation.deserialize(slice));
    if (stableJettonMinter != null) {
      return ContractTonTransactionPayload(
          payload: payload,
          content: stableJettonMinter.toJson(),
          type: TonWeb3TransactionPayloadType.minter,
          operation: stableJettonMinter.type.name);
    }
    slice.reset();
    final nftCollection =
        MethodUtils.fallbackOnException(() => NFTCollectionOperation.deserialize(slice));
    if (nftCollection != null) {
      return ContractTonTransactionPayload(
          payload: payload,
          content: nftCollection.toJson(),
          type: TonWeb3TransactionPayloadType.nft,
          operation: nftCollection.type.name);
    }
    slice.reset();
    final nftItem =
        MethodUtils.fallbackOnException(() => NFTItemOperation.deserialize(slice));
    if (nftItem != null) {
      return ContractTonTransactionPayload(
          payload: payload,
          content: nftItem.toJson(),
          type: TonWeb3TransactionPayloadType.nft,
          operation: nftItem.type.name);
    }
    return UnknownTonTransactionPayload(payload: payload);
  }

  T cast<T extends TonWeb3TransactionPayload>() {
    return this as T;
  }
}

class UnknownTonTransactionPayload extends TonWeb3TransactionPayload {
  UnknownTonTransactionPayload({required super.payload})
      : super(contentJson: {
          _TonWeb3TransactionPayloadConst.payloadKey: payload.toBase64()
        });

  @override
  TonWeb3TransactionPayloadType get type => TonWeb3TransactionPayloadType.unknown;
}

class CommentTonTransactionPayload extends TonWeb3TransactionPayload {
  CommentTonTransactionPayload(
      {required super.payload, required this.type, required String content})
      : assert(type.isCommet, "Invalid comment type. ${type.name}"),
        super(contentJson: {
          _TonWeb3TransactionPayloadConst.payloadKey: payload.toBase64(),
          _TonWeb3TransactionPayloadConst.commentKey: content
        });

  @override
  TonWeb3TransactionPayloadType type;
}

class ContractTonTransactionPayload extends TonWeb3TransactionPayload {
  ContractTonTransactionPayload(
      {required super.payload,
      required Map<String, dynamic> content,
      required this.type,
      required this.operation,
      this.jettonAmount,
      super.tonAmount})
      : super(contentJson: {
          _TonWeb3TransactionPayloadConst.payloadKey: payload.toBase64(),
          _TonWeb3TransactionPayloadConst.operationKey: operation,
          ...content
        });
  final BigInt? jettonAmount;

  // Map<String, dynamic> content;
  final String operation;
  @override
  final TonWeb3TransactionPayloadType type;
}

class JettonContractTonTransactionPayload extends TonWeb3TransactionPayload {
  JettonContractTonTransactionPayload(
      {required super.payload,
      required this.token,
      required this.type,
      required this.operation,
      required Map<String, dynamic> content,
      required BigInt? transferAmount,
      required super.tonAmount,
      required this.isAccountJetton})
      : assert(
            type == TonWeb3TransactionPayloadType.jetton ||
                type == TonWeb3TransactionPayloadType.transfer,
            "Invalid type. ${type.name}"),
        amount = transferAmount == null
            ? null
            : IntegerBalance.token(transferAmount, token.token),
        super(contentJson: {
          _TonWeb3TransactionPayloadConst.payloadKey: payload.toBase64(),
          _TonWeb3TransactionPayloadConst.operationKey: operation,
          ...content
        });

  final IntegerBalance? amount;
  final String operation;
  @override
  final TonWeb3TransactionPayloadType type;
  final TonJettonToken token;
  final bool? isAccountJetton;
}

class TonWeb3TransactionMessageInfo {
  final IntegerBalance amount;
  final ReceiptAddress<TonAddress> destination;
  final TonWeb3TransactionPayload? payload;
  final String? initState;

  const TonWeb3TransactionMessageInfo._(
      {required this.amount, required this.destination, this.payload, this.initState});
  factory TonWeb3TransactionMessageInfo(
      {required BigInt amount,
      required ReceiptAddress<TonAddress> destination,
      required WalletTonNetwork network,
      TonWeb3TransactionPayload? payload,
      StateInit? initState}) {
    return TonWeb3TransactionMessageInfo._(
        amount: IntegerBalance.token(amount, network.token),
        destination: destination,
        initState: initState?.serialize().toBase64(),
        payload: payload);
  }

  MessageRelaxed toMessage() {
    return TonHelper.internal(
      destination: destination.networkAddress,
      amount: amount.balance,
      body: payload?.payload,
      initState: initState == null
          ? null
          : StateInit.deserialize(Cell.fromBase64(initState!).beginParse()),
      bounce: destination.networkAddress.isBounceable,
    );
  }
}

class TonWeb3TransactionInfo {
  final List<TonWeb3TransactionMessageInfo> messages;
  TonWeb3TransactionInfo({required List<TonWeb3TransactionMessageInfo> messages})
      : messages = messages.immutable;
}

extension ExtMessageRelaxedContent on MessageRelaxed {
  Map<String, dynamic> toJson() {
    return {};
  }
}
