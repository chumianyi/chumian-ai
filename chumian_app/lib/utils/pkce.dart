import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PkceUtil {
  static String? _storedVerifier;

  static String generateCodeVerifier() {
    final random = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    _storedVerifier = List.generate(64, (i) => chars[random.nextInt(chars.length)]).join();
    return _storedVerifier!;
  }

  static String? get storedVerifier => _storedVerifier;

  static void clearStoredVerifier() {
    _storedVerifier = null;
  }

  static String generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  static String buildAuthUrl({
    required String clientId,
    required String redirectUri,
    required String scope,
  }) {
    final verifier = generateCodeVerifier();
    final challenge = generateCodeChallenge(verifier);
    // 使用 Uri.https 自动正确编码所有查询参数（特别是 redirect_uri 中的 ://）
    final uri = Uri.https('github.com', '/login/oauth/authorize', {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': scope,
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
    });
    return uri.toString();
  }
}
