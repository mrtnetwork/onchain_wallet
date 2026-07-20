import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';

class Web3GlobalRequestMethods extends Web3RequestMethods {
  @override
  bool get isGlobalMethod => true;
  const Web3GlobalRequestMethods._(
      {required super.identifier,
      required super.name,
      super.methodsName = const [],
      super.reloadAuthenticated = true});
  static const Web3GlobalRequestMethods disconnect = Web3GlobalRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag3, name: "disconnect");
  static const Web3GlobalRequestMethods connect = Web3GlobalRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag4, name: "connect");
  static const Web3GlobalRequestMethods connectSilent = Web3GlobalRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag5, name: "connect_silent");
  static const Web3GlobalRequestMethods switchNetwork = Web3GlobalRequestMethods._(
      identifier: AppSerializationIdentifier.runtimeTag6, name: "switch_network");
  static const List<Web3GlobalRequestMethods> values = [
    disconnect,
    connect,
    switchNetwork,
    connectSilent,
  ];
  static Web3GlobalRequestMethods fromIdentifier(int? id) {
    return values.firstWhere((e) => e.identifier.id == id,
        orElse: () => throw Web3RequestExceptionConst.methodDoesNotExist);
  }

  static Web3GlobalRequestMethods? fromName(String? name) {
    return values.firstWhereOrNull((e) => e.name == name || e.methodsName.contains(name));
  }
}
