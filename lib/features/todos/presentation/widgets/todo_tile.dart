import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/todo.dart';
import '../../../../services/audio_service.dart';
import '../providers/todo_provider.dart';

class TodoTile extends ConsumerWidget {
  const TodoTile({super.key, required this.todo});
  final Todo todo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draggingId = ref.watch(draggingTodoIdProvider);
    final isDragging = draggingId == todo.id;
    final dragOffset = isDragging ? ref.watch(dragOffsetProvider) : Offset.zero;

    // The live position is the stored DB position plus any active drag delta
    final x = todo.posX + dragOffset.dx;
    final y = todo.posY + dragOffset.dy;

    // Playful sticker styling
    final stickerColors = [
      AppColors.stickerPink,
      AppColors.stickerBlue,
      AppColors.stickerYellow,
      AppColors.stickerGreen,
      AppColors.stickerPurple,
    ];
    // Deterministic color based on id hash
    final stickerColor = stickerColors[todo.id.hashCode % stickerColors.length];

    // Dynamic font size: short tasks are loud/big, long tasks are detailed/small.
    final double fontSize = todo.title.length < 15 ? 32 : 18;
    final font = todo.title.length < 20
        ? GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900, color: Colors.black87)
        : GoogleFonts.caveat(
            fontWeight: FontWeight.w600, color: Colors.black87);

    return Positioned(
      left: x,
      top: y,
      child: Transform.rotate(
        angle: todo.rotation,
        child: Listener(
          onPointerDown: (event) {
            ref.read(draggingTodoIdProvider.notifier).set(todo.id);
            ref.read(dragOffsetProvider.notifier).set(Offset.zero);
          },
          onPointerMove: (event) {
            if (isDragging) {
              final current = ref.read(dragOffsetProvider);
              ref.read(dragOffsetProvider.notifier).set(current + event.delta);
            }
          },
          onPointerUp: (event) {
            if (isDragging) {
              ref
                  .read(todoActionsProvider.notifier)
                  .updatePosition(todo.id, x, y);
              ref.read(draggingTodoIdProvider.notifier).set(null);
              ref.read(dragOffsetProvider.notifier).set(Offset.zero);
              HapticFeedback.lightImpact();
            }
          },
          onPointerCancel: (event) {
            ref.read(draggingTodoIdProvider.notifier).set(null);
            ref.read(dragOffsetProvider.notifier).set(Offset.zero);
          },
          child: GestureDetector(
            onDoubleTap: () {
              ref.read(todoActionsProvider.notifier).toggle(todo.id);
              HapticFeedback.mediumImpact();
              AudioService.play(AudioEffect.check);
            },
            onLongPress: () {
              ref.read(todoActionsProvider.notifier).delete(todo.id);
              HapticFeedback.heavyImpact();
              AudioService.play(AudioEffect.delete);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: const BoxConstraints(maxWidth: 250),
              decoration: BoxDecoration(
                color: stickerColor.withValues(alpha: isDragging ? 1.0 : 0.9),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: isDragging ? 0.2 : 0.1),
                    blurRadius: isDragging ? 8 : 4,
                    offset:
                        isDragging ? const Offset(4, 4) : const Offset(2, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Text(
                    todo.title,
                    style: font.copyWith(fontSize: fontSize),
                  ),
                  if (todo.isCompleted)
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          height: 4,
                          width: double.infinity,
                          color: Colors.redAccent.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
