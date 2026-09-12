import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Check FlutterTimezone return type', () {
    final typeCheck = FlutterTimezone.getLocalTimezone;
    print('Type of getLocalTimezone: $typeCheck');
  });
}
