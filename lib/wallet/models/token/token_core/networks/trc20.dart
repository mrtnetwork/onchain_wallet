import 'package:on_chain/tron/src/address/tron_address.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/core/core.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';

class TronTRC20Token extends TronToken implements SolidityToken {
  TronTRC20Token._(
      {required super.balance,
      required super.token,
      required this.contractAddress,
      required super.updated})
      : super();
  factory TronTRC20Token.create(
      {required BigInt balance,
      required Token token,
      required TronAddress contractAddress}) {
    return TronTRC20Token._(
        balance: IntegerBalance.token(balance, token, immutable: true),
        token: token,
        contractAddress: contractAddress,
        updated: DateTime.now());
  }
  factory TronTRC20Token.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: TokenCoreType.trc20.tag);

    final Token token = Token.deserialize(object: cbor.objectAt<CborTagValue>(0));
    final TronAddress contractAddress =
        TronAddress.deserializeIAddress(bytes: cbor.rawValueAt(1));
    final IntegerBalance balance =
        IntegerBalance.token(cbor.rawValueAt(2), token, immutable: true);
    final DateTime updated = cbor.rawValueAt(3);
    return TronTRC20Token._(
        balance: balance,
        token: token,
        contractAddress: contractAddress,
        updated: updated);
  }
  @override
  TronTRC20Token clone({BigInt? balance}) {
    return TronTRC20Token.create(
        balance: balance ?? streamBalance.value.balance,
        token: token,
        contractAddress: contractAddress);
  }

  @override
  TronTRC20Token updateToken(Token updateToken) {
    return TronTRC20Token.create(
        balance: streamBalance.value.balance,
        token: updateToken,
        contractAddress: contractAddress);
  }

  @override
  final TronAddress contractAddress;

  @override
  List get variables => [contractAddress.toAddress()];

  @override
  String get issuer => contractAddress.toAddress();

  @override
  String toHexAddress() {
    return contractAddress.toAddress(false);
  }

  @override
  TokenCoreType get tokenType => TokenCoreType.trc20;

  @override
  TronTokenTypes get tronTokenType => TronTokenTypes.trc20;

  @override
  late final String? type = tronTokenType.name;

  @override
  String get identifier => contractAddress.toAddress();

  @override
  List<CborObject?> get serializationItems => [
        token.toCbor(),
        CborBytesValue(contractAddress.encodeAsIAddress()),
        streamBalance.value.balance.toCbor(),
        CborEpochIntValue(updated)
      ];
}
