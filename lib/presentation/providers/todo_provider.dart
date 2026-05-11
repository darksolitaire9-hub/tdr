import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/todo.dart';
import 'database_provider.dart';

part 'todo_provider.g.dart';

/// Reactive stream of todos. Re-emits automatically on any DB change.
@riverpod
Stream<List<Todo>> todoStream(
  Ref ref, {
  TodoFilter filter = TodoFilter.all,
  String? search,
}) =>
    ref.watch(todoRepositoryProvider).watchTodos(
          filter: filter,
          searchQuery: search,
        );

/// Write-only notifier. UI calls notifier methods; stream re-emits results.
@riverpod
class TodoActions extends _$TodoActions {
  @override
  void build() {}

  Future<void> create({
    required String title,
    String description = '',
    TodoPriority priority = TodoPriority.medium,
  }) =>
      ref.read(todoRepositoryProvider).createTodo(
            Todo(
              id: '',
              title: title,
              description: description,
              priority: priority,
              createdAt: DateTime.now(),
            ),
          );

  Future<void> update(Todo todo) =>
      ref.read(todoRepositoryProvider).updateTodo(todo);

  Future<void> delete(String id) =>
      ref.read(todoRepositoryProvider).deleteTodo(id);

  Future<void> toggle(String id) =>
      ref.read(todoRepositoryProvider).toggleCompletion(id);
}
