import 'package:flutter/material.dart';

/// Material 3 Permission Status Badge
/// 
/// Visuelles Feedback für Permission Status mit Animationen.
enum PermissionStatus {
  granted,
  denied,
  pending,
}

class PermissionStatusBadge extends StatefulWidget {
  final PermissionStatus status;
  final String permissionName;
  final VoidCallback? onTap;

  const PermissionStatusBadge({
    super.key,
    required this.status,
    required this.permissionName,
    this.onTap,
  });

  @override
  State<PermissionStatusBadge> createState() => _PermissionStatusBadgeState();
}

class _PermissionStatusBadgeState extends State<PermissionStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticIn,
    ));

    _startAnimation();
  }

  void _startAnimation() {
    if (widget.status == PermissionStatus.granted) {
      // Pulse animation for granted
      _animationController.repeat(reverse: true);
    } else if (widget.status == PermissionStatus.denied) {
      // Shake animation for denied (once)
      _animationController.forward();
    } else {
      // Spinner animation for pending
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(PermissionStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _animationController.reset();
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _getBackgroundColor(colorScheme),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getBorderColor(colorScheme),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Animated Icon
            _buildAnimatedIcon(colorScheme),
            const SizedBox(width: 12),
            
            // Permission Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.permissionName,
                    style: TextStyle(
                      color: _getTextColor(colorScheme),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: _getTextColor(colorScheme).withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Action Icon
            if (widget.onTap != null)
              Icon(
                Icons.chevron_right,
                color: _getTextColor(colorScheme),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(ColorScheme colorScheme) {
    switch (widget.status) {
      case PermissionStatus.granted:
        return ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
          ),
        );
        
      case PermissionStatus.denied:
        return AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cancel,
              color: Colors.red,
              size: 24,
            ),
          ),
        );
        
      case PermissionStatus.pending:
        return RotationTransition(
          turns: _animationController,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pending,
              color: Colors.orange,
              size: 24,
            ),
          ),
        );
    }
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (widget.status) {
      case PermissionStatus.granted:
        return Colors.green.withOpacity(0.1);
      case PermissionStatus.denied:
        return Colors.red.withOpacity(0.1);
      case PermissionStatus.pending:
        return Colors.orange.withOpacity(0.1);
    }
  }

  Color _getBorderColor(ColorScheme colorScheme) {
    switch (widget.status) {
      case PermissionStatus.granted:
        return Colors.green.withOpacity(0.5);
      case PermissionStatus.denied:
        return Colors.red.withOpacity(0.5);
      case PermissionStatus.pending:
        return Colors.orange.withOpacity(0.5);
    }
  }

  Color _getTextColor(ColorScheme colorScheme) {
    switch (widget.status) {
      case PermissionStatus.granted:
        return Colors.green.shade800;
      case PermissionStatus.denied:
        return Colors.red.shade800;
      case PermissionStatus.pending:
        return Colors.orange.shade800;
    }
  }

  String _getStatusText() {
    switch (widget.status) {
      case PermissionStatus.granted:
        return 'Erteilt';
      case PermissionStatus.denied:
        return 'Verweigert';
      case PermissionStatus.pending:
        return 'Ausstehend...';
    }
  }
}
