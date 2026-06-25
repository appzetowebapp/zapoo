import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class LocationSettingsUtil {
  static const _channel = MethodChannel('com.mobasket.user/geolocation');

  /// Shows the Google Location Enable Dialog (Play Services resolution dialog).
  /// Returns true if location was enabled, false otherwise.
  /// Only runs on Android; returns true immediately on other platforms.
  static Future<bool> showLocationEnableDialog() async {
    if (!Platform.isAndroid) return true;
    try {
      final result = await _channel.invokeMethod<bool>('showLocationSettingsDialog');
      return result ?? false;
    } catch (e) {
      debugPrint('LocationSettingsUtil: $e');
      return false;
    }
  }
}
