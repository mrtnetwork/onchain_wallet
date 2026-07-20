import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:zcash_dart/zcash.dart';

import '../cross/cross.dart'
    if (dart.library.js_interop) '../cross/web/crypto.dart'
    if (dart.library.io) '../cross/io/crypto.dart';

abstract class AppCryptoLibs {
  const AppCryptoLibs();
  factory AppCryptoLibs.instance() {
    return getAppCrypto();
  }
  Future<IResult<AppCryptoLibsMonero>> moneroCrypto(
      AppContext context, List<MoneroAccountKeys> accounts);
  Future<IResult<AppCryptoLibsZcash>> zcashCrypto(AppContext context);
}

abstract class AppCryptoLibsTarget {
  void close();
}

abstract class AppCryptoLibsMonero extends DefaultMoneroOutputUnlocker
    implements AppCryptoLibsTarget {
  const AppCryptoLibsMonero({super.accounts = const []});
}

class AppCryptoLibsZcash implements AppCryptoLibsTarget {
  final ZKLib zklib;
  const AppCryptoLibsZcash(this.zklib);

  @override
  void close() {
    zklib.close();
  }
}
