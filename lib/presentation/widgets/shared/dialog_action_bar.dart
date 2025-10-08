import 'package:flutter/material.dart';

/// Material 3 Expressive Dialog Action Bar
/// 
/// Standard Action Bar für Dialoge mit Löschen/Speichern Buttons
/// Inspiriert von Android Material Design Guidelines
class DialogActionBar extends StatelessWidget {
  final VoidCallback? onDelete;
  final VoidCallback? onSave;
  final bool canSave;
  final String deleteLabel;
  final String saveLabel;
  final bool showDeleteButton;

  const DialogActionBar({
    super.key,
    this.onDelete,
    this.onSave,
    this.canSave = true,
    this.deleteLabel = 'Löschen',
    this.saveLabel = 'Speichern',
    this.showDeleteButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Delete Button (left aligned)
          if (showDeleteButton && onDelete != null)
            TextButton(
              onPressed: onDelete,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.error,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                deleteLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            )
          else
            const SizedBox.shrink(),
          
          // Spacer
          const Spacer(),
          
          // Save Button (right aligned)
          _AnimatedSaveButton(
            onSave: onSave,
            canSave: canSave,
            saveLabel: saveLabel,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

class _AnimatedSaveButton extends StatefulWidget {
  final VoidCallback? onSave;
  final bool canSave;
  final String saveLabel;
  final ColorScheme colorScheme;

  const _AnimatedSaveButton({
    required this.onSave,
    required this.canSave,
    required this.saveLabel,
    required this.colorScheme,
  });

  @override
  State<_AnimatedSaveButton> createState() => _AnimatedSaveButtonState();
}

class _AnimatedSaveButtonState extends State<_AnimatedSaveButton>
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
    if (widget.canSave && widget.onSave != null) {
      _controller.forward().then((_) {
        _controller.reverse();
      });
      widget.onSave!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: widget.canSave ? _scaleAnimation.value : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: widget.canSave
                  ? widget.colorScheme.primary
                  : widget.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: widget.canSave
                  ? [
                      BoxShadow(
                        color: widget.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              widget.saveLabel,
              style: TextStyle(
                color: widget.canSave
                    ? widget.colorScheme.onPrimary
                    : widget.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
