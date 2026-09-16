import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'tab_session_storage.dart';

/// Persists the Supabase auth session in `sessionStorage` on web, so that
/// each browser tab keeps its own login (e.g. one tab as super admin, another
/// as a branch/warehouse user) instead of sharing — and overwriting — the
/// same `localStorage` session across tabs on the same origin.
///
/// Non-web platforms fall back to the default `SharedPreferencesLocalStorage`
/// — behavior there is unchanged.
class TabScopedLocalStorage extends LocalStorage {
  TabScopedLocalStorage({required this.persistSessionKey});

  final String persistSessionKey;
  late final _fallback =
      SharedPreferencesLocalStorage(persistSessionKey: persistSessionKey);

  @override
  Future<void> initialize() async {
    if (!kIsWeb) await _fallback.initialize();
  }

  @override
  Future<bool> hasAccessToken() async {
    if (kIsWeb) return tabSessionGet(persistSessionKey) != null;
    return _fallback.hasAccessToken();
  }

  @override
  Future<String?> accessToken() async {
    if (kIsWeb) return tabSessionGet(persistSessionKey);
    return _fallback.accessToken();
  }

  @override
  Future<void> removePersistedSession() async {
    if (kIsWeb) {
      tabSessionRemove(persistSessionKey);
      return;
    }
    await _fallback.removePersistedSession();
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    if (kIsWeb) {
      tabSessionSet(persistSessionKey, persistSessionString);
      return;
    }
    await _fallback.persistSession(persistSessionString);
  }
}

/// Same tab-scoping as [TabScopedLocalStorage], for the PKCE code verifier
/// storage used during the auth flow.
class TabScopedGotrueAsyncStorage extends GotrueAsyncStorage {
  final _fallback = SharedPreferencesGotrueAsyncStorage();

  @override
  Future<String?> getItem({required String key}) async {
    if (kIsWeb) return tabSessionGet(key);
    return _fallback.getItem(key: key);
  }

  @override
  Future<void> removeItem({required String key}) async {
    if (kIsWeb) {
      tabSessionRemove(key);
      return;
    }
    await _fallback.removeItem(key: key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    if (kIsWeb) {
      tabSessionSet(key, value);
      return;
    }
    await _fallback.setItem(key: key, value: value);
  }
}
