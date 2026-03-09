import 'package:flutter_test/flutter_test.dart';
import 'package:wifaq_association/main.dart';

void main() {
  test('Wifaq app widget is created', () {
    const app = WifaqApp();
    expect(app, isA<WifaqApp>());
  });
}
