import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain/solidity/address/core.dart';
import 'package:on_chain_wallet/crypto/networks/solidity/solidity.dart';

class RPCERC20Decimal extends EthereumRequest<int?, String> {
  RPCERC20Decimal(this.contractAddress, {BlockTagOrNumber? blockNumber})
      : super(blockNumber: blockNumber ?? BlockTagOrNumber.latest);

  @override
  String get method => EthereumMethods.call.value;

  final SolidityAddress contractAddress;

  final AbiFunctionFragment _function = SolidityContractUtils.erc20Decimal;

  @override
  int? onResonse(result) {
    if (result == "0x") return null;
    return EthereumRequest.onIntResponse(result);
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
