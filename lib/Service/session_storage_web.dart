import 'dart:html' as html;

class SessionStorageImpl {
  static String? getString(String key) {
    return html.window.sessionStorage[key];
  }

  static void setString(String key, String value) {
    html.window.sessionStorage[key] = value;
  }

  static void remove(String key) {
    html.window.sessionStorage.remove(key);
  }
}
