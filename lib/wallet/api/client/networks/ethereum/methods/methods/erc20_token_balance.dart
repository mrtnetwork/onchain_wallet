import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/crypto/networks/solidity/solidity.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain/solidity/address/core.dart';

class RPCERC20TokenBalance extends EthereumRequest<BigInt, String> {
  RPCERC20TokenBalance(
    this.contractAddress,
    this.accountAddress, {
    BlockTagOrNumber? blockNumber,
  }) : super(blockNumber: blockNumber ?? BlockTagOrNumber.latest);

  @override
  String get method => EthereumMethods.call.value;

  final String contractAddress;
  final SolidityAddress accountAddress;

  final AbiFunctionFragment _function = SolidityContractUtils.erc20Balance;

  @override
  BigInt onResonse(result) {
    return EthereumRequest.onBigintResponse(result);
  }

  @override
  List<dynamic> toJson() {
    return [
      {
        "to": contractAddress,
        "data": BytesUtils.toHexString(_function.encode([accountAddress]), prefix: "0x"),
      },
      blockNumber
    ];
  }
}
