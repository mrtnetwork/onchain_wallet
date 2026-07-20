import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/wallet/constant/networks/bitcoin.dart';
import 'package:on_chain_wallet/wallet/models/others/models/utxo_timelock.dart';

enum BitcoinUtxoSpendableStatus {
  /// related to shield request tracking and request not completed yet.
  notReady(0),

  /// ready to spend
  ready(1),

  /// spended and now this is in mempool and should be removed
  spended(2);

  final int value;
  const BitcoinUtxoSpendableStatus(this.value);
  static BitcoinUtxoSpendableStatus fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw AppInternalError.internalError("ZcashUtxoSpendableStatus",
          details: {"value": value?.toString()}),
    );
  }

  bool get isReady => this == ready;
}

final class BitcoinUtxoWithSpendingInfo with AppSerialization, PartialEquality {
  final BitcoinUtxo utxo;
  bool get coinbase => utxo.coinbase ?? false;
  BitcoinUtxoSpendableStatus _status;
  BitcoinUtxoSpendableStatus get status => _status;
  final int? sequence;
  final UtxoTimelock confirmation;
  BigInt get value => utxo.value;
  int get index => utxo.vout;

  BitcoinUtxoWithSpendingInfo._(
      {required this.utxo,
      required this.confirmation,
      this.sequence,
      required BitcoinUtxoSpendableStatus status})
      : _status = status;
  factory BitcoinUtxoWithSpendingInfo.unconfirmed(BitcoinUtxo utxo,
      {BitcoinUtxoSpendableStatus status = BitcoinUtxoSpendableStatus.ready}) {
    assert(utxo.coinbase != null, "missing coinbase info");
    return BitcoinUtxoWithSpendingInfo._(
        utxo: utxo, confirmation: UtxoTimelock.unknown(), status: status);
  }

  factory BitcoinUtxoWithSpendingInfo.fromBlockHeight(BitcoinUtxo utxo, int height,
      {BitcoinUtxoSpendableStatus status = BitcoinUtxoSpendableStatus.ready}) {
    UtxoTimelock timelock() {
      assert(utxo.coinbase != null, "missing coinbase info");
      if (!utxo.confirmed()) {
        return UtxosTimelockMempool();
      }
      return UtxoTimelockBlock(
          utxoBlock: utxo.blockHeight,
          currentHeight: height,
          minConfirmation: switch (utxo.coinbase ?? false) {
            true => BtcConst.minCoinbaseConfirmation,
            false => 1,
          });
    }

    return BitcoinUtxoWithSpendingInfo._(
      utxo: utxo,
      confirmation: timelock(),
      status: status,
    );
  }

  factory BitcoinUtxoWithSpendingInfo.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: AppSerializationIdentifier.bitcoinUtxo,
        cborBytes: bytes,
        cborObject: object);
    return BitcoinUtxoWithSpendingInfo._(
        utxo: BitcoinUtxo.deserialize(object: values.objectAt(0)),
        confirmation: UtxoTimelock.unknown(),
        sequence: values.rawValueAt(1),
        status: BitcoinUtxoSpendableStatus.fromValue(values.rawValueAt(2)));
  }
  String txId() => utxo.txHash;
  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.bitcoinUtxo;

  @override
  List<CborObject?> get serializationItems =>
      [utxo.toCbor(), sequence?.toCbor(), status.value.toCbor()];

  @override
  List<dynamic> get parts => [utxo];

  @override
  String toString() {
    return "Utxo: $utxo confirmation: $confirmation";
  }
}

final class BitcoinUtxosWithAccountInfo {
  final UtxoAddressDetails account;
  final List<BitcoinUtxoWithSpendingInfo> utxos;
  BitcoinUtxosWithAccountInfo(
      {required this.account, required List<BitcoinUtxoWithSpendingInfo> utxos})
      : utxos = utxos.immutable;

  @override
  String toString() {
    return utxos.join(", ");
  }
}

class BitcoinAddressUtxo with AppSerialization {
  Set<BitcoinUtxoWithSpendingInfo> _utxos;
  Set<BitcoinUtxoWithSpendingInfo> get utxos => _utxos;
  bool updateUtxos(Iterable<BitcoinUtxoWithSpendingInfo> utxos) {
    _utxos = utxos.toImutableSet;
    return true;
  }

  BigInt get totalBalance {
    return _utxos.fold<BigInt>(BigInt.zero, (p, c) => p + c.value);
  }

  BitcoinAddressUtxo({Set<BitcoinUtxoWithSpendingInfo> utxos = const {}})
      : _utxos = utxos.immutable;
  factory BitcoinAddressUtxo.deserialize({CborObject? object, List<int>? bytes}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.bitcoinAddressUtxo);
    return BitcoinAddressUtxo(
      utxos: values
          .listAt<CborTagValue>(0)
          .map((e) => BitcoinUtxoWithSpendingInfo.deserialize(object: e))
          .toSet(),
    );
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.bitcoinAddressUtxo;

  @override
  List<CborObject?> get serializationItems => [
        CborListValue.definite(_utxos.map((e) => e.toCbor()).toList()),
      ];
}
