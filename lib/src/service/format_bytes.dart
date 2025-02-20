import 'dart:math';

({double size, String unit}) formatBytes(int bytes, int decimals) {
  if (bytes <= 0) return (size: 0, unit: "B");
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  var i = (log(bytes) / log(1024)).floor();
  var size = bytes / pow(1024, i);
  return (
    size: double.parse(size.toStringAsFixed(decimals)),
    unit: suffixes[i],
  );
}
