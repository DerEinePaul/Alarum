import 'package:flutter/material.dart';

/// Material 3 Expressive Permission Request Dialog
/// 
/// Zeigt eine ansprechende Erklärung warum Permissions benötigt werden
/// mit Animationen und klaren Call-to-Actions.
class PermissionRequestDialog extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<PermissionExplanation> explanations;
  final VoidCallback onGrantPressed;
  final VoidCallback? onDenyPressed;

  const PermissionRequestDialog({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.explanations,
    required this.onGrantPressed,
    this.onDenyPressed,
  });

  @override
  State<PermissionRequestDialog> createState() => _PermissionRequestDialogState();
}

class _PermissionRequestDialogState extends State<PermissionRequestDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Icon
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 64,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Description
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                widget.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Explanation Cards
            ...widget.explanations.asMap().entries.map((entry) {
              final index = entry.key;
              final explanation = entry.value;
              
              return SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: index < widget.explanations.length - 1 ? 12 : 0,
                    ),
                    child: _ExplanationCard(
                      icon: explanation.icon,
                      title: explanation.title,
                      description: explanation.description,
                      colorScheme: colorScheme,
                    ),
                  ),
                ),
              );
            }),
            
            const SizedBox(height: 32),
            
            // Action Buttons
            FadeTransition(
              opacity: _fadeAnimation,
              child: Row(
                children: [
                  if (widget.onDenyPressed != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          widget.onDenyPressed?.call();
                          Navigator.of(context).pop(false);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: colorScheme.outline),
                        ),
                        child: const Text('Später'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: widget.onDenyPressed != null ? 1 : 2,
                    child: FilledButton(
                      onPressed: () {
                        widget.onGrantPressed();
                        Navigator.of(context).pop(true);
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: colorScheme.primary,
                      ),
                      child: const Text('Erlauben'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final ColorScheme colorScheme;

  const _ExplanationCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 24,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Permission Explanation Data Class
class PermissionExplanation {
  final IconData icon;
  final String title;
  final String description;

  const PermissionExplanation({
    required this.icon,
    required this.title,
    required this.description,
  });
}

/// Vordefinierte Permission Explanations
class AlarmPermissionExplanations {
  static const exactAlarm = PermissionExplanation(
    icon: Icons.alarm,
    title: 'Exakte Alarme',
    description: 'Alarme werden pünktlich ausgelöst, auch wenn das Gerät im Energiesparmodus ist.',
  );

  static const notification = PermissionExplanation(
    icon: Icons.notifications_active,
    title: 'Benachrichtigungen',
    description: 'Zeigt Alarme und Timer als Benachrichtigungen an.',
  );

  static const batteryOptimization = PermissionExplanation(
    icon: Icons.battery_charging_full,
    title: 'Akku-Optimierung',
    description: 'Verhindert, dass Android Alarme verzögert oder blockiert.',
  );

  static const bootComplete = PermissionExplanation(
    icon: Icons.restart_alt,
    title: 'Nach Neustart',
    description: 'Stellt Alarme nach einem Geräte-Neustart wieder her.',
  );

  static const fullScreenIntent = PermissionExplanation(
    icon: Icons.screen_lock_portrait,
    title: 'Sperrbildschirm',
    description: 'Zeigt Alarme auch auf dem gesperrten Bildschirm an.',
  );
}
