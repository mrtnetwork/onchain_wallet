class Web3AptosConst {
  static const String signMessage = "aptos_signMessage";
  static const String signTransaction = "aptos_signTransaction";
  static const String requestAccounts = "aptos_requestAccounts";
  static const String getNetwork = "aptos_network";
  static const String switchNetwork = "wallet_switchAptosChain";

  // static const int requestAccountTag = 100;
  // static const int signTransactionTag = 101;
  // static const int signMessageV2Tag = 102;
  // static const int signAllTransactionsTag = 103;
  // static const int sendTransactionTag = 104;
  // static const int sendAllTransactionsTag = 105;
  // static const int getNetworkTag = 106;
  // static const int changeNetworkTag = 107;

  static const List<int> sendTransactionDataTag = [1, 2];
  static const List<int> sendTransactionDataConfigTag = [1, 3];
  static const String signMessagePrefix = "APTOS";
}
