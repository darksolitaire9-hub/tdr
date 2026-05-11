import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('TodoData')
class Todos extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 500)();
  TextColumn get description =>
      text().withDefault(const Constant(''))();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  // Stored as enum name string: 'low' | 'medium' | 'high'
  TextColumn get priority =>
      text().withDefault(const Constant('medium'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Todos])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() =>
      driftDatabase(name: 'todo_db');

  Stream<List<TodoData>> watchTodos({
    bool? completed,
    String? search,
  }) {
    return (select(todos)
          ..where((t) {
            Expression<bool> cond = const Constant(true);
            if (completed != null) {
              cond = cond & t.isCompleted.equals(completed);
            }
            if (search != null && search.isNotEmpty) {
              cond = cond &
                  (t.title.like('%$search%') |
                      t.description.like('%$search%'));
            }
            return cond;
          })
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.isCompleted, mode: OrderingMode.asc),
            (t) => OrderingTerm(
                expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<TodoData?> getTodoById(String id) =>
      (select(todos)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertTodo(TodosCompanion row) =>
      into(todos).insert(row);

  Future<bool> updateTodoById(TodosCompanion data) async {
    final count = await (update(todos)
          ..where((t) => t.id.equals(data.id.value)))
        .write(data);
    return count > 0;
  }

  Future<int> deleteTodoById(String id) =>
      (delete(todos)..where((t) => t.id.equals(id))).go();

  Future<bool> toggleTodo(String id, {required bool completed}) async {
    final count = await (update(todos)
          ..where((t) => t.id.equals(id)))
        .write(TodosCompanion(
      isCompleted: Value(completed),
      completedAt: Value(completed ? DateTime.now() : null),
    ));
    return count > 0;
  }
}
