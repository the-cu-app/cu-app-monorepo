import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class TracedLogo extends StatefulWidget {
  final double width;
  final double height;
  final Color color;
  final Duration duration;

  const TracedLogo({
    Key? key,
    this.width = 147,
    this.height = 32,
    this.color = Colors.white,
    this.duration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<TracedLogo> createState() => _TracedLogoState();
}

class _TracedLogoState extends State<TracedLogo>
    with TickerProviderStateMixin {
  late AnimationController _traceController;
  late AnimationController _fillController;

  late Animation<double> _traceAnimation;
  late Animation<double> _fillAnimation;

  bool _isFilling = false;

  @override
  void initState() {
    super.initState();

    // Trace animation
    _traceController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _traceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _traceController,
        curve: Curves.easeInOut,
      ),
    );

    // Fill animation - 3x slower than trace
    _fillController = AnimationController(
      vsync: this,
      duration: widget.duration * 3, // 3x slower than trace
    );
    _fillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fillController,
        curve: Curves.easeInOut,
      ),
    );

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    setState(() => _isFilling = true);

    // Start trace and fill at the SAME TIME
    _traceController.forward();
    _fillController.forward();

    // Wait for fill to complete (it's slower)
    await _fillController.forward();

    // Pause before looping
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      setState(() {
        _isFilling = false;
      });
      _traceController.reset();
      _fillController.reset();
      _startAnimationSequence();
    }
  }

  @override
  void dispose() {
    _traceController.dispose();
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _traceController,
          _fillController,
        ]),
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: LogoPathPainter(
              traceProgress: _traceAnimation.value,
              fillProgress: _fillAnimation.value,
              isFilling: _isFilling,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class LogoPathPainter extends CustomPainter {
  final double traceProgress;
  final double fillProgress;
  final bool isFilling;
  final Color color;

  LogoPathPainter({
    required this.traceProgress,
    required this.fillProgress,
    required this.isFilling,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Parse the SVG path data
    final path = parseSvgPath(
      'M136.936 8.88951e-08C138.239 8.88951e-08 139.452 0.277756 140.573 0.762695C141.725 1.24767 142.726 1.91497 143.574 2.76367C144.423 3.61221 145.089 4.61216 145.574 5.76367C146.059 6.88518 146.302 8.098 146.302 9.40137C146.302 10.6138 146.09 11.7507 145.666 12.8115C145.242 13.8724 144.65 14.8271 143.893 15.6758C143.165 16.4942 142.301 17.1761 141.301 17.7217C140.301 18.2672 139.209 18.6004 138.027 18.7217L129.343 18.8125C128.282 18.8126 127.388 19.1769 126.66 19.9043C125.963 20.6317 125.615 21.5106 125.615 22.541V29.1338C125.615 30.6906 124.353 31.9531 122.796 31.9531C121.239 31.9531 119.977 30.6906 119.977 29.1338V22.541C119.977 21.2379 120.219 20.0256 120.704 18.9043C121.189 17.7525 121.856 16.752 122.705 15.9033C123.554 15.0546 124.539 14.3873 125.66 13.9023C126.812 13.4174 128.04 13.1748 129.343 13.1748H136.936C137.754 13.1748 138.437 12.9936 138.982 12.6299C139.528 12.2662 139.937 11.8112 140.21 11.2656C140.483 10.6899 140.619 10.0836 140.619 9.44727C140.619 8.78043 140.483 8.17353 140.21 7.62793C139.937 7.05217 139.528 6.58244 138.982 6.21875C138.437 5.85502 137.754 5.67285 136.936 5.67285L121.205 5.65625C121.223 5.69799 121.244 5.73911 121.262 5.78125C121.747 6.90263 121.989 8.11477 121.989 9.41797C121.989 10.6304 121.777 11.7672 121.353 12.8281C120.928 13.8888 120.338 14.8438 119.58 15.6924C118.853 16.5107 117.988 17.1927 116.988 17.7383C115.988 18.2838 114.897 18.617 113.715 18.7383L105.03 18.8301C103.969 18.8301 103.075 19.1934 102.348 19.9209C101.651 20.6483 101.302 21.5272 101.302 22.5576V29.1504C101.302 30.7071 100.04 31.9696 98.4834 31.9697C96.9266 31.9697 95.6641 30.7072 95.6641 29.1504V22.5576C95.6641 21.2545 95.9067 20.0422 96.3916 18.9209C96.8766 17.7691 97.5439 16.7686 98.3926 15.9199C99.2412 15.0713 100.226 14.4039 101.348 13.9189C102.499 13.4341 103.727 13.1914 105.03 13.1914H112.623C113.441 13.1914 114.123 13.0101 114.669 12.6465C115.215 12.2828 115.624 11.8278 115.896 11.2822C116.169 10.7064 116.306 10.1003 116.306 9.46387C116.306 8.79703 116.169 8.19013 115.896 7.64453C115.624 7.06884 115.214 6.59898 114.669 6.23535C114.125 5.87291 113.336 5.781 111.676 5.64648H111.117C111.117 5.64648 103.867 5.37052 98.7393 5.60254C95.144 5.76522 90.659 6.17335 89.4062 9.40137C89.1878 9.96429 89.0474 10.6144 88.958 11.3301V19.2988C88.9672 19.8613 88.9684 20.424 88.958 20.9824V21.8604C88.958 23.5273 88.6706 24.9975 88.0947 26.2705C87.5491 27.5436 86.7454 28.6044 85.6846 29.4531C84.6541 30.3018 83.3962 30.938 81.9111 31.3623C80.4259 31.7867 78.7737 31.999 76.9551 31.999C75.1668 31.999 73.4239 31.9386 71.7266 31.8174C70.0595 31.6658 68.5739 31.2722 67.2705 30.6357C65.9671 29.9992 64.9063 29.0436 64.0879 27.7705C63.2999 26.4672 62.9062 24.6638 62.9062 22.3604C62.9063 21.0268 63.1938 19.8751 63.7695 18.9053C64.3757 17.9353 65.1492 17.1014 66.0889 16.4043C67.0588 15.6769 68.15 15.0709 69.3623 14.5859C70.5747 14.101 71.8178 13.6762 73.0908 13.3125C74.394 12.9185 75.652 12.5853 76.8643 12.3125C78.0764 12.0095 79.1523 11.7064 80.0918 11.4033C81.0617 11.0699 81.8352 10.7212 82.4111 10.3574C83.0172 9.96349 83.3202 9.49364 83.3203 8.94824C83.3203 8.06924 83.0475 7.40193 82.502 6.94727C81.9564 6.4926 81.3348 6.17405 80.6377 5.99219C79.9406 5.81035 79.2586 5.71973 78.5918 5.71973H77.2275L61.3896 5.66113V5.67383C61.3896 5.67383 61.2807 5.67381 61.2109 5.67383C58.9103 5.67435 55.3245 5.71938 55.2969 5.71973C54.5391 5.71973 53.9176 5.84064 53.4326 5.99219C52.9476 6.11343 52.5687 6.34139 52.2959 6.6748C51.9929 6.97788 51.7804 7.40186 51.6592 7.94727C51.5379 8.49281 51.4776 9.17487 51.4775 9.99316V19.1777C51.4775 20.9357 51.1444 22.588 50.4775 24.1338C49.8107 25.6796 48.9008 27.0435 47.749 28.2256C46.567 29.3773 45.203 30.2863 43.6572 30.9531C42.1114 31.62 40.4592 31.9541 38.7012 31.9541C38.6921 31.9541 38.6829 31.9531 38.6738 31.9531C38.6647 31.9531 38.6556 31.9541 38.6465 31.9541C36.8885 31.9541 35.2363 31.62 33.6904 30.9531C32.1447 30.2863 30.7807 29.3773 29.5986 28.2256C28.4469 27.0436 27.5379 25.6794 26.8711 24.1338C26.2043 22.588 25.8701 20.9357 25.8701 19.1777V9.99316C25.8701 9.17487 25.8097 8.49281 25.6885 7.94727C25.5672 7.40181 25.3548 6.97788 25.0518 6.6748C24.779 6.34139 24.4 6.11343 23.915 5.99219C23.4301 5.84068 22.8084 5.71973 22.0508 5.71973L16.1377 5.67383H15.959C14.5344 5.67383 13.1852 5.9466 11.9121 6.49219C10.6694 7.03778 9.57831 7.78107 8.63867 8.7207C7.69911 9.63 6.9567 10.7212 6.41113 11.9941C5.89587 13.2369 5.6377 14.5705 5.6377 15.9951C5.63772 17.4196 5.89593 18.7681 6.41113 20.041C6.95673 21.2838 7.69903 22.3758 8.63867 23.3154C9.57825 24.2549 10.6695 24.9974 11.9121 25.543C13.1852 26.0583 14.5344 26.3154 15.959 26.3154H19.2324C20.7892 26.3155 22.0508 27.578 22.0508 29.1348C22.0508 30.6915 20.7892 31.954 19.2324 31.9541H15.959C13.7463 31.9541 11.6694 31.544 9.72949 30.7256C7.78988 29.8769 6.09246 28.7408 4.6377 27.3164C3.21308 25.8615 2.07624 24.1635 1.22754 22.2236C0.409218 20.2838 2.14112e-05 18.2077 0 15.9951C0 13.8127 0.40915 11.7514 1.22754 9.81152C2.07624 7.87163 3.21308 6.18926 4.6377 4.76465C6.09255 3.30982 7.78971 2.17286 9.72949 1.35449C11.6694 0.505787 13.7463 0.0820313 15.959 0.0820313H22.9609C24.7794 0.0820648 26.2497 0.293455 27.3711 0.717774C28.4925 1.11181 29.3557 1.65835 29.9619 2.35547C30.5984 3.05256 31.0076 3.85541 31.1895 4.76465C31.4016 5.64367 31.5078 6.55353 31.5078 7.49316V19.1777H31.5176C31.5176 20.1777 31.7145 21.1173 32.1084 21.9961C32.4721 22.8448 32.9875 23.5881 33.6543 24.2246C34.2908 24.8611 35.0488 25.3765 35.9277 25.7705C36.7686 26.1309 37.6842 26.3111 38.6738 26.3145C39.6635 26.3112 40.579 26.1309 41.4199 25.7705C42.2989 25.3765 43.0568 24.8611 43.6934 24.2246C44.3602 23.5881 44.8755 22.8448 45.2393 21.9961C45.6332 21.1172 45.8301 20.1778 45.8301 19.1777H45.8398V7.49316C45.8398 6.55353 45.946 5.64367 46.1582 4.76465C46.3401 3.85545 46.7493 3.05255 47.3857 2.35547C47.992 1.65832 48.856 1.11182 49.9775 0.717774C51.099 0.293547 52.5693 0.0820313 54.3877 0.0820313H77.2275C79.8949 0.0820313 82.002 0.339208 83.5479 0.854492C85.0936 1.36977 86.2608 2.08288 87.0488 2.99219C87.2763 3.23659 87.4795 3.49447 87.6602 3.76465C87.8095 3.49204 87.9738 3.26197 88.1562 3.08203C91.2824 -0.000677185 96.2846 -1.65737e-05 110.153 8.88951e-08C114.852 5.73378e-06 136.824 1.1753e-07 136.936 8.88951e-08ZM57.084 26.2402C58.6715 26.2404 59.958 27.5277 59.958 29.1152C59.9579 30.7027 58.6714 31.9901 57.084 31.9902C55.4964 31.9902 54.2091 30.7028 54.209 29.1152C54.209 27.5275 55.4963 26.2402 57.084 26.2402ZM83.3203 15.9043C81.8048 16.5105 80.1828 17.0258 78.4551 17.4502C76.7275 17.8745 75.1209 18.3139 73.6357 18.7686C72.1811 19.2231 70.9689 19.7231 69.999 20.2686C69.0291 20.8141 68.544 21.5117 68.5439 22.3604C68.5439 22.7847 68.5888 23.2396 68.6797 23.7246C68.7706 24.1792 69.0289 24.6031 69.4531 24.9971C69.8774 25.3911 70.5137 25.7253 71.3623 25.998C72.211 26.2405 73.3936 26.3613 74.9092 26.3613C77.3037 26.3613 79.0923 26.2103 80.2744 25.9072C81.4564 25.6041 82.2749 25.0731 82.7295 24.3154C83.1841 23.5274 83.3965 22.4508 83.3662 21.0869C83.3359 19.723 83.3203 17.9955 83.3203 15.9043Z',
    );

    // Create a PathMetric to measure the path
    final pathMetric = path.computeMetrics().first;
    final pathLength = pathMetric.length;

    // 1. Draw traced outline
    final extractPath = pathMetric.extractPath(
      0.0,
      pathLength * traceProgress,
    );
    canvas.drawPath(extractPath, strokePaint);

    // 2. Add dot at trace point
    if (traceProgress < 1.0 && traceProgress > 0) {
      final currentPoint = pathMetric.getTangentForOffset(pathLength * traceProgress);
      if (currentPoint != null) {
        final dotPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        canvas.drawCircle(currentPoint.position, 2, dotPaint);
      }
    }

    // 3. Fill the period and 'a' completely
    if (isFilling && fillProgress > 0) {
      final animatedFillPaint = Paint()
        ..color = color.withOpacity(fillProgress)
        ..style = PaintingStyle.fill;

      // Period - fill the circle completely
      final periodPath = Path()
        ..addOval(Rect.fromCircle(center: const Offset(57, 29), radius: 2.5));
      canvas.drawPath(periodPath, animatedFillPaint);

      // Fill the entire logo with reduced opacity for the full 'a' fill
      final logoFillPaint = Paint()
        ..color = color.withOpacity(fillProgress * 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, logoFillPaint);
    }
  }

  Path parseSvgPath(String svgPath) {
    final path = Path();
    final commands = svgPath.split(RegExp(r'(?=[MLHVCSQTAZ])', caseSensitive: false));

    double currentX = 0;
    double currentY = 0;
    double startX = 0;
    double startY = 0;

    for (var command in commands) {
      if (command.isEmpty) continue;

      final type = command[0];
      final coords = command.substring(1).trim().split(RegExp(r'[ ,]+'));
      final values = coords.where((s) => s.isNotEmpty).map((s) => double.tryParse(s) ?? 0).toList();

      switch (type.toUpperCase()) {
        case 'M': // MoveTo
          if (values.length >= 2) {
            currentX = values[0];
            currentY = values[1];
            startX = currentX;
            startY = currentY;
            path.moveTo(currentX, currentY);
          }
          break;
        case 'L': // LineTo
          if (values.length >= 2) {
            currentX = values[0];
            currentY = values[1];
            path.lineTo(currentX, currentY);
          }
          break;
        case 'H': // Horizontal LineTo
          if (values.isNotEmpty) {
            currentX = values[0];
            path.lineTo(currentX, currentY);
          }
          break;
        case 'V': // Vertical LineTo
          if (values.isNotEmpty) {
            currentY = values[0];
            path.lineTo(currentX, currentY);
          }
          break;
        case 'C': // Cubic Bezier
          if (values.length >= 6) {
            path.cubicTo(
              values[0], values[1],
              values[2], values[3],
              values[4], values[5],
            );
            currentX = values[4];
            currentY = values[5];
          }
          break;
        case 'Z': // Close path
          path.close();
          currentX = startX;
          currentY = startY;
          break;
      }
    }

    return path;
  }

  @override
  bool shouldRepaint(LogoPathPainter oldDelegate) {
    return oldDelegate.traceProgress != traceProgress ||
        oldDelegate.fillProgress != fillProgress ||
        oldDelegate.isFilling != isFilling;
  }
}
