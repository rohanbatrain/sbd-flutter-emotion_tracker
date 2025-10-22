import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<String> getUserAgent() async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfoPlugin = DeviceInfoPlugin();
    String platform = '', osVersion = '', device = '';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      platform = 'android';
      osVersion = androidInfo.version.release;
      device = '${androidInfo.manufacturer} ${androidInfo.model}';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      platform = 'ios';
      osVersion = iosInfo.systemVersion;
      device = iosInfo.utsname.machine;
    } else if (Platform.isLinux) {
      try {
        final linuxInfo = await deviceInfoPlugin.linuxInfo;
        platform = 'linux';
        osVersion = linuxInfo.version ?? '';
        device = linuxInfo.machineId ?? '';
      } catch (e) {
        // Fallback for Linux if device info fails
        platform = 'linux';
        osVersion = Platform.operatingSystemVersion;
        device = 'linux-desktop';
      }
    } else if (Platform.isMacOS) {
      try {
        final macInfo = await deviceInfoPlugin.macOsInfo;
        platform = 'macos';
        osVersion = macInfo.osRelease;
        device = macInfo.model;
      } catch (e) {
        // Fallback for macOS if device info fails
        platform = 'macos';
        osVersion = Platform.operatingSystemVersion;
        device = 'mac-desktop';
      }
    } else if (Platform.isWindows) {
      try {
        final winInfo = await deviceInfoPlugin.windowsInfo;
        platform = 'windows';
        osVersion = winInfo.displayVersion;
        device = winInfo.computerName;
      } catch (e) {
        // Fallback for Windows if device info fails
        platform = 'windows';
        osVersion = Platform.operatingSystemVersion;
        device = 'windows-desktop';
      }
    } else {
      platform = Platform.operatingSystem.toLowerCase();
      osVersion = Platform.operatingSystemVersion;
      device = 'unknown';
    }

    return '${packageInfo.appName}/${packageInfo.version} ; (platform=$platform; os=$osVersion; device=$device)';
  } catch (e) {
    // Ultimate fallback if everything fails - return a simple user agent
    print('Error getting user agent: $e');
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final platform = Platform.operatingSystem.toLowerCase();
      return '${packageInfo.appName}/${packageInfo.version} ; (platform=$platform; os=${Platform.operatingSystemVersion}; device=desktop)';
    } catch (e2) {
      // Last resort fallback
      return 'emotion_tracker/1.0.0 ; (platform=${Platform.operatingSystem.toLowerCase()}; os=${Platform.operatingSystemVersion}; device=desktop)';
    }
  }
}
