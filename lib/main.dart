import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'app.dart';
import 'core/providers/theme_provider.dart';
import 'core/data/local/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  await _cloneRecurringTasks();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const App(),
    ),
  );
}

/// On every app open: for any recurring task completed before today, create a
/// fresh clone for today — but only if one doesn't already exist.
Future<void> _cloneRecurringTasks() async {
  const uuid = Uuid();
  final db = AppDatabase();
  try {
    final recurring = await db.getAllRecurringTodos();
    if (recurring.isEmpty) return;

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    for (final todo in recurring) {
      // Only clone completed tasks whose completion predates today.
      if (!todo.isCompleted) continue;
      if (todo.completedAt == null) continue;
      if (!todo.completedAt!.isBefore(todayMidnight)) continue;

      // Guard against duplicates if app is opened multiple times in a day.
      final existing = await db.findTodayTaskByTitle(todo.title, todayMidnight);
      if (existing != null) continue;

      await db.insertTodo(TodosCompanion.insert(
        id: uuid.v4(),
        title: todo.title,
        description: Value(todo.description),
        priority: Value(todo.priority),
        createdAt: todayMidnight,
        recurrence: Value(todo.recurrence),
      ));
    }
  } finally {
    await db.close();
  }
}
