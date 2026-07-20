import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';

import 'package:on_chain_wallet/crypto/types/networks.dart' show NetworkType;
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/global/methods/methods.dart';

class Web3ConnectApplication extends Web3GlobalRequestParams<List<NetworkType>> {
  final NetworkType? chain;
  final List<int>? networks;
  factory Web3ConnectApplication.global() {
    return Web3ConnectApplication._();
  }
  factory Web3ConnectApplication.network(NetworkType network) {
    return Web3ConnectApplication._(chain: network);
  }
  factory Web3ConnectApplication.networks(List<int> networks) {
    return Web3ConnectApplication._(networks: networks.isEmpty ? null : networks);
  }

  Web3ConnectApplication._({this.chain, this.networks});

  factory Web3ConnectApplication.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletGlobalRequest.tag);
    return Web3ConnectApplication._(
        chain: values.maybeObjectAt<NetworkType, CborStringValue>(
            1, (e) => NetworkType.fromName(e.value)),
        networks: values.maybeObjectAt<List<int>, CborListValue>(
            2, (e) => e.allRawValuesAs<int>()));
  }

  @override
  Web3GlobalRequestMethods get method => Web3GlobalRequestMethods.connect;

  @override
  Object? toJsWalletResponse(response) {
    return null;
  }

  @override
  List<CborObject?> get serializationItems => [
        method.identifier.id.toCbor(),
        chain?.name.toCbor(),
        switch (networks) {
          null => CborNullValue(),
          List<int> ids =>
            AppSerialization.listFromObjects(ids.map((e) => e.toCbor()).toList())
        }
      ];
}
