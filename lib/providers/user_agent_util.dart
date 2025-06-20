import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<String> getUserAgent() async {
  final packageInfo = await PackageInfo.fromPlatform();
  final deviceInfoPlugin = DeviceInfoPlugin();
  String platform = '', osVersion = '', device = '';

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfoPlugin.androidInfo;
    platform = 'android';
    osVersion = androidInfo.version.release ?? '';
    device = '${androidInfo.manufacturer} ${androidInfo.model}';
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfoPlugin.iosInfo;
    platform = 'ios';
    osVersion = iosInfo.systemVersion ?? '';
    device = iosInfo.utsname.machine ?? '';
  } else if (Platform.isLinux) {
    final linuxInfo = await deviceInfoPlugin.linuxInfo;
    platform = 'linux';
    osVersion = linuxInfo.version ?? '';
    device = linuxInfo.machineId ?? '';
  } else if (Platform.isMacOS) {
    final macInfo = await deviceInfoPlugin.macOsInfo;
    platform = 'macos';
    osVersion = macInfo.osRelease ?? '';
    device = macInfo.model ?? '';
  } else if (Platform.isWindows) {
    final winInfo = await deviceInfoPlugin.windowsInfo;
    platform = 'windows';
    osVersion = winInfo.displayVersion ?? '';
    device = winInfo.computerName ?? '';
  } else {
    platform = Platform.operatingSystem.toLowerCase();
    osVersion = Platform.operatingSystemVersion;
    device = '';
  }

  return '${packageInfo.appName}/${packageInfo.version} ; (platform=$platform; os=$osVersion; device=$device)';
}
