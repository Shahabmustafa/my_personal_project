import 'tab_session_storage_stub.dart'
    if (dart.library.js_interop) 'tab_session_storage_web.dart' as impl;

/// Thin wrapper around the platform-specific sessionStorage functions.
/// Only ever called on web (callers must guard with `kIsWeb`).
String? tabSessionGet(String key) => impl.tabSessionGet(key);

void tabSessionSet(String key, String value) => impl.tabSessionSet(key, value);

void tabSessionRemove(String key) => impl.tabSessionRemove(key);
