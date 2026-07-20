extension ExtQuickImutableList<T> on Iterable<T> {
  List<T> get immutable => List<T>.unmodifiable(this);
  List<T>? get immutableAndNullOnEmpty => isEmpty ? null : List<T>.unmodifiable(this);
  List<T>? get nullOnEmoty => isEmpty ? null : toList();
  T? firstWhereOrNull(bool Function(T) test, {T? Function()? orElse}) {
    try {
      return firstWhere(test);
    } on StateError {
      return orElse?.call();
    }
  }

  T? lastWhereOrNull(bool Function(T) test, {T? Function()? orElse}) {
    try {
      return lastWhere(test);
    } on StateError {
      return orElse?.call();
    }
  }

  T? atIndexOrNull(int i) {
    if (length >= i) return null;
    return elementAt(i);
  }

  T? get lastOrNull {
    if (isEmpty) return null;
    return last;
  }

  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
