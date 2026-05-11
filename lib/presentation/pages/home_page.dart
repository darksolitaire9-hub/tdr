import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/theme_provider.dart';
import '../../domain/models/todo.dart';
import '../providers/todo_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_bar.dart';
import '../widgets/todo_tile.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  var _filter = TodoFilter.all;
  String? _search;
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(
      todoStreamProvider(filter: _filter, search: _search),
    );

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search todos...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onChanged: (v) =>
                    setState(() => _search = v.isEmpty ? null : v),
              )
            : const Text('My Todos'),
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
          IconButton(
            icon: const Icon(Icons.brightness_6_outlined),
            tooltip: 'Toggle theme',
            onPressed: ref.read(appThemeModeProvider.notifier).toggle,
          ),
        ],
      ),
      body: Column(
        children: [
          FilterBar(
            selected: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
          Expanded(
            child: todos.when(
              data: (list) => list.isEmpty
                  ? EmptyState(filter: _filter)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: list.length,
                      itemBuilder: (_, i) => TodoTile(todo: list[i]),
                    ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/todo/new'),
        tooltip: 'Add todo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
