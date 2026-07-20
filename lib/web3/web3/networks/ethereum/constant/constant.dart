class Web3EthereumConst {
  /// method name
  static const String sendTransaction = "eth_sendTransaction";
  static const String personalSign = "personal_sign";
  static const String ethSign_ = "eth_sign";

  static const String requestAccounts = "eth_requestAccounts";
  static const String ethAccounts = "eth_accounts";
  static const String ethChinId = "eth_chainId";
  static const String typedData = "eth_signTypedData";
  static const String typedDataV3 = "eth_signTypedData_v3";
  static const String typedDataV4 = "eth_signTypedData_v4";
  static const String addChain = "wallet_addEthereumChain";
  static const String switchEthereumChain = "wallet_switchEthereumChain";

  static const List<String> ethereumSupportedRpcPorotocols = [
    "http",
    "https",
    "wss",
    "ws"
  ];
}
