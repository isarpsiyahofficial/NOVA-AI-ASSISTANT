import 'package:flutter_test/flutter_test.dart';
import 'package:nova/core/config/app_constants.dart';

void main() {
  test('Nova identity smoke test', () {
    expect(AppConstants.appName, 'Nova');
  });
}
