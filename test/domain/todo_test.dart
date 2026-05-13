import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todos/domain/models/todo.dart';

void main() {
  final ts = DateTime(2024);

  group('Todo', () {
    test('defaults are correct', () {
      final t = Todo(id: '1', title: 'T', createdAt: ts);
      expect(t.description, '');
      expect(t.isCompleted, false);
      expect(t.priority, TodoPriority.medium);
      expect(t.completedAt, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      final t = Todo(id: '1', title: 'T', createdAt: ts);
      final u = t.copyWith(isCompleted: true, priority: TodoPriority.high);
      expect(u.isCompleted, true);
      expect(u.priority, TodoPriority.high);
      expect(u.id, '1');
      expect(u.title, 'T');
    });

    test('value equality', () {
      final a = Todo(id: '1', title: 'T', createdAt: ts);
      final b = Todo(id: '1', title: 'T', createdAt: ts);
      expect(a, equals(b));
    });

    test('inequality on different id', () {
      final a = Todo(id: '1', title: 'T', createdAt: ts);
      final b = Todo(id: '2', title: 'T', createdAt: ts);
      expect(a, isNot(equals(b)));
    });
  });

  group('TodoPriority', () {
    test('byName round-trips all values', () {
      for (final p in TodoPriority.values) {
        expect(TodoPriority.values.byName(p.name), p);
      }
    });
  });

  group('TodoFilter', () {
    test('has all three cases', () {
      expect(
        TodoFilter.values,
        containsAll([TodoFilter.all, TodoFilter.active, TodoFilter.completed]),
      );
    });
  });
}
