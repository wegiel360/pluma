import 'dart:ui';

import 'package:flutter/material.dart';

import 'pluma_theme.dart';

/// Animated iridescent border painter.
class _IridescentBorderPainter extends CustomPainter {
  final Color color;
  final double animationValue;

  _IridescentBorderPainter({
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color,
          Colors.white.withValues(alpha: 0.4),
          color,
          Colors.white.withValues(alpha: 0.2),
        ],
        stops: [
          (animationValue % 1.0),
          ((animationValue + 0.25) % 1.0),
          ((animationValue + 0.5) % 1.0),
          ((animationValue + 0.75) % 1.0),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_IridescentBorderPainter old) =>
      old.animationValue != animationValue || old.color != color;
}

/// A frosted-glass card with an iridescent animated border.
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? accent;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 24,
    this.accent,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accent ?? Theme.of(context).colorScheme.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      clipBehavior: Clip.none,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return CustomPaint(
              painter: _IridescentBorderPainter(
                color: color,
                animationValue: _ctrl.value,
              ),
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.radius),
                  color: PlumaColors.surface.withValues(alpha: 0.55),
                  border: Border.all(
                    color: color.withValues(alpha: 0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A full-screen background with the Bliss image and a blur/dark overlay.
class BlissBackground extends StatelessWidget {
  final Widget child;

  const BlissBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/bliss-1024p.jpg',
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.6),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              color: const Color(0x4D061700),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Primary amber pill button.
class NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const NeonButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: PlumaColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          shadowColor: color.withValues(alpha: 0.3),
          elevation: 6,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: PlumaColors.onPrimary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Frosted glass input field with leading icon.
class GlassInput extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final IconData icon;
  final VoidCallback? onToggleVisibility;
  final bool showToggle;

  const GlassInput({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.onToggleVisibility,
    this.showToggle = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              color: PlumaColors.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: PlumaColors.onSurface, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: PlumaColors.onSurfaceVariant.withValues(alpha: 0.4),
              fontSize: 13,
            ),
            prefixIcon: Icon(icon, size: 22, color: color.withValues(alpha: 0.6)),
            suffixIcon: showToggle
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off,
                      size: 20,
                    ),
                    color: PlumaColors.onSurfaceVariant,
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: color.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Circular avatar with optional online dot and neon border.
class NeonAvatar extends StatelessWidget {
  final String? image;
  final double size;
  final bool online;
  final Color? accent;

  const NeonAvatar({
    super.key,
    this.image,
    this.size = 40,
    this.online = false,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Theme.of(context).colorScheme.primary;
    final child = SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: image != null && image!.isNotEmpty && image!.startsWith('data:')
            ? Image.network(image!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _fallback(color))
            : Image.asset(
                image ?? 'assets/default-pfp.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(color),
              ),
      ),
    );

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
          ),
          child: Padding(padding: const EdgeInsets.all(2), child: child),
        ),
        if (online)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: PlumaColors.neonActive,
                shape: BoxShape.circle,
                border: Border.all(color: PlumaColors.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _fallback(Color color) {
    return Container(
      color: PlumaColors.surfaceBright,
      child: Icon(Icons.person, color: color.withValues(alpha: 0.7), size: size * 0.5),
    );
  }
}

/// A generic glass modal dialog.
class GlassModal extends StatelessWidget {
  final Widget child;
  final VoidCallback onClose;

  const GlassModal({
    super.key,
    required this.child,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: Container(color: Colors.black.withValues(alpha: 0.7)),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              radius: 24,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
