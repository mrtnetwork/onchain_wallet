import 'package:blockchain_utils/crypto/crypto/chacha20poly1305/chacha20poly1305.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:on_chain_bridge/models/events/models/wallet_event.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/models/models/encrypted.dart'
    show Web3EncryptedMessage;
import 'package:on_chain_wallet/web3/web3/core/messages/types/message.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';

typedef ONWEB3PERMISSIONUPDATED = Future<bool> Function(Web3PermissionUpdateResponse);

class Web3PermissionUpdateResponse {
  final Web3DappInfo appInfo;
  final Web3ApplicationAuthentication authentication;
  final List<NetworkType> chains;
  final bool hasRequiredPermission;
  const Web3PermissionUpdateResponse(
      {required this.authentication,
      required this.hasRequiredPermission,
      required this.appInfo,
      required this.chains});
}

class Web3UpdatePermissionRequest {
  final List<Chain> lockedChains;
  final List<NetworkType> lockedNetworks;
  final Web3ApplicationAuthentication authentication;
  final Web3ClientInfo? client;
  late final Web3ApplicationAuthentication cloneAutneticated = authentication.clone();

  Web3UpdatePermissionRequest._(
      {List<Chain> lockedChains = const [],
      List<NetworkType> lockedNetworks = const [],
      required this.authentication,
      this.client})
      : lockedChains = lockedChains.immutable,
        lockedNetworks = lockedNetworks.immutable;
  factory Web3UpdatePermissionRequest.chain(
      {List<Chain> lockedChains = const [],
      required Web3ApplicationAuthentication authentication,
      Web3ClientInfo? client}) {
    return Web3UpdatePermissionRequest._(
        authentication: authentication,
        lockedChains: lockedChains,
        client: client,
        lockedNetworks: lockedChains.map((e) => e.network.type).toSet().toList());
  }
  factory Web3UpdatePermissionRequest(
      {required Web3ApplicationAuthentication authentication, Web3ClientInfo? client}) {
    return Web3UpdatePermissionRequest._(
      authentication: authentication,
      client: client,
    );
  }
  factory Web3UpdatePermissionRequest.network(
      {List<NetworkType> networks = const [],
      required Web3ApplicationAuthentication authentication,
      Web3ClientInfo? client}) {
    return Web3UpdatePermissionRequest._(
        authentication: authentication,
        client: client,
        lockedNetworks: networks.toSet().toList());
  }
  bool get hasLockedNetwork => lockedNetworks.isNotEmpty;
  bool get hasLockedChain => lockedChains.isNotEmpty;
  bool networkDisabled(NetworkType network) {
    if (hasLockedNetwork) return !lockedNetworks.contains(network);
    return false;
  }

  bool chainDisabled(Chain network) {
    if (hasLockedChain) return !lockedChains.contains(network);
    return false;
  }
}

typedef ONUPDATEWEB3PERMISSION = void Function(
    Web3UpdatePermissionRequest?, ONWEB3PERMISSIONUPDATED);

enum WalletJSScriptStatus {
  progress,
  active,
  failed,
  block,
  unknownHost;

  bool get inProgress => this == progress;
  static WalletJSScriptStatus? fromJSWalletEvent(WalletEventTypes? event) {
    switch (event) {
      case WalletEventTypes.exception:
        return WalletJSScriptStatus.failed;
      case WalletEventTypes.activation:
        return WalletJSScriptStatus.active;
      default:
        return null;
    }
  }
}

class LastWeb3ActiveClient {
  final String? identifier;
  final String? url;
  final Web3ActiveClient? client;

  const LastWeb3ActiveClient(
      {this.identifier,
      this.web3Status = WalletJSScriptStatus.progress,
      this.client,
      this.url});
  final WalletJSScriptStatus web3Status;

  @override
  String toString() {
    return "latestClient: $identifier $url $client $web3Status ";
  }
}

class Web3PageAuthenticatedResponse {
  final JSWalletEventDart event;
  final Web3ActiveClient? client;
  const Web3PageAuthenticatedResponse({required this.event, required this.client});
}

final class Web3ActiveClient {
  final Web3ClientInfo client;
  final String identifier;
  final String selfPublicKey;
  final ChaCha20Poly1305 crypto;
  final String clientId;
  Web3ActiveClient._(
      {required this.client,
      required this.identifier,
      required this.crypto,
      required this.selfPublicKey,
      required this.clientId});
  factory Web3ActiveClient(
      {required Web3ClientInfo client,
      required String identifier,
      required String selfPublicKey,
      required String clientId,
      required List<int> sharedKey}) {
    return Web3ActiveClient._(
        client: client,
        identifier: identifier,
        selfPublicKey: selfPublicKey,
        crypto: ChaCha20Poly1305(sharedKey),
        clientId: clientId);
  }

  List<int>? decrypt(List<int> message) {
    final encryptMessage = Web3EncryptedMessage.deserialize(bytes: message);
    return crypto.decrypt(encryptMessage.nonce, encryptMessage.message);
  }

  Web3EncryptedMessage encrypt(Web3MessageCore message) {
    final nonce = QuickCrypto.generateRandom(12);
    final encrypt = crypto.encrypt(nonce, message.toCbor().encode());
    return Web3EncryptedMessage(message: encrypt, nonce: nonce);
  }
}
