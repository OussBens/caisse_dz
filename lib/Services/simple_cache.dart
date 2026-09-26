/// Cache générique en mémoire avec expiration (TTL), sans dépendance externe.
/// Utilisé pour éviter de re-solliciter le réseau pour des données qui
/// changent rarement (listes marques/catégories du catalogue distant) ou
/// pour accélérer les scans répétés d'un même code-barres pendant une
/// session de saisie en rafale (SmartScan / réassort).
class TtlCache<K, V> {
  TtlCache({required this.ttl, this.maxEntries = 100});

  final Duration ttl;
  final int maxEntries;
  final Map<K, _CacheEntry<V>> _entries = {};

  V? get(K key) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _entries.remove(key);
      return null;
    }
    return entry.value;
  }

  /// Indique si [key] a une entrée fraîche (non expirée), y compris quand la
  /// valeur mise en cache est elle-même `null` — utile pour distinguer "pas
  /// encore mis en cache" de "mis en cache comme absent/introuvable".
  bool has(K key) {
    final entry = _entries[key];
    if (entry == null) return false;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _entries.remove(key);
      return false;
    }
    return true;
  }

  void set(K key, V value) {
    if (_entries.length >= maxEntries && !_entries.containsKey(key)) {
      // Évince l'entrée la plus ancienne pour borner la taille du cache.
      final oldestKey = _entries.entries
          .reduce((a, b) => a.value.expiresAt.isBefore(b.value.expiresAt) ? a : b)
          .key;
      _entries.remove(oldestKey);
    }
    _entries[key] = _CacheEntry(value, DateTime.now().add(ttl));
  }

  void clear() => _entries.clear();
}

class _CacheEntry<V> {
  _CacheEntry(this.value, this.expiresAt);
  final V value;
  final DateTime expiresAt;
}
