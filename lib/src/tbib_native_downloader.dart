import 'package:flutter/services.dart';

class TbibNativeDownloader {
  static const MethodChannel _channel = MethodChannel('tbib_downloader');

  static Future<String?> getDownloadsDirectory() async {
    try {
      final String? downloadsPath =
          await _channel.invokeMethod('getDownloadsDirectory');
      return downloadsPath;
    } on PlatformException catch (e) {
      return null;
    }
  }
}
