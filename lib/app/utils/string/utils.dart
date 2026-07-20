import 'package:blockchain_utils/utf8/src/encoder.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_wallet/app/utils/utils.dart';

class StrUtils {
  static bool isHtml(String error) {
    return RegExp(
            r'<(html|head|body|title|h1|h2|h3|h4|h5|h6|p|div|span|a|form|table|img)[^>]*>',
            caseSensitive: false)
        .hasMatch(error);
  }

  static const String _rtlChars = r'\u0591-\u07FF\uFB1D-\uFDFD\uFE70-\uFEFC';

  /// Practical patterns to identify strong LTR and RTL characters,
  /// respectively.  These patterns are not completely correct according to the
  /// Unicode standard. They are simplified for performance and small code size.
  static const String _ltrChars =
      r'A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02B8\u0300-\u0590'
      r'\u0800-\u1FFF\u2C00-\uFB1C\uFDFE-\uFE6F\uFEFD-\uFFFF';

  /// Determines if the first character in [text] with strong directionality is
  /// RTL. If [isHtml] is true, the text is HTML or HTML-escaped.
  static bool startsWithRtl(String text, [bool isHtml = false]) {
    return RegExp('^[^$_ltrChars]*[$_rtlChars]').hasMatch(text);
  }

  static String camelCaseToSpaced(String input) {
    return input
        // Insert a space before each capital letter (except the first one)
        .replaceAllMapped(RegExp(r'(?<=[a-z])([A-Z])'), (match) => ' ${match.group(1)}')
        // Capitalize the first letter of each word
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  static String fromBytes(List<int> bytes,
      {bool allowInvalidOrMalformed = false, bool allowHexEncoding = true}) {
    try {
      return StringUtils.decode(bytes, allowInvalidOrMalformed: allowInvalidOrMalformed);
    } catch (_) {
      if (!allowHexEncoding) rethrow;
      return BytesUtils.toHexString(bytes);
    }
  }

  static String toCamelCase(String input, {bool space = false}) {
    if (input.isEmpty) {
      return input;
    }
    input = input.replaceAll('-', ' ').replaceAll('_', ' ');

    final List<String> words = input.split(' ');

    // Capitalize the first letter of each words
    final List<String> capitalizedWords = words.map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1);
      } else {
        return '';
      }
    }).toList();

    // Join the words to form CamelCase
    final String camelCaseString = capitalizedWords.join(space ? ' ' : '');

    return camelCaseString;
  }

  static String? validateLengthOrNull(String? val, int length) {
    if (val == null || val.length > length) return null;
    return val;
  }

  static String toRawString(String string) {
    return string
        .replaceAll('\\', '\\\\')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t')
        .replaceAll('\$', r'\$')
        .replaceAll('"', r'\"')
        .replaceAll("'", r"\'")
        .replaceAll('\f', r'\f')
        .replaceAll('\u0000', r'\u0000')
        .replaceAll('\u0001', r'\u0001')
        .replaceAll('\u0002', r'\u0002')
        .replaceAll('\u0003', r'\u0003')
        .replaceAll('\u0004', r'\u0004')
        .replaceAll('\u0005', r'\u0005')
        .replaceAll('\u0006', r'\u0006')
        .replaceAll('\u0007', r'\u0007')
        .replaceAll('\u0008', r'\u0008')
        .replaceAll('\u0009', r'\u0009')
        .replaceAll('\u000A', r'\u000A')
        .replaceAll('\u000B', r'\u000B')
        .replaceAll('\u000C', r'\u000C')
        .replaceAll('\u000D', r'\u000D')
        .replaceAll('\u000E', r'\u000E')
        .replaceAll('\u000F', r'\u000F')
        .replaceAll('\u0010', r'\u0010')
        .replaceAll('\u0011', r'\u0011')
        .replaceAll('\u0012', r'\u0012')
        .replaceAll('\u0013', r'\u0013')
        .replaceAll('\u0014', r'\u0014')
        .replaceAll('\u0015', r'\u0015')
        .replaceAll('\u0016', r'\u0016')
        .replaceAll('\u0017', r'\u0017')
        .replaceAll('\u0018', r'\u0018')
        .replaceAll('\u0019', r'\u0019')
        .replaceAll('\u001A', r'\u001A')
        .replaceAll('\u001B', r'\u001B')
        .replaceAll('\u001C', r'\u001C')
        .replaceAll('\u001D', r'\u001D')
        .replaceAll('\u001E', r'\u001E')
        .replaceAll('\u001F', r'\u001F')
        .replaceAll('\u007F', r'\u007F');
  }

  static String to3Digits(String number,
      {String separator = ",", bool allowEmptyFractional = false}) {
    String integerPart = '';
    String fractionalPart = '';
    bool negative = false;
    bool hasDot = false;
    if (number.contains('.')) {
      final List<String> parts = number.split('.');
      integerPart = parts[0];
      fractionalPart = parts[1];
      hasDot = true;
    } else {
      integerPart = number;
    }

    if (integerPart.startsWith("-")) {
      negative = true;
      integerPart = integerPart.substring(1);
    }

    final List<String> groups = [];
    int i = integerPart.length;
    while (i > 0) {
      final String group = integerPart.substring(IntUtils.max(0, i - 3), i);
      groups.insert(0, group);

      i -= 3;
    }
    String result = groups.join(separator);
    if (hasDot) {
      if (fractionalPart.isEmpty) {
        if (allowEmptyFractional) result += '.';
      } else {
        result += '.$fractionalPart';
      }
    }

    if (negative) return "-$result";
    return result;
  }

  static String? validateUri(String? url,
      {List<String> schame = const ['http', 'https']}) {
    if (url == null) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (!isValidHost(uri.host)) return null;
    if (!schame.contains(uri.scheme.toLowerCase())) return null;
    return uri.normalizePath().toString();
  }

  static bool isValidHost(String host) {
    if (host.isEmpty) return false;
    if (host == "localhost") return true;
    final RegExp regex = RegExp(
        r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$|^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)+([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])$');
    return regex.hasMatch(host);
  }

  static bool isLocalHost(String url) {
    final uri = Uri.tryParse(url);
    final host = uri?.host;
    if (host == null || host.isEmpty) return false;

    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '0.0.0.0' ||
        host == '::1';
  }

  static String? validateRawSocket(String? url,
      {List<String> schame = const ['tcp', 'tls']}) {
    if (url == null) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.isEmpty) return null;
    if (!schame.contains(uri.scheme.toLowerCase())) return null;
    if (!isValidHost(uri.host)) return null;
    if (uri.path.isNotEmpty && uri.path != "/") return null;
    return uri.normalizePath().toString();
  }

  static bool isOnion(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final onionRegex = RegExp(r'^[a-z2-7]{56}\.onion$');
    if (onionRegex.hasMatch(url)) {
      return true;
    }
    Uri? uri = Uri.tryParse(url);

    // If no scheme, try adding one
    if (uri == null || uri.host.isEmpty) {
      uri = Uri.tryParse("http://$url");
      if (uri == null) return false;
    }
    final host = uri.host.toLowerCase().replaceAll(RegExp(r'\.$'), '');
    return host.endsWith('.onion');
  }

  static int findFirstMissingNumber(List<int> numbers, {int start = 0}) {
    final List<int> sortedNumbers = List.from(numbers)..sort();
    int missingNumber = start;

    for (final number in sortedNumbers) {
      if (number == missingNumber) {
        missingNumber++;
      } else if (number > missingNumber) {
        break;
      }
    }
    return missingNumber;
  }

  static String addNumberToMakeUnique(List<String> list, String target) {
    int count = 1;
    String result = target;

    while (list.contains(result)) {
      count++;
      result = '$target ($count)';
    }

    return result;
  }

  static String stripControlChars(String url) {
    return url.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
  }

  static String _twoDigits(int n) {
    if (n >= 10) {
      return "$n";
    } else {
      return "0$n";
    }
  }

  static String toFileName(DateTime time) {
    return "${time.year}_${_twoDigits(time.month)}_${_twoDigits(time.day)}"
        "${_twoDigits(time.hour)}-${_twoDigits(time.minute)}-${_twoDigits(time.second)}";
  }

  static String removeSchame(String uri) {
    final schames = ["https://", "http://", "ws://", "wss://"];
    final lower = uri.toLowerCase();
    final schame = schames.firstWhereOrNull((element) => lower.startsWith(element));
    if (schame == null) return uri;
    return uri.substring(schame.length - 1);
  }

  static String substring(String value, {int length = 5, String replace = ''}) {
    if (value.length > length) {
      return value.replaceRange(length - 1, value.length, replace);
    }
    return value;
  }

  static bool isValidIPv4WithPort(String ipv4) {
    // Regular expression to match IPv4 address with optional port
    final RegExp ipv4WithPortRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}:\d+$');

    // Check if the input matches the pattern
    return ipv4WithPortRegex.hasMatch(ipv4);
  }

  static String? isValidTcpAddress(String? url) {
    if (url == null) return null;
    if (isValidIPv4WithPort(url)) {
      return url;
    }
    final RegExp regExp = RegExp(r'^[a-zA-Z0-9.-]+:\d+(/[^?#]*)?$');
    if (regExp.hasMatch(url)) {
      return url;
    }
    return null;
  }

  static bool isHex(String? v) {
    if (v == null) return false;
    if (v.isEmpty) return false;
    return StringUtils.isHexBytes(v);
  }

  static String removeLastSlash(String v) {
    if (v.endsWith("/")) return v.substring(v.length - 1);
    return v;
  }

  static String removeSeperator(String v, {String sperator = ','}) {
    return v.replaceAll(sperator, '');
  }

  static String toSnakeCase(String input) {
    // Replace all uppercase letters with _letter (lowercase)
    String snakeCase = input.replaceAllMapped(
        RegExp(r'[A-Z]'), (Match match) => '_${match.group(0)!.toLowerCase()}');

    // Remove any leading underscores that might have been added
    snakeCase = snakeCase.startsWith('_') ? snakeCase.substring(1) : snakeCase;

    // Replace spaces and special characters with underscores
    snakeCase = snakeCase.replaceAll(RegExp(r'\s+|[^a-zA-Z0-9]+'), '_');

    return snakeCase;
  }

  static final _domainRegex = RegExp(
      r"(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)");
  static bool isDomain(String? url) {
    if (url == null) return false;
    return _domainRegex.hasMatch(url);
  }

  static List<String> separateBySpace(String? str) {
    if (str == null) return [];
    final sperate = str.trim().split(" ");
    return sperate.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  static List<String>? separateByLength(String str, int length) {
    if (str.length % length != 0) return null;
    if (str.isEmpty) return [];
    int offset = 0;
    final List<String> results = [];
    while (offset < str.length) {
      results.add(str.substring(offset, offset + length));
      offset += length;
    }
    return results;
  }

  static int getStringBytesLength(String value) {
    return switch (StringUtils.isHexBytes(value)) {
      true => value.length ~/ 2,
      false => UTF8Encoder.inBytesLength(value),
    };
  }
}
