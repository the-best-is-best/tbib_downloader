import 'dart:developer' as dev;

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
  double progress = 0.0;
  bool isDownloading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('download file'),
      ),
      body: Column(
        children: [
          if (isDownloading)
            LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              backgroundColor: Colors.blue.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isDownloading) ...[
                  Text(
                    progress > 0
                        ? "${(progress * 100).toInt()}%"
                        : "Connecting...",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                ],
                ElevatedButton(
                  onPressed: isDownloading
                      ? null
                      : () async {
                          setState(() {
                            isDownloading = true;
                            progress = 0.0;
                          });

                          try {
                            var path = await TBIBDownloader().downloadFile(
                              context: context,
                              url: 'https://ash-speed.hetzner.com/1GB.bin',
                              receiveBytesAsMB: true,
                              showNotification: true,
                              fileName: 'remittance_report.pdf',
                              directoryName: 'pdf',
                              disabledShareFileButton: true,
                              onReceiveProgress: (
                                  {required receivedBytes,
                                  required totalBytes}) {
                                if (totalBytes > 0) {
                                  double currentProgress =
                                      receivedBytes / totalBytes;
                                  if ((currentProgress * 100).toInt() !=
                                      (progress * 100).toInt()) {
                                    if (mounted) {
                                      setState(() {
                                        progress = currentProgress;
                                      });
                                    }
                                  }
                                }
                              },
                            );

                            if (path != null && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Download Completed!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            dev.log("Download failed or connection lost: $e");
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Download failed. Connection lost or timed out!'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                isDownloading = false;
                                progress = 0.0;
                              });
                            }
                          }
                        },
                  child: const Text('download'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isDownloading
                      ? null
                      : () async {
                          setState(() {
                            isDownloading = true;
                            progress = 0.0;
                          });

                          try {
                            var path = await TBIBDownloader().downloadFile(
                              context: context,
                              url:
                                  'https://tourism.gov.in/sites/default/files/2019-04/dummy-pdf_2.pdf',
                              fileName: 'dummy1.pdf',
                              saveFileInDataApp: true,
                              directoryName: 'test',
                              receiveBytesAsMB: false,
                              onReceiveProgress: (
                                  {required receivedBytes,
                                  required totalBytes}) {
                                if (totalBytes > 0) {
                                  double currentProgress =
                                      receivedBytes / totalBytes;
                                  if ((currentProgress * 100).toInt() !=
                                      (progress * 100).toInt()) {
                                    if (mounted) {
                                      setState(() {
                                        progress = currentProgress;
                                      });
                                    }
                                  }
                                }
                              },
                            );

                            if (path != null) {
                              debugPrint('path $path');
                              TBIBDownloaderOpenFile().openFile(path: path);
                            }
                          } catch (e) {
                            dev.log("Download 1 failed or connection lost: $e");
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Download failed. Connection lost or timed out!'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                isDownloading = false;
                                progress = 0.0;
                              });
                            }
                          }
                        },
                  child: const Text('download 1'),
                ),
                const SizedBox(height: 20),
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
            ),
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
