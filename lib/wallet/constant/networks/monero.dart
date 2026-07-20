import 'package:blockchain_utils/bip/monero/monero_subaddr.dart';

class MoneroConst {
  static BigInt get extraTxWeight => BigInt.from(100);
  static const int decimal = 12;
  static const int minSubAddressIndex = 0;
  static const int maxSubAddressIndex = MoneroSubaddressConst.subaddrMaxIdx;
  static const int txHashLength = 32;
  static const int keyImageLength = 32;
  // static const Duration avarageBlockTime = Duration(minutes: 2);
  static const Duration moneroSigningTimeout = Duration(minutes: 10);
  static const int ringSize = 16;
  static const int fakeOutputsLength = ringSize - 1;
  static const int maxTxOutput = 15;
  static const String walletRPCLinkExample = "http://localhost:3000/json_rpc";
}
