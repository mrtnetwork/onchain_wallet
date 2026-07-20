import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/solidity/solidity.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain/solidity/address/core.dart';

enum SolidityContractInterface {
  erc20,
  erc721,
  erc1155,
  none;

  APPAssetUri? get getContractAssetPath {
    return switch (this) {
      SolidityContractInterface.erc1155 => APPConst.assetErc1155Abi,
      SolidityContractInterface.erc721 => APPConst.assetErc721Abi,
      SolidityContractInterface.erc20 => APPConst.assetErc20Abi,
      _ => null,
    };
  }

  String? get id {
    return switch (this) {
      SolidityContractInterface.erc1155 => "0xd9b67a26",
      SolidityContractInterface.erc721 => "0x80ac58cd",
      SolidityContractInterface.erc20 => "0x36372b07",
      _ => null
    };
  }
}

class RPCDetectContactInterface extends EthereumRequest<bool, String> {
  RPCDetectContactInterface(
      {required this.interface,
      required this.contractAddress,
      required this.from,
      super.blockNumber = BlockTagOrNumber.latest})
      : assert(interface.id != null, "Interface id must not be null.");
  final SolidityContractInterface interface;

  @override
  String get method => EthereumMethods.call.value;
  final SolidityAddress from;

  final SolidityAddress contractAddress;

  final AbiFunctionFragment _function = SolidityContractUtils.supperInterfaceId;

  @override
  bool onResonse(result) {
    return _function.decodeOutputHex(result).first;
  }

  @override
  List<dynamic> toJson() {
    final data = BytesUtils.toHexString(
        _function.encode([BytesUtils.fromHexString(interface.id!)]),
        prefix: "0x");
    return [
      {
        "from": from.toSolidityHex(),
        "to": contractAddress.toSolidityHex(),
        "data": data,
      },
      blockNumber
    ];
  }
}
