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
import 'package:tbib_downloader/src/service/get_avalible_file.dart';
import 'package:tbib_downloader/src/service/handler_time.dart';

///  class for downloading files from the internet
class TBIBDownloader {
  /// download file from the internet
  static late Dio dio;
  static bool downloadStarted = false;
  // static late double speed;

  /// init downloader
  Future<void> init() async {
    await AwesomeNotifications().requestPermissionToSendNotifications();
    await Permission.storage.request();
    dio = Dio();

    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
            icon: 'resource://drawable/ic_stat_file_download',
            channelKey: 'download_channel',
            importance: NotificationImportance.Low,
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
    //bool showDownloadSpeed = true,
    bool showNotificationWithoutProgress = false,
    Function({required int receivedBytes, required int totalBytes})?
        onReceiveProgress,
    //required Dio dio,
  }) async {
    late String downloadDirectory;
    if (downloadStarted) {
      dev.log('Download already started');
      return null;
    }
    downloadStarted = true;
    if (Platform.isAndroid) {
      downloadDirectory =
          "${await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOADS)}/";
    } else {
      downloadDirectory = "${(await getApplicationDocumentsDirectory()).path}/";
    }
    if (directoryName != null && !Platform.isAndroid) {
      downloadDirectory = "$downloadDirectory$directoryName/";
    }

    if (File(downloadDirectory).existsSync()) {
      File(downloadDirectory).deleteSync(recursive: true);
    }

    await Directory(downloadDirectory).create(recursive: true);
    // if (Platform.isIOS && showNotification) {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'download_channel',
        title: 'Downloading',
        body: 'Downloading $fileName',
        wakeUpScreen: true,
      ),
    );
    // }
    // String speedText = 'calculating...';
    // int speed = 0;

    // int lastCount = 0;
    // int totalSec = 0;
    Handler handler = Handler();
    String? solvePath;
    if (File('$downloadDirectory$fileName').existsSync()) {
      solvePath = await getAvailableFilePath('$downloadDirectory$fileName');
    }
    bool showNewNotification = true;
    await dio.download(
      url,
      solvePath ?? "$downloadDirectory$fileName",
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
      ),
      onReceiveProgress: (receivedBytes, totalBytes) async {
        if (showNotificationWithoutProgress || Platform.isIOS) {
          return onReceiveProgress?.call(
              receivedBytes: receivedBytes, totalBytes: totalBytes);
        }
        if (showNotification && totalBytes != -1) {
          // dev.log(
          //     'before noti receivedBytes: $receivedBytes, totalBytes: $totalBytes'
          //     'showNewNotification: $showNewNotification');
          if (showNewNotification) {
            showNewNotification = false;

            await _showProgressNotification(
                totalBytes, receivedBytes, fileName);
          } else {
            handler.post(const Duration(seconds: 1), () {
              showNewNotification = true;
            });
          }
        }
        if (totalBytes != -1) {
          return onReceiveProgress?.call(
              receivedBytes: receivedBytes, totalBytes: totalBytes);
        } else {
          dev.log('totalBytes == -1');
        }
      },
    );

    if (showNotification) {
      await Future.delayed(const Duration(milliseconds: 500));
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
    downloadStarted = false;
    return solvePath ?? "$downloadDirectory$fileName";
  }

  Future<void> _showProgressNotification(
      int totalBytes, int receivedBytes, String fileName) async {
    int progress = 0;
    double totalMB = 0;
    double receivedMB = 0;
    if (totalBytes != -1) {
      progress = min((receivedBytes / totalBytes * 100).round(), 100);
      totalMB = totalBytes / 1048576;
      receivedMB = (receivedBytes / 1048576);
    } else {
      progress = 100;
      totalMB = totalBytes / 1048576;
    }
    // dev.log(
    //     'after noti receivedBytes: $receivedBytes, totalBytes: $totalBytes progress: $progress');
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: 1,
          channelKey: 'download_channel',
          title: 'Downloading',
          body:
              'Downloading $fileName ${totalBytes >= 0 ? '(${(receivedMB).toStringAsFixed(2)} / ${(totalMB).toStringAsFixed(2)})' : '${(receivedMB).toStringAsFixed(2)} / nil'} MB/s',
          notificationLayout: NotificationLayout.ProgressBar,
          // wakeUpScreen: true,
          progress: progress),
    );

    // if (showDownloadSpeed) {
    //   // calculate internet speed
    //   Future.delayed(const Duration(seconds: 1), () async {
    //     if (!showDownloadSpeed) {
    //       return;
    //     }
    //     totalSec++;
    //     // calculate internet speed

    //     speed =
    //         ((lastCount / totalSec) * (totalBytes / receivedBytes))
    //             .toInt();
    //     // speed = (count - lastCount) ~/ total;
    //     lastCount = receivedBytes;
    //   });
    // }
  }
}
