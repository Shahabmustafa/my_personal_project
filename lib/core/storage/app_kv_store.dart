import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tab_session_storage.dart';

/// Key-value store used for auth/session data.
///
/// On web it is backed by `sessionStorage`, which is scoped to a single
/// browser tab — so logging in as a different user in another tab never
/// overwrites this tab's session. On other platforms (mobile/desktop, where
/// there is only ever one app instance) it keeps using `SharedPreferences`,
/// same as before.
class AppKvStore {
  Future<void> setString(String key, String value) async {
    if (kIsWeb) {
      tabSessionSet(key, value);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    if (kIsWeb) return tabSessionGet(key);
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> setBool(String key, bool value) async {
    if (kIsWeb) {
      tabSessionSet(key, value.toString());
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    if (kIsWeb) {
      final raw = tabSessionGet(key);
      return raw == null ? null : raw == 'true';
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  Future<void> remove(String key) async {
    if (kIsWeb) {
      tabSessionRemove(key);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
