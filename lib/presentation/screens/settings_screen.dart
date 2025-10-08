import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/settings/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Consumer<AppSettings>(
      builder: (context, settings, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(settings.getText('settings')),
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Spracheinstellungen
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.getText('language'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      RadioListTile<String>(
                        title: Text(settings.getText('german')),
                        value: 'de',
                        groupValue: settings.language,
                        onChanged: (value) {
                          if (value != null) {
                            settings.setLanguage(value);
                          }
                        },
                        activeColor: colorScheme.primary,
                      ),
                      RadioListTile<String>(
                        title: Text(settings.getText('english')),
                        value: 'en',
                        groupValue: settings.language,
                        onChanged: (value) {
                          if (value != null) {
                            settings.setLanguage(value);
                          }
                        },
                        activeColor: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Uhrzeitformat
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.getText('timeFormat'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      RadioListTile<bool>(
                        title: Text(settings.getText('24hour')),
                        subtitle: Text(settings.formatTime(DateTime.now().copyWith(hour: 14, minute: 30))),
                        value: true,
                        groupValue: settings.is24HourFormat,
                        onChanged: (value) {
                          if (value == true && !settings.is24HourFormat) {
                            settings.toggle24HourFormat();
                          }
                        },
                        activeColor: colorScheme.primary,
                      ),
                      RadioListTile<bool>(
                        title: Text(settings.getText('12hour')),
                        subtitle: Text(settings.formatTime(DateTime.now().copyWith(hour: 14, minute: 30))),
                        value: false,
                        groupValue: settings.is24HourFormat,
                        onChanged: (value) {
                          if (value == false && settings.is24HourFormat) {
                            settings.toggle24HourFormat();
                          }
                        },
                        activeColor: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Preview der aktuellen Zeit
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Vorschau',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        settings.formatTime(DateTime.now()),
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w300,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}