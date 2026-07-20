class NetworkConst {
  static const Duration defaultHttpStreamTimeout = Duration(minutes: 10);
  static const Duration defaultHttpRequestTimeout = Duration(minutes: 1);
  static const Duration torInitializationTimeout = Duration(minutes: 3);

  static const Duration socketCloseTimeout = Duration(seconds: 3);
  static const Duration socketConnectTimeout = Duration(seconds: 10);
  static const Duration socketAddMessageTimeout = Duration(seconds: 5);

  static const Duration defaultRequestTimeout = Duration(seconds: 30);
  static const Duration defaultTorRequestTimeout = Duration(seconds: 50);
  static const Duration defaultRequestCooldown = Duration(milliseconds: 150);
  static const Duration hightRequestCooldown = Duration(milliseconds: 500);
  static const Duration socketIdleTimout = Duration(minutes: 3);
}
