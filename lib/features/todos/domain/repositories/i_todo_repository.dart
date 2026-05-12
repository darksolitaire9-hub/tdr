import '../models/todo.dart';

abstract interface class ITodoRepository {
  Stream<List<Todo>> watchTodos({
    TodoFilter filter = TodoFilter.all,
    String? searchQuery,
  });

  Future<Todo?> getTodoById(String id);
  Future<List<Todo>> getRecurringTodos();
  Future<void> createTodo(Todo todo);
  Future<void> updateTodo(Todo todo);
  Future<void> deleteTodo(String id);
  Future<void> toggleCompletion(String id);

  Future<void> recordTaskText(String text);
  Future<List<String>> getFrequentTaskTexts({int minCount = 3});
}

