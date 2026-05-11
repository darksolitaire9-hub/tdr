import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../domain/models/todo.dart';
import '../../domain/repositories/i_todo_repository.dart';
import '../local/app_database.dart';

class TodoRepositoryImpl implements ITodoRepository {
  TodoRepositoryImpl(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  @override
  Stream<List<Todo>> watchTodos({
    TodoFilter filter = TodoFilter.all,
    String? searchQuery,
  }) {
    final bool? completed = switch (filter) {
      TodoFilter.active => false,
      TodoFilter.completed => true,
      TodoFilter.all => null,
    };
    return _db
        .watchTodos(completed: completed, search: searchQuery)
        .map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<Todo?> getTodoById(String id) async {
    final row = await _db.getTodoById(id);
    return row != null ? _toDomain(row) : null;
  }

  @override
  Future<void> createTodo(Todo todo) {
    final id = todo.id.isEmpty ? _uuid.v4() : todo.id;
    return _db.insertTodo(
      TodosCompanion.insert(
        id: id,
        title: todo.title.trim(),
        description: Value(todo.description.trim()),
        priority: Value(todo.priority.name),
        createdAt: todo.createdAt,
      ),
    );
  }

  @override
  Future<void> updateTodo(Todo todo) {
    return _db.updateTodoById(TodosCompanion(
      id: Value(todo.id),
      title: Value(todo.title.trim()),
      description: Value(todo.description.trim()),
      priority: Value(todo.priority.name),
      isCompleted: Value(todo.isCompleted),
      completedAt: Value(todo.completedAt),
    ));
  }

  @override
  Future<void> deleteTodo(String id) => _db.deleteTodoById(id);

  @override
  Future<void> toggleCompletion(String id) async {
    final row = await _db.getTodoById(id);
    if (row == null) return;
    await _db.toggleTodo(id, completed: !row.isCompleted);
  }

  Todo _toDomain(TodoData d) => Todo(
        id: d.id,
        title: d.title,
        description: d.description,
        isCompleted: d.isCompleted,
        priority: TodoPriority.values.byName(d.priority),
        createdAt: d.createdAt,
        completedAt: d.completedAt,
      );
}
