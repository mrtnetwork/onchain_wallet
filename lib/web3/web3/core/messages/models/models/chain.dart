import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message_types.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';

class Web3ChainMessage extends Web3MessageCore {
  @override
  Web3MessageTypes get type => Web3MessageTypes.chains;
  final Web3APPData authenticated;

  Web3ChainMessage({required this.authenticated});
  factory Web3ChainMessage.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: Web3MessageTypes.chains.tag);

    return Web3ChainMessage(
        authenticated: Web3APPData.deserialize(object: values.objectAt<CborTagValue>(0)));
  }

  @override
  List<CborObject?> get serializationItems => [authenticated.toCbor()];
}
