import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/database/actions/actions.dart';
import 'package:on_chain_wallet/app/utils/datetime/datetime.dart';
import 'package:on_chain_wallet/network/bridge/constants/constants.dart';
import 'package:on_chain_wallet/network/bridge/exception/exception.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/types.dart';
import 'package:on_chain_wallet/network/bridge/types/wallet_connect/types.dart';

class BridgeUtils {
  static BridgeUri wcParseUri(Uri uri) {
    String protocol = uri.scheme;
    String path = uri.path;
    final List<String> splitParams = path.split('@');
    final queryParameters = uri.queryParameters;
    final relayProtocol = queryParameters["relay-protocol"];
    final String? symKey = queryParameters["symKey"];
    final relayData = queryParameters["relay-data"];
    final expiryTimestamp = IntUtils.tryParse(queryParameters["expiryTimestamp"]);
    final topic = splitParams[0];
    if (splitParams.length == 1 ||
        relayProtocol == null ||
        symKey == null ||
        !StringUtils.isHexBytes(symKey, lengthInBytes: Ed25519KeysConst.pubKeyByteLen)) {
      throw BridgeExceptionConst.invalidPairUrl;
    }
    final int? version = IntUtils.tryParse(splitParams[1]);
    if (version == 1) {
      throw BridgeExceptionConst.unsuportedPairingUrl;
    }
    List<String> methods = uri.queryParameters['methods']
            ?.split(",")
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];
    return BridgeUri(
        protocol: protocol,
        topic: topic,
        version: version ?? BridgeConstants.wcDefaultVersion,
        expire: DateTimeUtils.detectEpochUnit(expiryTimestamp ?? -1) ??
            wcDefaultPairExpireTime(),
        methods: methods,
        relay: WCProtocolOptions(protocol: relayProtocol, data: relayData),
        symkey: BytesUtils.fromHexString(symKey));
  }

  static Uri wcCreateUri(BridgeUri uriData) {
    final path = [uriData.topic, uriData.version.toString()].join("@");
    String? methods;
    if (uriData.methods.isNotEmpty) {
      methods = uriData.methods.join(",");
    }
    final relayData = uriData.relay.data;
    final Map<String, String> queryParameters = {
      "relay-protocol": uriData.relay.protocol,
      if (relayData != null) "relay-data": relayData,
      "symKey": BytesUtils.toHexString(uriData.symkey),
      if (methods != null) "methods": methods,
      "expiryTimestamp": DateTimeUtils.secondsSinceEpoch(uriData.expire).toString(),
    };
    return Uri(path: path, scheme: uriData.protocol, queryParameters: queryParameters);
  }

  static String wcGenerateRelayUrl(
      {required String relayUrl, required String projectId, required String auth}) {
    final uri = Uri.parse(relayUrl);
    final params = {"auth": auth, "projectId": projectId};
    return uri.replace(queryParameters: params).toString();
  }

  static int wcDefaultSessionExpire() {
    final expire = DateTime.now().add(const Duration(days: 7)).toUtc();
    return DateTimeUtils.secondsSinceEpoch(expire);
  }

  static DateTime wcDefaultSessionExpireTime() {
    return DateTime.now().add(const Duration(days: 7)).toUtc();
  }

  static DateTime wcDefaultPairExpireTime() {
    return DateTime.now().add(const Duration(minutes: 5));
  }

  static DateTime wcDefaultRequestExpireTime() {
    return DateTime.now().add(const Duration(minutes: 5));
  }

  static int? createStorageRequestId(IStorageEvent event) {
    switch (event.action) {
      case StorageActionWrite action:
        final String key =
            "${action.storage}_${action.actionId}_${action.data.column.storageId ?? 0}_${action.data.column.key ?? ''}_${action.data.column.keyA ?? ''}";
        return Crc32().quickIntDigest(key.codeUnits);
      default:
        return null;
    }
  }
}
