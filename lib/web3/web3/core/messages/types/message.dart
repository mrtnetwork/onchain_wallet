import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/models/models.dart';
import 'package:on_chain_wallet/web3/web3/core/request/params.dart';
import 'message_types.dart';

abstract class Web3MessageCore with AppSerialization {
  abstract final Web3MessageTypes type;

  const Web3MessageCore();
  factory Web3MessageCore.deserialize({List<int>? bytes, CborObject? object}) {
    final CborTagValue cbor =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    final Web3MessageTypes type = Web3MessageTypes.fromIdentifier(cbor.tags);
    switch (type) {
      case Web3MessageTypes.chains:
        return Web3ChainMessage.deserialize(object: cbor);
      case Web3MessageTypes.walletResponse:
        return Web3WalletResponseMessage.deserialize(object: cbor);
      case Web3MessageTypes.walletRequest:
        return Web3RequestParams.deserialize(object: cbor);
      case Web3MessageTypes.walletGlobalRequest:
        return Web3GlobalRequestParams.deserialize(object: cbor);
      case Web3MessageTypes.globalResponse:
        return Web3GlobalResponseMessage.deserialize(object: cbor);
      case Web3MessageTypes.error:
        return Web3ExceptionMessage.deserialize(object: cbor);
    }
  }
  T cast<T extends Web3MessageCore>() {
    if (this is! T) {
      throw Web3RequestExceptionConst.internalErr("Web3MessageCore.cast",
          details: {"type": runtimeType.toString(), "expected": "$T"});
    }
    return this as T;
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;
}
