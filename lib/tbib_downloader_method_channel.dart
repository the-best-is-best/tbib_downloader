import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tbib_downloader_platform_interface.dart';

/// An implementation of [TbibDownloaderPlatform] that uses method channels.
class MethodChannelTbibDownloader extends TbibDownloaderPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('tbib_downloader');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
