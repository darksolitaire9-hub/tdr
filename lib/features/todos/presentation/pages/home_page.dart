import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../domain/models/todo.dart';
import '../../../../services/audio_service.dart';
import '../../../../services/pattern_service.dart';
import '../providers/database_provider.dart';
import '../providers/todo_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_bar.dart';
import '../widgets/pattern_suggestion_card.dart';
import '../widgets/todo_tile.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  var _filter     = TodoFilter.all;
  String? _search;
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();

  // Quick-add (Pass 5)
  final _quickCtrl  = TextEditingController();
  final _quickFocus = FocusNode();
  DateTime? _parsedDate;
  String?   _datePreview;

  // Pattern suggestions (Pass 4)
  List<String>     _suggestions         = [];
  final Set<String> _dismissedSuggestions = {};

  @override
  void initState() {
    super.initState();
    // Autofocus quick-add on first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _quickFocus.requestFocus();
    });
    // Keep suffix icon reactive.
    _quickCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _quickCtrl.dispose();
    _quickFocus.dispose();
    super.dispose();
  }

  // ── Quick-add ──────────────────────────────────────────────────────────

  void _onQuickChanged(String text) {
    final result = _parseDate(text);
    setState(() {
      _parsedDate  = result?.$1;
      _datePreview = result?.$2;
    });
  }

  Future<void> _submitQuick() async {
    final raw = _quickCtrl.text.trim();
    if (raw.isEmpty) return;

    final title = _parsedDate != null ? _stripDateTerms(raw).trim() : raw;

    await ref.read(todoActionsProvider.notifier).create(
          title:       title.isEmpty ? raw : title,
          scheduledAt: _parsedDate,
        );

    _quickCtrl.clear();
    setState(() {
      _parsedDate  = null;
      _datePreview = null;
    });
    _quickFocus.requestFocus();
  }

  // ── Suggestions ────────────────────────────────────────────────────────

  Future<void> _loadSuggestions() async {
    final texts = await ref.read(todoRepositoryProvider).getFrequentTaskTexts();
    if (mounted) setState(() => _suggestions = texts);
  }

  List<String> _visibleSuggestions() => _suggestions
      .where((s) => !_dismissedSuggestions.contains(s))
      .toList();

  Future<void> _applyRecurrence(
      String normalized, TodoRecurrence rec, List<Todo> allTodos) async {
    // Find the most recent todo whose title matches the normalized key.
    final match = allTodos
        .where((t) => PatternService.normalize(t.title) == normalized)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (match.isEmpty) return;
    await ref
        .read(todoRepositoryProvider)
        .updateTodo(match.first.copyWith(recurrence: rec));
    setState(() => _dismissedSuggestions.add(normalized));
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(
      todoStreamProvider(filter: _filter, search: _search),
    );

    final themeMode       = ref.watch(appThemeModeProvider);
    final platformDark    = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark          = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && platformDark);

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search todos…',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onChanged: (v) =>
                    setState(() => _search = v.isEmpty ? null : v),
              )
            : GestureDetector(
                // Long-press title toggles pencil scratch sound (Pass 2).
                onLongPress: () {
                  AudioService.enabled = !AudioService.enabled;
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(SnackBar(
                      content: Text(
                          AudioService.enabled ? 'Sound on' : 'Sound off'),
                      duration: const Duration(seconds: 1),
                    ));
                },
                child: Text(
                  'My Todos',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            tooltip: _showSearch ? 'Close search' : 'Search',
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchCtrl.clear();
                _search = null;
              }
            }),
          ),
          // Sun/moon icon reflects actual rendered brightness (Pass 1).
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: 'Toggle theme',
            onPressed: ref.read(appThemeModeProvider.notifier).toggle,
          ),
        ],
      ),
      // 560px max width centred (Pass 1).
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              FilterBar(
                selected: _filter,
                onChanged: (f) {
                  setState(() => _filter = f);
                  if (f == TodoFilter.completed) _loadSuggestions();
                },
              ),

              // ── Quick-add input (Pass 5) ─────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _quickCtrl,
                      focusNode:  _quickFocus,
                      onChanged:  _onQuickChanged,
                      onSubmitted: (_) => _submitQuick(),
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.dmSans(fontSize: 16),
                      decoration: InputDecoration(
                        hintText:   'Add a task…',
                        suffixIcon: _quickCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.add,
                                    size: 20, color: scheme.primary),
                                onPressed: _submitQuick,
                                splashRadius: 16,
                              )
                            : null,
                      ),
                    ),
                    // Date preview row (Pass 5).
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: _datePreview != null
                          ? Padding(
                              key: const ValueKey('preview'),
                              padding: const EdgeInsets.only(top: 4, left: 2),
                              child: Text(
                                '→ $_datePreview',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: scheme.primary,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('no-preview')),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),

              Expanded(
                child: todos.when(
                  data: (list) => _buildList(list),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      'Something went wrong\n$e',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/todo/new'),
        tooltip:   'Add todo',
        child:     const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(List<Todo> list) {
    final suggestions = _filter == TodoFilter.completed
        ? _visibleSuggestions()
        : <String>[];

    final hasSuggestions = suggestions.isNotEmpty;

    if (list.isEmpty && !hasSuggestions) {
      return EmptyState(filter: _filter);
    }

    // Suggestion rows: header + N cards.
    final extraCount = hasSuggestions ? suggestions.length + 1 : 0;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      itemCount: list.length + extraCount,
      itemBuilder: (_, i) {
        if (i < list.length) return TodoTile(todo: list[i]);

        final si = i - list.length;
        if (si == 0) {
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              'Patterns detected',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          );
        }
        final s = suggestions[si - 1];
        return PatternSuggestionCard(
          key:              ValueKey('sug_$s'),
          normalizedText:   s,
          onDismiss:        () =>
              setState(() => _dismissedSuggestions.add(s)),
          onSetRecurrence:  (rec) => _applyRecurrence(s, rec, list),
        );
      },
    );
  }

  // ── Natural language date parser (Pass 5) ─────────────────────────────

  static const _kDays = [
    'monday', 'tuesday', 'wednesday', 'thursday',
    'friday', 'saturday', 'sunday',
  ];

  /// Returns `(DateTime, previewLabel)` or null if nothing recognised.
  (DateTime, String)? _parseDate(String input) {
    if (input.trim().isEmpty) return null;
    final lower = input.toLowerCase();
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? base;
    String?   label;

    if (lower.contains('today')) {
      base  = today;
      label = 'Today';
    } else if (lower.contains('tomorrow')) {
      base  = today.add(const Duration(days: 1));
      label = 'Tomorrow';
    } else {
      for (var i = 0; i < _kDays.length; i++) {
        if (!lower.contains(_kDays[i])) continue;
        var daysAhead = (i + 1) - now.weekday;
        if (daysAhead <= 0) daysAhead += 7;
        if (lower.contains('next')) daysAhead += 7;
        base  = today.add(Duration(days: daysAhead));
        label = _kDays[i][0].toUpperCase() + _kDays[i].substring(1);
        break;
      }
    }

    if (base == null) return null;

    // Optional time: "3pm", "9am", "10:30am"
    final timeRe = RegExp(
        r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)',
        caseSensitive: false);
    final m = timeRe.firstMatch(lower);
    int hour = 0, minute = 0;
    String timePart = '';
    if (m != null) {
      hour   = int.parse(m.group(1)!);
      minute = int.parse(m.group(2) ?? '0');
      final ampm = m.group(3)!.toLowerCase();
      if (ampm == 'pm' && hour != 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      timePart = ' ${_fmtTime(hour, minute)}';
    }

    return (
      DateTime(base.year, base.month, base.day, hour, minute),
      '$label$timePart',
    );
  }

  String _fmtTime(int hour, int minute) {
    final h   = hour % 12 == 0 ? 12 : hour % 12;
    final min = minute > 0 ? ':${minute.toString().padLeft(2, '0')}' : '';
    return '$h$min ${hour < 12 ? 'AM' : 'PM'}';
  }

  String _stripDateTerms(String text) {
    String r = text;
    for (final d in _kDays) {
      r = r.replaceAll(RegExp(r'\b' + d + r'\b', caseSensitive: false), '');
    }
    r = r
        .replaceAll(RegExp(r'\btoday\b',    caseSensitive: false), '')
        .replaceAll(RegExp(r'\btomorrow\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bnext\b',     caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(at|@)\b',   caseSensitive: false), '')
        .replaceAll(RegExp(r'\d{1,2}(?::\d{2})?\s*(?:am|pm)',
                           caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return r;
  }
}

