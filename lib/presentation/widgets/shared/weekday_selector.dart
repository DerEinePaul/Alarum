import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Material 3 Expressive Weekday Selector
/// 
/// Kreisförmige Chips für Wochentags-Auswahl (M D M D F S S)
/// Mit Animationen und Haptic Feedback
class WeekdaySelector extends StatefulWidget {
  final Set<int> selectedDays;
  final ValueChanged<int> onDayToggle;
  final List<String> dayLabels;

  const WeekdaySelector({
    super.key,
    required this.selectedDays,
    required this.onDayToggle,
    this.dayLabels = const ['M', 'D', 'M', 'D', 'F', 'S', 'S'],
  });

  @override
  State<WeekdaySelector> createState() => _WeekdaySelectorState();
}

class _WeekdaySelectorState extends State<WeekdaySelector> {
  final Map<int, AnimationController> _controllers = {};

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleDayTap(int index) {
    HapticFeedback.lightImpact();
    widget.onDayToggle(index);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final isSelected = widget.selectedDays.contains(index);
        
        return _WeekdayChip(
          label: widget.dayLabels[index],
          isSelected: isSelected,
          onTap: () => _handleDayTap(index),
          colorScheme: colorScheme,
        );
      }),
    );
  }
}

class _WeekdayChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _WeekdayChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  State<_WeekdayChip> createState() => _WeekdayChipState();
}

class _WeekdayChipState extends State<_WeekdayChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _updateColorAnimation();
    
    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_WeekdayChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      _updateColorAnimation();
    }
  }

  void _updateColorAnimation() {
    _colorAnimation = ColorTween(
      begin: widget.colorScheme.surfaceContainerHighest,
      end: widget.colorScheme.primaryContainer,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap();
    // Pulse animation
    _controller.forward().then((_) {
      if (!widget.isSelected) {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isSelected
                      ? widget.colorScheme.primary
                      : widget.colorScheme.outline.withValues(alpha: 0.3),
                  width: widget.isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isSelected
                        ? widget.colorScheme.onPrimaryContainer
                        : widget.colorScheme.onSurface,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
