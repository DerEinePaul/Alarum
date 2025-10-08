import 'package:flutter/material.dart';

/// Material 3 Expressive Battery Optimization Dialog
/// 
/// Erklärt warum Battery Optimization deaktiviert werden sollte
/// und führt Benutzer durch die Schritte.
class BatteryOptimizationDialog extends StatefulWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback? onSkip;

  const BatteryOptimizationDialog({
    super.key,
    required this.onOpenSettings,
    this.onSkip,
  });

  @override
  State<BatteryOptimizationDialog> createState() => _BatteryOptimizationDialogState();
}

class _BatteryOptimizationDialogState extends State<BatteryOptimizationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
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
            // Pulsing Battery Icon
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.battery_charging_full,
                  size: 64,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Akku-Optimierung deaktivieren',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              'Damit Alarme zuverlässig funktionieren, auch wenn das Gerät im Energiesparmodus ist.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Step-by-Step Guide
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anleitung:',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStep(
                    '1.',
                    'Tippe auf "Einstellungen öffnen"',
                    colorScheme,
                  ),
                  const SizedBox(height: 8),
                  _buildStep(
                    '2.',
                    'Suche "Alarum" in der Liste',
                    colorScheme,
                  ),
                  const SizedBox(height: 8),
                  _buildStep(
                    '3.',
                    'Wähle "Nicht optimieren"',
                    colorScheme,
                  ),
                  const SizedBox(height: 8),
                  _buildStep(
                    '4.',
                    'Kehre zur App zurück',
                    colorScheme,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Warning Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.error.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: colorScheme.error,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ohne diese Einstellung könnten Alarme verzögert oder gar nicht ausgelöst werden.',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                if (widget.onSkip != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onSkip?.call();
                        Navigator.of(context).pop(false);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: colorScheme.outline),
                      ),
                      child: const Text('Überspringen'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      widget.onOpenSettings();
                      Navigator.of(context).pop(true);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: colorScheme.primary,
                    ),
                    icon: const Icon(Icons.settings, size: 20),
                    label: const Text('Einstellungen öffnen'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
