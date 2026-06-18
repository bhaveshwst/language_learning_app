import 'package:language_learning_app/core/constants/const_api_url.dart';

class MessagingMediaUrl {
  MessagingMediaUrl._();

  static String? resolve(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty || !_looksLikeUrl(value)) return null;

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    if (value.startsWith('/')) {
      final base = ConstApiUrl.baseURL.replaceAll(RegExp(r'/+$'), '');
      return '$base$value';
    }

    return value;
  }

  static bool _looksLikeUrl(String value) {
    if (value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('/')) {
      return true;
    }

    // Reject base64 payloads accidentally mapped to image fields.
    if (value.length > 256 && !value.contains('://')) {
      return false;
    }

    return false;
  }
}
