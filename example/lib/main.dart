import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:tbib_downloader/tbib_downloader.dart';
import 'package:tbib_downloader_example/new_screen.dart';
import 'package:tbib_downloader_example/services/notification_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TBIBDownloader().init();

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
        home: const MainPage());
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  double progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('download file'),
      ),

      // zip file url download
      /// pdf file total size issue is https://www.eurofound.europa.eu/sites/default/files/ef_publication/field_ef_document/ef1710en.pdf
      /// pdf file total size issue is https://freetestdata.com/wp-content/uploads/2022/11/Free_Test_Data_10.5MB_PDF.pdf
      body: Column(
        children: [
          if (progress > 0)
            Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(
                value: progress,
              ),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  var path = await TBIBDownloader().downloadFile(
                      context: context,
                      url: 'https://ash-speed.hetzner.com/1GB.bin',
                      receiveBytesAsMB: true,
                      fileName: 'remittance_report.pdf',
                      directoryName: 'pdf',
                      disabledShareFileButton: true);
                },
                child: const Text('download'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  var path = await TBIBDownloader().downloadFile(
                    context: context,

                    url:
                        'https://file-examples.com/wp-content/storage/2017/10/file-example_PDF_1MB.pdf',
                    fileName: 'dummy1.pdf',
                    saveFileInDataApp: true,
                    directoryName: 'test',
                    // onReceiveProgress: ({int? count, int? total}) => debugPrint(
                    //     'count: $count, total: $total, progress: ${count! / total!}'),
                  );
                  debugPrint('path $path');
                },
                child: const Text('download 1'),
              ),
              const SizedBox(height: 20),
              // button close this page and go to new page
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SecondPage(),
                    ),
                  );
                },
                child: const Text('go to second page'),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    AwesomeNotifications().setListeners(
        onActionReceivedMethod: MyNotificationService.onActionReceivedMethod,
        onNotificationCreatedMethod:
            MyNotificationService.onNotificationCreatedMethod,
        onNotificationDisplayedMethod:
            MyNotificationService.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod:
            MyNotificationService.onDismissActionReceivedMethod);
  }
}
