import 'package:qr_code_scanner/qr_code_scanner.dart';

/// Controller for widget [AnimatedQRView]
/// Provides functions to flip camera, toggle flashlight, pause, and resume
class AnimatedQRViewController{
  QRViewController controller;
  
  /// Call to flip camera
  void flipCamera() => controller?.flipCamera();

  /// Call to turn on/off lights
  void toggleFlash() => controller?.toggleFlash();

  /// Call to pause scanning
  void pause() => controller?.pauseCamera();

  /// Call to resume/restart scanning
  void resume() => controller?.resumeCamera();

  /// Decoded text
  String get text => controller?.qrText;
}