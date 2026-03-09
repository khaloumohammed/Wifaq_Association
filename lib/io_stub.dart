import 'dart:typed_data';

class File {
  File(this._path);

  final String _path;

  String get path => _path;

  Future<bool> exists() async => false;

  Future<Uint8List> readAsBytes() async => Uint8List(0);

  Future<void> writeAsBytes(List<int> bytes, {bool flush = false}) async {}
}
