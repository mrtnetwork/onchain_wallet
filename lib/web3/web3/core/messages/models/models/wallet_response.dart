import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message_types.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';

class Web3WalletResponseMessage extends Web3MessageCore {
  final Web3APPData? authenticated;
  final Object? result;
  final NetworkType network;
  Web3WalletResponseMessage._(
      {this.result, required this.network, required this.authenticated});
  factory Web3WalletResponseMessage(
      {Object? result, required NetworkType network, Web3APPData? authenticated}) {
    return Web3WalletResponseMessage._(
        result: result, authenticated: authenticated, network: network);
  }

  factory Web3WalletResponseMessage.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletResponse.tag);
    final Map<String, dynamic> result = StringUtils.toJson(values.rawValueAt<String>(0));
    return Web3WalletResponseMessage._(
        result: result["result"],
        authenticated: values.maybeObjectAt<Web3APPData, CborTagValue>(
            1, (p0) => Web3APPData.deserialize(object: p0)),
        network: NetworkType.fromIdentifier(values.rawValueAt(2)));
  }

  @override
  Web3MessageTypes get type => Web3MessageTypes.walletResponse;

  List<T> resultAsList<T>({int? length}) {
    try {
      final list = (result as List).cast<T>();
      if (length == null) return list;
      return list.sublist(0, length);
    } catch (e) {
      throw Web3RequestExceptionConst.internalErr("resultAsList",
          reason: "Uexpected result type.");
    }
  }

  List<List<int>> resultAsListOfBytes({int? length}) {
    try {
      final list = (result as List).map((e) => (e as List).cast<int>()).toList();
      if (length == null) return list;
      return list.sublist(0, length);
    } catch (e) {
      throw Web3RequestExceptionConst.internalErr("resultAsListOfBytes",
          reason: "Uexpected result type.");
    }
  }

  Map<String, dynamic> resultAsMap() {
    try {
      return (result as Map).cast<String, dynamic>();
    } catch (e) {
      throw Web3RequestExceptionConst.internalErr("resultAsMap",
          reason: "Uexpected result type.");
    }
  }

  String resultAsString() {
    try {
      return result as String;
    } catch (e) {
      throw Web3RequestExceptionConst.internalErr("resultAsString",
          reason: "Uexpected result type.");
    }
  }

  T resultAs<T>() {
    try {
      return result as T;
    } catch (e) {
      throw Web3RequestExceptionConst.internalErr("resultAs<$T>",
          reason: "Uexpected result type.");
    }
  }

  @override
  List<CborObject?> get serializationItems => [
        StringUtils.fromJson({"result": result}).toCbor(),
        authenticated?.toCbor(),
        network.identifier.id.toCbor(),
      ];
}
