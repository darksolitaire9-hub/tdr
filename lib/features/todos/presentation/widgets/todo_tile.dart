import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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
  late final AnimationController _strikeCtrl;
  late final Animation<double> _strikeProgress;
  late final Animation<double> _textAlpha;

  @override
  void initState() {
    super.initState();
    _strikeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    _strikeProgress = CurvedAnimation(
      parent: _strikeCtrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _textAlpha = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _strikeCtrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    if (widget.todo.isCompleted) {
      _strikeCtrl.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(TodoTile old) {
    super.didUpdateWidget(old);
    if (old.todo.isCompleted == widget.todo.isCompleted) return;

    if (widget.todo.isCompleted) {
      _strikeCtrl.forward();
      AudioService.play(AudioEffect.check);
      HapticFeedback.heavyImpact();
    } else {
      _strikeCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _strikeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = scheme.primary;
    final muted = scheme.onSurface.withValues(alpha: 0.4);

    return Slidable(
      key: ValueKey(widget.todo.id),
      // Swipe Right: Toggle Complete
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.2,
        children: [
          CustomSlidableAction(
            onPressed: (_) => ref
                .read(todoActionsProvider.notifier)
                .toggle(widget.todo.id),
            backgroundColor: Colors.transparent,
            child: Icon(
              widget.todo.isCompleted ? Icons.undo : Icons.check,
              color: AppColors.priorityLow,
              size: 20,
            ),
          ),
        ],
      ),
      // Swipe Left: Delete
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.2,
        children: [
          CustomSlidableAction(
            onPressed: (_) {
              AudioService.play(AudioEffect.delete);
              HapticFeedback.mediumImpact();
              ref.read(todoActionsProvider.notifier).delete(widget.todo.id);
            },
            backgroundColor: Colors.transparent,
            child: const Icon(Icons.delete_outline, color: AppColors.priorityHigh, size: 20),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(bottom: BorderSide(color: scheme.outline, width: 0.5)),
        ),
        child: Row(
          children: [
            _PriorityDot(priority: widget.todo.priority),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedBuilder(
                animation: _strikeCtrl,
                builder: (_, __) => Opacity(
                  opacity: _textAlpha.value,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomPaint(
                        foregroundPainter: _StrikethroughPainter(
                          progress: _strikeProgress.value,
                          color: muted,
                        ),
                        child: Text(
                          widget.todo.title,
                          style: textTheme.bodyLarge,
                        ),
                      ),
                      if (widget.todo.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            widget.todo.description,
                            style: textTheme.bodySmall?.copyWith(color: muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.todo.scheduledAt != null)
              Text(
                _fmtScheduled(widget.todo.scheduledAt!),
                style: GoogleFonts.lora(fontSize: 11, color: accent.withValues(alpha: 0.6)),
              ),
          ],
        ),
      ),
    );
  }

  String _fmtScheduled(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    if (target == today) return 'Today';
    if (target == today.add(const Duration(days: 1))) return 'Tomorrow';
    return '${dt.day}/${dt.month}';
  }
}

class _StrikethroughPainter extends CustomPainter {
  const _StrikethroughPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height * 0.55),
      Offset(size.width * progress, size.height * 0.55),
      paint,
    );
  }

  @override
  bool shouldRepaint(_StrikethroughPainter old) => old.progress != progress;
}

class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.priority});
  final TodoPriority priority;

  @override
  Widget build(BuildContext context) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: switch (priority) {
            TodoPriority.low => AppColors.priorityLow,
            TodoPriority.medium => AppColors.priorityMedium,
            TodoPriority.high => AppColors.priorityHigh,
          },
        ),
      );
}
