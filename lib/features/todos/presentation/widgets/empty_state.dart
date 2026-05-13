import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/todo.dart';

class EmptyState extends StatefulWidget {
  const EmptyState({super.key, required this.filter});
  final TodoFilter filter;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _wrap;
  late final Animation<double> _path;
  late final Animation<double> _text;

  @override
  void initState() {
    super.initState();
    // Total: 200ms delay + 900ms controller
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    // Widget fades in over 400ms (mapped to controller 0.22→0.67)
    _wrap = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.22, 0.67, curve: Curves.easeIn));

    // Checkmark draws over 500ms with elastic overshoot (0.22→0.78)
    _path = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.22, 0.78, curve: Curves.elasticOut));

    // "All clear." fades in after 200ms delay (0.44→0.78)
    _text = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.44, 0.78, curve: Curves.easeIn));

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.filter != TodoFilter.active) {
      return _SimpleEmpty(filter: widget.filter);
    }

    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _wrap.value,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CustomPaint(
                  painter: _CheckmarkPainter(
                    progress: _path.value.clamp(0.0, 1.0),
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Opacity(
                opacity: _text.value,
                child: Text(
                  'All clear.',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: scheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  const _CheckmarkPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Hand-drawn checkmark: short downstroke (bezier imperfection) + long upstroke.
    final path = Path()
      ..moveTo(s.width * 0.15, s.height * 0.50)
      ..quadraticBezierTo(
        s.width * 0.27, s.height * 0.60, // slight bow — the "pencil wobble"
        s.width * 0.38, s.height * 0.72,
      )
      ..lineTo(s.width * 0.85, s.height * 0.22);

    for (final metric in path.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CheckmarkPainter old) =>
      old.progress != progress || old.color != color;
}

class _SimpleEmpty extends StatelessWidget {
  const _SimpleEmpty({required this.filter});
  final TodoFilter filter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, msg) = switch (filter) {
      TodoFilter.all => (
          Icons.check_circle_outline,
          'No todos yet.\nTap + to add one.',
        ),
      TodoFilter.active => (Icons.task_alt, 'All done!'),
      TodoFilter.completed => (
          Icons.radio_button_unchecked,
          'Nothing completed yet.',
        ),
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: scheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
          ),
        ],
      ),
    );
  }
}
