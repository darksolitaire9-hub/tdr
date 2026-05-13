import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('TodoData')
class Todos extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 500)();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get scheduledAt => dateTime().nullable()();
  TextColumn get recurrence => text().nullable()();
  RealColumn get posX => real().withDefault(const Constant(0.0))();
  RealColumn get posY => real().withDefault(const Constant(0.0))();
  RealColumn get rotation => real().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TaskFrequencyData')
class TaskFrequencies extends Table {
  TextColumn get normalizedText => text()();
  IntColumn get count => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {normalizedText};
}

@DriftDatabase(tables: [Todos, TaskFrequencies])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(todos, todos.scheduledAt);
            await m.addColumn(todos, todos.recurrence);
            await m.createTable(taskFrequencies);
          }
          if (from < 3) {
            await m.addColumn(todos, todos.posX);
            await m.addColumn(todos, todos.posY);
            await m.addColumn(todos, todos.rotation);
          }
        },
      );

  static QueryExecutor _openConnection() => driftDatabase(name: 'todo_db');

  // ── Todos ────────────────────────────────────────────────────────────────

  Stream<List<TodoData>> watchTodos({bool? completed, String? search}) {
    return (select(todos)
          ..where((t) {
            Expression<bool> cond = const Constant(true);
            if (completed != null) {
              cond = cond & t.isCompleted.equals(completed);
            }
            if (search != null && search.isNotEmpty) {
              cond = cond &
                  (t.title.like('%$search%') | t.description.like('%$search%'));
            }
            return cond;
          })
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.isCompleted, mode: OrderingMode.asc),
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<TodoData?> getTodoById(String id) =>
      (select(todos)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<TodoData>> getAllRecurringTodos() =>
      (select(todos)..where((t) => t.recurrence.isNotNull())).get();

  Future<TodoData?> findTodayTaskByTitle(
          String title, DateTime todayMidnight) =>
      (select(todos)
            ..where((t) =>
                t.title.equals(title) &
                t.isCompleted.equals(false) &
                t.createdAt.isBiggerOrEqualValue(todayMidnight)))
          .getSingleOrNull();

  Future<void> insertTodo(TodosCompanion row) => into(todos).insert(row);

  Future<bool> updateTodoById(TodosCompanion data) async {
    final count = await (update(todos)
          ..where((t) => t.id.equals(data.id.value)))
        .write(data);
    return count > 0;
  }

  Future<int> deleteTodoById(String id) =>
      (delete(todos)..where((t) => t.id.equals(id))).go();

  Future<bool> toggleTodo(String id, {required bool completed}) async {
    final count = await (update(todos)..where((t) => t.id.equals(id)))
        .write(TodosCompanion(
      isCompleted: Value(completed),
      completedAt: Value(completed ? DateTime.now() : null),
    ));
    return count > 0;
  }

  // ── TaskFrequencies ──────────────────────────────────────────────────────

  Future<void> upsertFrequency(String normalizedText) => customStatement(
        'INSERT INTO task_frequencies (normalized_text, count) VALUES (?, 1) '
        'ON CONFLICT(normalized_text) DO UPDATE SET count = count + 1',
        [normalizedText],
      );

  Future<List<TaskFrequencyData>> getFrequentTasks({int minCount = 3}) =>
      (select(taskFrequencies)
            ..where((t) => t.count.isBiggerOrEqualValue(minCount))
            ..orderBy([
              (t) => OrderingTerm(expression: t.count, mode: OrderingMode.desc)
            ]))
          .get();
}
