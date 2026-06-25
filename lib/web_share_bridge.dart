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

  factory WebSharePayload.fromDynamic(dynamic raw, {String? currentUrl}) {
    if (raw is Map) {
      // Map case: Check for common field names used in different sharing implementations
      final title = (raw['title'] ?? raw['name'] ?? raw['subject'] ?? '').toString().trim();
      final text = (raw['text'] ?? raw['desc'] ?? raw['description'] ?? raw['body'] ?? '').toString().trim();
      var url = (raw['url'] ?? raw['link'] ?? raw['href'] ?? raw['uri'] ?? '').toString().trim();
      final message = (raw['message'] ?? '').toString().trim();
      final type = (raw['type'] ?? '').toString().trim();
      
      // Use current URL as fallback if specifically provided
      if (url.isEmpty && currentUrl != null) {
        url = currentUrl.trim();
      }
      
      // Check for slug if URL is missing
      if (url.isEmpty) {
        final slug = (raw['slug'] ?? raw['restaurant_slug'] ?? raw['store_slug'] ?? '').toString().trim();
        if (slug.isNotEmpty) {
          url = 'https://zapoo.co.in/store/$slug';
        }
      }
      
      // Extract URL from text if url is empty
      var finalUrl = url;
      if (finalUrl.isEmpty && text.isNotEmpty) {
        final urlRegExp = RegExp(r'https?://[^\s]+');
        final match = urlRegExp.firstMatch(text);
        if (match != null) {
          finalUrl = match.group(0) ?? '';
        }
      }

      return WebSharePayload(
        title: title,
        text: text,
        url: finalUrl,
        message: message,
        type: type,
      );
    }

    if (raw is List && raw.isNotEmpty) {
      // List case: arguments passed as separate parameters (Title, Text, Url)
      final title = raw.length > 0 ? (raw[0] ?? '').toString().trim() : '';
      final text = raw.length > 1 ? (raw[1] ?? '').toString().trim() : '';
      final url = raw.length > 2 ? (raw[2] ?? '').toString().trim() : '';
      
      // If the first element is actually a Map, recurse
      if (raw[0] is Map) return WebSharePayload.fromDynamic(raw[0], currentUrl: currentUrl);
      
      var finalUrl = url;
      if (finalUrl.isEmpty && currentUrl != null) {
        finalUrl = currentUrl;
      }
      return WebSharePayload(
        title: title,
        text: text,
        url: finalUrl,
        message: '',
        type: 'share',
      );
    }

    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return WebSharePayload.fromDynamic(decoded, currentUrl: currentUrl);
      } catch (_) {
        // Not a JSON string, treat as a direct message
        return WebSharePayload(
          title: '',
          text: '',
          url: '',
          message: raw.trim(),
          type: 'share',
        );
      }
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
    // If we have a direct message and nothing else, use it
    final hasComponents = title.isNotEmpty || text.isNotEmpty || url.isNotEmpty;
    if (!hasComponents && message.isNotEmpty) return message;

    List<String> parts = [];
    
    // Add title if present
    if (title.isNotEmpty) {
      parts.add(title);
    }
    
    // Add text/description if present
    if (text.isNotEmpty) {
      parts.add(text);
    }
    
    // Add URL if present and not already in text
    if (url.isNotEmpty && !text.contains(url)) {
      parts.add(url);
    }
    
    // If we still have nothing but have a message, use it
    if (parts.isEmpty && message.isNotEmpty) {
      return message;
    }
    
    // Final assembly of the share message
    String finalMessage = '';
    
    // 1. Add Title and Text if they exist
    if (title.isNotEmpty) finalMessage += '$title\n';
    if (text.isNotEmpty) finalMessage += '$text\n';
    
    // 2. Add the URL (Prioritize the specific restaurant URL)
    if (url.isNotEmpty) {
      if (finalMessage.isNotEmpty && !finalMessage.endsWith('\n')) finalMessage += '\n';
      finalMessage += url;
    } else {
      // Final Fallback: if absolutely no URL is found, use the base domain
      finalMessage += '\n\nOrder now on Zapoo: https://zapoo.co.in/';
    }
    
    // 3. Add App branding if missing
    if (!finalMessage.contains('Zapoo')) {
      finalMessage += '\n\nShared via Zapoo App';
    }
    
    return finalMessage.trim();
  }
}

// Track last share time to prevent duplicate triggers
DateTime? _lastShareTime;

Future<bool> openNativeShare(dynamic rawPayload, {String? currentUrl}) async {
  final now = DateTime.now();
  if (_lastShareTime != null &&
      now.difference(_lastShareTime!) < const Duration(seconds: 1)) {
    // Return true to avoid triggering error messages on the web side due to debouncing
    return true;
  }
  _lastShareTime = now;

  final payload = WebSharePayload.fromDynamic(rawPayload, currentUrl: currentUrl);
  if (payload.type.isNotEmpty && payload.type != 'share') return false;

  final shareText = payload.toShareText();
  if (shareText.isEmpty) return false;

  await Share.share(
    shareText,
    subject: payload.title.isNotEmpty ? payload.title : null,
  );
  return true;
}
