import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/argruments/argruments.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/crypto/crypto.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/non_encrypted/requests.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/stream/requests/monero_block_tracking.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/stream/requests/zcash_block_tracking.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/stream/requests/zcash_nullifier_tracking.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/wallet/wallet.dart';

sealed class AppCryptoMethods {
  CryptoArgsType get type;
  AppSerializationIdentifier get tag;
  static const List<AppCryptoMethods> values = [
    ...CryptoRequestMethod.values,
    // ...NoneEncryptedCryptoRequestMethod.values,
    ...WalletRequestMethod.values
  ];
  static AppCryptoMethods fromTag(List<int>? tags) {
    return values.firstWhere((e) => e.tag.isValidIdentifier(tags?.firstOrNull),
        orElse: () => throw AppInternalError.internalError("StreamIsolateMethod"));
  }
}

enum CryptoRequestMethod implements AppCryptoMethods {
  encryptChacha(AppSerializationIdentifier.encryptChacha),
  decryptChacha(AppSerializationIdentifier.decryptChacha),
  generateMnemonic(AppSerializationIdentifier.generateToneMenemonic),
  tonMnemonicToPrivateKey(AppSerializationIdentifier.tonMnemonicToPrivateKey),
  tonMnemonicValidate(AppSerializationIdentifier.tonMnemonicValidate),
  generateMoneroMnemonic(AppSerializationIdentifier.generateMoneroMnemonic),
  moneroMnemonicToPrivateKey(AppSerializationIdentifier.moneroMnemonicToPrivateKey),
  generateMasterKey(AppSerializationIdentifier.generateMasterKey),
  readMasterKey(AppSerializationIdentifier.readEncryptedMasterKey),
  createMasterKey(AppSerializationIdentifier.createMasterKey),
  createWallet(AppSerializationIdentifier.cryptoCreateWallet),
  decodeBackup(AppSerializationIdentifier.decodeBackup),
  generateBip39Mnemonic(AppSerializationIdentifier.generateBip39Mnemonic),
  jwt(AppSerializationIdentifier.jwt),
  hashing(AppSerializationIdentifier.cryptoHashing),
  symkey(AppSerializationIdentifier.generateSymKey),
  x25519(AppSerializationIdentifier.x25519),
  generateImportKey(AppSerializationIdentifier.generateImportKey),
  restoreExternalMasterKey(AppSerializationIdentifier.restoreExternalMasterKey),
  decryptExternalWalletBackup(AppSerializationIdentifier.decryptExternalWalletBackup),

  moneroFakeTx(AppSerializationIdentifier.moneroFakeTx, encrypted: false),
  generateRingOutput(AppSerializationIdentifier.moneroGenerateRingOutput,
      encrypted: false),
  noEncryptHashing(AppSerializationIdentifier.hashing, encrypted: false),
  moneroGenerateProof(AppSerializationIdentifier.moneroGenerateProof, encrypted: false),
  moneroVerifyProof(AppSerializationIdentifier.moneroVerifyProof, encrypted: false),
  ;

  final bool encrypted;
  @override
  final AppSerializationIdentifier tag;
  const CryptoRequestMethod(this.tag, {this.encrypted = true});

  @override
  CryptoArgsType get type => CryptoArgsType.crypto;
}

// enum NoneEncryptedCryptoRequestMethod implements AppCryptoMethods {

//   @override
//   final AppSerializationIdentifier tag;
//   const NoneEncryptedCryptoRequestMethod(this.tag);

//   @override
//   CryptoArgsType get type => CryptoArgsType.nonEncrypted;
// }

enum StreamIsolateMethod {
  moneroAccountTracker(AppSerializationIdentifier.moneroAccountTracker),
  zcashAccountTracker(AppSerializationIdentifier.zcashAccountTracker),
  zcashNullifierTracker(AppSerializationIdentifier.zcashNullifierTracker),
  streamArgs(AppSerializationIdentifier.streamArgs);

  final AppSerializationIdentifier tag;
  // List<int> get tag => [...StreamCryptoArgsType.streamRequest.tag, ..._tag];
  const StreamIsolateMethod(this.tag);
  static StreamIsolateMethod fromIdentifier(int? id) {
    return values.firstWhere((e) => e.tag.isValidIdentifier(id),
        orElse: () => throw AppInternalError.internalError("StreamIsolateMethod"));
  }
}

enum WalletRequestMethod implements AppCryptoMethods {
  signMessage(AppSerializationIdentifier.ethereumPersonalSign),
  bitcoinSignMessage(AppSerializationIdentifier.bitcoinPersonalSign),
  ethereumTypedDataSign(AppSerializationIdentifier.ethereumTypedDataSign),
  deriveAddress(AppSerializationIdentifier.deriveAddress),
  readPublicKeys(AppSerializationIdentifier.readPublicKeys),
  readPrivateKeys(AppSerializationIdentifier.readPrivateKeys),
  readImportKey(AppSerializationIdentifier.readImportKey),
  readMnemonic(AppSerializationIdentifier.readMnemonic),
  updateWalletKeys(AppSerializationIdentifier.updateWalletKeys),
  removeWalletKeys(AppSerializationIdentifier.removeWalletKeys),
  walletBackup(AppSerializationIdentifier.walletBackup),
  encodeBackup(AppSerializationIdentifier.encodeBackup),
  sign(AppSerializationIdentifier.sign),
  moneroOutputUnlocker(AppSerializationIdentifier.moneroOutputUnlocker),
  importSubWallet(AppSerializationIdentifier.importSubWallet),
  removeSubWallet(AppSerializationIdentifier.removeSubWallet),
  changeWalletPassword(AppSerializationIdentifier.changeWalletPassword),
  readAccountPublicKeys(AppSerializationIdentifier.readAccountPublicKeys),
  readAccountPrivateKeys(AppSerializationIdentifier.readAccountPrivateKeys),
  walletExternalBackup(AppSerializationIdentifier.walletExternalBackup),
  importExternalWallet(AppSerializationIdentifier.importExternalWallet),
  longTimeSecretKet(AppSerializationIdentifier.longTimeSecretKet),
  ;

  @override
  final AppSerializationIdentifier tag;
  const WalletRequestMethod(this.tag);
  static WalletRequestMethod fromTag(List<int>? tags) {
    return values.firstWhere((e) => e.tag.isValidTags(tags),
        orElse: () => throw AppInternalError.internalError("StreamIsolateMethod"));
  }

  @override
  CryptoArgsType get type => CryptoArgsType.wallet;
}

abstract class CryptoRequest<T extends CborTagSerializable>
    extends CryptoArgsCompleter<T> {
  CryptoRequest();
  @override
  abstract final CryptoRequestMethod method;

  @override
  bool get isEncrypted => method.encrypted;

  factory CryptoRequest.deserialize(CryptoRequestMethod method, CborTagValue decode) {
    final CryptoRequest args;
    switch (method) {
      case CryptoRequestMethod.encryptChacha:
        args = CryptoRequestEncryptChacha.deserialize(object: decode);
        break;
      case CryptoRequestMethod.decryptChacha:
        args = CryptoRequestDecryptChacha.deserialize(object: decode);
        break;
      case CryptoRequestMethod.generateMnemonic:
        args = TonMenmonicGenerateMessage.deserialize(object: decode);
        break;
      case CryptoRequestMethod.tonMnemonicToPrivateKey:
        args = TonMnemonicToPrivateKeyMessage.deserialize(object: decode);
      case CryptoRequestMethod.tonMnemonicValidate:
        args = TonMnemonicValidateMessage.deserialize(object: decode);
        break;
      case CryptoRequestMethod.generateMoneroMnemonic:
        args = MoneroMenmonicGenerateMessage.deserialize(object: decode);
        break;
      case CryptoRequestMethod.moneroMnemonicToPrivateKey:
        args = MoneroMnemonicToPrivateKeyMessage.deserialize(object: decode);
        break;
      case CryptoRequestMethod.generateMasterKey:
        args = CryptoRequestGenerateMasterKey.deserialize(object: decode);
        break;
      case CryptoRequestMethod.readMasterKey:
        args = CryptoRequestReadMasterKey.deserialize(object: decode);
        break;
      case CryptoRequestMethod.createMasterKey:
        args = CryptoRequestRestoreBackupMasterKey.deserialize(object: decode);
        break;
      case CryptoRequestMethod.createWallet:
        args = CryptoRequestCreateHDWallet.deserialize(object: decode);
        break;
      case CryptoRequestMethod.decodeBackup:
        args = CryptoRequestDecodeBackup.deserialize(object: decode);
        break;
      case CryptoRequestMethod.generateBip39Mnemonic:
        args = CryptoRequestGenerateBip39Mnemonic.deserialize(object: decode);
        break;
      case CryptoRequestMethod.hashing:
        args = CryptoRequestHashing.deserialize(object: decode);
        break;
      case CryptoRequestMethod.symkey:
        args = CryptoRequestGenerateWalletConnectSymKeyInfo.deserialize(object: decode);
        break;
      case CryptoRequestMethod.x25519:
        args = CryptoRequestGenerateX25519Key.deserialize(object: decode);
        break;
      case CryptoRequestMethod.jwt:
        args = CryptoRequestGenerateJwt.deserialize(object: decode);
        break;
      case CryptoRequestMethod.generateImportKey:
        args = CryptoRequestGenerateImportedKey.deserialize(object: decode);
        break;
      case CryptoRequestMethod.restoreExternalMasterKey:
        args = CryptoRequestRestoreExternalBackupMasterKey.deserialize(object: decode);
        break;
      case CryptoRequestMethod.decryptExternalWalletBackup:
        args = CryptoRequestDecryptExternalWalletBackup.deserialize(object: decode);
        break;
      case CryptoRequestMethod.moneroFakeTx:
        args = NoneEncryptedRequestFakeMoneroTx.deserialize(object: decode);
        break;
      case CryptoRequestMethod.generateRingOutput:
        args = NoneEncryptedRequestGenerateRingOutput.deserialize(object: decode);
        break;
      case CryptoRequestMethod.moneroGenerateProof:
        args = NoneEncryptedRequestMoneroGenerateTxProof.deserialize(object: decode);
        break;
      case CryptoRequestMethod.moneroVerifyProof:
        args = NoneEncryptedRequestMoneroVerifyTxProof.deserialize(object: decode);
        break;
      case CryptoRequestMethod.noEncryptHashing:
        args = NoneEncryptedRequestHashing.deserialize(object: decode);
        break;
    }
    if (args is! CryptoRequest<T>) {
      throw AppInternalError.internalError("CryptoRequest");
    }
    return args;
  }
}

abstract class WalletRequest<T extends AppSerialization> extends WalletArgsCompleter<T> {
  @override
  abstract final WalletRequestMethod method;
  const WalletRequest();

  factory WalletRequest.deserialize({List<int>? bytes, CborObject? object}) {
    final CborTagValue decode =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);

    final request = WalletRequestMethod.fromTag(decode.tags);
    final WalletRequest args;
    switch (request) {
      case WalletRequestMethod.signMessage:
        args = WalletRequestSignMessage.deserialize(object: decode);
        break;
      case WalletRequestMethod.bitcoinSignMessage:
        args = WalletRequestBitcoinSignMessage.deserialize(object: decode);
        break;
      case WalletRequestMethod.ethereumTypedDataSign:
        args = WalletRequestEthereumTypedDataSign.deserialize(object: decode);
        break;
      case WalletRequestMethod.deriveAddress:
        args = WalletRequestDeriveAddress.deserialize(object: decode);
        break;
      case WalletRequestMethod.readPublicKeys:
        args = WalletRequestReadPublicKeys.deserialize(object: decode);
        break;
      case WalletRequestMethod.readPrivateKeys:
        args = WalletRequestReadPrivateKeys.deserialize(object: decode);
        break;
      case WalletRequestMethod.readMnemonic:
        args = WalletRequestReadMnemonic.deserialize(object: decode);
        break;
      case WalletRequestMethod.updateWalletKeys:
        args = WalletRequestImportNewKey.deserialize(object: decode);
        break;
      case WalletRequestMethod.removeWalletKeys:
        args = WalletRequestRemoveKey.deserialize(object: decode);
        break;
      case WalletRequestMethod.sign:
        args = WalletRequestSign.deserialize(object: decode);
        break;
      case WalletRequestMethod.readImportKey:
        args = WalletRequestReadImportedKey.deserialize(object: decode);
        break;
      case WalletRequestMethod.walletBackup:
        args = WalletRequestBackupWallet.deserialize(object: decode);
        break;
      case WalletRequestMethod.moneroOutputUnlocker:
        args = WalletRequestMoneroOutputUnlocker.deserialize(object: decode);
        break;
      case WalletRequestMethod.importSubWallet:
        args = WalletRequestImportSubWallet.deserialize(object: decode);
        break;
      case WalletRequestMethod.removeSubWallet:
        args = WalletRequestRemoveSubWallet.deserialize(object: decode);
        break;
      case WalletRequestMethod.encodeBackup:
        args = WalletRequestBackupKey.deserialize(object: decode);
        break;
      case WalletRequestMethod.changeWalletPassword:
        args = WalletRequestChangePassword.deserialize(object: decode);
        break;
      case WalletRequestMethod.readAccountPublicKeys:
        args = WalletRequestReadAccountPublicKeys.deserialize(object: decode);
        break;
      case WalletRequestMethod.readAccountPrivateKeys:
        args = WalletRequestReadAccountPrivateKeys.deserialize(object: decode);
        break;
      case WalletRequestMethod.walletExternalBackup:
        args = WalletRequestBackupExternalWallet.deserialize(object: decode);
        break;
      case WalletRequestMethod.importExternalWallet:
        args = WalletRequestImportExternalWallet.deserialize(object: decode);
        break;
      case WalletRequestMethod.longTimeSecretKet:
        args = WalletRequestLognTimeSecretKeys.deserialize(object: decode);
        break;
    }
    if (args is! WalletRequest<T>) {
      throw AppInternalError.internalError("WalletRequest");
    }
    return args;
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;
}

abstract class IsolateStreamRequest<T, S> extends StreamArgsCompleter<T, S> {
  late SafeStreamController<({S message, List<int>? encryptedPart})>? _streamController =
      SafeStreamController(name: "IsolateStreamRequest.$runtimeType");
  SafeStreamController<({S message, List<int>? encryptedPart})>? get streamController =>
      _streamController;
  bool get closed => _streamController?.isClosed ?? true;
  IsolateStreamRequest({super.cancelable});
  factory IsolateStreamRequest.deserialize({List<int>? bytes, CborObject? object}) {
    final decode = AppSerialization.decodeTaggedValueWithInfo(
        cborBytes: bytes,
        cborObject: object,
        expectedTags: [
          StreamIsolateMethod.moneroAccountTracker.tag,
          StreamIsolateMethod.zcashAccountTracker.tag,
          StreamIsolateMethod.zcashNullifierTracker.tag
        ]);
    final request = StreamIsolateMethod.fromIdentifier(decode.identifier.id);
    final IsolateStreamRequest args;
    switch (request) {
      case StreamIsolateMethod.moneroAccountTracker:
        args = StreamRequestMoneroBlockTracking.deserialize(object: decode.tag);
        break;
      case StreamIsolateMethod.zcashAccountTracker:
        args = StreamRequestZcashBlockTracking.deserialize(object: decode.tag);
        break;
      case StreamIsolateMethod.zcashNullifierTracker:
        args = StreamRequestZcashNullifierTracking.deserialize(object: decode.tag);
        break;
      default:
        throw AppInternalError.internalError("IsolateStreamRequest");
    }
    if (args is! IsolateStreamRequest<T, S>) {
      throw AppInternalError.internalError("IsolateStreamRequest");
    }
    return args;
  }

  void handleIsolateData(
      {required S param,
      required EventSink<({MessageArgsStreamResponse message, bool encrypted})> sink,
      required String streamId,
      required AppContext context,
      List<int>? encryptedPart});

  @override
  Stream<({MessageArgsStreamResponse message, bool encrypted})> getIsolateResult(
      String streamId, AppContext context) {
    final controller = _streamController;
    if (controller == null || controller.isClosed) {
      throw AppCryptoException("stream_closed_desc");
    }
    return controller.stream().transform(StreamTransformer<
            ({S message, List<int>? encryptedPart}),
            ({MessageArgsStreamResponse message, bool encrypted})>.fromHandlers(
        handleData: (data, sink) => handleIsolateData(
            param: data.message,
            sink: sink,
            streamId: streamId,
            context: context,
            encryptedPart: data.encryptedPart)));
  }

  void close() {
    _streamController?.close();
    _streamController = null;
    Logging.debug(
        fn: () => AppLogData(
            runtime: runtimeType, function: "close", msg: "Stream request closed."));
  }

  @override
  void add(MessageArgsStream args, List<int>? encryptedPart) {
    switch (args.type) {
      case MessageArgsStreamMethod.close:
        close();
        break;
      default:
    }
  }
}
