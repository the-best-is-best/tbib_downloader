import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:tbib_downloader/tbib_downloader.dart';
import 'package:tbib_downloader_example/services/notification_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TBIBDownloader().init();
  await AwesomeNotifications().setListeners(
      onActionReceivedMethod: MyNotificationService.onActionReceivedMethod,
      onNotificationCreatedMethod:
          MyNotificationService.onNotificationCreatedMethod,
      onNotificationDisplayedMethod:
          MyNotificationService.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod:
          MyNotificationService.onDismissActionReceivedMethod);

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
        // zip file url download
        /// pdf file total size issue is https://www.eurofound.europa.eu/sites/default/files/ef_publication/field_ef_document/ef1710en.pdf
        /// pdf file total size issue is https://freetestdata.com/wp-content/uploads/2022/11/Free_Test_Data_10.5MB_PDF.pdf
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              var path = await TBIBDownloader().downloadFile(
                  url:
                      'https://freetestdata.com/wp-content/uploads/2022/11/Free_Test_Data_10.5MB_PDF.pdf',
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
