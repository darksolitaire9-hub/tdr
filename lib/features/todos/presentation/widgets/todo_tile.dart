import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/todo.dart';
import '../../../../services/audio_service.dart';
import '../../../../services/collision_service.dart';
import '../providers/todo_provider.dart';

class TodoTile extends ConsumerStatefulWidget {
  const TodoTile({super.key, required this.todo});
  final Todo todo;

  @override
  ConsumerState<TodoTile> createState() => _TodoTileState();
}

class _TodoTileState extends ConsumerState<TodoTile> {
  bool _isEditing = false;
  late TextEditingController _textCtrl;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.todo.title);
  }

  @override
  void didUpdateWidget(TodoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.todo.title != widget.todo.title && !_isEditing) {
      _textCtrl.text = widget.todo.title;
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveEdit() {
    setState(() => _isEditing = false);
    final newTitle = _textCtrl.text.trim();
    if (newTitle.isNotEmpty && newTitle != widget.todo.title) {
      ref.read(todoActionsProvider.notifier).update(widget.todo.copyWith(title: newTitle));
      AudioService.play(AudioEffect.create);
    } else {
      _textCtrl.text = widget.todo.title; // revert
    }
  }

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;
    final draggingId = ref.watch(draggingTodoIdProvider);
    final selectedId = ref.watch(selectedTodoIdProvider);
    final isDragging = draggingId == todo.id;
    final isSelected = selectedId == todo.id;
    final dragOffset = isDragging ? ref.watch(dragOffsetProvider) : Offset.zero;
    final snapState = ref.watch(snapDisplacementProvider);

    // Haptic feedback when snapping engages
    ref.listen(snapDisplacementProvider, (prev, next) {
      if (isDragging && (prev == null || !prev.isSnapped) && next.isSnapped) {
        HapticFeedback.selectionClick();
      }
    });

    // Force close edit mode if selection is lost
    ref.listen(selectedTodoIdProvider, (prev, next) {
      if (_isEditing && next != todo.id) {
        _saveEdit();
      }
    });

    // The live position is the stored DB position + active drag delta + snap offset (if any)
    final activeSnapOffset = (isDragging && snapState.isSnapped) ? snapState.offset : Offset.zero;
    final x = todo.posX + dragOffset.dx + activeSnapOffset.dx;
    final y = todo.posY + dragOffset.dy + activeSnapOffset.dy;

    // Visual scale up for dragging or selected
    final scale = isDragging ? 1.05 : (isSelected ? 1.02 : 1.0);

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
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutBack,
          child: Listener(
            onPointerDown: (event) async {
              if (_isEditing) return; // Don't interrupt editing
              ref.read(draggingTodoIdProvider.notifier).set(todo.id);
              ref.read(dragOffsetProvider.notifier).set(Offset.zero);
              
              // Only trigger haptic if not already selected
              if (!isSelected) {
                ref.read(selectedTodoIdProvider.notifier).set(todo.id);
                HapticFeedback.selectionClick();
              }
              
              // Ensure spatial grid is ready for collision checks
              final positions = await ref.read(allTodoPositionsProvider.future);
              ref.read(spatialGridProvider.notifier).rebuild(positions);
            },
            onPointerMove: (event) async {
              if (isDragging && !_isEditing) {
                final current = ref.read(dragOffsetProvider);
                final newOffset = current + event.delta;
                ref.read(dragOffsetProvider.notifier).set(newOffset);

                // Magnetic Snapping
                final allPos = await ref.read(allTodoPositionsProvider.future);
                final grid = ref.read(spatialGridProvider);
                final livePos = Offset(todo.posX + newOffset.dx, todo.posY + newOffset.dy);
                
                ref.read(snapDisplacementProvider.notifier).calculateSnap(
                  todo.id, livePos, allPos, grid
                );
              }
            },
            onPointerUp: (event) {
              if (isDragging && !_isEditing) {
                // Save this item's new position
                ref.read(todoActionsProvider.notifier).updatePosition(todo.id, x, y);

                ref.read(draggingTodoIdProvider.notifier).set(null);
                ref.read(dragOffsetProvider.notifier).set(Offset.zero);
                ref.read(snapDisplacementProvider.notifier).clear();
                
                HapticFeedback.lightImpact();
                AudioService.play(AudioEffect.select);
              }
            },
            onPointerCancel: (event) {
              if (!_isEditing) {
                ref.read(draggingTodoIdProvider.notifier).set(null);
                ref.read(dragOffsetProvider.notifier).set(Offset.zero);
                ref.read(snapDisplacementProvider.notifier).clear();
              }
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onDoubleTap: () {
                    if (!isSelected) return;
                    setState(() => _isEditing = true);
                    _focusNode.requestFocus();
                    HapticFeedback.lightImpact();
                  },
                  onLongPress: () {
                    if (_isEditing) return;
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
                          color: Colors.black.withValues(alpha: isDragging ? 0.3 : 0.1),
                          blurRadius: isDragging ? 12 : 4,
                          offset: isDragging ? const Offset(8, 8) : const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        _isEditing
                            ? TextField(
                                controller: _textCtrl,
                                focusNode: _focusNode,
                                style: font.copyWith(fontSize: fontSize),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                maxLines: null,
                                onSubmitted: (_) => _saveEdit(),
                                onEditingComplete: _saveEdit,
                                onTapOutside: (_) => _saveEdit(),
                              )
                            : Text(
                                todo.title,
                                style: font.copyWith(fontSize: fontSize),
                              ),
                        if (todo.isCompleted && !_isEditing)
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
                if (isSelected && !_isEditing) ...[
                  Positioned(
                    top: -4,
                    bottom: -4,
                    left: -4,
                    right: -4,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blueAccent, width: 2),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -48,
                    right: 0,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.surface,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () {
                              setState(() => _isEditing = true);
                              _focusNode.requestFocus();
                              HapticFeedback.lightImpact();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.check, size: 20),
                            onPressed: () {
                              ref.read(todoActionsProvider.notifier).toggle(todo.id);
                              HapticFeedback.mediumImpact();
                              AudioService.play(AudioEffect.check);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                            onPressed: () {
                              ref.read(todoActionsProvider.notifier).delete(todo.id);
                              HapticFeedback.heavyImpact();
                              AudioService.play(AudioEffect.delete);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
