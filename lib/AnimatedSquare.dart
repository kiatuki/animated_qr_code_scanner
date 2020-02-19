import 'package:flutter/material.dart';

class AnimatedSquare extends StatefulWidget {
  const AnimatedSquare ({
    this.width,
    this.height,
    this.widgetSize,
    this.padding,
    this.onScan,
    this.animationDuration,
    this.squareBorderColor,
    this.squareColor,
    this.borderWidth,
    Key key,
  }) : super(key: key);
  final double width;
  final double height;
  final EdgeInsets padding;
  final Size widgetSize;
  final Function(String str) onScan;
  final Duration animationDuration;
  final Color squareBorderColor;
  final Color squareColor;
  final double borderWidth;
  @override
  AnimatedSquareState createState() => AnimatedSquareState();
}

class AnimatedSquareState extends State<AnimatedSquare>
    with TickerProviderStateMixin {
  final double _fraction = 0.0;
  final List<Offset> from = [];
  final List<Offset> to = [];
  List<Offset> offsets;
  List<Animation<Offset>> animations;
  AnimationController controller;
  CurvedAnimation curved;
  String scanResult;

  void setScanResult(String result){
    setState(() {
        scanResult = result;
    });
  }

  void changeToOffset(List<Offset> newOffset) {
    setState(() {
      to.clear();
      to.addAll(newOffset);
      controller.stop();
      controller.duration = widget.animationDuration ?? controller.duration;
      for(Animation<Offset> animation in animations) animation.removeStatusListener(_statusListenerIdle);
      animations = newOffset.map((offset) {
        final int i = newOffset.indexOf(offset);
        final Offset fromOffset = offsets[i];
        return Tween<Offset>(
          begin: fromOffset,
          end: offset,
        ).animate(curved);
      }).toList();
    });
    controller.forward().whenComplete(
      () => widget?.onScan(scanResult));
    
  }

  void onRescan() => revertOffset().whenComplete(() => initAnimation());

  TickerFuture revertOffset() {
    final double left = (widget.widgetSize.width - widget.width) / 2;
    final double top = (widget.widgetSize.height - widget.height) / 2 + widget.padding.top;
    final double right = (widget.widgetSize.width - widget.width) / 2 + widget.width;
    final double bottom = (widget.widgetSize.height - widget.height) / 2 + widget.height + widget.padding.top;

    final List<Offset> newOffset = [
      Offset(left, top),
      Offset(right, top),
      Offset(right, bottom),
      Offset(left, bottom)
    ];
    setState(() {
      controller.stop();
      controller.duration = const Duration(milliseconds: 1000);
      for(Animation<Offset> animation in animations) animation.removeStatusListener(_statusListenerIdle);
      animations = newOffset.map((offset) {
        final int i = newOffset.indexOf(offset);
        final Offset fromOffset = offsets[i];
        return Tween<Offset>(
          begin: fromOffset,
          end: offset,
        ).animate(curved);
      }).toList();
    });
    return controller.forward();
  }

  void initAnimation() {
    const double tween = 0.9;
    double left = (widget.widgetSize.width - widget.width) / 2;
    double top = ((widget.widgetSize.height - widget.height) / 2) + widget.padding.top;
    double right = (widget.widgetSize.width - widget.width) / 2 + widget.width;
    double bottom = (widget.widgetSize.height - widget.height) / 2 + widget.height + widget.padding.top;

    from.clear();
    from.addAll([
      Offset(left, top),
      Offset(right, top),
      Offset(right, bottom),
      Offset(left, bottom)
    ]);
    offsets = from;

    right = (widget.widgetSize.width - widget.width) / 2 + widget.width * tween;
    bottom = (widget.widgetSize.height - widget.height) / 2 + widget.height * tween + widget.padding.top;
    left = (widget.widgetSize.width - widget.width) / 2 + widget.width * (1 - tween);
    top = (widget.widgetSize.height - widget.height) / 2 + widget.height * (1 - tween) + widget.padding.top;

    to.clear();
    to.addAll([
      Offset(left, top),
      Offset(right, top),
      Offset(right, bottom),
      Offset(left, bottom)
    ]);

    controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    curved = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    animations = from.map((offset) {
      final int i = from.indexOf(offset);
      final Offset toOffset = to[i];
      return Tween<Offset>(
        begin: offset,
        end: toOffset,
      ).animate(curved)
        ..addListener(() => setState(() => offsets[i] = animations[i].value))
        ..addStatusListener(_statusListenerIdle);
    }).toList();

    controller.forward();
  }

  void _statusListenerIdle(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      controller.reverse();
    } else if (status == AnimationStatus.dismissed) {
      controller.forward();
    }
  }

  @override
  void initState() {
    initAnimation();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.transparent,
    child: CustomPaint(
      painter: _SquarePainter(
        points: offsets,
        color: widget.squareColor
          ?? ((widget.squareBorderColor != null)
            ? widget.squareBorderColor.withOpacity(0.25)
            : Colors.blue.withOpacity(0.25)),
        borderColor: widget.squareBorderColor
          ?? ((widget.squareColor != null)
            ? widget.squareColor.withOpacity(1)
            : Colors.blue),
        borderWidth: widget.borderWidth ?? 2.5,
        tween: _fraction,
      ),
    ),
  );
}

class _SquarePainter extends CustomPainter {
  const _SquarePainter({this.points, this.color, this.borderColor, this.borderWidth, this.tween});

  final List<Offset> points;
  final double tween;
  final Color borderColor;
  final Color color;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(Path()..addPolygon(points ?? [], true),
        Paint()..color = color);
    final Paint _paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(points[0], points[1], _paint);
    canvas.drawLine(points[1], points[2], _paint);
    canvas.drawLine(points[2], points[3], _paint);
    canvas.drawLine(points[3], points[0], _paint);
  }

  @override
  bool shouldRepaint(_SquarePainter oldDelegate) {
    return true;
  }
}