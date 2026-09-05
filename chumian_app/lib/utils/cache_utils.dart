/// Cache utilities for enterprise services
class CacheUtils {
  CacheUtils._();
  static final CacheUtils instance = CacheUtils._();
  final Map<String, dynamic> _cache = <String, dynamic>{};
  final Map<String, DateTime> _expiry = <String, DateTime>{};
  
  void set(String key, dynamic value, [Duration? ttl]) {
    _cache[key] = value;
    if (ttl != null) _expiry[key] = DateTime.now().add(ttl);
  }
  
  dynamic get(String key) {
    if (!_cache.containsKey(key)) return null;
    if (_expiry.containsKey(key) && DateTime.now().isAfter(_expiry[key]!)) {
      _cache.remove(key);
      _expiry.remove(key);
      return null;
    }
    return _cache[key];
  }
  
  void remove(String key) { _cache.remove(key); _expiry.remove(key); }
  void clear() { _cache.clear(); _expiry.clear(); }
  bool containsKey(String key) => get(key) != null;
  int get length => _cache.length;
}
