import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message_types.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';

class Web3GlobalResponseMessage extends Web3MessageCore {
  final Web3APPData? authenticated;
  Web3GlobalResponseMessage({this.authenticated});

  factory Web3GlobalResponseMessage.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.globalResponse.tag);

    return Web3GlobalResponseMessage(
        authenticated: values.maybeObjectAt<Web3APPData, CborTagValue>(
            0, (e) => Web3APPData.deserialize(object: e)));
  }

  @override
  Web3MessageTypes get type => Web3MessageTypes.globalResponse;
  @override
  List<CborObject?> get serializationItems => [authenticated?.toCbor()];
}
