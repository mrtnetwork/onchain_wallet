import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';

class CosmosIBCChannelId with AppSerialization, Equality {
  final String channelId;
  final String port;
  const CosmosIBCChannelId({required this.channelId, required this.port});
  factory CosmosIBCChannelId.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.cosmosIbcChannelId);
    return CosmosIBCChannelId(
        channelId: values.rawValueAt(0), port: values.rawValueAt(1));
  }

  @override
  List get variables => [channelId, port];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.cosmosIbcChannelId;

  @override
  List<CborObject?> get serializationItems => [channelId.toCbor(), port.toCbor()];
}

class CosmosAccountIBCChannelIds with AppSerialization {
  List<CosmosIBCChannelId> _channelIds;
  List<CosmosIBCChannelId> get channelIds => _channelIds;
  CosmosAccountIBCChannelIds({List<CosmosIBCChannelId> channelIds = const []})
      : _channelIds = channelIds.immutable;
  factory CosmosAccountIBCChannelIds.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.cosmosAccountChannelId);
    return CosmosAccountIBCChannelIds(
        channelIds: values
            .allObjectsAs<CborTagValue>()
            .map((e) => CosmosIBCChannelId.deserialize(object: e))
            .toList());
  }

  void addChannel(CosmosIBCChannelId channel) {
    if (_channelIds.contains(channel)) return;
    _channelIds = [channel, ..._channelIds].toImutableList;
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.cosmosAccountChannelId;

  @override
  List<CborObject?> get serializationItems =>
      [AppSerialization.listFromObjects(_channelIds.map((e) => e.toCbor()).toList())];
}
