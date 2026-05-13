import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo.freezed.dart';

enum TodoPriority { low, medium, high }

enum TodoFilter { all, active, completed }

enum TodoRecurrence { daily, weekly }

@freezed
sealed class Todo with _$Todo {
  const factory Todo({
    required String id,
    required String title,
    @Default('') String description,
    @Default(false) bool isCompleted,
    @Default(TodoPriority.medium) TodoPriority priority,
    required DateTime createdAt,
    DateTime? completedAt,
    DateTime? scheduledAt,
    TodoRecurrence? recurrence,
    // Spatial properties for Moodboard UI
    @Default(0.0) double posX,
    @Default(0.0) double posY,
    @Default(0.0) double rotation,
    @Default(250.0) double width,
    double? height,
    @Default(0) int colorIndex,
  }) = _Todo;
}
