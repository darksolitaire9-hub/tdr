import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/todo.dart';
import '../../../../services/audio_service.dart';
import '../../../../services/hardware_service.dart';
import '../../../../services/task_parser_service.dart';
import '../providers/focus_provider.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_tile.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _inputCtrl = TextEditingController();
  final _inputFocus = FocusNode();
  DateTime? _parsedDate;
  String? _datePreview;
  final _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _listenToHardware();
    // Start slightly zoomed out and centered
    _transformationController.value = Matrix4.identity()
      ..setTranslationRaw(-500.0, -500.0, 0.0)
      ..storage[0] = 0.8 // scale X
      ..storage[5] = 0.8; // scale Y
  }

  void _listenToHardware() {
    ref.listenManual(hardwareServiceProvider, (prev, next) {
      next.whenData((button) {
        if (button == VolumeButton.up) {
          _openPenTool();
          AudioService.play(AudioEffect.create);
          HapticFeedback.lightImpact();
        } else if (button == VolumeButton.down) {
          ref.read(dailyFocusProvider.notifier).toggle();
          AudioService.play(AudioEffect.select);
          HapticFeedback.mediumImpact();
        }
      });
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _inputFocus.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _onInputChanged(String text) {
    final parser = ref.read(taskParserServiceProvider.notifier);
    final result = parser.parseDate(text);
    setState(() {
      _parsedDate = result?.$1;
      _datePreview = result?.$2;
    });
  }

  Future<void> _submit() async {
    final raw = _inputCtrl.text.trim();
    if (raw.isEmpty) return;

    final parser = ref.read(taskParserServiceProvider.notifier);
    final title = _parsedDate != null ? parser.stripDateTerms(raw) : raw;

    await ref.read(todoActionsProvider.notifier).create(
          title: title.isEmpty ? raw : title,
          scheduledAt: _parsedDate,
        );

    _inputCtrl.clear();
    setState(() {
      _parsedDate = null;
      _datePreview = null;
    });
    AudioService.play(AudioEffect.create);
    HapticFeedback.mediumImpact();

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _openPenTool() {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: _buildInputArea(scheme),
        );
      },
    ).then((_) {
      // Clear when closed
      _inputCtrl.clear();
      setState(() {
        _parsedDate = null;
        _datePreview = null;
      });
    });
    // Request focus after a tiny delay so the sheet can build
    Future.delayed(const Duration(milliseconds: 100), () {
      _inputFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDailyFocus = ref.watch(dailyFocusProvider);
    final draggingId = ref.watch(draggingTodoIdProvider);
    final isDragging = draggingId != null;
    final todosAsync = ref.watch(todoStreamProvider(filter: TodoFilter.active));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: _openPenTool,
        child: const Icon(Icons.edit),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // The Infinite Moodboard Canvas
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  // Future: Clear selection
                  HapticFeedback.selectionClick();
                },
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  boundaryMargin: const EdgeInsets.all(4000),
                  minScale: 0.2,
                  maxScale: 3.0,
                  panEnabled: !isDragging,
                  scaleEnabled: !isDragging,
                  child: Center(
                    child: SizedBox(
                      width: 2000,
                      height: 2000,
                      child: todosAsync.when(
                        data: (list) {
                          final filtered =
                              isDailyFocus ? _filterForToday(list) : list;

                          // Managed Z-index: Active dragging item stays on top
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ...filtered
                                  .where((t) => t.id != draggingId)
                                  .map((todo) => TodoTile(
                                      key: ValueKey(todo.id), todo: todo)),
                              if (isDragging)
                                ...filtered
                                    .where((t) => t.id == draggingId)
                                    .map((todo) => TodoTile(
                                        key: ValueKey(todo.id), todo: todo)),
                            ],
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e')),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Fixed Header overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.surface,
                      scheme.surface.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: _buildHeader(isDailyFocus),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDailyFocus) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isDailyFocus ? 'Today' : 'Moodboard',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 4),
          Text(
            isDailyFocus ? 'Focused on the now.' : 'Clutter yet freedom.',
            style: GoogleFonts.lora(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  List<Todo> _filterForToday(List<Todo> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return list.where((t) {
      if (t.scheduledAt == null) return false;
      final target = DateTime(
          t.scheduledAt!.year, t.scheduledAt!.month, t.scheduledAt!.day);
      return target == today;
    }).toList();
  }

  Widget _buildInputArea(ColorScheme scheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_datePreview != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.event, size: 14, color: scheme.primary),
                const SizedBox(width: 4),
                Text(
                  _datePreview!,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      color: scheme.primary,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        TextField(
          controller: _inputCtrl,
          focusNode: _inputFocus,
          onChanged: _onInputChanged,
          onSubmitted: (_) => _submit(),
          textCapitalization: TextCapitalization.sentences,
          style: GoogleFonts.caveat(fontSize: 28, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Drop a thought...',
            hintStyle: GoogleFonts.caveat(
              fontSize: 28,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            border: InputBorder.none,
          ),
        ),
        const SizedBox(height: 16), // Extra padding for bottom sheet
      ],
    );
  }
}
