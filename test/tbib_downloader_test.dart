import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:tbib_downloader/tbib_downloader_method_channel.dart';
import 'package:tbib_downloader/tbib_downloader_platform_interface.dart';

class MockTbibDownloaderPlatform
    with MockPlatformInterfaceMixin
    implements TbibDownloaderPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final TbibDownloaderPlatform initialPlatform =
      TbibDownloaderPlatform.instance;

  test('$MethodChannelTbibDownloader is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelTbibDownloader>());
  });
}
