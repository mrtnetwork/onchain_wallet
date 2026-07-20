import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_swap/on_chain_swap.dart';

import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

class APPSwapSettingsConst {
  static const double minTelerance = 0;
  static const double maxTolerance = 100;
}

class APPSwapSettings with AppSerialization, Equality {
  APPSwapSettings._(
      {required this.chainType,
      required List<SwapServiceProvider> swapProviders,
      this.tolerance})
      : swapProviders = swapProviders.immutable;
  final List<SwapServiceProvider> swapProviders;
  final ChainType chainType;
  final double? tolerance;

  APPSwapSettings copyWith(
      {required List<SwapServiceProvider> swapProviders,
      required ChainType chainType,
      required double tolerance}) {
    assert(tolerance >= APPSwapSettingsConst.minTelerance &&
        tolerance <= APPSwapSettingsConst.maxTolerance);

    return APPSwapSettings._(
        swapProviders: swapProviders,
        chainType: chainType,
        tolerance: (tolerance == APPSwapSettingsConst.minTelerance ? null : tolerance));
  }

  factory APPSwapSettings.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.swapSetting);
    List<SwapServiceProvider> providers = values
        .listAt<CborStringValue>(0)
        .map((e) => SwapConstants.findProvider(e.value))
        .whereType<SwapServiceProvider>()
        .toList();
    if (providers.isEmpty) {
      providers = SwapConstants.supportProviders;
    }
    final chainType = ChainType.fromValue(values.rawValueAt(1));
    return APPSwapSettings._(
        swapProviders: providers, chainType: chainType, tolerance: values.rawValueAt(2));
  }
  factory APPSwapSettings() {
    return APPSwapSettings._(
        chainType: ChainType.mainnet, swapProviders: SwapConstants.supportProviders);
  }

  @override
  List get variables => [swapProviders, chainType, tolerance];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.swapSetting;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(
            swapProviders.map((e) => CborStringValue(e.identifier)).toList()),
        chainType.name.toCbor(),
        tolerance?.toCbor()
      ];
}
