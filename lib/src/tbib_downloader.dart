import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math' as math;
import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tbib_downloader/src/service/format_bytes.dart';
import 'package:tbib_downloader/src/service/get_avalible_file.dart';

///  class for downloading files from the internet
class TBIBDownloader {
  /// download file from the internet
  static bool _downloadStarted = false;
  static final num _convertBytesToMB = pow(10, 6);

  // 100 ms

  // static late double speed;

  /// download file from the internet
  /// file name with extension
  /// directory name ios only
  Future<String?> downloadFile<T>({
    required Dio dio,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    required String method,
    required String url,
    required String fileName,
    String? directoryName,
    required BuildContext context,
    bool disabledOpenFileButton = false,
    bool disabledDeleteFileButton = false,
    bool disabledShareFileButton = false,
    bool hideButtons = false,
    bool saveFileInDataApp = false,
    bool showNotification = true,
    Duration refreshNotificationProgress = const Duration(seconds: 1),
    bool showDownloadSpeed = true,
    bool showNotificationWithoutProgress = false,
    bool receiveBytesAsMB = false,
    Function({required int receivedBytes, required int totalBytes})?
        onReceiveProgress,
    //required Dio dio,
  }) async {
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.version.sdkInt < 30) {
        await Permission.storage.request();
        if (!await Permission.storage.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              behavior: SnackBarBehavior.floating,
              content: Text('Permission denied to access storage'),
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            openAppSettings();
          });
          return null;
        }
      }
    }

    late String downloadDirectory;

    if (_downloadStarted) {
      dev.log('Download already started');
      return null;
    }
    _downloadStarted = true;
    if (Platform.isAndroid && !saveFileInDataApp) {
      downloadDirectory =
          "${await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOADS)}/";
    } else {
      if (saveFileInDataApp) {
        downloadDirectory = "${(await getApplicationSupportDirectory()).path}/";
      } else {
        downloadDirectory =
            "${(await getApplicationDocumentsDirectory()).path}/";
      }
    }
    if (directoryName != null && Platform.isIOS) {
      downloadDirectory = "$downloadDirectory$directoryName/";
    }
    if (Platform.isAndroid && directoryName != null) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.version.sdkInt > 30) {
        downloadDirectory = "$downloadDirectory$directoryName/";
      }
    }

    if (File(downloadDirectory).existsSync()) {
      File(downloadDirectory).deleteSync(recursive: true);
    }

    await Directory(downloadDirectory).create(recursive: true);
    if (Platform.isIOS && showNotification) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 1,
            channelKey: 'download_channel',
            title: 'Downloading',
            body: 'Downloading $fileName',
            wakeUpScreen: true,
            locked: true),
      );
    }

    DateTime startTime = DateTime.now();
    DateTime endTime = DateTime.now().add(refreshNotificationProgress);
    String? solvePath;
    if (File('$downloadDirectory$fileName').existsSync()) {
      solvePath = await getAvailableFilePath('$downloadDirectory$fileName');
    }
    bool showNewNotification = true;
    try {
      await dio.download(
        url,
        queryParameters: queryParameters,
        solvePath ?? "$downloadDirectory$fileName",
        options: Options(
          headers: headers,
          responseType: ResponseType.bytes,
          followRedirects: false,
        ),
        onReceiveProgress: (count, total) async {
          if (showNotification) {
            final now = DateTime.now();
            if (showNewNotification || now.isAfter(endTime)) {
              showNewNotification = false;

              if (Platform.isAndroid) {
                _onSendProgress(
                  count,
                  total,
                  startTime: startTime,
                  refreshNotificationProgress: refreshNotificationProgress,
                  showNotification: showDownloadSpeed,
                  showDownloadSpeed: showDownloadSpeed,
                  receiveBytesAsMB: receiveBytesAsMB,
                  showNotificationWithoutProgress:
                      showNotificationWithoutProgress,
                  onReceiveProgress: onReceiveProgress,
                );
              } else {
                // iOS-specific updates
                endTime = now.add(refreshNotificationProgress);
                showNewNotification = true;
              }
            }
          }
        },
      );

      if (showNotification) {
        await AwesomeNotifications().dismiss(1);
        await AwesomeNotifications().createNotification(
          actionButtons: hideButtons
              ? null
              : [
                  if (!disabledOpenFileButton)
                    NotificationActionButton(
                      color: Colors.green.shade900,
                      key: "tbib_downloader_open_file",
                      label: "Open File",
                    ),
                  if (!disabledDeleteFileButton)
                    NotificationActionButton(
                      isDangerousOption: true,
                      color: Colors.red.shade900,
                      key: "tbib_downloader_delete_file",
                      label: "Delete File",
                    ),
                  if (!disabledShareFileButton)
                    NotificationActionButton(
                      color: Colors.green.shade900,
                      key: "tbib_downloader_share_file",
                      label: "Share File",
                    ),
                ],
          content: NotificationContent(
            id: 1,
            channelKey: 'download_completed_channel',
            title: 'Download completed',
            body: 'Download completed $fileName',
            wakeUpScreen: true,
            color: Colors.green,
            payload: {
              'path': solvePath ?? "$downloadDirectory$fileName",
              'mime': lookupMimeType(downloadDirectory + fileName)
            },
          ),
        );
      }
    } catch (e) {
      dev.log('download error: $e');
    }
    _downloadStarted = false;

    return solvePath ?? "$downloadDirectory$fileName";
  }

  /// init downloader
  Future<void> init() async {
    var permission = await Permission.notification.isGranted;
    if (!permission) {
      await Permission.notification.request();
    }
    permission = await Permission.notification.isGranted;
    if (permission) {
      await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
              icon: 'resource://drawable/ic_stat_file_download',
              channelKey: 'download_channel',
              importance: NotificationImportance.Max,
              ledOffMs: 100,
              ledOnMs: 500,
              locked: true,
              channelName: 'Download notifications',
              channelDescription: 'Notification channel for download progress',
              defaultColor: Colors.black,
              ledColor: Colors.white,
              channelShowBadge: false),
          NotificationChannel(
              icon: 'resource://drawable/ic_stat_file_download_done',
              importance: NotificationImportance.Max,
              channelKey: 'download_completed_channel',
              channelName: 'Download completed notifications',
              channelDescription: 'Notification channel for download completed',
              defaultColor: Colors.black,
              ledColor: Colors.white,
              channelShowBadge: false),
        ],
      );
    }
  }

  Future<void> _onSendProgress(
    int countDownloaded,
    int total, {
    required bool showDownloadSpeed,
    required bool showNotificationWithoutProgress,
    required bool receiveBytesAsMB,
    required bool showNotification,
    required Duration refreshNotificationProgress,
    required DateTime startTime,
    required Function({required int receivedBytes, required int totalBytes})?
        onReceiveProgress,
  }) async {
    if (Platform.isIOS && showNotification) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: 'upload_channel',
          title: 'Start uploading',
          body: '',
          wakeUpScreen: true,
          locked: true,
        ),
      );
    }

    if (showNotificationWithoutProgress || Platform.isIOS) {
      if (receiveBytesAsMB) {
        onReceiveProgress?.call(
          receivedBytes: (countDownloaded / _convertBytesToMB).floor(),
          totalBytes: (total / _convertBytesToMB).floor(),
        );
      }
      onReceiveProgress?.call(
        receivedBytes: (countDownloaded / _convertBytesToMB).floor(),
        totalBytes: (total / _convertBytesToMB).floor(),
      );
    }
    if (!showNotification) {
      if (receiveBytesAsMB) {
        onReceiveProgress?.call(
          receivedBytes: (countDownloaded / _convertBytesToMB).floor(),
          totalBytes: (total / _convertBytesToMB).floor(),
        );
      }
      onReceiveProgress?.call(
        receivedBytes: (countDownloaded / _convertBytesToMB).floor(),
        totalBytes: (total / _convertBytesToMB).floor(),
      );
    } else {
      await _showProgressNotification(
        // receiveBytesAsFileSizeUnit,
        showDownloadSpeed,
        total,
        countDownloaded,
        // fileName,
        startTime,
      );
      if (receiveBytesAsMB) {
        onReceiveProgress?.call(
          receivedBytes: (countDownloaded / _convertBytesToMB).floor(),
          totalBytes: (total / _convertBytesToMB).floor(),
        );
      }
      onReceiveProgress?.call(
        receivedBytes: (countDownloaded / _convertBytesToMB).floor(),
        totalBytes: (total / _convertBytesToMB).floor(),
      );
    }
  }

  Future<void> _showProgressNotification(
    bool showDownloadSpeed,
    int totalBytes,
    int receivedBytes,
    DateTime startTime,
  ) async {
    // Calculate progress
    final progress =
        totalBytes > 0 ? math.min(receivedBytes / totalBytes * 100, 100) : 0;

    // Format bytes into human-readable units
    final totalData = formatBytes(totalBytes, 2);
    final receivedData = formatBytes(receivedBytes, 2);
    final totalMB = totalData.size;
    final receivedMB = receivedData.size;

    // Calculate download speed
    var speedMBps = 0.0;
    if (showDownloadSpeed) {
      final duration = DateTime.now().difference(startTime);
      final seconds =
          duration.inMilliseconds > 0 ? duration.inMilliseconds / 1000 : 1;
      speedMBps = receivedBytes / seconds / (1024 * 1024); // Speed in MB/s
    }

    // Send notification
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'download_channel',
        title: 'Downloading',
        body:
            'Downloading (${receivedMB.toStringAsFixed(2)} / ${totalMB.toStringAsFixed(2)} MB)'
            '${speedMBps > 0 ? ' Speed: ${speedMBps.toStringAsFixed(2)} MB/s' : ''}',
        notificationLayout: NotificationLayout.ProgressBar,
        wakeUpScreen: true,
        locked: true,
        progress: progress.clamp(0, 100).toDouble(),
      ),
    );
  }
}
