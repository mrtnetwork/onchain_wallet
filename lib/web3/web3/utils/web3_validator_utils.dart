import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message.dart';
import 'package:on_chain_wallet/web3/web3/core/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/core/exception/exception.dart';

class Web3ValidatorUtils {
  static bool isCaip2(String chainId) {
    final split = chainId.split(":");
    return split.length == 2 && split.every((e) => e.trim().isNotEmpty);
  }

  static String parseChainId(NetworkType type, String caip2) {
    String chainId = caip2;
    if (chainId.indexOf(":") > 0) {
      chainId = chainId.split(":").last;
    }
    switch (type) {
      case NetworkType.solana:
        bool isBase58 = StringUtils.isBase58(chainId);
        if (isBase58 && chainId.length > 32) {
          return chainId.substring(0, 32);
        }
        return chainId;
      case NetworkType.bitcoinAndForked:
      case NetworkType.monero:
      case NetworkType.substrate:
        chainId = StringUtils.strip0x(chainId.toLowerCase());
        if (chainId.length > 32) {
          chainId = caip2.substring(0, 32);
        }
        break;
      case NetworkType.tron:
        chainId = chainId.toLowerCase();
        if (chainId.startsWith("0x") && StringUtils.ixHexaDecimalNumber(chainId)) {
          return chainId;
        }
        final blockNumner = IntUtils.tryParse(chainId);
        if (blockNumner == null) return chainId;
        return blockNumner.toRadix16;

      default:
    }
    return chainId;
  }

  static T onValidate<T>(
      {Object? value,
      required T Function() to,
      required Exception Function() onException,
      bool exceptionWhenIsWrong = true}) {
    if (null is T && value == null) {
      return null as T;
    }
    final result = MethodUtils.fallbackOnException(to, logOnDebug: false);
    if (result == null) {
      throw onException();
    }
    return result;
  }

  /// if object
  static T parse<T, V>(
      {required T? Function(V value) onParse,
      required Object? value,
      required Web3NetworkRequestMethods method,
      required Web3RequestException Function() onFailed}) {
    if (value == null && null is T) {
      return null as T;
    }
    T? v;
    try {
      v = onParse(value as V);
      if (v == null && null is T) {
        return null as T;
      }
      if (v != null) {
        return v as T;
      }
    } catch (_) {}
    throw onFailed();
  }

  static T praseObject<T, V>(
      {required T? Function(V value) onParse,
      required String key,
      required Web3NetworkRequestMethods method,
      required Map<String, dynamic>? json}) {
    final value = (json?[key] ?? json?[StrUtils.toSnakeCase(key)])?.toString();
    if (value == null && null is T) {
      return null as T;
    }
    if (value is! V) {
      throw throw Web3RequestExceptionConst.failedToParse(key);
    }
    final obj =
        MethodUtils.fallbackOnException(() => onParse(value as V), logOnDebug: false);

    if (obj != null) {
      return obj as T;
    }
    throw throw Web3RequestExceptionConst.failedToParse(key);
  }

  /// check provider value is hex
  static T parseAddress<T>({
    required T Function(String address) onParse,
    required String key,
    required Web3NetworkRequestMethods method,
    required Map<String, dynamic>? json,
    required String network,
  }) {
    final value = (json?[key] ?? json?[StrUtils.toSnakeCase(key)])?.toString();
    if (value == null && null is T) {
      return null as T;
    }
    if (value is! String) {
      throw Web3RequestExceptionConst.invalidStringArgrument(key);
    }

    T? addr;
    try {
      addr = onParse(value);
    } on Web3RequestException {
      rethrow;
    } catch (_) {}
    if (addr != null) {
      return addr as T;
    }
    throw Web3RequestExceptionConst.invalidAddressArgrument(key: key, network: network);
  }

  /// check provider value is hex
  static T parseHex<T extends Object?>(
      {required String key,
      required Web3NetworkRequestMethods method,
      required Map<String, dynamic>? json,
      bool strip0x = true,
      bool required0x = true}) {
    final value = (json?[key] ?? json?[StrUtils.toSnakeCase(key)])?.toString();
    if (null is T && value == null) {
      return null as T;
    }
    if (value != null && StringUtils.isHexBytes(value)) {
      if (!required0x || value.startsWith("0x")) {
        if (T == String) {
          if (strip0x) return StringUtils.strip0x(value).toLowerCase() as T;
          return value.toLowerCase() as T;
        }
        return BytesUtils.fromHexString(value) as T;
      }
    }
    throw Web3RequestExceptionConst.invalidHexBytes(key);
  }

  /// check provider value is hex
  static T parseBase64<T>(
      {required String key,
      required Web3NetworkRequestMethods method,
      required Map<String, dynamic>? json,
      bool allowBytes = false,
      Web3RequestException? error}) {
    final value = (json?[key] ?? json?[StrUtils.toSnakeCase(key)]);
    if (null is T && value == null) {
      return null as T;
    }
    List<int>? toBytes;
    if (allowBytes && value is List) {
      toBytes = parseParams2(() {
        try {
          return value.cast<int>();
        } catch (_) {}
        return null;
      });
    } else if (value is String) {
      toBytes = StringUtils.tryEncode(value, encoding: StringEncoding.base64);
    }
    if (toBytes != null) {
      if (T == String) {
        if (value is String) return value as T;
        return StringUtils.decode(toBytes, encoding: StringEncoding.base64) as T;
      }
      return toBytes as T;
    }
    throw error ?? Web3RequestExceptionConst.invalidBase64Bytes(key);
  }

  static T parseBase58<T>(
      {required String key,
      required Web3NetworkRequestMethods method,
      required Map<String, dynamic>? json}) {
    final value = (json?[key] ?? json?[StrUtils.toSnakeCase(key)])?.toString();
    if (null is T && value == null) {
      return null as T;
    }
    final List<int>? toBytes = MethodUtils.fallbackOnException(
        () => Base58Decoder.decode(value!),
        logOnDebug: false);
    if (toBytes != null) {
      if (T == String) {
        if (value!.isEmpty && null is T) return null as T;
        return value as T;
      }
      return toBytes as T;
    }
    throw Web3RequestExceptionConst.invalidBase58(key);
  }

  static T parseList<T extends List<E>?, E>(
      {required String key,
      required Web3RequestMethods method,
      required Map<String, dynamic>? json,
      Web3RequestExceptionConst? error,
      int? length,
      bool allowEmpty = false}) {
    final value = json?[key] ?? json?[StrUtils.toSnakeCase(key)];
    if (null is T && value == null) {
      return null as T;
    }
    final toList = MethodUtils.fallbackOnException(
        () => JsonParser.valueEnsureAsList<E>(value),
        logOnDebug: false);
    if (toList != null && (length == null || length == toList.length)) {
      if (toList.isEmpty) {
        if (null is T) {
          return null as T;
        }
        if (allowEmpty) {
          return toList as T;
        }
        throw error ?? Web3RequestExceptionConst.invalidListArgument(key);
      } else {
        return toList as T;
      }
    }
    throw error ?? Web3RequestExceptionConst.invalidListArgument(key);
  }

  static T parseMap<T extends Map<String, dynamic>?>({
    required String key,
    required Web3NetworkRequestMethods method,
    required Map<String, dynamic>? json,
    List<String> requiredKeys = const [],
  }) {
    final value = json?[key] ?? json?[StrUtils.toSnakeCase(key)];
    if (null is T && value == null) {
      return null as T;
    }
    final toMap = MethodUtils.fallbackOnException(
        () => JsonParser.valueEnsureAsMap<String, dynamic>(value),
        logOnDebug: false);
    if (toMap != null) {
      if (requiredKeys.every((e) => toMap[e] != null)) {
        return toMap as T;
      }
    }
    throw Web3RequestExceptionConst.invalidMapArguments(name: key, keys: requiredKeys);
  }

  static Map<String, dynamic>? tryObjectAsMap(Object? r) {
    if (r == null) return null;
    if (r is Map<String, dynamic>) return r;
    if (r is String) return StringUtils.tryToJson<Map<String, dynamic>>(r);
    try {
      return (r as Map).cast<String, dynamic>();
    } catch (_) {}
    return StringUtils.tryToJson<Map<String, dynamic>>(StringUtils.tryFromJson(r));
  }

  static List<Map<String, dynamic>>? tryObjectAsListOfMap(Object? r) {
    if (r == null) return null;
    if (r is String) {
      return StringUtils.tryToJson<List>(r)?.cast();
    }
    try {
      return (r as List)
          .map((e) => tryObjectAsMap(e))
          .cast<Map<String, dynamic>>()
          .toList();
    } catch (_) {}
    return StringUtils.tryToJson<List>(StringUtils.tryFromJson(r))?.cast();
  }

  static T parseString<T extends String?>({
    required String key,
    required Web3NetworkRequestMethods method,
    required Map<String, dynamic>? json,
  }) {
    final value = json?[key] ?? json?[StrUtils.toSnakeCase(key)];
    if (null is T && value == null) {
      return null as T;
    }
    if (value != null && value is String) {
      return value as T;
    }
    throw Web3RequestExceptionConst.invalidStringArgrument(key);
  }

  static T parseDouble<T extends BigRational?>({
    required String key,
    required Web3NetworkRequestMethods method,
    required Map<String, dynamic>? json,
  }) {
    final value = json?[key] ?? json?[StrUtils.toSnakeCase(key)];
    if (null is T && value == null) {
      return null as T;
    }
    final ratinal = BigRational.tryParse(value.toString());
    if (ratinal != null) {
      return ratinal as T;
    }
    throw Web3RequestExceptionConst.invalidDecimalsNumbers(key);
  }

  /// parse dynamic to bigint
  static T parseBigInt<T extends BigInt?>(
      {required String key,
      required Web3NetworkRequestMethods method,
      required Map<String, dynamic>? json,
      bool sign = true,
      Web3RequestException? error}) {
    final value = json?[key] ?? json?[StrUtils.toSnakeCase(key)];
    if (null is T && value == null) {
      return null as T;
    }
    final toBigInt = BigintUtils.tryParse(value);
    if (toBigInt != null) {
      if (sign || !toBigInt.isNegative) return toBigInt as T;
    }
    throw error ?? Web3RequestExceptionConst.invalidNumbers(key);
  }

  static String containsOnlyOnce({
    required List<String> keys,
    required Web3NetworkRequestMethods method,
    required Map<String, dynamic>? json,
    required String name,
  }) {
    String? key;
    for (final i in keys) {
      if (json?.containsKey(i) ?? false) {
        if (key != null) {
          key = null;
          break;
        }
        key = i;
      }
    }

    if (key != null) return key;
    throw Web3RequestExceptionConst.invalidObjectKeys(name, keys);
  }

  static T parseInt<T extends int?>(
      {required String key,
      required Web3NetworkRequestMethods method,
      required Map<String, dynamic>? json,
      bool sign = true,
      Web3RequestExceptionConst? error}) {
    final value = json?[key] ?? json?[StrUtils.toSnakeCase(key)];
    if (null is T && value == null) {
      return null as T;
    }
    final toInt = IntUtils.tryParse(value);
    if (toInt != null) {
      if (sign || !toInt.isNegative) return toInt as T;
    }
    throw error ?? Web3RequestExceptionConst.invalidNumbers(key);
  }

  static T parseBool<T extends bool?>({
    required String key,
    required Web3NetworkRequestMethods method,
    required Map<String, dynamic>? json,
  }) {
    final value = json?[key] ?? json?[StrUtils.toSnakeCase(key)];
    if (null is T && value == null) {
      return null as T;
    }

    if (value is bool) {
      return value as T;
    }
    throw Web3RequestExceptionConst.invalidBoolean(key);
  }

  static T parseParams<T extends Web3MessageCore>(T Function() onParse,
      {Web3RequestException error = Web3RequestExceptionConst.invalidMethodArgruments}) {
    try {
      return onParse();
    } on Web3RequestException {
      rethrow;
    } catch (e) {
      throw error;
    }
  }

  static T parseParams2<T>(T? Function() onParse,
      {Web3RequestException error = Web3RequestExceptionConst.invalidMethodArgruments,
      bool errorOnNull = true}) {
    try {
      final parse = onParse();
      if (parse != null) return parse;
      if (errorOnNull) throw error;
      if (null is T) return parse as T;
      throw error;
    } on Web3RequestException {
      rethrow;
    } catch (e) {
      throw error;
    }
  }
}
