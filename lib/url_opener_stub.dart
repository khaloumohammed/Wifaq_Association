import 'package:flutter/services.dart';

Future<void> openUrl(String url) async {
  await Clipboard.setData(ClipboardData(text: url));
}
