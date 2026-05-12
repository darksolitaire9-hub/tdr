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

  Future<void> create({
    required String title,
    String description = '',
    TodoPriority priority = TodoPriority.medium,
    DateTime? scheduledAt,
  }) async {
    final repo = ref.read(todoRepositoryProvider);
    await repo.createTodo(Todo(
      id:          '',
      title:       title,
      description: description,
      priority:    priority,
      createdAt:   DateTime.now(),
      scheduledAt: scheduledAt,
    ));
    await repo.recordTaskText(title);
  }

  Future<void> update(Todo todo) =>
      ref.read(todoRepositoryProvider).updateTodo(todo);

  Future<void> delete(String id) =>
      ref.read(todoRepositoryProvider).deleteTodo(id);

  Future<void> toggle(String id) =>
      ref.read(todoRepositoryProvider).toggleCompletion(id);
}

