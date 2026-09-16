// coverage:ignore-file
// Non-web platforms never call these (guarded by kIsWeb at every call site).
String? tabSessionGet(String key) => throw UnimplementedError();

void tabSessionSet(String key, String value) => throw UnimplementedError();

void tabSessionRemove(String key) => throw UnimplementedError();
