import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tbib_downloader/src/service/format_bytes.dart';
import 'package:tbib_downloader/src/service/get_avalible_file.dart';
import 'package:tbib_downloader/src/tbib_native_downloader.dart';

class TBIBDownloader {
  static bool _downloadStarted = false;
  static final num _convertBytesToMB = pow(10, 6);

  Future<String?> downloadFile<T>({
    Dio? dio,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
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
    bool receiveBytesAsMB = false,
    Function({required int receivedBytes, required int totalBytes})?
        onReceiveProgress,
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
                  borderRadius: BorderRadius.all(Radius.circular(10))),
              behavior: SnackBarBehavior.floating,
              content: Text('Permission denied to access storage'),
            ),
          );
          Future.delayed(const Duration(seconds: 2), () => openAppSettings());
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

    try {
      if (Platform.isAndroid && !saveFileInDataApp) {
        downloadDirectory =
            "${(await TbibNativeDownloader.getDownloadsDirectory())!}/";
      } else {
        downloadDirectory = saveFileInDataApp
            ? "${(await getApplicationSupportDirectory()).path}/"
            : "${(await getApplicationDocumentsDirectory()).path}/";
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
      dio ??= Dio();
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 15);
      await dio.download(
        url,
        solvePath ?? "$downloadDirectory$fileName",
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          responseType: ResponseType.bytes,
          followRedirects: false,
        ),
        onReceiveProgress: (count, total) async {
          // Trigger the callback ONLY when receiveBytesAsMB is true
          if (onReceiveProgress != null && receiveBytesAsMB == true) {
            onReceiveProgress(
              receivedBytes: (count / _convertBytesToMB).floor(),
              totalBytes: (total / _convertBytesToMB).floor(),
            );
          }

          if (showNotification) {
            final now = DateTime.now();
            if (showNewNotification || now.isAfter(endTime)) {
              showNewNotification = false;

              if (Platform.isAndroid) {
                await _showProgressNotification(
                    showDownloadSpeed, total, count, startTime);
              }

              endTime = now.add(refreshNotificationProgress);
              showNewNotification = true;
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
                        label: "Open File"),
                  if (!disabledDeleteFileButton)
                    NotificationActionButton(
                        isDangerousOption: true,
                        color: Colors.red.shade900,
                        key: "tbib_downloader_delete_file",
                        label: "Delete File"),
                  if (!disabledShareFileButton)
                    NotificationActionButton(
                        color: Colors.green.shade900,
                        key: "tbib_downloader_share_file",
                        label: "Share File"),
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

      return solvePath ?? "$downloadDirectory$fileName";
    } catch (e) {
      dev.log('download error: $e');
      try {
        String attemptPath = "$downloadDirectory$fileName";
        if (File(attemptPath).existsSync()) {
          File(attemptPath).deleteSync();
        }
      } catch (_) {}

      rethrow;
    } finally {
      _downloadStarted = false;
    }
  }

  Future<void> init() async {
    var permission = await Permission.notification.isGranted;
    if (!permission) await Permission.notification.request();
  }

  Future<void> _showProgressNotification(bool showDownloadSpeed, int totalBytes,
      int receivedBytes, DateTime startTime) async {
    final progress =
        totalBytes > 0 ? min(receivedBytes / totalBytes * 100, 100) : 0;
    final totalData = formatBytes(totalBytes, 2);
    final receivedData = formatBytes(receivedBytes, 2);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'download_channel',
        title: 'Downloading',
        body:
            'Downloading (${receivedData.size.toStringAsFixed(2)} ${receivedData.unit} / ${totalData.size.toStringAsFixed(2)} ${totalData.unit})',
        notificationLayout: NotificationLayout.ProgressBar,
        wakeUpScreen: true,
        locked: true,
        progress: progress.clamp(0, 100).toDouble(),
      ),
    );
  }
}
