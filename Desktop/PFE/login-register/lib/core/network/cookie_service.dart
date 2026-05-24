import 'dart:html' as html;

class CookieService {
  static void setString(String key, String value, {int maxAge = 2592000}) {
    html.document.cookie = '$key=${Uri.encodeComponent(value)}; max-age=$maxAge; path=/; samesite=Lax';
  }

  static String? getString(String key) {
    final cookies = html.document.cookie?.split(';') ?? [];
    for (var cookie in cookies) {
      final parts = cookie.split('=');
      if (parts.length >= 2) {
        final currentKey = parts[0].trim();
        if (currentKey == key) {
          return Uri.decodeComponent(parts.sublist(1).join('='));
        }
      }
    }
    return null;
  }

  static void setBool(String key, bool value, {int maxAge = 2592000}) {
    setString(key, value.toString(), maxAge: maxAge);
  }

  static bool? getBool(String key) {
    final val = getString(key);
    if (val == 'true') return true;
    if (val == 'false') return false;
    return null;
  }

  static void setInt(String key, int value, {int maxAge = 2592000}) {
    setString(key, value.toString(), maxAge: maxAge);
  }

  static int? getInt(String key) {
    final val = getString(key);
    if (val != null) {
      return int.tryParse(val);
    }
    return null;
  }

  static void setStringList(String key, List<String> value, {int maxAge = 2592000}) {
    setString(key, value.join(','), maxAge: maxAge);
  }

  static List<String>? getStringList(String key) {
    final val = getString(key);
    if (val != null && val.isNotEmpty) {
      return val.split(',');
    }
    return null;
  }

  static void remove(String key) {
    html.document.cookie = '$key=; max-age=0; path=/';
  }

  static void clear() {
    final cookies = html.document.cookie?.split(';') ?? [];
    for (var cookie in cookies) {
      final parts = cookie.split('=');
      if (parts.isNotEmpty) {
        remove(parts[0].trim());
      }
    }
  }
}
