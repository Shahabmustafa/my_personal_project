/// Network na hone par bhi raw URL / "ClientException" dikhane ke bajaye
/// saaf message — baqi errors ka text wahi rehta hai.
const noInternetMessage =
    'No internet connection. Please check your connection and try again.';

bool isNetworkError(Object? e) {
  final s = (e ?? '').toString().toLowerCase();
  return s.contains('failed to fetch') ||
      s.contains('socketexception') ||
      s.contains('failed host lookup') ||
      s.contains('xmlhttprequest error') ||
      s.contains('network is unreachable') ||
      s.contains('connection refused') ||
      s.contains('connection closed') ||
      s.contains('connection reset') ||
      s.contains('connection timed out') ||
      s.contains('timeoutexception') ||
      s.contains('authretryablefetchexception') ||
      s.contains('clientexception with socketexception');
}

/// UI ke liye error text: network issue → "No internet connection…",
/// warna `Exception: ` hata kar asal message.
String friendlyError(Object? e, {String prefix = ''}) {
  if (isNetworkError(e)) return noInternetMessage;
  final msg = (e ?? 'Unknown error').toString().replaceFirst(
    RegExp(r'^Exception: '),
    '',
  );
  return '$prefix$msg';
}
