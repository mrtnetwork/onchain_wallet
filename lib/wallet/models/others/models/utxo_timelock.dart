import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/utils/numbers/numbers.dart';
import 'package:on_chain_wallet/app/core.dart';

sealed class UtxoTimelock {
  const UtxoTimelock();
  bool get confirmed;
  bool get inMempool => false;
  void update(int currentHeight);
  factory UtxoTimelock.fromBip68(
      {required int sequence,
      required int currentHeight,
      required int utxoBlockHeight,
      required int utxoTimeSeconds,
      required int avrageBlocktimeSeconds,
      bool useMtp = true,
      int minConfirmation = 1}) {
    final decode = Bip68Sequence.decode(sequence);
    if (decode.isFinal || decode.disabled) {
      return UtxoTimelockBlock(
          utxoBlock: utxoBlockHeight,
          currentHeight: currentHeight,
          minConfirmation: minConfirmation);
    }
    return switch (decode.isTimeBased) {
      true when decode.seconds != null => UtxoTimelockTimestamp(
          utxoConfirmedTime:
              DateTimeUtils.fromSecondsSinceEpoch((utxoTimeSeconds + decode.seconds!)),
          averageBlocktimeSeconds: avrageBlocktimeSeconds,
          useMtp: true),
      false when decode.blocks != null => UtxoTimelockBlock(
          utxoBlock: utxoBlockHeight + IntUtils.max(decode.blocks!, minConfirmation),
          currentHeight: currentHeight,
          minConfirmation: 0),
      _ => UtxosTimelockUnknown()
    };
  }
  factory UtxoTimelock.unknown() => UtxosTimelockUnknown();
}

class UtxosTimelockUnknown extends UtxoTimelock {
  @override
  bool get confirmed => false;

  @override
  void update(int _) {}
}

class UtxosTimelockConfirmed extends UtxoTimelock {
  @override
  bool get confirmed => true;

  @override
  void update(int _) {}
}

class UtxoTimelockBlock extends UtxoTimelock {
  final int utxoBlock;
  final int minConfirmation;
  int _currentHeight;
  int get currentHeight => _currentHeight;
  int _remainingBlocks;
  int get remainingBlocks => _remainingBlocks;
  bool _confirmed;
  @override
  bool get confirmed => _confirmed;
  UtxoTimelockBlock._({
    required this.utxoBlock,
    required int currentHeight,
    required this.minConfirmation,
    required bool confirmed,
  })  : _currentHeight = currentHeight,
        _confirmed = confirmed,
        _remainingBlocks = IntUtils.max(0, (utxoBlock + minConfirmation) - currentHeight);
  factory UtxoTimelockBlock(
      {required int utxoBlock, required int currentHeight, int minConfirmation = 1}) {
    bool confirmed = currentHeight >= (utxoBlock + minConfirmation);
    return UtxoTimelockBlock._(
        utxoBlock: utxoBlock,
        currentHeight: currentHeight,
        minConfirmation: minConfirmation,
        confirmed: confirmed);
  }

  @override
  void update(int currentHeight) {
    assert(currentHeight >= _currentHeight);
    if (currentHeight < _currentHeight) return;
    _currentHeight = currentHeight;
    _confirmed = currentHeight >= (utxoBlock + minConfirmation);
    _remainingBlocks = IntUtils.max(0, (utxoBlock + minConfirmation) - currentHeight);
  }
}

class UtxoTimelockTimestamp extends UtxoTimelock {
  final DateTime utxoConfirmedTime;

  /// Delay in seconds (simulated MTP / lock window)
  final int averageMtpSeconds;

  Duration _remaining;

  Duration get remaining => _remaining;

  bool _isAvailable;

  /// True if UTXO is past the timelock window
  @override
  bool get confirmed => _isAvailable;

  UtxoTimelockTimestamp._({
    required this.utxoConfirmedTime,
    required bool isAvailable,
    required this.averageMtpSeconds,
  })  : _isAvailable = isAvailable,
        _remaining = utxoConfirmedTime
            .add(Duration(seconds: averageMtpSeconds))
            .difference(DateTime.now());

  factory UtxoTimelockTimestamp({
    required DateTime utxoConfirmedTime,
    required int averageBlocktimeSeconds,
    bool useMtp = true,
  }) {
    final delaySeconds = useMtp ? (averageBlocktimeSeconds * 7) : 0;

    final now = DateTime.now();
    final unlockTime = utxoConfirmedTime.add(Duration(seconds: delaySeconds));

    return UtxoTimelockTimestamp._(
      utxoConfirmedTime: utxoConfirmedTime,
      isAvailable: unlockTime.isBefore(now),
      averageMtpSeconds: delaySeconds,
    );
  }

  @override
  void update(int _) {
    final now = DateTime.now();
    final unlockTime = utxoConfirmedTime.add(Duration(seconds: averageMtpSeconds));

    _isAvailable = unlockTime.isBefore(now);
    _remaining = unlockTime.difference(now);
  }
}

class UtxosTimelockMempool extends UtxoTimelock {
  @override
  bool get confirmed => false;
  @override
  bool get inMempool => true;

  @override
  void update(int _) {}
}

sealed class Bip68Configuration {
  int toSequence();
}

class Bip68ConfigurationBlocks implements Bip68Configuration {
  final int blocks;
  const Bip68ConfigurationBlocks._(this.blocks);
  factory Bip68ConfigurationBlocks(int blocks) {
    if (blocks.isNegative || blocks > Bip68Const.valueMask) {
      throw AppInternalError.internalError("Bip68ConfigurationBlocks",
          details: {"blocks": "$blocks"});
    }
    return Bip68ConfigurationBlocks._(blocks);
  }

  @override
  int toSequence() {
    return Bip68Sequence.encodeBlocks(blocks);
  }
}

class Bip68ConfigurationTimelock implements Bip68Configuration {
  final int minutes;
  final int bip64Minutes;
  factory Bip68ConfigurationTimelock(int minutes) {
    if (((minutes * 60) / 512).round() > Bip68Const.valueMask) {
      throw AppInternalError.internalError("Bip68ConfigurationTimelock",
          details: {"minutes": "$minutes"});
    }
    return Bip68ConfigurationTimelock._(minutes);
  }

  Bip68ConfigurationTimelock._(this.minutes)
      : bip64Minutes = ((minutes * 60) / 512).round() * 512;

  @override
  int toSequence() {
    return Bip68Sequence.encodeTime(bip64Minutes);
  }
}
