// lib/services/device_service.dart
// Wraps native Android APIs for device & system information.
//
// ── Native Android APIs used ──────────────────────────────────────────────
//   android.os.Build                     → device model, brand, hardware info
//   android.os.Build.VERSION             → OS version, API level, SDK
//   android.app.ActivityManager          → RAM info (getMemoryInfo)
//   android.os.Environment               → storage paths, external storage state
//   android.os.StatFs                    → filesystem stats (free/total bytes)
//   android.content.pm.PackageManager    → installed packages, features
//   android.os.Process                   → process ID, UID
//
// Flutter interops via MethodChannel to native Kotlin/Java code.
// For the Flutter layer, device_info_plus wraps android.os.Build for us.
// ─────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceService {
  DeviceService._();
  static final DeviceService instance = DeviceService._();

  final DeviceInfoPlugin _plugin = DeviceInfoPlugin();

  /// Returns all Android device/OS info from android.os.Build.
  /// Equivalent to: Build.MODEL, Build.BRAND, Build.VERSION.RELEASE etc.
  Future<Map<String, String>> getAndroidInfo() async {
    if (!Platform.isAndroid) {
      return {'error': 'Not running on Android'};
    }
    try {
      final info = await _plugin.androidInfo;
      return {
        'Device Name':     info.device,
        'Brand':           info.brand,
        'Model':           info.model,
        'Manufacturer':    info.manufacturer,
        'Product':         info.product,
        'Hardware':        info.hardware,
        'Board':           info.board,
        'Host':            info.host,
        'Android Version': info.version.release,
        'API Level':       info.version.sdkInt.toString(),
        'Security Patch':  info.version.securityPatch ?? 'N/A',
        'Build ID':        info.id,
        'Fingerprint':     info.fingerprint,
        'Is Physical':     info.isPhysicalDevice.toString(),
        'Supported ABIs':  info.supportedAbis.join(', '),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
