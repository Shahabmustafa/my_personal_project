import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FingerprintHelperException implements Exception {
  final String message;

  /// Finger lagayi hi nahi gayi (wait khatam) — error nahi, dobara suno.
  final bool isTimeout;
  const FingerprintHelperException(this.message, {this.isTimeout = false});
  @override
  String toString() => message;
}

/// Branch PC par chalne wale "Safi Fingerprint Helper" se baat — wahi
/// DigitalPersona U.are.U 4500 reader ko chalata hai (browser USB nahi
/// padh sakta). Helper sirf is PC (127.0.0.1) par sunta hai.
///   GET  /status    → {"reader": true}
///   POST /enroll    → {"template": "BASE64"}        (finger 4 dafa)
///   POST /identify  → {"user_id": "UUID" or null}      (finger 1 dafa)
///        body: {"templates":[{"user_id":..,"template":..}]}
class FingerprintHelperClient {
  static const baseUrl = 'http://127.0.0.1:8765';

  static const _notRunning =
      'Fingerprint helper is not running on this computer. '
      'Start "Safi Fingerprint Helper" and plug in the reader.';

  Future<Map<String, dynamic>> _call(
    String method,
    String path, {
    Object? body,
    required Duration timeout,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final res = method == 'GET'
          ? await http.get(uri).timeout(timeout)
          : await http
                .post(
                  uri,
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(body ?? {}),
                )
                .timeout(timeout);
      final map = res.body.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(res.body) as Map).cast<String, dynamic>();
      if (res.statusCode >= 400) {
        throw FingerprintHelperException(
          map['error'] as String? ?? 'Fingerprint reader error',
        );
      }
      return map;
    } on FingerprintHelperException {
      rethrow;
    } on TimeoutException {
      throw const FingerprintHelperException(
        'No finger detected — try again',
        isTimeout: true,
      );
    } catch (_) {
      throw const FingerprintHelperException(_notRunning);
    }
  }

  /// Helper chal raha hai aur reader laga hai?
  Future<bool> isReady() async {
    try {
      final r = await _call(
        'GET',
        '/status',
        timeout: const Duration(seconds: 3),
      );
      return r['reader'] == true;
    } on FingerprintHelperException {
      return false;
    }
  }

  /// Naya finger register — template (base64) wapas.
  Future<String> enroll() async {
    final r = await _call(
      'POST',
      '/enroll',
      timeout: const Duration(seconds: 90),
    );
    final t = r['template'] as String?;
    if (t == null || t.isEmpty) {
      throw const FingerprintHelperException('Fingerprint was not captured');
    }
    return t;
  }

  /// Ek finger lagwa kar [templates] mein se match — user_id ya null.
  Future<String?> identify(
    List<({String userId, String template})> templates,
  ) async {
    final r = await _call(
      'POST',
      '/identify',
      body: {
        'templates': [
          for (final t in templates)
            {'user_id': t.userId, 'template': t.template},
        ],
      },
      timeout: const Duration(seconds: 20),
    );
    return r['user_id'] as String?;
  }
}
