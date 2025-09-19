import 'package:flutter/material.dart';
import 'dart:ui';

import '../theme/app_theme.dart';
import '../constants/app_constants.dart';

class GlassmorphismCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final List<Color>? gradientColors;
  final bool showBorder;

  const GlassmorphismCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.borderRadius,
    this.gradientColors,
    this.showBorder = true,
  });

  @override
  State<GlassmorphismCard> createState() => _GlassmorphismCardState();
}

class _GlassmorphismCardState extends State<GlassmorphismCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _scaleController.reverse();
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? 
        BorderRadius.circular(AppConstants.borderRadius);
    final gradientColors = widget.gradientColors ?? [
      AppTheme.glassBackground,
      AppTheme.glassBackground.withOpacity(0.05),
    ];

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _glowAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            margin: widget.margin,
            child: GestureDetector(
              onTap: widget.onTap,
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              child: ClipRRect(
                borderRadius: borderRadius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors,
                      ),
                      borderRadius: borderRadius,
                      border: widget.showBorder
                          ? Border.all(
                              color: AppTheme.glassBorder.withOpacity(0.3 + _glowAnimation.value * 0.2),
                              width: 1,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.glassShadow.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                        if (_glowAnimation.value > 0)
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.1 * _glowAnimation.value),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: Container(
                      padding: widget.padding ?? 
                          const EdgeInsets.all(AppConstants.defaultPadding),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}




