import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:animated_qr_code_scanner/animated_qr_code_scanner.dart';

void main() {
  const MethodChannel channel = MethodChannel('animated_qr_code_scanner');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  // test('getPlatformVersion', () async {
  //   expect(await AnimatedQrCodeScanner.platformVersion, '42');
  // });
}
