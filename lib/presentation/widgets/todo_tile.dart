import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/models/todo.dart';
import '../providers/todo_provider.dart';

class TodoTile extends ConsumerWidget {
  const TodoTile({super.key, required this.todo});

  final Todo todo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Slidable(
      key: ValueKey(todo.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (_) =>
                ref.read(todoActionsProvider.notifier).delete(todo.id),
            backgroundColor: scheme.errorContainer,
            foregroundColor: scheme.error,
            icon: Icons.delete_outline,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/todo/edit/${todo.id}'),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _PriorityDot(priority: todo.priority),
                Checkbox(
                  value: todo.isCompleted,
                  onChanged: (_) =>
                      ref.read(todoActionsProvider.notifier).toggle(todo.id),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyLarge?.copyWith(
                          decoration: todo.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: todo.isCompleted
                              ? scheme.onSurface.withOpacity(0.4)
                              : null,
                        ),
                      ),
                      if (todo.description.isNotEmpty)
                        Text(
                          todo.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurface.withOpacity(0.55),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.05, end: 0);
  }
}

class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.priority});

  final TodoPriority priority;

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: switch (priority) {
            TodoPriority.low => AppColors.priorityLow,
            TodoPriority.medium => AppColors.priorityMedium,
            TodoPriority.high => AppColors.priorityHigh,
          },
        ),
      );
}
