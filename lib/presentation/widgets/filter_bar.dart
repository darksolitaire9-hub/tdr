import 'package:flutter/material.dart';

import '../../domain/models/todo.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final TodoFilter selected;
  final ValueChanged<TodoFilter> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: TodoFilter.values.map((f) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_label(f)),
                selected: selected == f,
                onSelected: (_) => onChanged(f),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      );

  String _label(TodoFilter f) => switch (f) {
        TodoFilter.all => 'All',
        TodoFilter.active => 'Active',
        TodoFilter.completed => 'Done',
      };
}
