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

  // Local interaction state for 60fps performance
  bool _isInteracting = false;
  bool _isResizing = false;
  late double _localX;
  late double _localY;
  late double _localRotation;
  late double _localWidth;

  double _baseRotation = 0;
  double _baseWidth = 250;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.todo.title);
    _localX = widget.todo.posX;
    _localY = widget.todo.posY;
    _localRotation = widget.todo.rotation;
    _localWidth = widget.todo.width;
  }

  @override
  void didUpdateWidget(TodoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.todo.title != widget.todo.title && !_isEditing) {
      _textCtrl.text = widget.todo.title;
    }

    // Only update local state from the widget if we aren't currently interacting
    // AND the widget property has fundamentally changed (e.g. from the DB stream).
    if (!_isInteracting && !_isResizing) {
      if (oldWidget.todo.posX != widget.todo.posX) {
        _localX = widget.todo.posX;
      }
      if (oldWidget.todo.posY != widget.todo.posY) {
        _localY = widget.todo.posY;
      }
      if (oldWidget.todo.rotation != widget.todo.rotation) {
        _localRotation = widget.todo.rotation;
      }
      if (oldWidget.todo.width != widget.todo.width) {
        _localWidth = widget.todo.width;
      }
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

    final activeSnapOffset = (isDragging && snapState.isSnapped) ? snapState.offset : Offset.zero;

    // Use local state for high-performance rendering during gestures
    final x = _isInteracting ? _localX + activeSnapOffset.dx : todo.posX;
    final y = _isInteracting ? _localY + activeSnapOffset.dy : todo.posY;
    final rotation = _isInteracting ? _localRotation : todo.rotation;
    final width = (_isInteracting || _isResizing) ? _localWidth : todo.width;

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
    final stickerColor = stickerColors[todo.colorIndex % stickerColors.length];

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
        angle: rotation,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutBack,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. The Sticker itself (Handles Pan/Scale/Rotate)
              GestureDetector(
                onTap: () {
                  if (!isSelected) {
                    ref.read(selectedTodoIdProvider.notifier).set(todo.id);
                    HapticFeedback.selectionClick();
                  }
                },
                onDoubleTap: () {
                  if (!isSelected) {
                    ref.read(selectedTodoIdProvider.notifier).set(todo.id);
                  }
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
                onScaleStart: (details) async {
                  if (_isEditing) return;
                  setState(() {
                    _isInteracting = true;
                    _baseRotation = _localRotation;
                    _baseWidth = _localWidth;
                  });

                  ref.read(draggingTodoIdProvider.notifier).set(todo.id);

                  if (!isSelected) {
                    ref.read(selectedTodoIdProvider.notifier).set(todo.id);
                    HapticFeedback.selectionClick();
                  }

                  final positions =
                      await ref.read(allTodoPositionsProvider.future);
                  ref.read(spatialGridProvider.notifier).rebuild(positions);
                },
                onScaleUpdate: (details) {
                  if (!_isInteracting || _isEditing) return;

                  setState(() {
                    _localX += details.focalPointDelta.dx;
                    _localY += details.focalPointDelta.dy;

                    if (details.rotation != 0.0) {
                      _localRotation = _baseRotation + details.rotation;
                    }
                    if (details.scale != 1.0) {
                      _localWidth =
                          (_baseWidth * details.scale).clamp(100.0, 800.0);
                    }
                  });

                  final allPos =
                      ref.read(allTodoPositionsProvider).valueOrNull ?? {};
                  final grid = ref.read(spatialGridProvider);
                  final livePos = Offset(_localX, _localY);

                  ref.read(snapDisplacementProvider.notifier).calculateSnap(
                        todo.id,
                        livePos,
                        allPos,
                        grid,
                      );
                },
                onScaleEnd: (details) {
                  if (!_isInteracting) return;

                  final activeSnap = ref.read(snapDisplacementProvider);
                  final snapOffset =
                      activeSnap.isSnapped ? activeSnap.offset : Offset.zero;

                  // Brick Alignment: Snap final position to 20px grid
                  final finalX = _localX + snapOffset.dx;
                  final finalY = _localY + snapOffset.dy;
                  final snappedX = (finalX / 20).round() * 20.0;
                  final snappedY = (finalY / 20).round() * 20.0;

                  setState(() {
                    _isInteracting = false;
                    _localX = snappedX;
                    _localY = snappedY;
                  });

                  ref.read(todoActionsProvider.notifier).update(todo.copyWith(
                        posX: snappedX,
                        posY: snappedY,
                        rotation: _localRotation,
                        width: _localWidth,
                      ));

                  ref.read(draggingTodoIdProvider.notifier).set(null);
                  ref.read(snapDisplacementProvider.notifier).clear();

                  HapticFeedback.lightImpact();
                  AudioService.play(AudioEffect.select);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: BoxConstraints(maxWidth: width),
                  decoration: BoxDecoration(
                    color:
                        stickerColor.withValues(alpha: isDragging ? 1.0 : 0.9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDragging ? 0.3 : 0.1),
                        blurRadius: isDragging ? 12 : 4,
                        offset:
                            isDragging ? const Offset(8, 8) : const Offset(2, 2),
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

              // 2. Bounding Box & Toolbar (Siblings of Sticker)
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
                  right: -100, // Extend a bit for the color dots
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(stickerColors.length, (idx) {
                            return GestureDetector(
                              onTap: () {
                                ref
                                    .read(todoActionsProvider.notifier)
                                    .update(todo.copyWith(colorIndex: idx));
                                HapticFeedback.selectionClick();
                              },
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: stickerColors[idx],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: todo.colorIndex == idx
                                        ? Colors.black54
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          }),
                          const VerticalDivider(
                              width: 8, thickness: 1, indent: 8, endIndent: 8),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32),
                            onPressed: () {
                              setState(() => _isEditing = true);
                              _focusNode.requestFocus();
                              HapticFeedback.lightImpact();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.check, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32),
                            onPressed: () {
                              ref
                                  .read(todoActionsProvider.notifier)
                                  .toggle(todo.id);
                              HapticFeedback.mediumImpact();
                              AudioService.play(AudioEffect.check);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                size: 20, color: Colors.redAccent),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32),
                            onPressed: () {
                              ref
                                  .read(todoActionsProvider.notifier)
                                  .delete(todo.id);
                              HapticFeedback.heavyImpact();
                              AudioService.play(AudioEffect.delete);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Resize Handle
                Positioned(
                  bottom: -8,
                  right: -8,
                  child: GestureDetector(
                    onPanStart: (_) {
                      setState(() {
                        _isResizing = true;
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _localWidth =
                            (_localWidth + details.delta.dx).clamp(100.0, 500.0);
                      });
                    },
                    onPanEnd: (_) {
                      setState(() => _isResizing = false);
                      ref
                          .read(todoActionsProvider.notifier)
                          .update(todo.copyWith(width: _localWidth));
                    },
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.blueAccent, width: 2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
