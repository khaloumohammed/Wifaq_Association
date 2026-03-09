import 'url_opener_stub.dart' if (dart.library.html) 'url_opener_web.dart' as impl;

Future<void> openUrl(String url) => impl.openUrl(url);
