import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/network.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/signing.dart';

typedef CbOnSigning<T> = Future<T> Function(OnSignRequest generateSignature);

class WalletSigningRequest<T> {
  final List<ChainAccount> addresses;
  final WalletNetwork network;
  final CbOnSigning<T> sign;
  const WalletSigningRequest._(
      {required this.addresses, required this.network, required this.sign});
  factory WalletSigningRequest(
      {required List<ChainAccount> addresses,
      required WalletNetwork network,
      required CbOnSigning<T> sign}) {
    return WalletSigningRequest._(addresses: addresses, network: network, sign: sign);
  }
}
