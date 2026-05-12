import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/todo.dart';
import '../../../../services/audio_service.dart';
import '../providers/todo_provider.dart';

class TodoTile extends ConsumerStatefulWidget {
  const TodoTile({super.key, required this.todo});
  final Todo todo;

  @override
  ConsumerState<TodoTile> createState() => _TodoTileState();
}

class _TodoTileState extends ConsumerState<TodoTile>
    with TickerProviderStateMixin {
  // Checkbox fill: 150ms easeOut
  late final AnimationController _checkCtrl;
  // Strikethrough draw (0→250ms) + text fade (250→450ms) = 450ms total
  late final AnimationController _strikeCtrl;

  late final Animation<double> _checkFill;
  late final Animation<double> _strikeProgress; // 0→1 over first 55% of ctrl
  late final Animation<double> _textAlpha;       // 1→0.45 over last 45%

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _strikeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));

    _checkFill = CurvedAnimation(parent: _checkCtrl, curve: Curves.easeOut);

    _strikeProgress = CurvedAnimation(
      parent: _strikeCtrl,
      curve: const Interval(0.0, 0.556, curve: Curves.easeOut),
    );
    _textAlpha = Tween<double>(begin: 1.0, end: 0.45).animate(
      CurvedAnimation(
        parent: _strikeCtrl,
        curve: const Interval(0.556, 1.0, curve: Curves.easeIn),
      ),
    );

    // Initialise at final state for already-completed items.
    if (widget.todo.isCompleted) {
      _checkCtrl.value  = 1.0;
      _strikeCtrl.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(TodoTile old) {
    super.didUpdateWidget(old);
    if (old.todo.isCompleted == widget.todo.isCompleted) return;

    final noAnim = MediaQuery.of(context).disableAnimations;
    if (!old.todo.isCompleted && widget.todo.isCompleted) {
      // incomplete → complete
      if (noAnim) {
        _checkCtrl.value  = 1.0;
        _strikeCtrl.value = 1.0;
      } else {
        _checkCtrl.forward();
        _strikeCtrl.forward();
        AudioService.playCheck();
      }
    } else {
      // complete → incomplete: reverse (no sound)
      if (noAnim) {
        _checkCtrl.value  = 0.0;
        _strikeCtrl.value = 0.0;
      } else {
        _checkCtrl.reverse();
        _strikeCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _strikeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme    = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent    = scheme.primary;
    final muted     = scheme.onSurface.withValues(alpha: 0.45);

    return Slidable(
      key: ValueKey(widget.todo.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (_) =>
                ref.read(todoActionsProvider.notifier).delete(widget.todo.id),
            backgroundColor: scheme.errorContainer,
            foregroundColor: scheme.error,
            icon: Icons.delete_outline,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/todo/edit/${widget.todo.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                _PriorityDot(priority: widget.todo.priority),
                _AnimatedCheckbox(
                  fillAnim:    _checkFill,
                  accent:      accent,
                  borderColor: muted,
                  onTap: () => ref
                      .read(todoActionsProvider.notifier)
                      .toggle(widget.todo.id),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_strikeProgress, _textAlpha]),
                    builder: (_, __) => Opacity(
                      opacity: _textAlpha.value,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomPaint(
                            foregroundPainter: _StrikethroughPainter(
                              progress: _strikeProgress.value,
                              color:    muted,
                            ),
                            child: Text(
                              widget.todo.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyLarge,
                            ),
                          ),
                          if (widget.todo.description.isNotEmpty)
                            Text(
                              widget.todo.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          if (widget.todo.scheduledAt != null)
                            Text(
                              _fmtScheduled(widget.todo.scheduledAt!),
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: accent.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.06, end: 0);
  }

  String _fmtScheduled(DateTime dt) {
    final now       = DateTime.now();
    final today     = DateTime(now.year, now.month, now.day);
    final tomorrow  = today.add(const Duration(days: 1));
    final target    = DateTime(dt.year, dt.month, dt.day);
    final hasTime   = dt.hour != 0 || dt.minute != 0;
    final timeSuffix = hasTime ? ' ${_fmtTime(dt)}' : '';

    if (target == today)    return 'Today$timeSuffix';
    if (target == tomorrow) return 'Tomorrow$timeSuffix';

    const days   = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]}$timeSuffix';
  }

  String _fmtTime(DateTime dt) {
    final h   = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute > 0
        ? ':${dt.minute.toString().padLeft(2, '0')}'
        : '';
    return '$h$min ${dt.hour < 12 ? 'AM' : 'PM'}';
  }
}

// ── Custom checkbox ────────────────────────────────────────────────────────

class _AnimatedCheckbox extends StatelessWidget {
  const _AnimatedCheckbox({
    required this.fillAnim,
    required this.accent,
    required this.borderColor,
    required this.onTap,
  });

  final Animation<double> fillAnim;
  final Color             accent;
  final Color             borderColor;
  final VoidCallback      onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: fillAnim,
          builder: (_, __) {
            final t      = fillAnim.value;
            final fill   = Color.lerp(Colors.transparent, accent, t)!;
            final border = Color.lerp(borderColor, accent, t)!;
            return Container(
              width:  22,
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                border: Border.all(color: border, width: 1.5),
              ),
              child: t > 0.5
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            );
          },
        ),
      );
}

// ── Strikethrough painter ──────────────────────────────────────────────────

class _StrikethroughPainter extends CustomPainter {
  const _StrikethroughPainter({required this.progress, required this.color});

  final double progress;
  final Color  color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    canvas.drawLine(
      Offset(0, size.height * 0.52),
      Offset(size.width * progress, size.height * 0.52),
      Paint()
        ..color      = color
        ..strokeWidth = 1.3
        ..strokeCap  = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StrikethroughPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Priority dot ──────────────────────────────────────────────────────────

class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.priority});
  final TodoPriority priority;

  @override
  Widget build(BuildContext context) => Container(
        width:  7,
        height: 7,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: switch (priority) {
            TodoPriority.low    => AppColors.priorityLow,
            TodoPriority.medium => AppColors.priorityMedium,
            TodoPriority.high   => AppColors.priorityHigh,
          },
        ),
      );
}

