import 'dart:developer';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dio/dio.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tbib_downloader/src/service/can_manage_storage.dart';

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
    // await TBIBDownloaderGetSpeed().getSpeed(
    //   ({double? speed}) {
    //     speed = speed;
    //   },
    // );
    // log('speed: $speed');
    // init awesome notifications
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
  Future<String> downloadFile<T>({
    required String url,

    /// file name with extension
    required String fileName,
    String? directoryName,
    String? customDirectory,
    bool showNotification = true,
    bool disabledOpenFileButton = true,
    bool disabledDeleteFileButton = true,
    bool hideButtons = false,
    bool showDownloadSpeed = false,
    Function({required int count, required int total})? onReceiveProgress,
    //required Dio dio,
  }) async {
    late String downloadDirectory;

    if (customDirectory != null) {
      downloadDirectory = customDirectory;
    } else {
      if (Platform.isAndroid) {
        if (await canManageStorage()) {
          PackageInfo packageInfo = await PackageInfo.fromPlatform();

          downloadDirectory =
              "${await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOADS)}/${packageInfo.appName}/$directoryName/";
        } else {
          downloadDirectory =
              "${await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOADS)}/";
        }
      } else {
        downloadDirectory =
            "${(await getApplicationDocumentsDirectory()).path}/$directoryName/";
      }
      if (directoryName != null) {
        if (await canManageStorage()) {
          downloadDirectory = downloadDirectory;
        } else {
          downloadDirectory = "$downloadDirectory$directoryName/";
        }
      }
    }
    await Directory(downloadDirectory).create(recursive: true);
    if (Platform.isIOS) {
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
    // log('speed: $speed');
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
      onReceiveProgress: (count, total) async {
        if (Platform.isIOS) {
          if (showNotification == false) {
            return onReceiveProgress?.call(count: count, total: total);
          }
        } else {
          if (showNotification == false) {
            return onReceiveProgress?.call(count: count, total: total);
          }
          // calculate speed
          if (speed != 0) {
            speedText = "${(speed / 1048576).toStringAsFixed(2)} MB/s";
          }

          log('speed text $speedText');
          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: 1,
              channelKey: 'download_channel',
              title: 'Downloading',
              body:
                  'Downloading $fileName ${total >= 0 ? '(${(count / 1048576).toStringAsFixed(2)} / ${(total / 1048576).toStringAsFixed(2)})' : '${(count / 1048576).toStringAsFixed(2)} / nil'} MB/s ${showDownloadSpeed ? ' speed: $speedText' : ''}',
              notificationLayout: NotificationLayout.ProgressBar,
              wakeUpScreen: true,
              progress: total <= 0 ? 100 : ((count / total) * 100).toInt(),
            ),
          );
          await Future.delayed(const Duration(seconds: 1), () {
            if (!showDownloadSpeed) {
              return;
            }
            totalSec++;
            log('downloaded: ${(count)} last downloaded: $lastCount');
            // calculate internet speed

            speed = ((lastCount / totalSec) * (total / count)).toInt();
            // speed = (count - lastCount) ~/ total;
            lastCount = count;
            log('new speed: $speed');
          });

          return onReceiveProgress?.call(count: count, total: total);
        }
      },
    );
    await AwesomeNotifications().cancel(1);
    await AwesomeNotifications().createNotification(
      actionButtons: hideButtons
          ? null
          : [
              NotificationActionButton(
                enabled: disabledOpenFileButton,
                color: Colors.green,
                key: "tbib_downloader_open_file",
                label: "Open File",
              ),
              NotificationActionButton(
                enabled: disabledDeleteFileButton,
                key: "tbib_downloader_delete_file",
                isDangerousOption: true,
                color: Colors.red,
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

    return "$downloadDirectory$fileName";
  }
}
