import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:blockchain_utils/bip/ton/ton.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:ton_dart/ton_dart.dart';

class _TonUtilsConst {
  static const int encryptedCommentMessageTag = 0x2167da4b;
  static const int commentTag = 0;
}

enum TonMessageBodyType {
  comment._("comment"),
  binaryComment._("binary_comment"),
  cell._("cell"),
  encryptedMessage._("encrypted_message"),
  none._("none");

  final String name;
  const TonMessageBodyType._(this.name);
  String get helperText {
    switch (this) {
      case TonMessageBodyType.comment:
        return "enter_comment_as_string_or_hex";
      case TonMessageBodyType.binaryComment:
        return "enter_binary_message_as_hex";
      case TonMessageBodyType.cell:
        return "enter_cell_as_hex_or_base64";
      default:
        return "";
    }
  }

  bool isValid(String? v) {
    switch (this) {
      case TonMessageBodyType.binaryComment:
        return StrUtils.isHex(v);
      case TonMessageBodyType.comment:
        return v?.isNotEmpty ?? false;
      case TonMessageBodyType.cell:
        return TonUtils.isValidCell(v);
      default:
        return false;
    }
  }

  Cell? toValue(String value) {
    switch (this) {
      case TonMessageBodyType.binaryComment:
        return TonUtils.toBinaryCommetBody(value);
      case TonMessageBodyType.comment:
        return TonUtils.toComment(value);
      case TonMessageBodyType.cell:
        return TonUtils.toCell(value);
      default:
        return null;
    }
  }

  bool get hasBody => this != TonMessageBodyType.none;

  static const List<TonMessageBodyType> supportValues = [
    TonMessageBodyType.comment,
    TonMessageBodyType.binaryComment,
    TonMessageBodyType.cell,
    TonMessageBodyType.none,
  ];
}

class TonUtils {
  static bool isValidTonMnemonicLength(String? mnemonic) {
    if (mnemonic == null) return false;
    final List<String> toList = CryptoKeyUtils.normalizeMnemonic(mnemonic);
    return toList.length >= 8 && toList.length <= 48;
  }

  static TonPrivateKey generateTonPrivateKeyFromSeed(
      {required String mnemonic, String? password, bool validateTonMnemonic = true}) {
    try {
      final mn = Mnemonic.fromString(mnemonic);
      final seed = TonSeedGenerator(mn)
          .generate(password: password ?? "", validateTonMnemonic: validateTonMnemonic);
      return TonPrivateKey.fromBytes(seed);
    } catch (e) {
      throw AppCryptoExceptionConst.invalidMnemonic;
    }
  }

  static Mnemonic generateTonMnemonic({String? password, required int wordsNum}) {
    try {
      return TonMnemonicGenerator().fromWordsNumber(wordsNum, password: password ?? "");
    } catch (e) {
      throw AppCryptoExceptionConst.invalidMnemonic;
    }
  }

  static bool isValidCell(String? v) {
    return TonHelper.tryToCell(v) != null;
  }

  static bool isValidQueryId(BigInt? v) {
    if (v == null) return false;
    return !v.isNegative && v < BinaryOps.maxU64;
  }

  static Cell toBinaryCommetBody(String hexBytes) {
    List<int>? toBytes = BytesUtils.tryFromHexString(hexBytes);
    if (toBytes != null) {
      if (toBytes[0] != BinaryOps.mask8) {
        toBytes = [BinaryOps.mask8, ...toBytes];
        return beginCell().storeUint32(0).storeBytesTail(toBytes).endCell();
      }
    }
    throw AppCryptoExceptionConst.invalidHexBytes;
  }

  static Cell toCell(String v) {
    return TonHelper.toCell(v);
  }

  static Cell toComment(String comment) {
    return beginCell().storeUint32(0).storeStringTail(comment).endCell();
  }

  static (TonMessageBodyType, String)? deserializeComment(Slice slice) {
    try {
      final tag = slice.tryLoadUint32();
      switch (tag) {
        case _TonUtilsConst.encryptedCommentMessageTag:
          return (TonMessageBodyType.encryptedMessage, slice.asCell().toBase64());
        case _TonUtilsConst.commentTag:
          final data = slice.loadBufferTail();
          if (data.isEmpty) {
            return (TonMessageBodyType.cell, "0x");
          }
          if (data[0] == BinaryOps.mask8) {
            return (
              TonMessageBodyType.binaryComment,
              BytesUtils.toHexString(data.sublist(1), prefix: "0x")
            );
          }
          return (
            TonMessageBodyType.comment,
            StringUtils.tryDecode(data) ?? BytesUtils.toHexString(data, prefix: "0x")
          );
        default:
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static MessageRelaxed createJettonTransaferBody(
      {required TonAddress walletAddress,
      required BigInt amount,
      required BigInt jettonAmount,
      required BigInt forwardTonAmount,
      required TonAddress responseAddress,
      required TonAddress destination,
      bool bounce = false,
      BigInt? queryId,
      Cell? payload}) {
    final body = beginCell()
        .storeUint32(JettonWalletConst.transfer)
        .storeUint64(queryId ?? 0)
        .storeCoins(jettonAmount)
        .storeAddress(destination)
        .storeAddress(responseAddress)
        .storeMaybeRef()
        .storeCoins(forwardTonAmount)
        .storeMaybeRef(cell: payload)
        .endCell();
    return TonHelper.internal(
        destination: walletAddress, amount: amount, bounce: bounce, body: body);
  }
}
