import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo.freezed.dart';

enum TodoPriority { low, medium, high }

enum TodoFilter { all, active, completed }

/// Aggregate root for the todo domain.
@freezed
class Todo with _$Todo {
  const factory Todo({
    required String id,
    required String title,
    @Default('') String description,
    @Default(false) bool isCompleted,
    @Default(TodoPriority.medium) TodoPriority priority,
    required DateTime createdAt,
    DateTime? completedAt,
  }) = _Todo;
}
