import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/todo.dart';

class PatternSuggestionCard extends StatefulWidget {
  const PatternSuggestionCard({
    super.key,
    required this.normalizedText,
    required this.onDismiss,
    required this.onSetRecurrence,
  });

  final String normalizedText;
  final VoidCallback onDismiss;
  final ValueChanged<TodoRecurrence> onSetRecurrence;

  @override
  State<PatternSuggestionCard> createState() => _PatternSuggestionCardState();
}

class _PatternSuggestionCardState extends State<PatternSuggestionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _slide = Tween<double>(begin: 20, end: 0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _slide.value),
        child:  Opacity(opacity: _fade.value, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
        decoration: BoxDecoration(
          color:        scheme.surface,
          border:       Border.all(color: scheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"${widget.normalizedText}"',
                    style: GoogleFonts.dmSans(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'You do this often — make it recurring?',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  Row(
                    children: [
                      _pill('Daily',  () => widget.onSetRecurrence(TodoRecurrence.daily)),
                      _pill('Weekly', () => widget.onSetRecurrence(TodoRecurrence.weekly)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon:        const Icon(Icons.close, size: 16),
              onPressed:   widget.onDismiss,
              padding:     EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, VoidCallback onTap) => TextButton(
        style: TextButton.styleFrom(
          padding:         const EdgeInsets.symmetric(horizontal: 8),
          minimumSize:     Size.zero,
          tapTargetSize:   MaterialTapTargetSize.shrinkWrap,
          textStyle:       GoogleFonts.dmSans(fontSize: 13),
        ),
        onPressed: onTap,
        child:     Text(label),
      );
}

