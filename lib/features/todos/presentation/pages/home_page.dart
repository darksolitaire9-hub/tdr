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
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _listenToHardware();
  }

  void _listenToHardware() {
    ref.listenManual(hardwareServiceProvider, (prev, next) {
      next.whenData((button) {
        if (button == VolumeButton.up) {
          _inputFocus.requestFocus();
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
    _pageController.dispose();
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
  }

  @override
  Widget build(BuildContext context) {
    final isDailyFocus = ref.watch(dailyFocusProvider);
    final todosAsync = ref.watch(todoStreamProvider(filter: TodoFilter.active));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDailyFocus),
            Expanded(
              child: todosAsync.when(
                data: (list) {
                  final filtered = isDailyFocus ? _filterForToday(list) : list;
                  return _buildPagedContent(filtered);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
            _buildInputArea(scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDailyFocus) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isDailyFocus ? 'Today' : 'Gathered',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 4),
          Text(
            isDailyFocus ? 'Focused on the now.' : 'All that awaits your attention.',
            style: GoogleFonts.lora(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
      final target = DateTime(t.scheduledAt!.year, t.scheduledAt!.month, t.scheduledAt!.day);
      return target == today;
    }).toList();
  }

  Widget _buildPagedContent(List<Todo> list) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          'A quiet moment.',
          style: GoogleFonts.lora(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ),
      );
    }

    const itemsPerPage = 7;
    final pageCount = (list.length / itemsPerPage).ceil();

    return PageView.builder(
      controller: _pageController,
      itemCount: pageCount,
      itemBuilder: (context, pageIndex) {
        final start = pageIndex * itemsPerPage;
        final end = (start + itemsPerPage < list.length) ? start + itemsPerPage : list.length;
        final pageItems = list.sublist(start, end);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              ...pageItems.map((todo) => TodoTile(todo: todo)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputArea(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
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
                    style: GoogleFonts.lora(fontSize: 13, color: scheme.primary),
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
            style: GoogleFonts.lora(fontSize: 18),
            decoration: InputDecoration(
              hintText: 'What calls to you?',
              hintStyle: GoogleFonts.lora(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
