import 'dart:js_interop';
import 'package:on_chain_bridge/web/api/types/types.dart';

import '../../../utils/utils/extensions.dart';
import 'wallet_standard.dart';

class SolanaJSConstant {
  static const String sendTransaction = "solana_signAndSendTransaction";
  static const String signAndSendAllTransactions = "solana_signAndSendAllTransactions";
  static const String signMessage = "solana_signMessage";
  static const String signTransaction = "solana_signTransaction";
  static const String signAllTransaction = "solana_signAllTransactions";
  static const String requestAccounts = "solana_requestAccounts";
  static const String signInMessage = "solana_signIn";
  static const String version = '1.0.0';
  static final JSArray<JSAny> solanaTransactionVersion = ['legacy'.toJS, 0.toJS].toJS;
  static final JSArray<JSString> solanaDefaultAccountFeatures = [
    "solana:signAndSendTransaction".toJS,
    "solana:signAllTransactions".toJS,
    "solana:signAndSendAllTransactions".toJS,
    "solana:signTransaction".toJS,
    "solana:signMessage".toJS,
    "solana:signIn".toJS
  ].toJS;
  static const String walletStandardRegisterEvent = "wallet-standard:register-wallet";
  static const String walletStandardAppReadyEvent = "wallet-standard:app-ready";
}

// @JS("Uint8Array")
// extension type APPJSUint8Array(JSAny _) implements JSAny {
//   external static APPJSUint8Array from(JSAny? v);
//   external APPJSUint8Array slice();
//   factory APPJSUint8Array.fromList(List<int> bytes) {
//     return APPJSUint8Array.from(bytes.jsify());
//   }
//   List<int> toListInt() {
//     return (dartify() as List?)?.cast<int>() ?? [];
//   }
// }
@JS()
extension type StandardWalletAdapterRegisterEvent(JSAny _) implements JSAny {
  external void register(JSAny wallet);
}

@JS()
extension type SolanaWalletAdapterStandardConnectFeature(JSAny _) implements JSAny {
  factory SolanaWalletAdapterStandardConnectFeature.setup(
      {required JSFunction connect, String version = SolanaJSConstant.version}) {
    return SolanaWalletAdapterStandardConnectFeature(JSObject())
      ..connect = connect
      ..version = version;
  }
  external set version(String version);
  external set connect(JSFunction _);
}
@JS()
extension type SolanaWalletAdapterStandardEventsFeature(JSAny _) implements JSAny {
  factory SolanaWalletAdapterStandardEventsFeature.setup(
      {required JSFunction on, String version = SolanaJSConstant.version}) {
    return SolanaWalletAdapterStandardEventsFeature(JSObject())
      ..on = on
      ..version = version;
  }
  external set version(String version);
  external set on(JSFunction _);
}
@JS()
extension type SolanaWalletAdapterSolanaSignAndSendTransactionFeature(JSAny _)
    implements JSAny {
  factory SolanaWalletAdapterSolanaSignAndSendTransactionFeature.setup(
      {required JSFunction signAndSendTransaction,
      String version = SolanaJSConstant.version}) {
    return SolanaWalletAdapterSolanaSignAndSendTransactionFeature(JSObject())
      ..signAndSendTransaction = signAndSendTransaction
      ..version = version
      ..supportedTransactionVersions = SolanaJSConstant.solanaTransactionVersion;
  }
  external set version(String version);
  external set supportedTransactionVersions(JSArray _);
  external set signAndSendTransaction(JSFunction _);
}

@JS()
extension type SolanaWalletAdapterSolanaSignAndSendAllTransactionsFeature(JSAny _)
    implements JSAny {
  factory SolanaWalletAdapterSolanaSignAndSendAllTransactionsFeature.setup(
      {required JSFunction signAndSendAllTransactions,
      String version = SolanaJSConstant.version}) {
    return SolanaWalletAdapterSolanaSignAndSendAllTransactionsFeature(JSObject())
      ..signAndSendAllTransactions = signAndSendAllTransactions
      ..version = version
      ..supportedTransactionVersions = SolanaJSConstant.solanaTransactionVersion;
  }
  external set version(String version);
  external set supportedTransactionVersions(JSArray _);
  external set signAndSendAllTransactions(JSFunction _);
}

@JS()
extension type SolanaWalletAdapterSolanaSignInFeature(JSAny _) implements JSAny {
  factory SolanaWalletAdapterSolanaSignInFeature.setup(
      {required JSFunction signIn, String version = SolanaJSConstant.version}) {
    return SolanaWalletAdapterSolanaSignInFeature(JSObject())
      ..signIn = signIn
      ..version = version;
  }
  external set version(String version);
  external set signIn(JSFunction _);
}
@JS()
extension type SolanaWalletAdapterSolanaSignTransactionFeature(JSAny _) implements JSAny {
  factory SolanaWalletAdapterSolanaSignTransactionFeature.setup(
      {required JSFunction signTransaction,
      required JSArray supportedTransactionVersions,
      String version = SolanaJSConstant.version}) {
    return SolanaWalletAdapterSolanaSignTransactionFeature(JSObject())
      ..signTransaction = signTransaction
      ..version = version
      ..supportedTransactionVersions = supportedTransactionVersions;
  }
  external set version(String version);
  external set supportedTransactionVersions(JSArray _);
  external set signTransaction(JSFunction _);
}
@JS()
extension type SolanaWalletAdapterSolanaSignAllTransactionsFeature(JSAny _)
    implements JSAny {
  factory SolanaWalletAdapterSolanaSignAllTransactionsFeature.setup(
      {required JSFunction signAllTransactions,
      required JSArray supportedTransactionVersions,
      String version = SolanaJSConstant.version}) {
    return SolanaWalletAdapterSolanaSignAllTransactionsFeature(JSObject())
      ..signAllTransactions = signAllTransactions
      ..version = version
      ..supportedTransactionVersions = supportedTransactionVersions;
  }
  external set version(String version);
  external set supportedTransactionVersions(JSArray _);
  external set signAllTransactions(JSFunction _);
}

@JS()
extension type SolanaWalletAdapterSolanaSignMessageFeature(JSAny _) implements JSAny {
  factory SolanaWalletAdapterSolanaSignMessageFeature.setup(
      {required JSFunction signMessage, String version = SolanaJSConstant.version}) {
    return SolanaWalletAdapterSolanaSignMessageFeature(JSObject())
      ..signMessage = signMessage
      ..version = version;
  }
  external set version(String version);
  external set signMessage(JSFunction _);
}

@JS()
extension type JSSolanaTransactionSerializationConfig._(JSObject _) implements JSAny {
  external factory JSSolanaTransactionSerializationConfig(
      {required bool verifySignatures});
}

extension type SolanaSignTransactionOutput._(JSObject _) implements JSAny {
  factory SolanaSignTransactionOutput.setup(List<int> signedTransaction) {
    return SolanaSignTransactionOutput._(JSObject())
      ..signedTransaction = APPJSUint8Array.fromList(signedTransaction);
  }

  external APPJSUint8Array get signedTransaction;
  external set signedTransaction(APPJSUint8Array _);
}
extension type SolanaSignAndSendTransactionOutput._(JSObject _) implements JSAny {
  factory SolanaSignAndSendTransactionOutput.setup(List<int> signature) {
    return SolanaSignAndSendTransactionOutput._(JSObject())
      ..signature = APPJSUint8Array.fromList(signature);
  }
  external APPJSUint8Array get signature;
  external set signature(APPJSUint8Array _);
}

extension type JSSolanaSignMessageParams(JSObject _) implements JSAny {
  external JSSolanaWalletAccount get account;
  external APPJSUint8Array get message;
  static List<String> properties = ['account', 'message'];
}

extension type JSSolanaWalletAccount._(JSObject _) implements JSWalletStandardAccount {
  factory JSSolanaWalletAccount.setup(
      {required String address, required List<int> publicKey, required String chain}) {
    return JSSolanaWalletAccount._(JSObject())
      ..address = address
      ..chains = [chain.toJS].toJS
      ..features = SolanaJSConstant.solanaDefaultAccountFeatures.freez
      ..publicKey = APPJSUint8Array.fromList(publicKey);
  }
}

extension type JSSolanaWalletStandardConnect._(JSObject _) implements JSAny {
  factory JSSolanaWalletStandardConnect.setup(List<JSSolanaWalletAccount> accounts) {
    return JSSolanaWalletStandardConnect._(JSObject())..accounts = accounts.toJS;
  }
  external JSArray<JSSolanaWalletAccount> get accounts;
  external set accounts(JSArray<JSSolanaWalletAccount> _);
}
@JS()
extension type JSSolanaWalletStandardConnectFeature(JSAny _) implements JSAny {
  factory JSSolanaWalletStandardConnectFeature.setup(
      {required JSFunction connect, String version = SolanaJSConstant.version}) {
    return JSSolanaWalletStandardConnectFeature(JSObject())
      ..connect = connect
      ..version = version;
  }
  external set version(String version);
  external set connect(JSFunction _);
}

extension type JSSolanaSignTransactionParams._(JSObject _) implements JSAny {
  external JSSolanaWalletAccount get account;
  external APPJSUint8Array get transaction;
  external String? get chain;
  external JSSolanaTranasctionSendOptions? get options;
  static const List<String> properties = ['account', 'transaction'];
}

@JS()
extension type JSSolanaTranasctionSendOptions._(JSObject _) implements JSAny {
  /// sign
  external String? get preflightCommitment;
  external int? get minContextSlot;

  /// send
  external bool? get skipPreflight;
  external String? get commitment;
  external int? get maxRetries;
}
extension type JSSolanaSignAndSendTransactionParams._(JSObject _)
    implements JSSolanaSignTransactionParams {
  external String? get chain;
}

extension type JSSolanaSignAndSendAllTransactionMode._(JSObject _) implements JSAny {
  external String? get mode;
}
extension type JSSolanaSignInParams(JSObject _) implements JSAny {
  external String? get domain;
  external String? get address;
  external String? get statement;
  external String? get uri;
  external String? get version;
  external String? get chainId;
  external String? get nonce;
  external String? get issuedAt;
  external String? get expirationTime;
  external String? get notBefore;
  external String? get requestId;
  external JSArray<JSString>? get resources;
}
extension type JSSolanaSignInResponse(JSObject _) implements JSAny {
  external JSSolanaWalletAccount? get account;
  external set account(JSSolanaWalletAccount? _);
  external APPJSUint8Array get signedMessage;
  external set signedMessage(APPJSUint8Array _);

  external APPJSUint8Array get signature;
  external set signature(APPJSUint8Array _);
  external String? get signatureType;
  external set signatureType(String? _);
  factory JSSolanaSignInResponse.setup(
      {JSSolanaWalletAccount? account,
      required List<int> signedMessage,
      required List<int> signature,
      String? signatureType = 'ed25519'}) {
    return JSSolanaSignInResponse(JSObject())
      ..account = account
      ..signedMessage = APPJSUint8Array.fromList(signedMessage)
      ..signature = APPJSUint8Array.fromList(signature)
      ..signatureType = signatureType;
  }
}
