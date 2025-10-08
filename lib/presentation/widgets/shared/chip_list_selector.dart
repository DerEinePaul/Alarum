import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Material 3 Expressive Chip List Selector
/// 
/// Horizontale scrollbare Tag-Liste mit + Button
/// Animierte Chip-Addition und Removal
class ChipListSelector extends StatefulWidget {
  final List<String> items;
  final ValueChanged<String> onItemAdded;
  final ValueChanged<String> onItemRemoved;
  final String addButtonLabel;
  final String hintText;

  const ChipListSelector({
    super.key,
    required this.items,
    required this.onItemAdded,
    required this.onItemRemoved,
    this.addButtonLabel = 'Tag',
    this.hintText = 'Tag hinzufügen',
  });

  @override
  State<ChipListSelector> createState() => _ChipListSelectorState();
}

class _ChipListSelectorState extends State<ChipListSelector> {
  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        title: Text(
          widget.addButtonLabel,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: widget.hintText,
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              widget.onItemAdded(value.trim());
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Abbrechen',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                widget.onItemAdded(value);
                Navigator.of(context).pop();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Existing chips
        ...widget.items.map((item) => _AnimatedChip(
              label: item,
              onDeleted: () {
                HapticFeedback.lightImpact();
                widget.onItemRemoved(item);
              },
              colorScheme: colorScheme,
            )),
        // Add button
        _AddChipButton(
          label: widget.addButtonLabel,
          onTap: () => _showAddDialog(context),
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _AnimatedChip extends StatefulWidget {
  final String label;
  final VoidCallback onDeleted;
  final ColorScheme colorScheme;

  const _AnimatedChip({
    required this.label,
    required this.onDeleted,
    required this.colorScheme,
  });

  @override
  State<_AnimatedChip> createState() => _AnimatedChipState();
}

class _AnimatedChipState extends State<_AnimatedChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDelete() {
    _controller.reverse().then((_) {
      widget.onDeleted();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Opacity(
          opacity: _fadeAnimation.value,
          child: Chip(
            label: Text(
              widget.label,
              style: TextStyle(
                color: widget.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
            deleteIcon: Icon(
              Icons.close,
              size: 18,
              color: widget.colorScheme.onSecondaryContainer,
            ),
            onDeleted: _handleDelete,
            backgroundColor: widget.colorScheme.secondaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: widget.colorScheme.secondary.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddChipButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _AddChipButton({
    required this.label,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  State<_AddChipButton> createState() => _AddChipButtonState();
}

class _AddChipButtonState extends State<_AddChipButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: widget.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.colorScheme.outline.withValues(alpha: 0.5),
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  size: 18,
                  color: widget.colorScheme.onSurface,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
