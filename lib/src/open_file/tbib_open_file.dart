import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_app_file/open_app_file.dart';

class TBIBDownloaderOpenFile {
  Future<OpenResult> openFile(
      {required String path,
      String? mimeType,
      bool linuxByProcess = false,
      String linuxDesktopName = "xdg",
      String? uti}) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw Exception("Platform not supported");
    }

    // if (await canManageStorage() == false) {
    //   throw Exception("Permission not granted");
    // }
    var getType = androidType.containsKey('.${path.split(".").last}')
        ? androidType['.${path.split(".").last}']
        : null;
    var getUti = iosUTI.containsKey('.${path.split(".").last}')
        ? iosUTI['.${path.split(".").last}']
        : null;
    return await OpenAppFile.open(path,
        mimeType: mimeType ?? getType, uti: uti ?? getUti);
  }

  // Future<void> openFolder(String path) async {
  //   File file = File(path);
  //   final FileManagerController controller = FileManagerController();
  //   controller.openDirectory(file);
  // }

  Future<void> deleteFile(String path) async {
    // if (await canManageStorage() == false) {
    //   throw Exception("Permission not granted");
    // }
    File file = File(path);
    if (file.existsSync()) {
      file.deleteSync();
    } else {
      debugPrint("File not found");
    }
  }
}

Map<String, String> androidType = {
  ".3gp": "video/3gpp",
  ".torrent": "application/x-bittorrent",
  ".kml": "application/vnd.google-earth.kml+xml",
  ".gpx": "application/gpx+xml",
  ".csv": "application/vnd.ms-excel",
  ".apk": "application/vnd.android.package-archive",
  ".asf": "video/x-ms-asf",
  ".avi": "video/x-msvideo",
  ".bin": "application/octet-stream",
  ".bmp": "image/bmp",
  ".c": "text/plain",
  ".class": "application/octet-stream",
  ".conf": "text/plain",
  ".cpp": "text/plain",
  ".doc": "application/msword",
  ".docx":
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  ".xls": "application/vnd.ms-excel",
  ".xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  ".exe": "application/octet-stream",
  ".gif": "image/gif",
  ".gtar": "application/x-gtar",
  ".gz": "application/x-gzip",
  ".h": "text/plain",
  ".htm": "text/html",
  ".html": "text/html",
  ".jar": "application/java-archive",
  ".java": "text/plain",
  ".jpeg": "image/jpeg",
  ".jpg": "image/jpeg",
  ".js": "application/x-javascript",
  ".log": "text/plain",
  ".m3u": "audio/x-mpegurl",
  ".m4a": "audio/mp4a-latm",
  ".m4b": "audio/mp4a-latm",
  ".m4p": "audio/mp4a-latm",
  ".m4u": "video/vnd.mpegurl",
  ".m4v": "video/x-m4v",
  ".mov": "video/quicktime",
  ".mp2": "audio/x-mpeg",
  ".mp3": "audio/x-mpeg",
  ".mp4": "video/mp4",
  ".mpc": "application/vnd.mpohun.certificate",
  ".mpe": "video/mpeg",
  ".mpeg": "video/mpeg",
  ".mpg": "video/mpeg",
  ".mpg4": "video/mp4",
  ".mpga": "audio/mpeg",
  ".msg": "application/vnd.ms-outlook",
  ".ogg": "audio/ogg",
  ".pdf": "application/pdf",
  ".png": "image/png",
  ".pps": "application/vnd.ms-powerpoint",
  ".ppt": "application/vnd.ms-powerpoint",
  ".pptx":
      "application/vnd.openxmlformats-officedocument.presentationml.presentation",
  ".prop": "text/plain",
  ".rc": "text/plain",
  ".rmvb": "audio/x-pn-realaudio",
  ".rtf": "application/rtf",
  ".sh": "text/plain",
  ".tar": "application/x-tar",
  ".tgz": "application/x-compressed",
  ".txt": "text/plain",
  ".wav": "audio/x-wav",
  ".wma": "audio/x-ms-wma",
  ".wmv": "audio/x-ms-wmv",
  ".wps": "application/vnd.ms-works",
  ".xml": "text/plain",
  ".z": "application/x-compress",
  ".zip": "application/x-zip-compressed",
  "": "*/*"
};

Map iosUTI = {
  ".rtf": "public.rtf",
  ".txt": "public.plain-text",
  ".html": "public.html",
  ".htm": "public.html",
  ".xml": "public.xml",
  ".tar": "public.tar-archive",
  ".gz": "org.gnu.gnu-zip-archive",
  ".gzip": "org.gnu.gnu-zip-archive",
  ".tgz": "org.gnu.gnu-zip-tar-archive",
  ".jpg": "public.jpeg",
  ".jpeg": "public.jpeg",
  ".png": "public.png",
  ".avi": "public.avi",
  ".mpg": "public.mpeg",
  ".mpeg": "public.mpeg",
  ".mp4": "public.mpeg-4",
  ".3gpp": "public.3gpp",
  ".3gp": "public.3gpp",
  ".mp3": "public.mp3",
  ".zip": "com.pkware.zip-archive",
  ".gif": "com.compuserve.gif",
  ".bmp": "com.microsoft.bmp",
  ".ico": "com.microsoft.ico",
  ".doc": "com.microsoft.word.doc",
  ".xls": "com.microsoft.excel.xls",
  ".ppt": "com.microsoft.powerpoint.​ppt",
  ".wav": "com.microsoft.waveform-​audio",
  ".wm": "com.microsoft.windows-​media-wm",
  ".wmv": "com.microsoft.windows-​media-wmv",
  ".pdf": "com.adobe.pdf"
};
