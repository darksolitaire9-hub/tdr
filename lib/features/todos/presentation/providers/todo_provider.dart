import 'dart:math';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/todo.dart';
import 'database_provider.dart';

part 'todo_provider.g.dart';

@riverpod
Stream<List<Todo>> todoStream(
  Ref ref, {
  TodoFilter filter = TodoFilter.all,
  String? search,
}) =>
    ref.watch(todoRepositoryProvider).watchTodos(
          filter:      filter,
          searchQuery: search,
        );

@riverpod
class TodoActions extends _$TodoActions {
  @override
  void build() {}

  static final _rng = Random();

  Future<void> create({
    required String title,
    String description = '',
    TodoPriority priority = TodoPriority.medium,
    DateTime? scheduledAt,
  }) async {
    final repo = ref.read(todoRepositoryProvider);
    
    // Random placement within a central zone (0-300 range)
    final posX     = _rng.nextDouble() * 200 + 50; 
    final posY     = _rng.nextDouble() * 200 + 100;
    final rotation = (_rng.nextDouble() - 0.5) * 0.2; // ±0.1 radians (~5.7 degrees)

    await repo.createTodo(Todo(
      id:          '',
      title:       title,
      description: description,
      priority:    priority,
      createdAt:   DateTime.now(),
      scheduledAt: scheduledAt,
      posX:        posX,
      posY:        posY,
      rotation:    rotation,
    ));
    await repo.recordTaskText(title);
  }

  Future<void> update(Todo todo) =>
      ref.read(todoRepositoryProvider).updateTodo(todo);

  Future<void> updatePosition(String id, double x, double y) async {
    final repo = ref.read(todoRepositoryProvider);
    final todo = await repo.getTodoById(id);
    if (todo == null) return;
    await repo.updateTodo(todo.copyWith(posX: x, posY: y));
  }

  Future<void> delete(String id) =>
      ref.read(todoRepositoryProvider).deleteTodo(id);

  Future<void> toggle(String id) =>
      ref.read(todoRepositoryProvider).toggleCompletion(id);
}

