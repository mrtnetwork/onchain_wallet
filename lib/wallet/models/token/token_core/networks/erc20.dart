import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain/ethereum/src/address/evm_address.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/core/core.dart';

class ETHERC20Token extends SolidityToken {
  ETHERC20Token._(
      {required super.balance,
      required super.token,
      required this.contractAddress,
      required super.updated})
      : super();
  factory ETHERC20Token.create(
      {required BigInt balance,
      required Token token,
      required ETHAddress contractAddress}) {
    return ETHERC20Token._(
        balance: IntegerBalance.token(balance, token, immutable: true),
        token: token,
        contractAddress: contractAddress,
        updated: DateTime.now());
  }
  factory ETHERC20Token.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: TokenCoreType.erc20.tag);
    final Token token = Token.deserialize(object: cbor.objectAt<CborTagValue>(0));
    final ETHAddress contractAddress =
        ETHAddress.deserializeIAddress(bytes: cbor.rawValueAt(1));
    final IntegerBalance balance =
        IntegerBalance.token(cbor.rawValueAt(2), token, immutable: true);
    final DateTime updated = cbor.rawValueAt(3);
    return ETHERC20Token._(
        balance: balance,
        token: token,
        contractAddress: contractAddress,
        updated: updated);
  }
  @override
  ETHERC20Token clone({BigInt? balance}) {
    return ETHERC20Token.create(
        balance: balance ?? streamBalance.value.balance,
        token: token,
        contractAddress: contractAddress);
  }

  @override
  ETHERC20Token updateToken(Token updateToken) {
    return ETHERC20Token.create(
        balance: streamBalance.value.balance,
        token: updateToken,
        contractAddress: contractAddress);
  }

  @override
  final ETHAddress contractAddress;

  @override
  List get variables => [contractAddress.address];

  @override
  String? get issuer => contractAddress.address;

  @override
  String toHexAddress() {
    return contractAddress.toHex();
  }

  @override
  late final String? type = "erc20";

  @override
  TokenCoreType get tokenType => TokenCoreType.erc20;

  @override
  String get identifier => contractAddress.address;

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        CborBytesValue(contractAddress.encodeAsIAddress()),
        streamBalance.value.balance.toCbor(),
        CborEpochIntValue(updated)
      ];
}
