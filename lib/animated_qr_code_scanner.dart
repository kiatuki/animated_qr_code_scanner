import 'dart:async';
import 'dart:math' as Math;

import 'package:animated_qr_code_scanner/AnimatedQRViewController.dart';
import 'package:animated_qr_code_scanner/AnimatedSquare.dart';
import 'package:animated_qr_code_scanner/BitMatrix.dart';
import 'package:animated_qr_code_scanner/Detector.dart';
import 'package:animated_qr_code_scanner/PerspectiveTransform.dart';
import 'package:flutter/material.dart';

import 'package:qr_code_scanner/qr_code_scanner.dart';

class AnimatedQRView extends StatefulWidget {
  const AnimatedQRView({
    Key key,
    this.onScan,
    this.onScanBeforeAnimation,
    this.controller,
    this.animationDuration,
    this.squareBorderColor,
    this.squareColor,
    this.borderWidth,
  }) : super(key: key);

  /// Callback function whenever the scanner found a QR.
  /// Called AFTER the targetting square has finished moving to the detected code
  final Function(String string) onScan;

  /// Callback function whenever the scanner found a QR.
  /// Called BEFORE the targetting square has finished moving to the detected code
  final Function(String string) onScanBeforeAnimation;

  /// Controller for developers
  final AnimatedQRViewController controller;

  /// The duration the targetting square moves to the detected code.
  /// Also affects the targetting square's idle animation 
  final Duration animationDuration;

  /// The color of the borders of the targetting square
  /// If null, takes [squareColor] with 100% opacity
  /// If [squareColor] is also null, defaults to [Colors.blue]
  final Color squareBorderColor;

  /// The color of the inside of the targetting square
  /// Color with low opacity is recommended
  /// If null, takes [squareBorderColor] with 100% opacity
  /// If [squareBorderColor] is also null, defaults to [Colors.blue] with 25% opacity
  final Color squareColor;

  /// The width of each border side of the targetting square
  /// Defaults to 2.5 if left null
  final double borderWidth;

  @override
  State<StatefulWidget> createState() => _AnimatedQRViewState();
}

class _AnimatedQRViewState extends State<AnimatedQRView> {
  /// The decoded text contained within the detected QR Code
  String qrText = "";

  /// Coordinates of corners of detected QR code relative to the targetting square.
  /// Top-left of square is (0,0). QRs will only become detected when inside the square
  List<Offset> qrCornersPreviewFramingRect;

  /// Coordinates of corners of detected QR code relative to the camera's preview size (the whole image's size)
  /// Top-left of the camera's sight (may not be displayed in the viewfinder) is (0,0)
  List<Offset> qrCornersPreview;

  /// Coordinates of corners of detected QR code relative to this app's layout
  /// Top-left corner of the display is (0,0)
  List<Offset> qrCornerFlutter;

  /// Coordinates of the center of square finder patterns and the bottom-right
  /// alignment pattern of detected QR relative to the targetting square
  List<Offset> resultPointsPreviewFramingRect;
  
  /// Scale the preview to cover the viewfinder, then center it.
  /// See com.journeyapps.barcodescanner.camera.CenterCropStrategy.scalePreview for more details
  Rect viewfinderRect;

  /// The framing rect, relative to the camera preview resolution.
  Rect previewFramingRect;

  /// The size of the image seen by the camera
  Size previewSize;

  /// Whether or not phone torch is turned on
  _FlashState flashState = _FlashState.flash_on;

  /// Whether the active camera is front or back
  _CameraState cameraState = _CameraState.front_camera;

  /// Whether or not the preview is mirrorred
  bool previewMirrored;

  /// Secondary  detector the QR code. The android built-in zxing detector already detects the qr.
  /// This detector only re-evaluate the image to determine the corners of the QR code.
  final Detector detector = Detector();

  /// Size of the image displayed to user
  Size viewFinderSize;

  /// Internal controller used in case widget.controller is not provided
  QRViewController _controller;

  QRViewController get _effectiveController => widget.controller?.controller ?? _controller;
  set _effectiveController(QRViewController qrViewController)
  {
    if(widget.controller != null) {
      widget.controller.controller = qrViewController;
    }
    else {
      _controller = qrViewController;
    }
  }

  /// Keys
  final GlobalKey parentQrKey = GlobalKey();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final GlobalKey interfaceKey = GlobalKey();
  final GlobalKey<AnimatedSquareState> animatedKey = GlobalKey<AnimatedSquareState>();

  @override
  void initState() {
    previewMirrored = cameraState != _CameraState.front_camera;
    super.initState();
    // Get widget size after widget has been rendered once, then rebuild it 
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
        Size widgetSize = (parentQrKey.currentContext.findRenderObject() as RenderBox).size;
        viewFinderSize=Size(
            widgetSize.width,
            widgetSize.height - MediaQuery.of(context).padding.top,
        );
      })
    );
  }

  @override
  Widget build(BuildContext context) {
    previewMirrored = cameraState != _CameraState.front_camera;

    return Container(
      key: parentQrKey,
      child: viewFinderSize != null
          // Show QRView alongside with animated targetting box with size relative to widget size if we know widget size
          ? Stack(
            children: <Widget>[
              QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
              ),
              SizedBox(
                width: viewFinderSize.width,
                height: viewFinderSize.height,
                child: AnimatedSquare(
                  widgetSize: viewFinderSize,
                  padding: MediaQuery.of(context).padding,
                  key: animatedKey,
                  width: Math.min<double>(viewFinderSize.height,viewFinderSize.width)*0.8,
                  height: Math.min<double>(viewFinderSize.height,viewFinderSize.width)*0.8,
                  onScan: widget.onScan,
                  animationDuration: widget.animationDuration,
                  squareBorderColor: widget.squareBorderColor,
                  squareColor : widget.squareColor,
                  borderWidth: widget.borderWidth,
                ),
              )
            ],
          )
          // Show nothing if we don't know widget size yet. Widget size will be gotten after this has been rendered
          : const SizedBox.expand(),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    _effectiveController = controller;

    // Listen to get scanned string
    controller.scannedStringStream.listen((scannedString) async {
      controller?.pauseCamera();
      animatedKey.currentState.setScanResult(scannedString);
      setState(() {
        qrText = scannedString;
        widget?.onScanBeforeAnimation(scannedString);
      });
    });

    // Listen to detected points' coordinates
    controller.scannedResultPointsStream.listen((scannedPointsString) async =>
        resultPointsPreviewFramingRect = _parseListPoint(scannedPointsString.toString()));

    controller.viewfinderRectStream.listen((viewfinderRectString) async {
      print('Viewfinder Rect : $viewfinderRectString');
      List<String> rectLstStr = viewfinderRectString.split(' ');
      viewfinderRect = Rect.fromLTRB(
        double.parse(rectLstStr[0]),
        double.parse(rectLstStr[1]),
        double.parse(rectLstStr[2]),
        double.parse(rectLstStr[3]),
      );
    });

    controller.previewFramingRectStream.listen((previewFramingRectString) async {
      print('Preview Framing Rect : $previewFramingRectString');
      List<String> rectLstStr = previewFramingRectString.split(' ');
      previewFramingRect = Rect.fromLTRB(
        double.parse(rectLstStr[0]),
        double.parse(rectLstStr[1]),
        double.parse(rectLstStr[2]),
        double.parse(rectLstStr[3]),
      );
    });

    controller.previewSizeStream.listen((previewSizeString) async {
      print('Preview Size : $previewSizeString');
      List<String> rectLstStr = previewSizeString.split('x');
      previewSize = Size(
        double.parse(rectLstStr[0]),
        double.parse(rectLstStr[1]),
      );
    });

    controller.bitMatrixStream.listen((binarizedCroppedImage) async {
      detector.bitMatrix = BitMatrix.fromString(binarizedCroppedImage);

      PerspectiveTransform transform = detector.createTransform(
          resultPointsPreviewFramingRect[1],
          resultPointsPreviewFramingRect[2],
          resultPointsPreviewFramingRect[0],
          resultPointsPreviewFramingRect.length >= 4 ? resultPointsPreviewFramingRect[3] : null);

      qrCornersPreviewFramingRect = transform.transformPointsFromOffset([
        Offset(0, 0),
        Offset(detector.computedDimension.toDouble(), 0),
        Offset(detector.computedDimension.toDouble(), detector.computedDimension.toDouble()),
        Offset(0, detector.computedDimension.toDouble()),
      ]);

        Offset translateResultPointFramingRectToPreview(Offset point) {
          double x = point.dx + this.previewFramingRect.left;
          double y = point.dy + this.previewFramingRect.top;
          if (previewMirrored) {
            x = previewSize.width/2 - x;
          }
          return new Offset(x, y);
        }

        qrCornersPreview = [
          for (int i = 0; i < qrCornersPreviewFramingRect.length; i++)
            translateResultPointFramingRectToPreview(
              Offset(qrCornersPreviewFramingRect[i].dx, qrCornersPreviewFramingRect[i].dy)
            )
        ];

        Size scaledSize = Size(viewfinderRect.right-viewfinderRect.left,viewfinderRect.bottom-viewfinderRect.top);
        Offset previewCenter = Offset(previewSize.width/2,previewSize.height/2);
        Offset scaledCenter = Offset(scaledSize.width/2,scaledSize.height/2);

        List<Offset> qrCornerScaled = [
          for(int i=0;i<qrCornersPreview.length;i++) Offset(
            ((qrCornersPreview[i].dx-previewCenter.dx)*scaledSize.width/previewSize.width)+scaledCenter.dx,
            ((qrCornersPreview[i].dy-previewCenter.dy)*scaledSize.height/previewSize.height)+scaledCenter.dy,
          )
        ];

        Size centerCroppedSize = previewSize.width/previewSize.height < viewFinderSize.width/viewFinderSize.height
          ? Size(
            scaledSize.width,
            viewFinderSize.height/viewFinderSize.width*scaledSize.width,
          )
          : Size(
            viewFinderSize.width/viewFinderSize.height*scaledSize.height,
            scaledSize.height,
          );

        List<Offset> qrCornerCenterCropped = [
          for(int i=0;i<qrCornerScaled.length;i++)Offset(
            qrCornerScaled[i].dx-(scaledSize.width-centerCroppedSize.width)/2,
            qrCornerScaled[i].dy-(scaledSize.height-centerCroppedSize.height)/2,
          )
        ];

        Offset previewToFlutterRatio = Offset(
          viewFinderSize.width/centerCroppedSize.width,
          viewFinderSize.height/centerCroppedSize.height,
        );

        qrCornerFlutter = [
          for(int i=0;i<qrCornerCenterCropped.length;i++)
          Offset(
            qrCornerCenterCropped[i].dx * previewToFlutterRatio.dx,
            qrCornerCenterCropped[i].dy * previewToFlutterRatio.dy + MediaQuery.of(context).padding.top,
          )
        ];

        animatedKey.currentState.changeToOffset(qrCornerFlutter);

    });
    controller.animatedSquareStream.listen((strCommand) async {
      if(strCommand == "flip" || strCommand == "resume") {
        animatedKey.currentState.onRescan();
        animatedKey.currentState.controller.animateTo(1);
      }
      if(strCommand == "pause") animatedKey.currentState.controller.stop();
    });
  }

  @override
  void dispose() {
    _effectiveController.dispose();
    super.dispose();
  }
}

List<Offset> _parseListPoint(String str) {
  str = str.replaceAll('[', '');
  str = str.replaceAll('(', '');
  str = str.replaceAll(')', '');
  str = str.replaceAll(']', '');
  List<double> doubles =
      str.split(',').map<double>((st) => double.parse(st)).toList();

  List<Offset> points = doubles.length < 8
      ? [
          Offset(doubles[0], doubles[1]),
          Offset(doubles[2], doubles[3]),
          Offset(doubles[4], doubles[5]),
        ]
      : [
          Offset(doubles[0], doubles[1]),
          Offset(doubles[2], doubles[3]),
          Offset(doubles[4], doubles[5]),
          Offset(doubles[6], doubles[7]),
        ];

  return points;
}

enum _FlashState { flash_on,flash_off }
enum _CameraState { front_camera, back_camera }