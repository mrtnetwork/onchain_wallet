import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/crypto/wallet/keys.dart';

class ExtentionWalletKey with AppSerialization {
  final String key;
  const ExtentionWalletKey(this.key);

  factory ExtentionWalletKey.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.historyTag);
    return ExtentionWalletKey(values.rawValueAt(0));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.historyTag;

  @override
  List<CborObject?> get serializationItems => [CborStringValue(key)];
}

class ExtentionKey with AppSerialization {
  final List<int> key;
  final List<int> nonce;

  ExtentionKey({required List<int> key, required List<int> nonce})
      : key = key.asImmutableBytes,
        nonce = nonce.asImmutableBytes;
  ExtentionKey.fromHex(this.key, this.nonce);
  factory ExtentionKey.generate() {
    return ExtentionKey(
        key: QuickCrypto.generateRandom(), nonce: QuickCrypto.generateRandom(12));
  }
  factory ExtentionKey.deserialize({List<int>? bytes, CborObject? object, String? hex}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        cborHex: hex,
        identifier: AppSerializationIdentifier.keyTag);
    return ExtentionKey.fromHex(values.rawValueAt(0), values.rawValueAt(1));
  }

  String encrypt(ExtentionWalletKey key) {
    return BytesUtils.toHexString(CryptoKeyUtils.encryptChacha(
        key: this.key, nonce: nonce, data: key.toCbor().encode()));
  }

  ExtentionWalletKey? decrypt(String plaintext) {
    final pw = BytesUtils.tryFromHexString(plaintext);
    if (pw == null) return null;
    final decrypt = CryptoKeyUtils.decryptChacha(key: key, nonce: nonce, data: pw);
    if (decrypt == null) return null;
    return ExtentionWalletKey.deserialize(bytes: decrypt);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.keyTag;

  @override
  List<CborObject?> get serializationItems => [key.toCborBytes(), nonce.toCborBytes()];
}

class ExtentionSessionStorageConst {
  static const String key = "extention_setting";
  static const String history = "extention_history";
  static const String expireKey = "extention_expire";
  static const String extentionType = "popup";
  static const String normalTabType = "normal";

  static const String iframeName = "iframe";
  static const String viewQueryParameters = "view";
  static const String contextQueryParameters = "context";
  static const String updateTabCompleteStatus = "complete";
  static const Map<String, dynamic> closeEvent = {
    "message": "close_iframe",
    "source": "wallet",
  };
}

enum ExtensionWalletContextType {
  action(0),
  sidePanel(1),
  popup(2),
  tab(3),
  sidebarAction(4);

  bool get isAction => this == action;
  bool get isSidePanel => this == sidePanel;
  bool get isSidebarAction => this == sidebarAction;
  bool get isTab => this == tab;
  bool get isPopup => this == popup;
  final int value;
  const ExtensionWalletContextType(this.value);

  static ExtensionWalletContextType? fromName(String? name) {
    return values.firstWhereOrNull((e) => e.name == name);
  }

  static ExtensionWalletContextType fromValue(int? value) {
    return values.firstWhere((e) => e.value == value,
        orElse: () => throw AppInternalError.internalError("ExtensionWalletContextType"));
  }
}

class ExtensionWalletContext {
  final ExtensionWalletContextType context;
  final int windowId;
  final String instanceId;
  final int? tabId;
  final bool iframe;
  const ExtensionWalletContext(
      {required this.context,
      required this.windowId,
      required this.instanceId,
      required this.tabId,
      required this.iframe});
  static const ExtensionWalletContext init = ExtensionWalletContext(
      context: ExtensionWalletContextType.action,
      windowId: 0,
      instanceId: '',
      tabId: null,
      iframe: false);
}
