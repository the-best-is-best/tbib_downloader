import 'package:share_plus/share_plus.dart';

class TBIBShareFile {
  Future<void> share(String path, {String? subject, String? message}) async {
    final result =
        await Share.shareXFiles([XFile(path)], subject: subject, text: message);

    if (result.status != ShareResultStatus.success) {
      throw Exception("Share failed");
    }
  }
}
