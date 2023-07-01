import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'tbib_downloader_method_channel.dart';

abstract class TbibDownloaderPlatform extends PlatformInterface {
  /// Constructs a TbibDownloaderPlatform.
  TbibDownloaderPlatform() : super(token: _token);

  static final Object _token = Object();

  static TbibDownloaderPlatform _instance = MethodChannelTbibDownloader();

  /// The default instance of [TbibDownloaderPlatform] to use.
  ///
  /// Defaults to [MethodChannelTbibDownloader].
  static TbibDownloaderPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TbibDownloaderPlatform] when
  /// they register themselves.
  static set instance(TbibDownloaderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
