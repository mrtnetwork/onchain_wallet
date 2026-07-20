import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/core/core.dart';
import 'package:on_chain_wallet/network/bridge/types/server/types.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/types.dart';

mixin IBridgeSesshionController on IBridgeCore {
  final Map<String, IBridgeSession> _activeSessions = {};

  @override
  Future<IBridgeSession?> getSession(String topic) async {
    return _activeSessions[topic];
  }

  void _removeProtocolsSessions(Iterable<BridgeProtocol> protocols) {
    final keys = _activeSessions.entries
        .where((e) => protocols.contains(e.value.protocol))
        .map((e) => e.key)
        .toList();
    for (final i in keys) {
      _activeSessions.remove(i);
    }
  }

  @override
  Future<IResult<void>> addAndSubscribeSession(IBridgeSession session) {
    addSession(session);
    return subscribe(session);
  }

  @override
  void addSession(IBridgeSession session) {
    _activeSessions[session.topic] = session;
  }

  @override
  Future<IResult<void>> removeAndUnSubscribeSession(IBridgeSession session) {
    removeSession(session);
    return unSubscribe(session);
  }

  @override
  bool removeSession(IBridgeSession session) {
    return _activeSessions.remove(session.topic) != null;
  }

  @override
  Future<void> dispose({List<BridgeProtocol> protocols = BridgeProtocol.values}) async {
    _removeProtocolsSessions(protocols);
  }

  @override
  Future<void> close({List<BridgeProtocol> protocols = BridgeProtocol.values}) async {
    _removeProtocolsSessions(protocols);
  }
}
