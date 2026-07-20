import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/networks/types/address.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/ada.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/aptos.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/bitcoin.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/cosmos.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/ethereum.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/monero.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/solana.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/stellar.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/substrate.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/sui.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/ton.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/tron.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/xrp.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/zcash.dart';

enum WalletTransactionType {
  send(0),

  web3(1),
  web3Sign(2),
  web3Tx(3),
  receive(4);

  final int value;
  const WalletTransactionType(this.value);
  static WalletTransactionType fromValue(int? value) {
    return values.firstWhere((e) => e.value == value,
        orElse: () => throw AppInternalError.internalError("WalletTransactionType"));
  }
}

class WalletAccountTransactions<TRANSACTION extends ChainTransaction> {
  List<TRANSACTION> _transactions;
  List<TRANSACTION> get transactions => _transactions;
  bool _havePendingTxes = false;
  bool get havePendingTxes => _havePendingTxes;
  WalletAccountTransactions._({required List<TRANSACTION> transactions})
      : _transactions = transactions.immutable,
        _havePendingTxes = transactions.any((e) => e.status.inMempool);

  List<TRANSACTION> get pendingTxes =>
      _transactions.where((e) => e.status.inMempool).toList();
  factory WalletAccountTransactions({required List<TRANSACTION> transactions}) {
    final txes = transactions.clone();
    txes.sort((a, b) => b.time.compareTo(a.time));
    return WalletAccountTransactions._(transactions: txes);
  }
  bool updateTx(TRANSACTION tx) {
    if (!_transactions.contains(tx)) return false;
    _addTx(tx);
    return true;
  }

  bool addTx(TRANSACTION tx) {
    _addTx(tx);
    return true;
  }

  void _addTx(TRANSACTION tx) {
    List<TRANSACTION> txes = _transactions.clone();
    if (_transactions.contains(tx)) {
      txes.remove(tx);
      txes = [tx, ...txes];
    } else {
      txes.add(tx);
    }
    txes.sort((a, b) => b.time.compareTo(a.time));
    _transactions = txes.toSet().toImutableList;
    _havePendingTxes = _transactions.any((e) => e.status.inMempool);
  }

  void removeTx(TRANSACTION tx) {
    final txes = _transactions.clone();
    txes.remove(tx);
    // txes.sort((a, b) => a.time.compareTo(b.time));
    _transactions = txes.immutable;
    _havePendingTxes = _transactions.any((e) => e.status.inMempool);
  }

  TRANSACTION? byTxId(String txId, {List<WalletTransactionType>? types}) {
    if (StringUtils.isHexBytes(txId)) {
      txId = StringUtils.normalizeHex(txId);
    }
    return switch (types) {
      List<WalletTransactionType> types =>
        _transactions.firstWhereOrNull((e) => e.txId == txId && types.contains(e.type)),
      _ => _transactions.firstWhereOrNull((e) => e.txId == txId)
    };
  }
}

class WalletWeb3ClientTransaction with AppSerialization {
  final String name;
  final String applicationId;
  final APPImage? image;
  const WalletWeb3ClientTransaction(
      {required this.name, required this.applicationId, required this.image});

  factory WalletWeb3ClientTransaction.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.transactionWeb3Client);
    return WalletWeb3ClientTransaction(
        name: values.rawValueAt(0),
        applicationId: values.rawValueAt(1),
        image: values.maybeObjectAt<APPImage, CborTagValue>(
            2, (e) => APPImage.deserialize(object: e)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.transactionWeb3Client;
  @override
  List<CborObject?> get serializationItems =>
      [name.toCbor(), applicationId.toCbor(), image?.toCbor()];
}

enum WalletTransactionStatus {
  pending(0),
  block(1),
  failed(2),
  unknown(3);

  final int value;
  const WalletTransactionStatus(this.value);

  bool get inMempool => this == pending;
  bool get isUnknown => this == unknown;
  bool get inBlock => this == block;

  static WalletTransactionStatus fromValue(int? value) {
    return values.firstWhere((e) => e.value == value,
        orElse: () => throw AppInternalError.internalError("WalletTransactionStatus"));
  }
}

abstract class ChainTransaction<OUTPUTS extends WalletTransactionOutput>
    with AppSerialization, Equality {
  final WalletTransactionType type;
  final String txId;
  final DateTime time;
  final WalletTransactionAmount? totalOutput;
  final List<OUTPUTS> outputs;
  final List<WalletTransactionInput> inputs;
  final WalletWeb3ClientTransaction? web3Client;
  final List<WalletTransactionMemo> memos;
  WalletTransactionStatus _status;
  WalletTransactionStatus get status => _status;

  ChainTransaction(
      {required this.txId,
      DateTime? time,
      this.web3Client,
      required WalletTransactionAmount? totalOutput,
      List<OUTPUTS> outputs = const [],
      List<WalletTransactionInput> inputs = const [],
      List<WalletTransactionMemo> memos = const [],
      required WalletTransactionStatus status,
      this.type = WalletTransactionType.send})
      : outputs = outputs.immutable,
        inputs = inputs.immutable,
        _status = status,
        time = time ?? DateTime.now(),
        memos = memos.immutable,
        totalOutput = (totalOutput?.amount.isZero ?? true) ? null : totalOutput,
        assert(type != WalletTransactionType.send || web3Client == null);
  static T deserialize<T extends ChainTransaction>(WalletNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final transaction = switch (network.type) {
      NetworkType.cardano =>
        ADAWalletTransaction.deserialize(network.cast(), bytes: bytes, object: object),
      NetworkType.aptos =>
        AptosWalletTransaction.deserialize(network.cast(), bytes: bytes, object: object),
      NetworkType.bitcoinAndForked ||
      NetworkType.bitcoinCash =>
        BitcoinWalletTransaction.deserialize(network.cast(),
            bytes: bytes, object: object),
      NetworkType.cosmos =>
        CosmosWalletTransaction.deserialize(network.cast(), bytes: bytes, object: object),
      NetworkType.ethereum =>
        EthWalletTransaction.deserialize(network.cast(), bytes: bytes, object: object),
      NetworkType.monero =>
        MoneroWalletTransaction.deserialize(network.cast(), bytes: bytes, object: object),
      NetworkType.solana =>
        SolanaWalletTransaction.deserialize(network.cast(), bytes: bytes, object: object),
      NetworkType.stellar => StellarWalletTransaction.deserialize(network.cast(),
          bytes: bytes, object: object),
      NetworkType.substrate => SubstrateWalletTransaction.deserialize(network.cast(),
          bytes: bytes, object: object),
      NetworkType.sui =>
        SuiWalletTransaction.deserialize(network.cast(), bytes: bytes, object: object),
      NetworkType.ton =>
        TonWalletTransaction.deserialize(network.cast(), bytes: bytes, object: object),
      NetworkType.tron =>
        TronWalletTransaction.deserialize(network.cast(), bytes: bytes, object: object),
      NetworkType.xrpl =>
        XRPWalletTransaction.deserialize(network.cast(), bytes: bytes, object: object),
      NetworkType.zcash =>
        ZcashWalletTransaction.deserialize(network.cast(), bytes: bytes, object: object),
    };
    if (transaction is! T) {
      throw AppInternalError.internalError("ChainTransaction");
    }
    return transaction;
  }

  void updateStatus(WalletTransactionStatus status) {
    if (_status != WalletTransactionStatus.pending ||
        status == WalletTransactionStatus.pending) {
      return;
    }
    _status = status;
  }

  NetworkType get network;

  @override
  List get variables => [txId, type];

  String get storageIdentifier => switch (type) {
        WalletTransactionType.send || WalletTransactionType.web3Tx => txId,
        _ => "${type.value}_$txId"
      };
  @override
  SerializationIdentifier get serializationIdentifier => network.identifier;
  @override
  List<CborObject?> get serializationItems => [
        CborStringValue(txId),
        CborEpochFloatValue(time),
        totalOutput?.toCbor(),
        CborListValue.definite(outputs.map((e) => e.toCbor()).toList()),
        web3Client?.toCbor(),
        CborIntValue(type.value),
        CborIntValue(status.value),
        CborListValue.definite(inputs.map((e) => e.toCbor()).toList()),
        CborListValue.definite(memos.map((e) => e.toCbor()).toList()),
      ];
}

enum WalletTransactionOutputType {
  transfer(AppSerializationIdentifier.transactionOutputTransfer),
  contract(AppSerializationIdentifier.transactionOutputOperation),
  operation(AppSerializationIdentifier.transactionOutputContract);

  const WalletTransactionOutputType(this.tag);
  final AppSerializationIdentifier tag;

  static WalletTransactionOutputType fromTag(List<int>? tags) {
    return values.firstWhere((e) => e.tag.isValidTags(tags),
        orElse: () =>
            throw AppInternalError.internalError("WalletTransactionOutputType"));
  }
}

enum WalletTransactionInputType {
  operation(AppSerializationIdentifier.transactionInputOperation);

  const WalletTransactionInputType(this.tag);
  final AppSerializationIdentifier tag;

  static WalletTransactionInputType fromTag(List<int>? tags) {
    return values.firstWhere((e) => e.tag.isValidTags(tags),
        orElse: () =>
            throw AppInternalError.internalError("WalletTransactionOutputType"));
  }
}

enum WalletTransactionMemoType {
  binary(AppSerializationIdentifier.transactionMemoBinary),
  string(AppSerializationIdentifier.transactionMemoString);

  const WalletTransactionMemoType(this.tag);
  final AppSerializationIdentifier tag;

  static WalletTransactionMemoType fromTag(int? tags) {
    return values.firstWhere((e) => e.tag.isValidIdentifier(tags),
        orElse: () =>
            throw AppInternalError.internalError("WalletTransactionOutputType"));
  }
}

class WalletTransactionMemo with AppSerialization {
  final String memo;
  final WalletTransactionMemoType type;
  const WalletTransactionMemo._({required this.memo, required this.type});
  factory WalletTransactionMemo.deserialize({List<int>? bytes, CborObject? object}) {
    final decode = AppSerialization.decodeTaggedValueWithInfo(
        cborObject: object,
        cborBytes: bytes,
        expectedTags: [
          AppSerializationIdentifier.transactionMemoBinary,
          AppSerializationIdentifier.transactionMemoString,
        ]);
    final type = WalletTransactionMemoType.fromTag(decode.identifier.id);
    return switch (type) {
      WalletTransactionMemoType.binary =>
        WalletTransactionMemo.binary(decode.values.rawValueAt(0)),
      WalletTransactionMemoType.string =>
        WalletTransactionMemo.string(decode.values.rawValueAt(0)),
    };
  }
  factory WalletTransactionMemo(List<int> bytes) {
    final toString = StringUtils.tryDecode(bytes);
    return WalletTransactionMemo._(
        memo: toString ?? BytesUtils.toHexString(bytes),
        type: switch (toString) {
          null => WalletTransactionMemoType.binary,
          _ => WalletTransactionMemoType.string,
        });
  }
  factory WalletTransactionMemo.binary(List<int> bytes) {
    return WalletTransactionMemo._(
        memo: BytesUtils.toHexString(bytes), type: WalletTransactionMemoType.binary);
  }
  factory WalletTransactionMemo.from(String memo, WalletTransactionMemoType type) {
    return WalletTransactionMemo._(memo: memo, type: type);
  }
  factory WalletTransactionMemo.string(List<int> bytes) {
    return WalletTransactionMemo._(
        memo: StringUtils.decode(bytes), type: WalletTransactionMemoType.string);
  }
  factory WalletTransactionMemo.fromString(String memo) {
    return WalletTransactionMemo._(memo: memo, type: WalletTransactionMemoType.string);
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems => [
        switch (type) {
          WalletTransactionMemoType.binary => BytesUtils.fromHexString(memo),
          WalletTransactionMemoType.string => StringUtils.encode(memo),
        }
            .toCborBytes()
      ];
}

abstract class WalletTransactionOutput with AppSerialization {
  final WalletTransactionOutputType type;
  final WalletTransactionMemo? memo;
  const WalletTransactionOutput({required this.type, this.memo});
}

abstract class WalletTransactionInput with AppSerialization {
  final WalletTransactionInputType type;
  const WalletTransactionInput({required this.type});
}

abstract class WalletTransactionOperationInput<NETWORKADDRESS extends IAddress>
    extends WalletTransactionInput {
  String get addressStr;
  final String operation;
  NETWORKADDRESS get address;

  const WalletTransactionOperationInput({required this.operation})
      : super(type: WalletTransactionInputType.operation);
}

abstract class WalletTransactionOperationOutput extends WalletTransactionOutput {
  final String name;
  final String? content;
  final WalletTransactionAmount? amount;
  const WalletTransactionOperationOutput(
      {required this.name, this.content, this.amount, super.memo})
      : super(type: WalletTransactionOutputType.operation);

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;
}

abstract class WalletTransactionTransferOutput<NETWORKADDRESS extends IAddress>
    extends WalletTransactionOutput {
  final NETWORKADDRESS to;
  final WalletTransactionAmount amount;
  String get address;

  const WalletTransactionTransferOutput(
      {required this.to, required this.amount, super.memo})
      : super(type: WalletTransactionOutputType.transfer);
  @override
  SerializationIdentifier get serializationIdentifier => type.tag;
}

enum WalletTransactionAmountType {
  integer(AppSerializationIdentifier.transactionIntegerAmount),
  decimals(AppSerializationIdentifier.transactionDecimalsAmount);

  final AppSerializationIdentifier tag;
  const WalletTransactionAmountType(this.tag);

  static WalletTransactionAmountType fromTag(List<int>? tags) {
    return values.firstWhere((e) => e.tag.isValidTags(tags),
        orElse: () =>
            throw AppInternalError.internalError("WalletTransactionAmountType"));
  }
}

abstract class WalletTransactionAmount<AMOUNT extends BalanceCore, TOKEN extends APPToken>
    with AppSerialization {
  final AMOUNT amount;
  final TOKEN? token;
  final String? tokenIdentifier;
  final WalletTransactionAmountType type;
  bool get isNativeToken => token == null;
  const WalletTransactionAmount(
      {required this.amount,
      required this.token,
      required this.tokenIdentifier,
      required this.type});

  factory WalletTransactionAmount.deserialize(WalletNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborTagValue values =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    final type = WalletTransactionAmountType.fromTag(values.tags);
    final WalletTransactionAmount amount = switch (type) {
      WalletTransactionAmountType.integer =>
        WalletTransactionIntegerAmount.deserialize(network, bytes: bytes, object: object),
      WalletTransactionAmountType.decimals =>
        WalletTransactionDecimalsAmount.deserialize(bytes: bytes, object: object),
    };
    if (amount is! WalletTransactionAmount<AMOUNT, TOKEN>) {
      throw AppInternalError.internalError("WalletTransactionAmount");
    }
    return amount;
  }
}

class WalletTransactionIntegerAmount
    extends WalletTransactionAmount<IntegerBalance, Token> {
  WalletTransactionIntegerAmount(
      {required BigInt amount,
      required WalletNetwork network,
      super.token,
      super.tokenIdentifier})
      : super(
            type: WalletTransactionAmountType.integer,
            amount: IntegerBalance.token(amount, token ?? network.token,
                allowNegative: false, immutable: true));
  factory WalletTransactionIntegerAmount.deserialize(WalletNetwork network,
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletTransactionAmountType.integer.tag);
    return WalletTransactionIntegerAmount(
        amount: values.rawValueAt(0),
        token: values.maybeObjectAt<Token, CborTagValue>(
            1, (e) => Token.deserialize(object: e)),
        tokenIdentifier: values.rawValueAt(2),
        network: network);
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems =>
      [amount.balance.toCbor(), token?.toCbor(), tokenIdentifier?.toCbor()];
}

class WalletTransactionDecimalsAmount
    extends WalletTransactionAmount<DecimalBalance, NonDecimalToken> {
  WalletTransactionDecimalsAmount(
      {required String amount,
      required NonDecimalToken super.token,
      super.tokenIdentifier})
      : super(
            type: WalletTransactionAmountType.decimals,
            amount: DecimalBalance.fromString(amount, token));
  factory WalletTransactionDecimalsAmount.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletTransactionAmountType.decimals.tag);
    return WalletTransactionDecimalsAmount(
        amount: values.rawValueAt(0),
        token: NonDecimalToken.deserialize(object: values.objectAt<CborTagValue>(1)),
        tokenIdentifier: values.rawValueAt(2));
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems =>
      [amount.price.toCbor(), token?.toCbor(), tokenIdentifier?.toCbor()];
}
