import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
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
  static late Dio _dio;
  static bool _downloadStarted = false;
  static final num _convertBytesToMB = pow(10, 6);

  // 100 ms

  // static late double speed;

  /// init downloader
  Future<void> init() async {
    await AwesomeNotifications().requestPermissionToSendNotifications();
    await Permission.storage.request();
    _dio = Dio();

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

  /// download file from the internet
  /// file name with extension
  /// directory name ios only
  Future<String?> downloadFile<T>({
    required String url,
    required String fileName,
    String? directoryName,
    bool showNotification = true,
    bool disabledOpenFileButton = false,
    bool disabledDeleteFileButton = false,
    bool hideButtons = false,
    bool saveFileInDataApp = false,
    Duration refreshNotificationProgress = const Duration(seconds: 1),
    bool showDownloadSpeed = true,
    bool showNotificationWithoutProgress = false,
    bool receiveBytesAsMB = false,
    Function({required int receivedBytes, required int totalBytes})?
        onReceiveProgress,
    //required Dio dio,
  }) async {
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
      downloadDirectory = "${(await getApplicationDocumentsDirectory()).path}/";
    }
    if (directoryName != null) {
      downloadDirectory = "$downloadDirectory$directoryName/";
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
    DateTime notificationDisplayDate = DateTime.now();
    DateTime endTime = DateTime.now().add(refreshNotificationProgress);
    String? solvePath;
    if (File('$downloadDirectory$fileName').existsSync()) {
      solvePath = await getAvailableFilePath('$downloadDirectory$fileName');
    }
    bool showNewNotification = true;
    try {
      await _dio.download(
        url,
        solvePath ?? "$downloadDirectory$fileName",
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
        ),
        onReceiveProgress: (receivedBytes, totalBytes) async {
          // if (receiveBytesAsFileSizeUnit) {
          // receivedBytes = formatBytes(receivedBytes, 2).size;
          // totalBytes = formatBytes(totalBytes, 2).size;
          // }
          if (showNotificationWithoutProgress || Platform.isIOS) {
            if (totalBytes == -1) {
              dev.log('totalBytes == -1');

              return;
            }
            if (receiveBytesAsMB) {
              return onReceiveProgress?.call(
                  receivedBytes: (receivedBytes / _convertBytesToMB).floor(),
                  totalBytes: (totalBytes / _convertBytesToMB).floor());
            }
            return onReceiveProgress?.call(
                receivedBytes: receivedBytes, totalBytes: totalBytes);
          }
          if (showNotification && totalBytes != -1) {
            if (showNewNotification) {
              showNewNotification = false;

              await _showProgressNotification(showDownloadSpeed, totalBytes,
                  receivedBytes, fileName, startTime);
            } else {
              notificationDisplayDate = DateTime.now();
              if (notificationDisplayDate.millisecondsSinceEpoch >
                  endTime.millisecondsSinceEpoch) {
                //   await AwesomeNotifications().dismiss(1);
                showNewNotification = true;
                notificationDisplayDate = endTime;
                endTime = DateTime.now().add(refreshNotificationProgress);
              }

              // _showProgressNotification(showDownloadSpeed, totalBytes,
              //     receivedBytes, fileName, startTime);
            }
          }
          if (totalBytes != -1) {
            if (receiveBytesAsMB) {
              return onReceiveProgress?.call(
                  receivedBytes: (receivedBytes / _convertBytesToMB).floor(),
                  totalBytes: (totalBytes / _convertBytesToMB).floor());
            }
            return onReceiveProgress?.call(
                receivedBytes: receivedBytes, totalBytes: totalBytes);
          } else {
            dev.log('totalBytes == -1');
          }
        },
      );

      if (showNotification) {
        await AwesomeNotifications().dismiss(1);
        await AwesomeNotifications().createNotification(
          actionButtons: hideButtons
              ? null
              : [
                  NotificationActionButton(
                    enabled: !disabledOpenFileButton,
                    color: Colors.green.shade900,
                    key: "tbib_downloader_open_file",
                    label: "Open File",
                  ),
                  NotificationActionButton(
                    enabled: !disabledDeleteFileButton,
                    key: "tbib_downloader_delete_file",
                    isDangerousOption: true,
                    color: Colors.red.shade900,
                    label: "Delete File",
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

  Future _showProgressNotification(
      // bool receiveBytesAsFileSizeUnit,
      bool showDownloadSpeed,
      int totalBytes,
      int receivedBytes,
      String fileName,
      DateTime startTime) async {
    num progress = min((receivedBytes / totalBytes * 100).round(), 100);
    num totalMB = formatBytes(totalBytes, 2).size;
    num receivedMB = formatBytes(receivedBytes, 2).size;
    // String receiveUnit = formatBytes(receivedBytes, 2).unit;
    String totalUnit = formatBytes(totalBytes, 2).unit;

    double speedMbps = 0;
    if (showDownloadSpeed) {
      Duration duration = DateTime.now().difference(startTime);
      double seconds = duration.inMilliseconds / 1000;
      speedMbps = receivedMB / seconds * 8;
    }
    // dev.log(
    //     'after noti receivedBytes: $receivedBytes, totalBytes: $totalBytes progress: $progress');
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: 1,
          channelKey: 'download_channel',
          title: 'Downloading',
          body:
              'Downloading $fileName ${totalBytes >= 0 ? '(${(receivedMB).toStringAsFixed(2)} / ${(totalMB).toStringAsFixed(2)})' : '${(receivedMB).toStringAsFixed(2)} / nil'} $totalUnit ${speedMbps == 0 ? "" : 'speed ${(speedMbps / 8).toStringAsFixed(2)} MB/s'} ',
          notificationLayout: NotificationLayout.ProgressBar,
          wakeUpScreen: true,
          locked: true,
          progress: progress.toInt()),
    );
  }
}
