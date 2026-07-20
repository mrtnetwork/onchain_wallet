import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/crypto/networks/solidity/solidity.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain/solidity/address/core.dart';

class RPCERC20Name extends EthereumRequest<String?, String?> {
  RPCERC20Name(this.contractAddress, {super.blockNumber});

  @override
  String get method => EthereumMethods.call.value;

  final SolidityAddress contractAddress;

  final AbiFunctionFragment _function = SolidityContractUtils.erc20Name;

  @override
  String? onResonse(result) {
    if (result == null || result == "0x") return null;
    final decode = _function.decodeOutputHex(result);
    if (decode.isEmpty) return null;
    return decode.first;
  }

  @override
  List<dynamic> toJson() {
    return [
      {
        "to": contractAddress.toSolidityHex(),
        "data": BytesUtils.toHexString(_function.encode([]), prefix: "0x"),
      },
      blockNumber
    ];
  }
}
