import 'package:on_chain_wallet/app/core.dart';

enum CosmosNetworkTypes {
  main(0),
  forked(1),
  thorAndForked(2),
  ethermint(3);

  bool get isEthreum => this == ethermint;
  bool get isThorAndForked => this == thorAndForked;
  final int value;
  const CosmosNetworkTypes(this.value);
  factory CosmosNetworkTypes.fromValue(int value) {
    return values.firstWhere((e) => e.value == value,
        orElse: () => throw AppInternalError.internalError("CosmosNetworkTypes"));
  }
}
