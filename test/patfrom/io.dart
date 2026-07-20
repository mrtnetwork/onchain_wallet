import 'dart:async';

FutureOr<T> doSomting<T>(FutureOr<T> Function() doSomthing) async =>
    await doSomthing();
