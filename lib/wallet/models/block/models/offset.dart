import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/wallet/models/block/models/utils.dart';
import 'status.dart';

abstract class BlockSyncedOffset with AppSerialization {
  final int currentHeight;
  final int total;
  final BlockSyncStatus status;
  int? get requestId;
  BlockTrackingOffset get offset;
  const BlockSyncedOffset({
    required this.currentHeight,
    required this.total,
    required this.status,
  });
}

class BlockTrackingOffset with AppSerialization, Equality {
  final int startHeight;
  final int endHeight;
  BlockSyncStatus _status;
  BlockSyncStatus get status => _status;
  bool get synced => _status.synced;
  int _currentHeight;
  int get currentHeight => _currentHeight;

  void _updateStatus(BlockSyncStatus status) {
    assert(!_status.synced);
    if (_status.synced) return;
    _status = status;
  }

  void _updateCurrentHeight(int height) {
    if (height <= startHeight) {
      _currentHeight = startHeight;
    } else {
      _currentHeight = IntUtils.min(endHeight, height);
    }
    if (_currentHeight == endHeight) {
      _status = BlockSyncStatusSynced();
    } else {
      _status = BlockSyncStatusPending();
    }
  }

  IResult<BlockSyncStatus> updateOffset(BlockSyncedOffset response) {
    int total = response.currentHeight;
    if (!response.status.isErr) {
      total += response.total;
    }
    if (_status.synced || _currentHeight != response.currentHeight || total > endHeight) {
      return ResultErr.fromException(AppInternalError.internalError(
          "BlockTrackingOffset._updateOffset",
          reason: "Invalid offset data."));
    }
    if (total < endHeight) {
      if (response.status.synced) {
        return ResultErr.fromException(AppInternalError.internalError(
            "BlockTrackingOffset._updateOffset",
            reason: "Invalid status."));
      }
      _updateStatus(response.status);
      _currentHeight = switch (response.status) {
        BlockSyncStatusError() => _currentHeight,
        _ => total
      };
    } else {
      _currentHeight = endHeight;
      _updateStatus(BlockSyncStatusSynced());
    }
    Logging.error(
      when: () => _status.isErr,
      fn: () {
        return AppLogData(
            runtime: runtimeType,
            function: "updateOffset",
            msg: "Update offset failed. $status $startHeight/$currentHeight/$endHeight");
      },
    );
    return ResultOk(_status);
  }

  void setAsPending() {
    _updateStatus(BlockSyncStatusPending());
  }

  BlockTrackingOffset._(
      {required this.startHeight,
      required this.endHeight,
      required BlockSyncStatus status,
      required int currentHeight})
      : _status = status,
        _currentHeight = currentHeight;

  factory BlockTrackingOffset({
    required int startHeight,
    required int endHeight,
    required int currentHeight,
    required BlockSyncStatus status,
  }) {
    if (startHeight.isNegative || startHeight > endHeight) {
      throw AppInternalError.internalError("BlockTrackingOffset");
    }
    return BlockTrackingOffset._(
        startHeight: startHeight,
        endHeight: endHeight,
        status: status,
        currentHeight: currentHeight);
  }
  factory BlockTrackingOffset.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.trackingOffset);
    return BlockTrackingOffset._(
      startHeight: values.rawValueAt(0),
      endHeight: values.rawValueAt(1),
      status: BlockSyncStatus.deserialize(object: values.objectAt(2)),
      currentHeight: values.rawValueAt(3),
    );
  }

  @override
  List get variables => [startHeight, endHeight];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.trackingOffset;

  @override
  List<CborObject?> get serializationItems => [
        startHeight.toCbor(),
        endHeight.toCbor(),
        status.toCbor(),
        currentHeight.toCbor(),
      ];

  @override
  String toString() {
    return "(start: $startHeight, height: $currentHeight, end: $endHeight)";
  }
}

class BlockSyncingOffsets with AppSerialization {
  int _startHeight;
  int get startHeight => _startHeight;
  int _endHeight;
  int get endHeight => _endHeight;
  int _currentHeight;
  int get currentHeight => _currentHeight;
  List<BlockTrackingOffset> _offsets;
  List<BlockTrackingOffset> get offsets => _offsets;
  BlockSyncStatus _status;
  BlockSyncStatus get status => _status;
  final int? requestId;

  BlockSyncingOffsets clone() {
    return BlockSyncingOffsets._(
        startHeight: startHeight,
        endHeight: endHeight,
        currentHeight: currentHeight,
        offsets: _offsets,
        status: status,
        requestId: requestId);
  }

  factory BlockSyncingOffsets.start(
      {int? startHeight, BlockSyncStatus? status, int? requestId}) {
    startHeight ??= 0;
    return BlockSyncingOffsets._(
        startHeight: startHeight,
        endHeight: startHeight,
        currentHeight: startHeight,
        offsets: [],
        status: status ?? BlockSyncStatusPending(),
        requestId: requestId);
  }
  factory BlockSyncingOffsets.buildDefault({
    required int startHeight,
    required int endHeight,
    int? currentHeight,
    BlockSyncStatus? status,
  }) {
    currentHeight ??= startHeight;
    if (!BlockTrackerUtils.isValidOffsetRange(
        startHeight: startHeight, currentHeight: currentHeight, endHeight: endHeight)) {
      throw AppInternalError.internalError("BlockSyncingOffsets.buildDefault",
          details: {
            "startHeight": "$startHeight",
            "endHeight": "$endHeight",
            "currentHeight": "$currentHeight"
          },
          reason: "Invalid offset ranges.");
    }

    final offsets = BlockTrackerUtils.buildFixedChunkOffsets(
        currentHeight: currentHeight,
        endHeight: endHeight,
        totalOffsets: BlockTrackerUtils.zcashTotalOffset,
        blockPerOffset: BlockTrackerUtils.zcashBlockPerOffset);
    assert(offsets.isNotEmpty || currentHeight == endHeight);
    return BlockSyncingOffsets._(
        startHeight: startHeight,
        endHeight: endHeight,
        currentHeight: currentHeight,
        offsets: offsets,
        status: status ??
            switch (offsets.isEmpty) {
              true => BlockSyncStatusSynced(),
              false => BlockSyncStatusPending(),
            },
        requestId: null);
  }
  factory BlockSyncingOffsets.buildRequest(
      {required int startHeight,
      required int endHeight,
      BlockSyncStatus? status,
      required int requestId,
      int? currentHeight,
      int totalBlockPerOffset = BlockTrackerUtils.zcashBlockPerOffset,
      int totalOffsets = BlockTrackerUtils.zcashTotalOffset}) {
    currentHeight ??= startHeight;
    if (!BlockTrackerUtils.isValidOffsetRange(
        startHeight: startHeight, currentHeight: currentHeight, endHeight: endHeight)) {
      throw AppInternalError.internalError("BlockSyncingOffsets.buildRequest",
          details: {
            "startHeight": "$startHeight",
            "endHeight": "$endHeight",
            "currentHeight": "$currentHeight"
          },
          reason: "Invalid offset ranges.");
    }
    final offsets = BlockTrackerUtils.buildFixedChunkOffsets(
        currentHeight: currentHeight,
        endHeight: endHeight,
        totalOffsets: totalOffsets,
        blockPerOffset: totalBlockPerOffset);
    assert(offsets.isNotEmpty || currentHeight == endHeight);
    return BlockSyncingOffsets._(
        startHeight: startHeight,
        endHeight: endHeight,
        currentHeight: currentHeight,
        offsets: offsets,
        status: status ??
            switch (offsets.isEmpty) {
              true => BlockSyncStatusSynced(),
              false => BlockSyncStatusPending(),
            },
        requestId: requestId);
  }

  BlockSyncingOffsets._(
      {required int startHeight,
      required int endHeight,
      required int currentHeight,
      required List<BlockTrackingOffset> offsets,
      required BlockSyncStatus status,
      required this.requestId})
      : _startHeight = startHeight,
        _endHeight = endHeight,
        _currentHeight = currentHeight,
        _offsets = offsets.immutable,
        _status = status;
  factory BlockSyncingOffsets.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.syncingOffsets);
    return BlockSyncingOffsets._(
        startHeight: values.rawValueAt(0),
        endHeight: values.rawValueAt(1),
        currentHeight: values.rawValueAt(2),
        offsets: values
            .listAt<CborObject>(3)
            .map((e) => BlockTrackingOffset.deserialize(object: e))
            .toList(),
        status: BlockSyncStatus.deserialize(object: values.objectAt(4)),
        requestId: values.rawValueAt(5));
  }

  void _rebuildOffsets(
      {int totalOffsets = BlockTrackerUtils.zcashTotalOffset,
      int totalBlockPerOffset = BlockTrackerUtils.zcashBlockPerOffset}) {
    int synced = 0;
    for (final i in offsets) {
      if (!i.synced) {
        _currentHeight = i.currentHeight;
        break;
      }
      _currentHeight = i.endHeight;
      synced++;
    }
    _offsets = _offsets.sublist(synced, _offsets.length);
    final newOffsets = BlockTrackerUtils.buildFixedChunkOffsets(
        currentHeight: _offsets.isEmpty ? currentHeight : _offsets.last.endHeight,
        endHeight: endHeight,
        totalOffsets: totalOffsets - _offsets.length,
        blockPerOffset: totalBlockPerOffset);
    _offsets = [..._offsets, ...newOffsets];
  }

  BlockSyncStatus _updateStatus(
      {int totalOffsets = BlockTrackerUtils.zcashTotalOffset,
      int totalBlockPerOffset = BlockTrackerUtils.zcashBlockPerOffset}) {
    _rebuildOffsets(totalOffsets: totalOffsets, totalBlockPerOffset: totalBlockPerOffset);
    if (_currentHeight == endHeight) {
      _status = BlockSyncStatusSynced();
    } else {
      assert(_currentHeight < endHeight);

      _status = offsets.firstWhereOrNull((e) => e._status.isErr)?._status ??
          BlockSyncStatusPending();
    }
    return _status;
  }

  IResult<UpdateOffsetResult> updateOffset(BlockSyncedOffset offset,
      {int totalOffsets = BlockTrackerUtils.zcashTotalOffset,
      int totalBlockPerOffset = BlockTrackerUtils.zcashBlockPerOffset}) {
    final index = _offsets.indexOf(offset.offset);
    if (index.isNegative) {
      return ResultErr.fromException(AppInternalError.internalError(
          "ZcashRequestBlockTrackingInfo._updateOffset",
          reason: "Offset not found.",
          details: {
            "offset": offset.offset.toString(),
            "offsets": offsets.map((e) => e.toString()).join("")
          }));
    }
    if (status.synced) {
      return ResultErr.fromException(AppInternalError.internalError(
          "ZcashRequestBlockTrackingInfo._updateOffset",
          reason: "request already synced."));
    }
    final cOffset = _offsets[index];
    return cOffset.updateOffset(offset).map((status) {
      return UpdateOffsetResult(
          offset: cOffset,
          offsetsStatus: _updateStatus(
              totalBlockPerOffset: totalBlockPerOffset, totalOffsets: totalOffsets));
    });
  }

  IResult<BlockSyncStatus> updateHeight(int height) {
    if (height < endHeight || requestId != null) {
      return ResultErr.fromException(AppInternalError.internalError("updateEndHeight",
          details: {
            "height": "$height",
            "end_height": "$endHeight",
            "request_id": requestId?.toString()
          }));
    }
    _endHeight = height;
    _updateStatus();
    return ResultOk(_status);
  }

  IResult<void> trancateCurrentHeight(int height) {
    if (requestId != null) {
      return ResultErr.fromException(
          AppInternalError.internalError("trancateCurrentHeight", details: {
        "height": "$height",
        "end_height": "$endHeight",
        "request_id": requestId?.toString()
      }));
    }
    if (height >= currentHeight) return ResultOk.okVoid;
    final newOffsets = BlockTrackerUtils.buildFixedChunkOffsets(
        currentHeight: height < startHeight ? height : startHeight,
        endHeight: endHeight,
        totalOffsets: BlockTrackerUtils.zcashTotalOffset,
        blockPerOffset: BlockTrackerUtils.zcashBlockPerOffset);
    for (final i in newOffsets) {
      i._updateCurrentHeight(height);
    }
    _offsets = newOffsets;
    _currentHeight = height;
    _updateStatus();
    return ResultOk(_status);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.syncingOffsets;

  @override
  List<CborObject?> get serializationItems => [
        startHeight.toCbor(),
        endHeight.toCbor(),
        currentHeight.toCbor(),
        AppSerialization.listFromObjects(offsets.map((e) => e.toCbor()).toList()),
        status.toCbor(),
        requestId?.toCbor()
      ];

  @override
  String toString() {
    return "status ${offsets.map((e) => e.toString()).join(",")} $startHeight $endHeight $_currentHeight";
  }
}

class UpdateOffsetResult {
  final BlockTrackingOffset offset;
  final BlockSyncStatus offsetsStatus;
  const UpdateOffsetResult({required this.offset, required this.offsetsStatus});

  @override
  String toString() {
    return "{offset: $offset, status: $offsetsStatus}";
  }
}
