import 'package:cosmos_sdk/proto_messages/ibc/core/channel/v1/src/channel.dart';

class IbcChannelStatus {
  final Channel channel;
  final KnownIbcClientStatus clientStatus;
  final String counterpartyChannelId;
  final String counterpartyPort;
  final bool isActive;
  final bool channelIsOpen;
  IbcChannelStatus(
      {required this.channel,
      required this.clientStatus,
      required this.counterpartyChannelId,
      required this.counterpartyPort})
      : isActive = clientStatus.isActive && channel.state == State.stateOpen,
        channelIsOpen = channel.state == State.stateOpen;
}

enum KnownIbcClientStatus {
  statusActive("Active"),
  statusExpired("Expired"),
  statusFrozen("Frozen"),
  statusUnknown("Unknown");

  final String name;
  const KnownIbcClientStatus(this.name);

  bool get isActive => this != statusExpired && this != statusFrozen;
  static KnownIbcClientStatus fromStatus(String? status) => values.firstWhere(
        (e) => e.name == status,
        orElse: () => KnownIbcClientStatus.statusUnknown,
      );
}
