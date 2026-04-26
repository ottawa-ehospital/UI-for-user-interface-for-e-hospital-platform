class SessionStorageImpl {
  static final Map<String, String> _memory = <String, String>{};

  static String? getString(String key) {
    return _memory[key];
  }

  static void setString(String key, String value) {
    _memory[key] = value;
  }

  static void remove(String key) {
    _memory.remove(key);
  }
}
