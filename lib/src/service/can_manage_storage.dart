import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> canManageStorage() async {
  if (!Platform.isAndroid) return true;
  if (Platform.isAndroid) {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    var androidInfo = await deviceInfo.androidInfo;
    if (int.parse(androidInfo.version.release) > 10 &&
        await Permission.manageExternalStorage.isGranted == true) {
      return true;
    } else {
      return false;
    }
  } else {
    return true;
  }
}
