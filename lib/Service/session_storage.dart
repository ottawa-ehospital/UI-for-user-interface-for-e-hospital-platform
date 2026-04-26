import 'session_storage_stub.dart'
    if (dart.library.html) 'session_storage_web.dart';

class SessionStorage {
  static String? getString(String key) {
    return SessionStorageImpl.getString(key);
  }

  static void setString(String key, String value) {
    SessionStorageImpl.setString(key, value);
  }

  static void remove(String key) {
    SessionStorageImpl.remove(key);
  }
}
