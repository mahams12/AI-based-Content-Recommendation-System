import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedLogo extends StatefulWidget {
  final double size;
  final Color? primaryColor;
  final Color? secondaryColor;
  final bool showText;
  final String? customText;

  const AnimatedLogo({
    super.key,
    this.size = 100,
    this.primaryColor,
    this.secondaryColor,
    this.showText = true,
    this.customText,
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _glowController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Rotation animation
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Scale animation
    _scaleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _rotationController.repeat();
    _scaleController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? Theme.of(context).primaryColor;
    final secondaryColor = widget.secondaryColor ?? Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated Logo Container
        AnimatedBuilder(
          animation: Listenable.merge([
            _rotationAnimation,
            _scaleAnimation,
            _pulseAnimation,
            _glowAnimation,
          ]),
          builder: (context, child) {
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3 * _glowAnimation.value),
                    blurRadius: 20 * _glowAnimation.value,
                    spreadRadius: 5 * _glowAnimation.value,
                  ),
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1 * _pulseAnimation.value),
                    blurRadius: 30 * _pulseAnimation.value,
                    spreadRadius: 10 * _pulseAnimation.value,
                  ),
                ],
              ),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: ContentNationLogoPainter(
                      primaryColor: primaryColor,
                      secondaryColor: secondaryColor,
                      pulseValue: _pulseAnimation.value,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // App Name Text
        if (widget.showText) ...[
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseAnimation.value * 0.05),
                child: Text(
                  widget.customText ?? 'Content Nation',
                  style: TextStyle(
                    fontSize: widget.size * 0.2,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class ContentNationLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final double pulseValue;

  ContentNationLogoPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Main content icon (play button with content elements)
    final mainPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    // Draw play button
    final playPath = Path();
    final playSize = radius * 0.4;
    playPath.moveTo(center.dx - playSize * 0.3, center.dy - playSize);
    playPath.lineTo(center.dx - playSize * 0.3, center.dy + playSize);
    playPath.lineTo(center.dx + playSize * 0.7, center.dy);
    playPath.close();
    canvas.drawPath(playPath, mainPaint);

    // Draw content elements around the play button
    final contentPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    // Music note
    final musicNotePath = Path();
    final musicNoteCenter = Offset(
      center.dx + radius * 0.6 * math.cos(math.pi / 4),
      center.dy + radius * 0.6 * math.sin(math.pi / 4),
    );
    musicNotePath.addOval(Rect.fromCenter(
      center: musicNoteCenter,
      width: radius * 0.15,
      height: radius * 0.15,
    ));
    musicNotePath.moveTo(musicNoteCenter.dx, musicNoteCenter.dy + radius * 0.075);
    musicNotePath.lineTo(musicNoteCenter.dx, musicNoteCenter.dy + radius * 0.3);
    musicNotePath.moveTo(musicNoteCenter.dx, musicNoteCenter.dy + radius * 0.2);
    musicNotePath.lineTo(musicNoteCenter.dx + radius * 0.1, musicNoteCenter.dy + radius * 0.25);
    canvas.drawPath(musicNotePath, contentPaint);

    // Video camera icon
    final cameraCenter = Offset(
      center.dx + radius * 0.6 * math.cos(-math.pi / 4),
      center.dy + radius * 0.6 * math.sin(-math.pi / 4),
    );
    final cameraRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: cameraCenter,
        width: radius * 0.2,
        height: radius * 0.15,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(cameraRect, contentPaint);

    // Film strip
    final filmCenter = Offset(
      center.dx + radius * 0.6 * math.cos(3 * math.pi / 4),
      center.dy + radius * 0.6 * math.sin(3 * math.pi / 4),
    );
    final filmRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: filmCenter,
        width: radius * 0.25,
        height: radius * 0.1,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(filmRect, contentPaint);

    // Draw small squares on film strip
    for (int i = 0; i < 3; i++) {
      final squareRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(
            filmCenter.dx - radius * 0.08 + (i * radius * 0.08),
            filmCenter.dy,
          ),
          width: radius * 0.06,
          height: radius * 0.06,
        ),
        Radius.circular(1),
      );
      canvas.drawRRect(squareRect, mainPaint);
    }

    // Pulsing rings
    final ringPaint = Paint()
      ..color = primaryColor.withOpacity(0.3 * pulseValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 1; i <= 3; i++) {
      final ringRadius = radius * 0.8 + (i * radius * 0.1 * pulseValue);
      canvas.drawCircle(center, ringRadius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
