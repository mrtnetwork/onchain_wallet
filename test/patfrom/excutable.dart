import 'dart:async';

import 'cross.dart'
    if (dart.library.js_interop) 'web.dart'
    if (dart.library.io) 'io.dart';

class PlatformExutable {
  static FutureOr<T> paltformCall<T>(FutureOr<T> Function() callback) async =>
      await doSomting(callback);
}
