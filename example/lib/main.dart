// import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tbib_downloader/tbib_downloader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Permission.storage.request();

  await TBIBDownloader().init();
  // await AwesomeNotifications().setListeners(
  //     onActionReceivedMethod: MyNotificationService.onActionReceivedMethod,
  //     onNotificationCreatedMethod:
  //         MyNotificationService.onNotificationCreatedMethod,
  //     onNotificationDisplayedMethod:
  //         MyNotificationService.onNotificationDisplayedMethod,
  //     onDismissActionReceivedMethod:
  //         MyNotificationService.onDismissActionReceivedMethod);

  runApp(const App());
}

//app
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Background downloader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('download file'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              var path = await TBIBDownloader().downloadFile(
                  url:
                      'https://cartographicperspectives.org/index.php/journal/article/download/cp25-full/pdf/3698',
                  fileName: 'test.pdf',
                  directoryName: 'test',
                  onReceiveProgress: ({int? count, int? total}) => debugPrint(
                      'count: $count, total: $total, progress: ${count! / total!}'));
              debugPrint(path);
            },
            child: const Text('download'),
          ),
        ),
      ),
    );
  }
}
