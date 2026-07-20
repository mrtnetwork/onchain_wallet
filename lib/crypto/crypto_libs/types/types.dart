import 'package:monero_dart/monero_dart.dart';

class MoneroCryptoUnlockOutput {
  final MoneroAccountKeys account;
  final MoneroLockedOutput output;
  MoneroCryptoUnlockOutput({required this.account, required this.output});
}
