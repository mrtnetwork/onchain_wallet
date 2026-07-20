extension ExtQuickImutableMap<K, V> on Map<K, V> {
  Map<K, V> get withoutNullValue => {
        for (final i in entries)
          if (i.value != null) i.key: i.value
      };
  Map<K, V>? get nullOnEmpty => isEmpty ? null : this;
}
