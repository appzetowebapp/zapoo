import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

/// Utility class to handle deep linking
class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  
  // Callback for when a new link is received
  Function(Uri)? onLinkReceived;

  /// Initialize deep link listening
  Future<void> initialize() async {
    // 1. Handle the initial link (if the app was opened via a link)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('🔗 Initial Deep Link: $initialUri');
        // Wait a bit to ensure the UI is ready or use a post-frame callback
        Future.delayed(const Duration(milliseconds: 500), () {
          onLinkReceived?.call(initialUri);
        });
      }
    } catch (e) {
      debugPrint('❌ Error getting initial link: $e');
    }

    // 2. Listen for subsequent links (when the app is already running)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('🔗 New Deep Link Received: $uri');
      onLinkReceived?.call(uri);
    }, onError: (err) {
      debugPrint('❌ Deep Link Stream Error: $err');
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
