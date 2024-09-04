import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:tbib_downloader/tbib_downloader.dart';

class MyNotificationService {
  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    if (receivedAction.buttonKeyPressed == 'tbib_downloader_open_file') {
      await TBIBDownloaderOpenFile()
          .openFile(path: receivedAction.payload!['path']!);
    } else if (receivedAction.buttonKeyPressed ==
        'tbib_downloader_delete_file') {
      await TBIBDownloaderOpenFile()
          .deleteFile(receivedAction.payload!['path']!);
    } else if (receivedAction.buttonKeyPressed ==
        'tbib_downloader_share_file') {
      await TBIBShareFile().share(receivedAction.payload!['path']!);
    }
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Your code goes here
  }

  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    // Your code goes here
  }
}
