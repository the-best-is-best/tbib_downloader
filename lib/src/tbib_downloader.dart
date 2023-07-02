import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dio/dio.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

///  class for downloading files from the internet
class TBIBDownloader {
  /// download file from the internet
  static late Dio dio;
  // static late double speed;

  /// init downloader
  Future<void> init() async {
    await AwesomeNotifications().requestPermissionToSendNotifications();
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
    dio = Dio();

    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
            icon: 'resource://drawable/ic_stat_file_download',
            channelKey: 'download_channel',
            channelName: 'Download notifications',
            channelDescription: 'Notification channel for download progress',
            defaultColor: Colors.black,
            ledColor: Colors.white,
            channelShowBadge: false),
        NotificationChannel(
            icon: 'resource://drawable/ic_stat_file_download_done',
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
  Future<String> downloadFile<T>({
    required String url,
    required String fileName,
    String? directoryName,
    bool showNotification = true,
    bool disabledOpenFileButton = false,
    bool disabledDeleteFileButton = false,
    bool hideButtons = false,
    bool showDownloadSpeed = true,
    bool showNotificationWithoutProgress = false,
    Function({required int count, required int total})? onReceiveProgress,
    //required Dio dio,
  }) async {
    late String downloadDirectory;

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
    if (Platform.isIOS || showNotificationWithoutProgress) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: 'download_channel',
          title: 'Downloading',
          body: 'Downloading $fileName',
          wakeUpScreen: true,
        ),
      );
    }
    String speedText = 'calculating...';
    int speed = 0;
    int lastCount = 0;
    int totalSec = 0;
    await dio.download(
      url,
      "$downloadDirectory$fileName",
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
      ),
      onReceiveProgress: (receivedBytes, totalBytes) async {
        if (showNotification == false || showNotificationWithoutProgress) {
          return onReceiveProgress?.call(
              count: receivedBytes, total: totalBytes);
        }
        if (Platform.isIOS) {
          if (showNotification == false) {
            return onReceiveProgress?.call(
                count: receivedBytes, total: totalBytes);
          }
        } else {
          // calculate speed
          if (speed != 0) {
            speedText = "${(speed / 1000000).toStringAsFixed(2)} MB/s";
          }
          double progress = 0;
          double totalMB = 0;
          double receivedMB = 0;
          if (totalBytes != -1) {
            progress = ((receivedBytes / totalBytes) * 100);
            totalMB = totalBytes / 1048576;
            receivedMB = receivedBytes / 1048576;
          } else {
            progress = 100;
            totalMB = receivedMB = receivedBytes / 1048576;
          }

          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: 1,
              channelKey: 'download_channel',
              title: 'Downloading',
              body:
                  'Downloading $fileName ${totalBytes >= 0 ? '(${(receivedMB).toStringAsFixed(2)} / ${(totalMB).toStringAsFixed(2)})' : '${(receivedMB).toStringAsFixed(2)} / nil'} MB/s ${showDownloadSpeed ? ' speed: $speedText' : ''}',
              notificationLayout: NotificationLayout.ProgressBar,
              wakeUpScreen: true,
              progress: progress.toInt(),
            ),
          );
        }
        Future.delayed(const Duration(seconds: 1), () async {
          if (!showDownloadSpeed) {
            return;
          }
          totalSec++;
          // calculate internet speed

          speed =
              ((lastCount / totalSec) * (totalBytes / receivedBytes)).toInt();
          // speed = (count - lastCount) ~/ total;
          lastCount = receivedBytes;
        });

        return onReceiveProgress?.call(count: receivedBytes, total: totalBytes);
      },
    );
    if (showNotification || showNotificationWithoutProgress) {
      await AwesomeNotifications().cancel(1);
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
            'path': "$downloadDirectory$fileName",
            'mime': lookupMimeType(downloadDirectory + fileName)
          },
        ),
      );
    }

    return "$downloadDirectory$fileName";
  }
}
