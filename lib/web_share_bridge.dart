import 'dart:convert';
import 'package:share_plus/share_plus.dart';

class WebSharePayload {
  final String title;
  final String text;
  final String url;
  final String message;
  final String type;

  const WebSharePayload({
    required this.title,
    required this.text,
    required this.url,
    required this.message,
    required this.type,
  });

  factory WebSharePayload.fromDynamic(dynamic raw) {
    if (raw is Map) {
      return WebSharePayload(
        title: (raw['title'] ?? '').toString().trim(),
        text: (raw['text'] ?? '').toString().trim(),
        url: (raw['url'] ?? '').toString().trim(),
        message: (raw['message'] ?? '').toString().trim(),
        type: (raw['type'] ?? '').toString().trim(),
      );
    }

    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return WebSharePayload.fromDynamic(decoded);
      } catch (_) {}
    }

    return const WebSharePayload(
      title: '',
      text: '',
      url: '',
      message: '',
      type: '',
    );
  }

  String toShareText() {
    // If we have a direct message, use it as fallback only if other fields are empty
    final hasMainContent = title.isNotEmpty || text.isNotEmpty || url.isNotEmpty;
    if (!hasMainContent) return message;

    String out = '';
    if (title.isNotEmpty) out += '$title\n';
    if (text.isNotEmpty) out += '$text\n';
    
    // Only add URL if it's not already present in the text
    if (url.isNotEmpty && !text.contains(url)) {
      out += url;
    }
    
    out = out.trim();
    return out.isNotEmpty ? out : message;
  }
}

// Track last share time to prevent duplicate triggers
DateTime? _lastShareTime;

Future<bool> openNativeShare(dynamic rawPayload) async {
  final now = DateTime.now();
  if (_lastShareTime != null &&
      now.difference(_lastShareTime!) < const Duration(seconds: 1)) {
    // Return true to avoid triggering error messages on the web side due to debouncing
    return true;
  }
  _lastShareTime = now;

  final payload = WebSharePayload.fromDynamic(rawPayload);
  if (payload.type.isNotEmpty && payload.type != 'share') return false;

  final shareText = payload.toShareText();
  if (shareText.isEmpty) return false;

  await Share.share(
    shareText,
    subject: payload.title.isNotEmpty ? payload.title : null,
  );
  return true;
}
