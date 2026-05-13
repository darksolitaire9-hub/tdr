import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:todo_app/core/data/local/app_database.dart';
import 'package:todo_app/features/todos/data/repositories/todo_repository_impl.dart';
import 'package:todo_app/features/todos/domain/models/todo.dart';

class MockDb extends Mock implements AppDatabase {}

void main() {
  late MockDb db;
  late TodoRepositoryImpl repo;
  final ts = DateTime(2024);

  setUpAll(() {
    registerFallbackValue(const TodosCompanion());
  });

  setUp(() {
    db = MockDb();
    repo = TodoRepositoryImpl(db);
  });

  TodoData todoData({
    String id = '1',
    String title = 'Test',
    bool done = false,
    String priority = 'medium',
    double posX = 0.0,
    double posY = 0.0,
    double rotation = 0.0,
  }) =>
      TodoData(
        id: id,
        title: title,
        description: '',
        isCompleted: done,
        priority: priority,
        createdAt: ts,
        completedAt: null,
        posX: posX,
        posY: posY,
        rotation: rotation,
      );

  group('watchTodos filter → db argument', () {
    void stubWatch() {
      when(() => db.watchTodos(
            completed: any(named: 'completed'),
            search: any(named: 'search'),
          )).thenAnswer((_) => Stream.value([]));
    }

    test('all → completed: null', () {
      stubWatch();
      repo.watchTodos();
      verify(() => db.watchTodos(completed: null, search: null)).called(1);
    });

    test('active → completed: false', () {
      stubWatch();
      repo.watchTodos(filter: TodoFilter.active);
      verify(() => db.watchTodos(completed: false, search: null)).called(1);
    });

    test('completed → completed: true', () {
      stubWatch();
      repo.watchTodos(filter: TodoFilter.completed);
      verify(() => db.watchTodos(completed: true, search: null)).called(1);
    });

    test('maps priority string to enum', () async {
      when(() => db.watchTodos(
            completed: any(named: 'completed'),
            search: any(named: 'search'),
          )).thenAnswer((_) => Stream.value([todoData(priority: 'high')]));
      final list = await repo.watchTodos().first;
      expect(list.first.priority, TodoPriority.high);
    });
  });

  group('toggleCompletion', () {
    test('flips false → true', () async {
      when(() => db.getTodoById('1')).thenAnswer((_) async => todoData());
      when(() => db.toggleTodo('1', completed: true))
          .thenAnswer((_) async => true);
      await repo.toggleCompletion('1');
      verify(() => db.toggleTodo('1', completed: true)).called(1);
    });

    test('flips true → false', () async {
      when(() => db.getTodoById('1'))
          .thenAnswer((_) async => todoData(done: true));
      when(() => db.toggleTodo('1', completed: false))
          .thenAnswer((_) async => true);
      await repo.toggleCompletion('1');
      verify(() => db.toggleTodo('1', completed: false)).called(1);
    });

    test('no-ops when todo not found', () async {
      when(() => db.getTodoById('x')).thenAnswer((_) async => null);
      await repo.toggleCompletion('x');
      verifyNever(
          () => db.toggleTodo(any(), completed: any(named: 'completed')));
    });
  });

  group('createTodo', () {
    setUp(() {
      when(() => db.insertTodo(any())).thenAnswer((_) async {});
    });

    test('generates UUID when id is empty', () async {
      await repo.createTodo(Todo(id: '', title: 'New', createdAt: ts));
      final cap = verify(() => db.insertTodo(captureAny())).captured.single
          as TodosCompanion;
      expect(cap.id.value, isNotEmpty);
      expect(cap.id.value.length, greaterThan(10));
    });

    test('uses provided id when non-empty', () async {
      await repo.createTodo(Todo(id: 'my-id', title: 'X', createdAt: ts));
      final cap = verify(() => db.insertTodo(captureAny())).captured.single
          as TodosCompanion;
      expect(cap.id.value, 'my-id');
    });

    test('trims whitespace from title', () async {
      await repo.createTodo(Todo(id: '', title: '  Hello  ', createdAt: ts));
      final cap = verify(() => db.insertTodo(captureAny())).captured.single
          as TodosCompanion;
      expect(cap.title.value, 'Hello');
    });
  });
}
