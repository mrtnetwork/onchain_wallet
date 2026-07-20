import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/models/networks/monero/account/account.dart';
import 'package:on_chain_wallet/wallet/models/networks/monero/syncing/sync_account.dart';
import 'package:on_chain_wallet/wallet/models/others/models/utxo_timelock.dart';

class MoneroUtxo with AppSerialization, Equality {
  final BigInt globalIndex;
  final MoneroUtxoSpendableStatus status;
  late final String keyImage = output.keyImageAsHex;
  final MoneroUnlockedOutput output;
  final String txId;
  final int blockHeight;

  BigInt get amount => output.amount;
  @override
  List<dynamic> get variables => [output.realIndex, txId];
  MoneroUtxo({
    required this.globalIndex,
    required this.output,
    required String txId,
    required this.blockHeight,
    this.status = MoneroUtxoSpendableStatus.ready,
  }) : txId = StringUtils.normalizeHex(txId);
  factory MoneroUtxo.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.moneroUtxo,
        cborBytes: bytes,
        cborObject: object);
    return MoneroUtxo(
        output: MoneroUnlockedOutput.deserialize(values.rawValueAt(0)),
        txId: values.rawValueAt(1),
        globalIndex: values.rawValueAt(2),
        blockHeight: values.rawValueAt(3),
        status: MoneroUtxoSpendableStatus.fromValue(values.rawValueAt(4)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.moneroUtxo;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(output.serialize()),
        txId.toCbor(),
        globalIndex.toCbor(),
        blockHeight.toCbor(),
        status.value.toCbor()
      ];
  @override
  String toString() {
    return "MoneroUtxo({txId:$txId, index:${output.realIndex}, })";
  }
}

enum MoneroUtxoSpendableStatus {
  /// Unknown global index.
  notReady(0),

  /// ready to spend
  ready(1),

  /// spended and now this is in mempool and should be removed
  spended(2);

  final int value;
  const MoneroUtxoSpendableStatus(this.value);
  static MoneroUtxoSpendableStatus fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw AppInternalError.internalError("MoneroUtxoSpendableStatus",
          details: {"value": value?.toString()}),
    );
  }

  bool get isReady => this == ready;
}

class MoneroUtxoWithSpendingInfo with AppSerialization, PartialEquality {
  final MoneroUtxo utxo;
  final UtxoTimelock confirmation;
  BigInt get amount => utxo.amount;
  bool get coinbase => utxo.output.coinbase;

  MoneroUtxoWithSpendingInfo({
    required this.utxo,
    required this.confirmation,
  });
  factory MoneroUtxoWithSpendingInfo.unconfirmed(MoneroUtxo utxo) {
    return MoneroUtxoWithSpendingInfo(
      utxo: utxo,
      confirmation: UtxoTimelock.unknown(),
    );
  }

  factory MoneroUtxoWithSpendingInfo.fromBlockHeight(MoneroUtxo utxo, int height) {
    final unlocktime = utxo.output.getUnlockTime();
    final timelock = switch (unlocktime) {
      MoneroOutputUnlockTimeNone() => UtxoTimelockBlock(
          utxoBlock: utxo.blockHeight, currentHeight: height, minConfirmation: 10),
      MoneroOutputUnlockTimeHeight(height: final unlockHeight) => UtxoTimelockBlock(
          utxoBlock: utxo.blockHeight,
          currentHeight: height,
          minConfirmation: IntUtils.max(unlockHeight - height, 0)),
      MoneroOutputUnlockTimeTimestamp(:final unlockTimeUtc) => UtxoTimelockTimestamp(
          utxoConfirmedTime: unlockTimeUtc, averageBlocktimeSeconds: 120, useMtp: false),
    };
    return MoneroUtxoWithSpendingInfo(
      utxo: utxo,
      confirmation: timelock,
    );
  }

  String txId() => utxo.txId;

  MoneroLockedPayment toLockedPayment() {
    final lockedOutput = utxo.output;
    return MoneroLockedPayment(
        output: MoneroLockedOutput(
            amount: utxo.amount,
            coinbase: lockedOutput.coinbase,
            derivation: lockedOutput.derivation,
            mask: lockedOutput.mask,
            outputPublicKey: lockedOutput.outputPublicKey,
            accountIndex: lockedOutput.accountIndex,
            unlockTime: lockedOutput.unlockTime,
            realIndex: lockedOutput.realIndex),
        txPubkey: lockedOutput.outputPublicKey,
        paymentId: null,
        encryptedPaymentid: null,
        globalIndex: utxo.globalIndex);
  }

  MoneroUnLockedPayment toUnlockedFakePayment() {
    final lockedOutput = utxo.output;
    return MoneroUnLockedPayment(
        output: MoneroUnlockedOutput(
            amount: lockedOutput.amount,
            coinbase: lockedOutput.coinbase,
            derivation: lockedOutput.derivation,
            ephemeralSecretKey: RCT.identity(clone: false),
            ephemeralPublicKey: lockedOutput.outputPublicKey,
            keyImage: TxKeyImage(RCT.identity(clone: false)),
            mask: lockedOutput.mask,
            outputPublicKey: lockedOutput.outputPublicKey,
            accountIndex: lockedOutput.accountIndex,
            unlockTime: lockedOutput.unlockTime,
            realIndex: lockedOutput.realIndex),
        txPubkey: lockedOutput.outputPublicKey,
        paymentId: null,
        encryptedPaymentid: null,
        globalIndex: utxo.globalIndex);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag2;

  @override
  List<CborObject?> get serializationItems => [utxo.toCbor()];

  @override
  List<dynamic> get parts => [utxo];

  @override
  String toString() {
    return "Utxo: $utxo";
  }
}

class MoneroUtxosWithAccountInfo with AppSerialization {
  final MoneroAccountIndex account;
  final List<MoneroUtxoWithSpendingInfo> utxos;
  MoneroUtxosWithAccountInfo._(
      {required this.account, required List<MoneroUtxoWithSpendingInfo> utxos})
      : utxos = utxos.immutable;
  factory MoneroUtxosWithAccountInfo(
      {required MoneroAccountIndex account,
      required List<MoneroUtxoWithSpendingInfo> utxos}) {
    return MoneroUtxosWithAccountInfo._(account: account, utxos: utxos);
  }

  MoneroUtxosWithAccountInfo updateUtxosConfirmation(int height) {
    return MoneroUtxosWithAccountInfo(
        account: account,
        utxos: utxos
            .map((e) => MoneroUtxoWithSpendingInfo.fromBlockHeight(e.utxo, height))
            .toList());
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag2;

  @override
  List<CborObject?> get serializationItems => [
        account.toCbor(),
        AppSerialization.listFromObjects(utxos.map((e) => e.toCbor()).toList())
      ];

  @override
  String toString() {
    return utxos.join(", ");
  }
}

sealed class MoneroAccountTxTrackerStatus with AppSerialization {
  final String txId;
  MoneroAccountTxTrackerStatus({required String txId})
      : txId = StringUtils.normalizeHex(txId);
  factory MoneroAccountTxTrackerStatus.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final decode = AppSerialization.decodeTaggedValueWithInfo(expectedTags: [
      AppSerializationIdentifier.runtimeTag3,
      AppSerializationIdentifier.runtimeTag2,
      AppSerializationIdentifier.runtimeTag
    ], cborBytes: bytes, cborObject: object);
    return switch (decode.identifier) {
      AppSerializationIdentifier.runtimeTag3 =>
        MoneroAccountTxTrackerSpended.deserialize(object: decode.tag),
      AppSerializationIdentifier.runtimeTag2 =>
        MoneroAccountTxTrackerNotFound.deserialize(object: decode.tag),
      AppSerializationIdentifier.runtimeTag =>
        MoneroAccountTxTrackerUtxo.deserialize(object: decode.tag),
      _ =>
        throw AppInternalError.internalError("MoneroAccountTxTrackerStatus.deserialize")
    };
  }
}

class MoneroAccountTxTrackerUtxo extends MoneroAccountTxTrackerStatus {
  final MoneroAccountIndex index;
  final MoneroUtxo utxo;
  MoneroAccountTxTrackerUtxo(
      {required super.txId, required this.utxo, required this.index});
  factory MoneroAccountTxTrackerUtxo.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return MoneroAccountTxTrackerUtxo(
      index: MoneroAccountIndex.deserialize(object: values.objectAt(0)),
      txId: values.rawValueAt(1),
      utxo: MoneroUtxo.deserialize(object: values.objectAt(2)),
    );
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [index.toCbor(), txId.toCbor(), utxo.toCbor()];
}

class MoneroAccountTxTrackerNotFound extends MoneroAccountTxTrackerStatus {
  final bool inMempool;
  final bool noAccountUtxos;
  final bool hasError;
  MoneroAccountTxTrackerNotFound({
    required super.txId,
    this.inMempool = false,
    this.noAccountUtxos = false,
    this.hasError = false,
  });
  factory MoneroAccountTxTrackerNotFound.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag2,
        cborBytes: bytes,
        cborObject: object);
    return MoneroAccountTxTrackerNotFound(
        txId: values.rawValueAt(0),
        inMempool: values.rawValueAt(1),
        noAccountUtxos: values.rawValueAt(2),
        hasError: values.rawValueAt(3));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag2;

  @override
  List<CborObject?> get serializationItems =>
      [txId.toCbor(), inMempool.toCbor(), noAccountUtxos.toCbor(), hasError.toCbor()];
}

class MoneroAccountTxTrackerSpended extends MoneroAccountTxTrackerStatus {
  final TxKeyImage keyImage;
  MoneroAccountTxTrackerSpended({
    required super.txId,
    required this.keyImage,
  });
  factory MoneroAccountTxTrackerSpended.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag3,
        cborBytes: bytes,
        cborObject: object);
    return MoneroAccountTxTrackerSpended(
      txId: values.rawValueAt(1),
      keyImage: TxKeyImage.deserialize(obj: values.objectAt(1)),
    );
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag3;

  @override
  List<CborObject?> get serializationItems => [txId.toCbor(), keyImage.toCbor()];
}

class MoneroAccountTxTrackerResponse extends AppSerialization {
  final List<MoneroAccountTxTrackerStatus> txes;
  final int height;
  MoneroAccountTxTrackerResponse({
    required List<MoneroAccountTxTrackerStatus> txes,
    required this.height,
  }) : txes = txes.immutable;
  factory MoneroAccountTxTrackerResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return MoneroAccountTxTrackerResponse(
        txes: values
            .listAt<CborTagValue>(0)
            .map((e) => MoneroAccountTxTrackerStatus.deserialize(object: e))
            .toList(),
        height: values.rawValueAt(1));
  }

  List<MoneroSyncAccountIndex> toSyncAccounts() {
    Map<MoneroAccountIndex, MoneroSyncAccountIndex> accounts = {};
    final utxos = txes.whereType<MoneroAccountTxTrackerUtxo>().toList();
    for (final i in utxos) {
      final syncIndex =
          accounts[i.index] ??= MoneroSyncAccountIndex(index: i.index, startHeight: 0);
      syncIndex.addUtxo(i.utxo);
    }
    return accounts.values.toList();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(txes.map((e) => e.toCbor()).toList()),
        height.toCbor()
      ];
}
