import 'dart:io';

Future<String> getAvailableFilePath(String filePath) async {
  int fileCount = 0;
  String availablePath = filePath;

  // Check if the file already exists
  while (await File(availablePath).exists()) {
    // If the file exists, append a number to the file name
    fileCount++;
    availablePath =
        '${filePath.replaceAll(RegExp(r'\.\w+$'), '')}($fileCount)${filePath.split('.').last}';
  }

  return availablePath;
}
