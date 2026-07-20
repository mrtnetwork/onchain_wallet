import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/repository/types/storage.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/account.dart';
import 'package:on_chain_wallet/wallet/models/others/models/utxo_timelock.dart';
import 'package:zcash_dart/zcash.dart';

class ZcashUtxoConst {
  static const int minCoinbaseConfirmation = 100;
  static const int zcashAvarageBlockTimeSeconds = 20;
}

sealed class ZcashUtxo<ZUTXO extends Object>
    with AppSerialization, Equality
    implements StorageKeyIdentifier {
  final BigInt amount;
  final ZcashAccountInfoType type;
  final ZUTXO utxo;
  final ZcashUtxoSpendableStatus status;
  int get blockHeight;
  ZcashProtocol get protocol => type.protocol;

  UtxoTimelock timelock(int currentHeight);
  const ZcashUtxo(
      {required this.amount,
      required this.type,
      required this.utxo,
      required this.status});
  factory ZcashUtxo.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValueWithInfo(
        cborBytes: bytes,
        cborObject: object,
        expectedTags: ZcashAccountInfoType.values.map((e) => e.tag).toList());
    final type = ZcashAccountInfoType.fromIdentifier(values.identifier.id);
    final ZcashUtxo utxo = switch (type) {
      ZcashAccountInfoType.p2pkh => ZcashUtxoTransparent.deserialize(object: values.tag),
      ZcashAccountInfoType.orchard => ZcashUtxoOrchard.deserialize(object: values.tag),
      ZcashAccountInfoType.sapling => ZcashUtxoSapling.deserialize(object: values.tag),
      _ => throw WalletExceptionConst.invalidAccountData("Invalid zcash account data")
    };
    return utxo.cast();
  }

  T cast<T extends ZcashUtxo>() {
    if (this is! T) {
      throw AppInternalError.internalError("Failed to cast ZcashUtxo");
    }
    return this as T;
  }

  // @override
  // List<dynamic> get variables => [amount, type, utxo];
  @override
  String get storageIdentifier;
  ZcashTxId txId();
  bool get coinbase => false;

  @override
  String toString() {
    return "Utxo ${protocol.name}/${txId().txId}/$amount ";
  }
}

sealed class ZcashUtxoShield<ZUTXO extends ScannedOutputWithNullifier>
    extends ZcashUtxo<ZUTXO> {
  ZcashUtxoShield(
      {required super.amount,
      required super.type,
      required super.utxo,
      required super.status});
  factory ZcashUtxoShield.deserialize({List<int>? bytes, CborObject? object}) {
    return ZcashUtxo.deserialize(bytes: bytes, object: object).cast();
  }

  Nullifier get nullifier => utxo.nullifier;

  ZcashUtxoShield withoutMemo({ZcashUtxoSpendableStatus? status});

  ZcashUtxoShield updateStatus(ZcashUtxoSpendableStatus status);

  @override
  UtxoTimelock timelock(int _) {
    return UtxosTimelockConfirmed();
  }

  @override
  String toString() {
    return "Utxo ${BytesUtils.toHexString(nullifier.toBytes())} ${protocol.name}/${txId().txId}/$amount ";
  }
}

enum ZcashUtxoSpendableStatus {
  /// related to shield request tracking and request not completed yet.
  notReady(0),

  /// ready to spend
  ready(1),

  /// spended and now this is in mempool and should be removed
  spended(2);

  final int value;
  const ZcashUtxoSpendableStatus(this.value);
  static ZcashUtxoSpendableStatus fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw AppInternalError.internalError("ZcashUtxoSpendableStatus",
          details: {"value": value?.toString()}),
    );
  }

  bool get isReady => this == ready;
}

class ZcashUtxoTransparent extends ZcashUtxo<TransparentUtxo> {
  @override
  final bool coinbase;
  final int time;
  ZcashUtxoTransparent(
      {required super.utxo,
      required this.coinbase,
      required this.time,
      super.status = ZcashUtxoSpendableStatus.ready})
      : super(type: ZcashAccountInfoType.p2pkh, amount: utxo.amount.value);
  factory ZcashUtxoTransparent.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: ZcashAccountInfoType.p2pkh.tag,
    );
    return ZcashUtxoTransparent(
        utxo: TransparentUtxo.deserialize(values.rawValueAt(0)),
        status: ZcashUtxoSpendableStatus.fromValue(values.rawValueAt(1)),
        coinbase: values.rawValueAt(2),
        time: values.rawValueAt(3));
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(utxo.toSerializeBytes()),
        status.value.toCbor(),
        coinbase.toCbor(),
        time.toCbor()
      ];

  @override
  String get storageIdentifier => utxo.identifier;

  @override
  ZcashTxId txId() {
    return utxo.txId;
  }

  @override
  int get blockHeight => utxo.blockHeight;

  @override
  List<dynamic> get variables => [utxo.txId, utxo.vout];

  @override
  UtxoTimelock timelock(int currentHeight) {
    return UtxoTimelockBlock(
        utxoBlock: blockHeight,
        currentHeight: currentHeight,
        minConfirmation: switch (coinbase) {
          true => ZcashUtxoConst.minCoinbaseConfirmation,
          false => 1,
        });
  }
}

class ZcashUtxoSapling extends ZcashUtxoShield<SaplingScannedOutputWithNullifier> {
  ZcashUtxoSapling({required super.utxo, required super.status})
      : super(type: ZcashAccountInfoType.sapling, amount: utxo.output.amount.value);
  factory ZcashUtxoSapling.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: ZcashAccountInfoType.sapling.tag,
    );
    return ZcashUtxoSapling(
        utxo: SaplingScannedOutputWithNullifier.deserialize(values.rawValueAt(0)),
        status: ZcashUtxoSpendableStatus.fromValue(values.rawValueAt(1)));
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(utxo.toSerializeBytes()), status.value.toCbor()];

  @override
  String get storageIdentifier => utxo.identifier;

  @override
  ZcashTxId txId() {
    return utxo.txId;
  }

  @override
  int get blockHeight => utxo.blockHeight;

  @override
  ZcashUtxoSapling withoutMemo({ZcashUtxoSpendableStatus? status}) {
    return ZcashUtxoSapling(utxo: utxo.withoutMemo(), status: status ?? this.status);
  }

  @override
  ZcashUtxoSapling updateStatus(ZcashUtxoSpendableStatus status) {
    return ZcashUtxoSapling(utxo: utxo, status: status);
  }

  @override
  List<dynamic> get variables => [utxo.txId, utxo.output.index];
}

class ZcashUtxoOrchard extends ZcashUtxoShield<OrchardScannedOutputWithNullifier> {
  ZcashUtxoOrchard({required super.utxo, required super.status})
      : super(type: ZcashAccountInfoType.orchard, amount: utxo.output.amount.value);
  factory ZcashUtxoOrchard.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: ZcashAccountInfoType.orchard.tag,
    );
    return ZcashUtxoOrchard(
        utxo: OrchardScannedOutputWithNullifier.deserialize(values.rawValueAt(0)),
        status: ZcashUtxoSpendableStatus.fromValue(values.rawValueAt(1)));
  }
  @override
  SerializationIdentifier get serializationIdentifier => type.tag;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(utxo.toSerializeBytes()), status.value.toCbor()];

  @override
  String get storageIdentifier => utxo.identifier;

  @override
  ZcashTxId txId() {
    return utxo.txId;
  }

  @override
  int get blockHeight => utxo.blockHeight;

  @override
  ZcashUtxoOrchard withoutMemo({ZcashUtxoSpendableStatus? status}) {
    return ZcashUtxoOrchard(utxo: utxo.withoutMemo(), status: status ?? this.status);
  }

  @override
  ZcashUtxoOrchard updateStatus(ZcashUtxoSpendableStatus status) {
    return ZcashUtxoOrchard(utxo: utxo, status: status);
  }

  @override
  List<dynamic> get variables => [utxo.txId, utxo.output.index];
}

class ZcashTransparentAddressUtxos with AppSerialization {
  Set<ZcashUtxoTransparent> _utxos = {};
  BigInt _totalBalance = BigInt.zero;
  void _updateTotal() {
    _totalBalance = _utxos.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount);
  }

  List<ZcashUtxoTransparent> get utxos => _utxos.toList();

  ZcashTransparentAddressUtxos({Iterable<ZcashUtxoTransparent> utxos = const {}})
      : _utxos = utxos.toSet() {
    _updateTotal();
  }

  factory ZcashTransparentAddressUtxos.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: AppSerializationIdentifier.zcashAddressUtxos,
    );
    return ZcashTransparentAddressUtxos(
        utxos: values
            .listAt<CborTagValue>(0)
            .map((e) => ZcashUtxo.deserialize(object: e).cast()));
  }

  bool updateUtxos(List<ZcashUtxoTransparent> utxos) {
    final cUtxos = _utxos.toList().clone();
    _utxos = utxos.toSet();
    _updateTotal();
    if (cUtxos.length != utxos.length) return true;
    return cUtxos.any((e) => !utxos.contains(e));
  }

  BigInt get totalBalance {
    return _totalBalance;
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.zcashAddressUtxos;

  @override
  List<CborObject?> get serializationItems =>
      [AppSerialization.listFromObjects(_utxos.map((e) => e.toCbor()).toList())];
}

sealed class ZcashTransactionOutput with AppSerialization {
  const ZcashTransactionOutput();
  ZcashProtocol get protocol;
  BigInt get amount;
  ZcashAddress? get address;
  ZcashTransactionMemo? get memo;
  factory ZcashTransactionOutput.deserialize({List<int>? bytes, CborObject? object}) {
    final decode = AppSerialization.decodeTaggedValueWithInfo(
        cborBytes: bytes,
        cborObject: object,
        expectedTags: [
          AppSerializationIdentifier.runtimeTag,
          AppSerializationIdentifier.runtimeTag2
        ]);
    return switch (decode.identifier) {
      AppSerializationIdentifier.runtimeTag =>
        ZcashTransactionOutputShielded.deserialize(object: decode.tag),
      AppSerializationIdentifier.runtimeTag2 =>
        ZcashTransactionOutputTransparent.deserialize(object: decode.tag),
      _ => throw AppInternalError.internalError("ZcashTransactionOutput")
    };
  }
}

final class ZcashTransactionOutputShielded extends ZcashTransactionOutput {
  @override
  final ZcashAddress address;
  @override
  final BigInt amount;
  @override
  final ZcashProtocol protocol;
  @override
  final ZcashTransactionMemoShielded? memo;
  final ZcashAccountInfoShield? change;
  const ZcashTransactionOutputShielded._(
      {required this.address,
      required this.amount,
      required this.protocol,
      this.change,
      this.memo});
  factory ZcashTransactionOutputShielded(
      {required ZcashAddress address,
      required BigInt amount,
      required ZcashProtocol protocol,
      ZcashAccountInfoShield? change,
      ZcashTransactionMemoShielded? memo}) {
    if (!address.supportedProtocols.contains(protocol) || !protocol.sheilded) {
      throw AppInternalError.internalError("Invalid address protocol.");
    }
    if (change != null && change.protocol != protocol) {
      throw AppInternalError.internalError("Invalid change account info.");
    }

    return ZcashTransactionOutputShielded._(
        address: address, amount: amount, protocol: protocol, change: change, memo: memo);
  }
  factory ZcashTransactionOutputShielded.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return ZcashTransactionOutputShielded(
        address: ZcashAddress(values.rawValueAt(0)),
        amount: values.rawValueAt(1),
        protocol: ZcashProtocol.fromValue(values.rawValueAt(2)),
        memo: values.maybeObjectAt<ZcashTransactionMemoShielded, CborTagValue>(
            3, (obj) => ZcashTransactionMemoShielded.deserialize(object: obj)),
        change: values.maybeRawValueAt<ZcashAccountInfoShield, CborObject>(
            4,
            (e) =>
                ZcashAccountInfo.deserialize(object: e).cast<ZcashAccountInfoShield>()));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        address.address.toCbor(),
        amount.toCbor(),
        protocol.value.toCbor(),
        memo?.toCbor(),
        change?.toCbor()
      ];
}

final class ZcashTransactionOutputTransparent extends ZcashTransactionOutput {
  @override
  final ZcashTransparentAddress? address;
  @override
  final BigInt amount;
  @override
  final ZcashTransactionMemoTransparent? memo;
  const ZcashTransactionOutputTransparent._(
      {this.address, required this.amount, this.memo});
  factory ZcashTransactionOutputTransparent.transfer(
      {required ZcashAddress address, required BigInt amount}) {
    final transparentAddr = address.toProtocolAddress(ZcashProtocol.transparent);
    if (transparentAddr == null || amount == BigInt.zero) {
      throw AppInternalError.internalError("Invalid transparent address.");
    }

    return ZcashTransactionOutputTransparent._(
        address: transparentAddr.cast(), amount: amount);
  }
  factory ZcashTransactionOutputTransparent.opReturn(
      ZcashTransactionMemoTransparent memo) {
    return ZcashTransactionOutputTransparent._(memo: memo, amount: BigInt.zero);
  }

  factory ZcashTransactionOutputTransparent.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag2,
        cborBytes: bytes,
        cborObject: object);
    return ZcashTransactionOutputTransparent._(
        address: values.maybeRawValueAt<ZcashTransparentAddress, String>(
            0, (e) => ZcashTransparentAddress(e)),
        amount: values.rawValueAt(1),
        memo: values.maybeObjectAt<ZcashTransactionMemoTransparent, CborTagValue>(
            2, (obj) => ZcashTransactionMemoTransparent.deserialize(object: obj)));
  }

  TransparentTxOutput toTxOutput() {
    final address = this.address;
    if (address != null) {
      return TransparentTxOutput(amount: amount, scriptPubKey: address.toScriptPubKey());
    }
    final memo = this.memo;
    if (amount == BigInt.zero && memo != null) {
      return TransparentTxOutput(amount: amount, scriptPubKey: memo.encode());
    }
    throw AppInternalError.internalError("Invalid zcash transparent output.");
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag2;

  @override
  List<CborObject?> get serializationItems => [
        address?.address.toCbor(),
        amount.toCbor(),
        memo?.toCbor(),
      ];

  @override
  ZcashProtocol get protocol => ZcashProtocol.transparent;
}

final class ZcashUtxoWithSpendingInfo with AppSerialization, PartialEquality {
  final ZcashUtxo utxo;
  final int? sequence;
  final UtxoTimelock confirmation;
  ZcashUtxoSpendableStatus get status => utxo.status;
  ZcashUtxoWithSpendingInfo._(
      {required this.utxo, required this.confirmation, this.sequence});
  factory ZcashUtxoWithSpendingInfo.unconfirmed(ZcashUtxo utxo) {
    return ZcashUtxoWithSpendingInfo._(utxo: utxo, confirmation: UtxoTimelock.unknown());
  }
  factory ZcashUtxoWithSpendingInfo.transparent(ZcashUtxoTransparent utxo,
      {int? sequence}) {
    return ZcashUtxoWithSpendingInfo._(
        utxo: utxo, confirmation: UtxoTimelock.unknown(), sequence: sequence);
  }

  factory ZcashUtxoWithSpendingInfo.fromBlockHeight(ZcashUtxo utxo, int height) {
    return ZcashUtxoWithSpendingInfo._(utxo: utxo, confirmation: utxo.timelock(height));
  }

  ZcashTxId txId() => utxo.txId();
  ZcashProtocol get protocol => utxo.protocol;

  factory ZcashUtxoWithSpendingInfo.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag2,
        cborBytes: bytes,
        cborObject: object);
    return ZcashUtxoWithSpendingInfo._(
        utxo: ZcashUtxo.deserialize(object: values.objectAt(0)),
        confirmation: UtxoTimelock.unknown(),
        sequence: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag2;

  @override
  List<CborObject?> get serializationItems => [utxo.toCbor(), sequence?.toCbor()];

  @override
  List<dynamic> get parts => [utxo];

  @override
  String toString() {
    return "Utxo: $utxo confirmation: $confirmation";
  }
}

final class ZcashUtxosWithAccountInfo with AppSerialization {
  final ZcashAccountInfo account;
  final List<ZcashUtxoWithSpendingInfo> utxos;
  ZcashUtxosWithAccountInfo._(
      {required this.account, required List<ZcashUtxoWithSpendingInfo> utxos})
      : utxos = utxos.immutable;
  factory ZcashUtxosWithAccountInfo(
      {required ZcashAccountInfo account,
      required List<ZcashUtxoWithSpendingInfo> utxos}) {
    if (utxos.isEmpty ||
        utxos.any((e) => e.utxo.type.protocol != account.type.protocol)) {
      throw AppInternalError.internalError("Invalid zcash utxos.");
    }
    return ZcashUtxosWithAccountInfo._(account: account, utxos: utxos);
  }
  factory ZcashUtxosWithAccountInfo.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag2,
        cborBytes: bytes,
        cborObject: object);
    return ZcashUtxosWithAccountInfo._(
        account: ZcashAccountInfo.deserialize(object: values.objectAt(0)),
        utxos: values
            .listAt<CborTagValue>(1)
            .map((e) => ZcashUtxoWithSpendingInfo.deserialize(object: e))
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

extension ExtSaplingUtxos on List<ZcashUtxo> {
  List<ZcashUtxoSapling> get saplingUtxos => whereType<ZcashUtxoSapling>().toList();
  List<ZcashUtxoOrchard> get orchardUtxos => whereType<ZcashUtxoOrchard>().toList();
  List<ZcashUtxoTransparent> get transparentUtxos =>
      whereType<ZcashUtxoTransparent>().toList();
}

sealed class ZcashTransactionMemo<PENCODED> {
  final String content;
  const ZcashTransactionMemo({required this.content});
  PENCODED encode();
}

class ZcashTransactionMemoShielded extends ZcashTransactionMemo<List<int>>
    with AppSerialization {
  ZcashTransactionMemoShielded({required super.content});
  factory ZcashTransactionMemoShielded.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return ZcashTransactionMemoShielded(content: values.rawValueAt(0));
  }

  @override
  List<int> encode() {
    return StringUtils.encode(content);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [content.toCbor()];
}

class ZcashTransactionMemoTransparent extends ZcashTransactionMemo<Script>
    with AppSerialization {
  final Script script;
  ZcashTransactionMemoTransparent._({required this.script, required super.content});
  factory ZcashTransactionMemoTransparent.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.runtimeTag,
        cborBytes: bytes,
        cborObject: object);
    return ZcashTransactionMemoTransparent._(
        content: values.rawValueAt(0),
        script: Script.deserialize(bytes: values.rawValueAt(1)));
  }
  factory ZcashTransactionMemoTransparent.fromMemo(String memo) {
    return ZcashTransactionMemoTransparent._(
        script: BitcoinScriptUtils.buildOpReturn([StringUtils.toBytes(memo)]),
        content: memo);
  }

  factory ZcashTransactionMemoTransparent.fromScript(Script script, {String? content}) {
    if (BitcoinScriptUtils.isOpReturn(script)) {
      throw AppInternalError.internalError("Invalid zcash transparent opRetrun script.");
    }
    content ??= BitcoinScriptUtils.getOpRetrunContent(script);
    return ZcashTransactionMemoTransparent._(
        script: script, content: content ?? BytesUtils.toHexString(script.toBytes()));
  }

  @override
  Script encode() {
    return script;
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [content.toCbor(), CborBytesValue(script.toBytes())];
}
