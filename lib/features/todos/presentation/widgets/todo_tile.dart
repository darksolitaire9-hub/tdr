import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _TodoTileState extends ConsumerState<TodoTile> {
  late double _x;
  late double _y;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _x = widget.todo.posX;
    _y = widget.todo.posY;
  }

  @override
  void didUpdateWidget(TodoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging) {
      _x = widget.todo.posX;
      _y = widget.todo.posY;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Playful sticker styling
    final stickerColors = [
      AppColors.stickerPink,
      AppColors.stickerBlue,
      AppColors.stickerYellow,
      AppColors.stickerGreen,
      AppColors.stickerPurple,
    ];
    // Deterministic color based on id hash
    final stickerColor = stickerColors[widget.todo.id.hashCode % stickerColors.length];
    
    // Dynamic font size: short tasks are loud/big, long tasks are detailed/small.
    final double fontSize = widget.todo.title.length < 15 ? 32 : 18;
    final font = widget.todo.title.length < 20 
        ? GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, color: Colors.black87)
        : GoogleFonts.caveat(fontWeight: FontWeight.w600, color: Colors.black87);

    return Positioned(
      left: _x,
      top: _y,
      child: Transform.rotate(
        angle: widget.todo.rotation,
        child: GestureDetector(
          onPanStart: (_) => setState(() => _isDragging = true),
          onPanUpdate: (details) {
            setState(() {
              _x += details.delta.dx;
              _y += details.delta.dy;
            });
          },
          onPanEnd: (_) {
            setState(() => _isDragging = false);
            ref.read(todoActionsProvider.notifier).updatePosition(widget.todo.id, _x, _y);
            HapticFeedback.lightImpact();
          },
          onDoubleTap: () {
            ref.read(todoActionsProvider.notifier).toggle(widget.todo.id);
            HapticFeedback.mediumImpact();
            AudioService.play(AudioEffect.check);
          },
          onLongPress: () {
            ref.read(todoActionsProvider.notifier).delete(widget.todo.id);
            HapticFeedback.heavyImpact();
            AudioService.play(AudioEffect.delete);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: const BoxConstraints(maxWidth: 250),
            decoration: BoxDecoration(
              color: stickerColor.withValues(alpha: 0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Text(
                  widget.todo.title,
                  style: font.copyWith(fontSize: fontSize),
                ),
                if (widget.todo.isCompleted)
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
    );
  }
}
