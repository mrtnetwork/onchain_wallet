import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/global/methods/methods.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';

class Web3DisconnectApplication extends Web3GlobalRequestParams<List<NetworkType>> {
  final NetworkType chain;
  Web3DisconnectApplication({required this.chain});

  factory Web3DisconnectApplication.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletGlobalRequest.tag);
    return Web3DisconnectApplication(chain: NetworkType.fromName(values.rawValueAt(1)));
  }

  @override
  Web3GlobalRequestMethods get method => Web3GlobalRequestMethods.disconnect;

  @override
  Object? toJsWalletResponse(response) {
    return null;
  }

  @override
  List<CborObject?> get serializationItems =>
      [method.identifier.id.toCbor(), chain.name.toCbor()];
}
