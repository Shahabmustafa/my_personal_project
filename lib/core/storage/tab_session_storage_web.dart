import 'package:web/web.dart';

/// Browser `sessionStorage` — unlike `localStorage`, it is scoped to a single
/// tab, so it never leaks a login between two tabs open on the same origin.
final _sessionStorage = window.sessionStorage;

String? tabSessionGet(String key) => _sessionStorage.getItem(key);

void tabSessionSet(String key, String value) =>
    _sessionStorage.setItem(key, value);

void tabSessionRemove(String key) => _sessionStorage.removeItem(key);
