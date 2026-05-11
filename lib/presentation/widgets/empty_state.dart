import 'package:flutter/material.dart';

import '../../domain/models/todo.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.filter});

  final TodoFilter filter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, msg) = switch (filter) {
      TodoFilter.all => (
          Icons.check_circle_outline,
          'No todos yet.\nTap + to add one!',
        ),
      TodoFilter.active => (Icons.task_alt, 'All done! 🎉'),
      TodoFilter.completed => (
          Icons.radio_button_unchecked,
          'Nothing completed yet.',
        ),
    };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 72, color: scheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface.withOpacity(0.45),
                ),
          ),
        ],
      ),
    );
  }
}
