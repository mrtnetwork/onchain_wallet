import 'dart:js_interop';
import 'package:on_chain_bridge/web/api/types/types.dart';
import 'wallet_standard.dart';

class BitcoinJSConstant {
  static const String version = '1.0.0';
  static List<String> accountFeatures(String chain, bool allowPersonalMessage) {
    return [
      if (allowPersonalMessage) "bitcoin:signPersonalMessage",
      "bitcoin:signTransaction",
      "bitcoin:sendTransaction"
    ];
  }

  static const String requestAccountRequestName = "bitcoin_requestAccounts";
  static const String signTransactionRequestName = "bitcoin_signTransaction";
  static const String sendTransactionRequestName = "bitcoin_sendTransaction";
  static const String getAccountAddresses = "bitcoin_getAccountAddresses";
  static const String signPersonalMessageRequestName = "bitcoin_signPersonalMessage";
}

extension type JSBitcoinWalletAccount._(JSObject _) implements JSWalletStandardAccount {
  factory JSBitcoinWalletAccount.setup(
      {required String address,
      required List<int> publicKey,
      required String chain,
      required String type,
      required String? witnessScript,
      required String? redeemScript,
      required List<String> features}) {
    return JSBitcoinWalletAccount._(JSObject())
      ..address = address
      ..publicKey = APPJSUint8Array.fromList(publicKey)
      ..chains = [chain.toJS].toJS
      ..type = type
      ..witnessScript = witnessScript
      ..redeemScript = redeemScript
      ..features = features.map((e) => e.toJS).toList().toJS;
  }
  external set address(String address);
  external String get address;
  external APPJSUint8Array get publicKey;
  external set type(String _);
  external set witnessScript(String? _);
  external set redeemScript(String? _);
  external JSArray<JSString>? get chains;
  external JSArray<JSString>? get features;
  external set chains(JSArray<JSString>? chains);
  external set features(JSArray<JSString>? features);
  external set label(String? _);
  external set icon(String? _);
}

extension type JSBitcoinSignTransactionParams(JSAny _) implements JSAny {
  external JSArray<JSAny> get accounts;
  external String get psbt;
  static const List<String> properties = ['accounts', 'psbt'];
}

extension type JSBitcoinSendTransactionParams(JSAny _) implements JSAny {
  external JSArray<JSAny> get accounts;
  external String? get recipientAddress;
  external String? get script;
  external String get amount;
  static const List<String> properties = ['accounts', 'outputs'];
}
extension type JSBitcoinGetAccountAddressParams(JSAny _) implements JSAny {
  external JSAny get account;
}
extension type JSBitcoinGetAccountAddressResponse(JSAny _) implements JSAny {
  external String get address;
  external String get script;
  external String get type;
  external String? get witnessScript;
  external String? get redeemScript;
  external String? get publicKey;
}
extension type JSBitcoinSignTransactionResponse(JSAny _) implements JSAny {
  factory JSBitcoinSignTransactionResponse.setup(String psbt) {
    return JSBitcoinSignTransactionResponse(JSObject())..psbt = psbt;
  }
  external String get psbt;
  external set psbt(String _);
}
extension type JSBitcoinSendTransactionResponse(JSAny _) implements JSAny {
  factory JSBitcoinSendTransactionResponse.setup(String txId) {
    return JSBitcoinSendTransactionResponse(JSObject())..txid = txId;
  }
  external String get txid;
  external set txid(String _);
}
extension type JSBitcoinSignMessageParams(JSAny _) implements JSAny {
  external APPJSUint8Array get message;
  external String? get messagePrefix;
  external JSAny get account;
}
extension type JSBitcoinSignMessageResponse(JSAny _) implements JSAny {
  factory JSBitcoinSignMessageResponse.setup(
      {required String signature, required List<int> digest}) {
    return JSBitcoinSignMessageResponse(JSObject())
      ..signature = signature
      ..digest = APPJSUint8Array.fromList(digest);
  }

  external APPJSUint8Array get digest;
  external set digest(APPJSUint8Array _);
  external String get signature;
  external set signature(String _);
}
