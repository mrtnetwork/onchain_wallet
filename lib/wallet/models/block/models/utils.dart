import 'package:on_chain_wallet/wallet/models/block/models/offset.dart';
import 'package:on_chain_wallet/wallet/models/block/models/status.dart';

class BlockTrackerUtils {
  static const int zcashBlockPerOffset = 100000;
  static const int zcashTotalOffset = 1;
  static const int moneroBlockPerOffset = 250000;
  static const int moneroTotalOffset = 10;
  static bool isValidOffsetRange({
    required int startHeight,
    required int currentHeight,
    required int endHeight,
  }) {
    return !startHeight.isNegative &&
        endHeight >= startHeight &&
        currentHeight >= startHeight &&
        currentHeight <= endHeight;
  }

  static List<BlockTrackingOffset> buildFixedChunkOffsets(
      {required int currentHeight,
      required int endHeight,
      required int blockPerOffset,

      ///  max thread
      int totalOffsets = 1}) {
    assert(currentHeight <= endHeight);
    if (currentHeight >= endHeight || totalOffsets == 0) return [];

    int start = currentHeight;
    final List<BlockTrackingOffset> offsets = [];

    while (start < endHeight && offsets.length < totalOffsets) {
      int nextEnd = start + blockPerOffset;
      if (nextEnd > endHeight) {
        nextEnd = endHeight;
      }
      final offset = BlockTrackingOffset(
        startHeight: start,
        endHeight: nextEnd,
        currentHeight: start,
        status: BlockSyncStatusPending(),
      );

      offsets.add(offset);
      start = nextEnd;
    }
    return offsets;
  }
}
