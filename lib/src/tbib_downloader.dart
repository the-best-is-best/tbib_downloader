import 'dart:io';

// import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tbib_downloader/src/local_notification_service.dart';

///  class for downloading files from the internet
class TBIBDownloader {
  /// download file from the internet
  static late Dio dio;

  /// init downloader
  Future<void> init() async {
    // await AwesomeNotifications().requestPermissionToSendNotifications();
    dio = Dio();
    // init awesome notifications
    // await AwesomeNotifications().initialize(
    //   null,
    //   [
    //     NotificationChannel(
    //       icon: 'resource://drawable/ic_stat_file_download',
    //       channelKey: 'download_channel',
    //       channelName: 'Download notifications',
    //       channelDescription: 'Notification channel for download progress',
    //       defaultColor: Colors.black,
    //       ledColor: Colors.white,
    //     ),
    //     NotificationChannel(
    //       icon: 'resource://drawable/ic_stat_file_download_done',
    //       channelKey: 'download_completed_channel',
    //       channelName: 'Download completed notifications',
    //       channelDescription: 'Notification channel for download completed',
    //       defaultColor: Colors.black,
    //       ledColor: Colors.white,
    //     ),
    //   ],
    // );

    ///
    /// init flutter local notifications
    AndroidInitializationSettings initializationSettingsAndroid =
        const AndroidInitializationSettings('ic_stat_file_download');
    DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            requestSoundPermission: false,
            requestBadgePermission: false,
            requestAlertPermission: false,
            onDidReceiveLocalNotification:
                (int id, String? title, String? body, String? payload) async {
              didReceiveLocalNotificationStream.add(
                ReceivedNotification(
                  id: id,
                  title: title,
                  body: body,
                  payload: payload,
                ),
              );
            });

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      // linux: initializationSettingsLinux,
    );

    const AndroidNotificationDetails firstNotificationAndroidSpecifics =
        AndroidNotificationDetails('groupChannelId', 'groupChannelName',
            channelDescription: 'groupChannelDescription',
            importance: Importance.max,
            priority: Priority.high,
            icon: 'secondary_icon',
            groupKey: 'groupKey');

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        switch (notificationResponse.notificationResponseType) {
          case NotificationResponseType.selectedNotification:
            selectNotificationStream.add(notificationResponse.payload);
            break;
          case NotificationResponseType.selectedNotificationAction:
            // if (notificationResponse.actionId == navigationActionId) {
            //   selectNotificationStream.add(notificationResponse.payload);
            // }
            break;
        }
      },
      // onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    // final List<DarwinNotificationCategory> darwinNotificationCategories =
    //     <DarwinNotificationCategory>[
    //   DarwinNotificationCategory(
    //     'category_1',
    //     actions: <DarwinNotificationAction>[
    //       DarwinNotificationAction.text(
    //         'text_1',
    //         'Action 1',
    //         buttonTitle: 'Send',
    //         placeholder: 'Placeholder',
    //       ),
    //     ],
    //   ),
    //   DarwinNotificationCategory(
    //     darwinNotificationCategoryPlain,
    //     actions: <DarwinNotificationAction>[
    //       DarwinNotificationAction.plain('id_1', 'Action 1'),
    //       DarwinNotificationAction.plain(
    //         'id_2',
    //         'Action 2 (destructive)',
    //         options: <DarwinNotificationActionOption>{
    //           DarwinNotificationActionOption.destructive,
    //         },
    //       ),
    //       DarwinNotificationAction.plain(
    //         navigationActionId,
    //         'Action 3 (foreground)',
    //         options: <DarwinNotificationActionOption>{
    //           DarwinNotificationActionOption.foreground,
    //         },
    //       ),
    //       DarwinNotificationAction.plain(
    //         'id_4',
    //         'Action 4 (auth required)',
    //         options: <DarwinNotificationActionOption>{
    //           DarwinNotificationActionOption.authenticationRequired,
    //         },
    //       ),
    //     ],
    //     options: <DarwinNotificationCategoryOption>{
    //       DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
    //     },
    //   )
    // ];
  }

  Future<NotificationDetails> _notificationDetails() async {
    return const NotificationDetails(
      android: AndroidNotificationDetails('channelId', 'channelName',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_stat_file_download'),
    );
  }

  /// download file from the internet
  Future<String> downloadFile<T>({
    required String url,
    required String fileName,
    String? directoryName,
    String? customDirectory,
    bool showNotification = true,
    Function({required int count, required int total})? onReceiveProgress,
    //required Dio dio,
  }) async {
    late String downloadDirectory;
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    var androidInfo = await deviceInfo.androidInfo;

    if (customDirectory != null) {
      downloadDirectory = customDirectory;
    } else {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (Platform.isAndroid) {
        if (int.parse(androidInfo.version.release) > 10) {
          downloadDirectory =
              "${await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOADS)}/";
        } else {
          downloadDirectory =
              "${await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOADS)}/${packageInfo.appName}/";
        }
      } else {
        downloadDirectory =
            "${(await getApplicationDocumentsDirectory()).path}/";
      }
      if (directoryName != null) {
        if (Platform.isAndroid && int.parse(androidInfo.version.release) > 10) {
          downloadDirectory = downloadDirectory;
        } else {
          downloadDirectory = "$downloadDirectory$directoryName/";
        }
      }
    }
    await Directory(downloadDirectory).create(recursive: true);
    // if (Platform.isIOS) {
    //   await AwesomeNotifications().createNotification(
    //     content: NotificationContent(
    //       id: 1,
    //       channelKey: 'download_channel',
    //       title: 'Downloading',
    //       body: 'Downloading $fileName',
    //       wakeUpScreen: true,
    //     ),
    //   );
    // }
    await flutterLocalNotificationsPlugin.show(
        1, 'start plain title', 'test', await _notificationDetails(),
        payload: 'item x');
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

          // await AwesomeNotifications().createNotification(
          //   content: NotificationContent(
          //     id: 1,
          //     channelKey: 'download_channel',
          //     title: 'Downloading',
          //     body: 'Downloading $fileName',
          //     notificationLayout: NotificationLayout.ProgressBar,
          //     wakeUpScreen: true,
          //     progress: (count / total * 100).toInt(),
          //   ),
          // );
          return onReceiveProgress?.call(count: count, total: total);
        }
      },
    );
    // await AwesomeNotifications().createNotification(
    //   actionButtons: [
    //     NotificationActionButton(
    //       key: "open",
    //       label: "Open File",
    //     ),
    //   ],
    //   content: NotificationContent(
    //     id: 2,
    //     channelKey: 'download_completed_channel',
    //     title: 'Download completed',
    //     body: 'Download completed $fileName',
    //     wakeUpScreen: true,
    //     payload: {
    //       'path': downloadDirectory + fileName,
    //       'mime': lookupMimeType(downloadDirectory + fileName)
    //     },
    //   ),
    // );
    await flutterLocalNotificationsPlugin
        .show(1, 'end plain title', 'test', null, payload: 'item x');

    return downloadDirectory + fileName;
  }
}
