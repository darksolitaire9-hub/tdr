import '../models/todo.dart';

/// Port (DDD) — data layer implements this interface.
abstract interface class ITodoRepository {
  /// Reactive stream; re-emits when matching todos change.
  Stream<List<Todo>> watchTodos({
    TodoFilter filter = TodoFilter.all,
    String? searchQuery,
  });

  Future<Todo?> getTodoById(String id);
  Future<void> createTodo(Todo todo);
  Future<void> updateTodo(Todo todo);
  Future<void> deleteTodo(String id);
  Future<void> toggleCompletion(String id);
}
