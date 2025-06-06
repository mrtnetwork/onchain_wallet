import 'package:on_chain_wallet/wallet/models/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/models/network/network.dart';
import 'package:on_chain_wallet/crypto/requets/messages/models/models/signing.dart';

typedef OnSigning<T> = Future<T> Function(OnSignRequest generateSignature);

class WalletSigningRequest<T> {
  final List<ChainAccount> addresses;
  final WalletNetwork network;
  final OnSigning<T> sign;
  const WalletSigningRequest._(
      {required this.addresses, required this.network, required this.sign});
  factory WalletSigningRequest(
      {required List<ChainAccount> addresses,
      required WalletNetwork network,
      required OnSigning<T> sign}) {
    return WalletSigningRequest._(
        addresses: addresses, network: network, sign: sign);
  }
}
