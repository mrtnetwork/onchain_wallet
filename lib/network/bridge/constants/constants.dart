class BridgeConstants {
  static const Duration relayMessageResponseTimeout = Duration(seconds: 60);
  static const int nonceLength = 12;
  static const int messageTypeLength = 1;
  static const Duration defaultRequestTimeout = Duration(minutes: 1);

  static const String wcRelayUrl = "wss://relay.walletconnect.org/";
  static const String wcProjectId = "eca409135e9616e51b4e4de241abe322";
  static const String wcRelayProtocol = "irn";
  static const String wcProtocol = "wc";
  static const int wcDefaultVersion = 2;
  static const Duration wcClientPrediocEvent = Duration(seconds: 20);
}
