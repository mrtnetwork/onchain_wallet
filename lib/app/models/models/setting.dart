import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_wallet/app/models/models/currencies.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/serialization/serialization.dart';

class APPWalletSetting with AppSerialization {
  final bool showTestnetNetworks;
  final bool enableWebView;
  final bool enableSwap;
  const APPWalletSetting(
      {this.showTestnetNetworks = false,
      this.enableWebView = true,
      this.enableSwap = true});

  factory APPWalletSetting.deserialize({List<int>? cborBytes, CborObject? object}) {
    try {
      final CborListValue values = AppSerialization.decodeTaggedValue(
          cborBytes: cborBytes,
          cborObject: object,
          identifier: AppSerializationIdentifier.walletSetting);

      return APPWalletSetting(
          showTestnetNetworks: values.rawValueAt(0),
          enableWebView: values.rawValueAt(1),
          enableSwap: values.rawValueAt(2));
    } catch (_) {
      return APPWalletSetting();
    }
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.walletSetting;

  @override
  List<CborObject?> get serializationItems =>
      [showTestnetNetworks.toCbor(), enableWebView.toCbor(), enableSwap.toCbor()];
  APPWalletSetting copyWith(
      {bool? showTestnetNetworks, bool? enableWebView, bool? enableSwap}) {
    return APPWalletSetting(
        enableWebView: enableWebView ?? this.enableWebView,
        showTestnetNetworks: showTestnetNetworks ?? this.showTestnetNetworks,
        enableSwap: enableSwap ?? this.enableSwap);
  }
}

class APPSetting with AppSerialization {
  const APPSetting(
      {required this.appColor,
      required this.appBrightness,
      required this.currency,
      required this.walletSetting,
      this.size});
  final String? appColor;
  final String? appBrightness;
  final Currency currency;
  final WidgetRect? size;
  final APPWalletSetting walletSetting;

  APPSetting copyWith({
    String? appColor,
    String? appBrightness,
    Currency? currency,
    WidgetRect? size,
    APPWalletSetting? walletSetting,
  }) {
    return APPSetting(
        appColor: appColor ?? this.appColor,
        appBrightness: appBrightness ?? this.appBrightness,
        currency: currency ?? this.currency,
        size: size ?? this.size,
        walletSetting: walletSetting ?? this.walletSetting);
  }

  factory APPSetting.defaultSetting() => APPSetting(
      appColor: null,
      appBrightness: null,
      currency: Currency.USD,
      walletSetting: APPWalletSetting());

  factory APPSetting.deserialize(List<int>? bytes) {
    if (bytes == null) {
      return APPSetting.defaultSetting();
    }
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, identifier: AppSerializationIdentifier.appSettingTag);
    final String? colorHex = values.rawValueAt(0);
    final String? brightnessName = values.rawValueAt(1);
    final Currency currency = Currency.fromName(values.rawValueAt(2)) ?? Currency.USD;
    WidgetRect? rect = values.maybeObjectAt<WidgetRect, CborTagValue>(
        3, (e) => WidgetRect.deserialize(object: e));
    APPWalletSetting walletSetting = values.maybeObjectAt<APPWalletSetting, CborTagValue>(
            4, (e) => APPWalletSetting.deserialize(object: e)) ??
        APPWalletSetting();
    return APPSetting(
      appColor: colorHex,
      appBrightness: brightnessName,
      currency: currency,
      size: rect,
      walletSetting: walletSetting,
    );
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.appSettingTag;

  @override
  List<CborObject?> get serializationItems => [
        appColor?.toCbor(),
        appBrightness?.toCbor(),
        currency.name.toCbor(),
        size?.toCbor(),
        walletSetting.toCbor(),
      ];
}
