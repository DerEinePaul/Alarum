import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/clock_widget.dart';
import '../widgets/stopwatch_widget.dart';
import '../widgets/timer_widget.dart';
import '../widgets/grouped_alarm_list_widget.dart';
import '../widgets/dialogs/unified_create_alarm_dialog.dart';
import '../../core/settings/app_settings.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const ClockWidget(),
    const StopwatchWidget(),
    const TimerWidget(),
    const GroupedAlarmListWidget(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'settings':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
      case 'screensaver':
        // TODO: Implementiere Bildschirmschoner
        _showComingSoonDialog(context, 'Bildschirmschoner');
        break;
      case 'privacy':
        // TODO: Implementiere Datenschutzerklärung
        _showComingSoonDialog(context, 'Datenschutzerklärung');
        break;
      case 'feedback':
        // TODO: Implementiere Feedback
        _showComingSoonDialog(context, 'Feedback senden');
        break;
      case 'help':
        // TODO: Implementiere Hilfe
        _showComingSoonDialog(context, 'Hilfe');
        break;
    }
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    final settings = context.read<AppSettings>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text(settings.getText('comingSoon')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(settings.getText('ok')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 600;
        return Scaffold(
          appBar: AppBar(
            title: Consumer<AppSettings>(
              builder: (context, settings, child) => TextButton(
                onPressed: () => _launchGitHub(),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface,
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Alarum',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            elevation: 0,
            actions: [
              Consumer<AppSettings>(
                builder: (context, settings, child) => PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
                  onSelected: (value) => _handleMenuSelection(context, value),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'screensaver',
                      child: Row(
                        children: [
                          Icon(Icons.display_settings, color: colorScheme.onSurface),
                          const SizedBox(width: 12),
                          Text(settings.getText('screenSaver')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings, color: colorScheme.onSurface),
                          const SizedBox(width: 12),
                          Text(settings.getText('settings')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'privacy',
                      child: Row(
                        children: [
                          Icon(Icons.privacy_tip, color: colorScheme.onSurface),
                          const SizedBox(width: 12),
                          Text(settings.getText('privacy')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'feedback',
                      child: Row(
                        children: [
                          Icon(Icons.feedback, color: colorScheme.onSurface),
                          const SizedBox(width: 12),
                          Text(settings.getText('feedback')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'help',
                      child: Row(
                        children: [
                          Icon(Icons.help, color: colorScheme.onSurface),
                          const SizedBox(width: 12),
                          Text(settings.getText('help')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: isDesktop
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _onItemTapped,
                      backgroundColor: colorScheme.surfaceContainerLow,
                      selectedIconTheme: IconThemeData(color: colorScheme.primary),
                      unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
                      selectedLabelTextStyle: TextStyle(color: colorScheme.primary),
                      unselectedLabelTextStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                      destinations: [
                        NavigationRailDestination(
                          icon: Icon(Icons.access_time),
                          label: Consumer<AppSettings>(
                            builder: (context, settings, child) => Text(settings.getText('clock')),
                          ),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.timer),
                          label: Consumer<AppSettings>(
                            builder: (context, settings, child) => Text(settings.getText('stopwatch')),
                          ),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.hourglass_empty),
                          label: Consumer<AppSettings>(
                            builder: (context, settings, child) => Text(settings.getText('timer')),
                          ),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.alarm),
                          label: Consumer<AppSettings>(
                            builder: (context, settings, child) => Text(settings.getText('alarms')),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Center(
                        child: _widgetOptions.elementAt(_selectedIndex),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: _widgetOptions.elementAt(_selectedIndex),
                ),
          floatingActionButton: (_selectedIndex == 3 || _selectedIndex == 0)
              ? AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    // Combine fade and scale for Material 3 expressive effect
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: _selectedIndex == 3
                      ? SizedBox(key: const ValueKey('alarm_fab'), child: _buildAlarmFAB(context))
                      : SizedBox(key: const ValueKey('clock_fab'), child: _buildClockFAB(context)),
                )
              : null,
          bottomNavigationBar: isDesktop
              ? null
              : Consumer<AppSettings>(
                  builder: (context, settings, child) => BottomNavigationBar(
                    items: [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.access_time),
                        label: settings.getText('clock'),
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.timer),
                        label: settings.getText('stopwatch'),
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.hourglass_empty),
                        label: settings.getText('timer'),
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.alarm),
                        label: settings.getText('alarms'),
                      ),
                    ],
                    currentIndex: _selectedIndex,
                    selectedItemColor: colorScheme.primary,
                    unselectedItemColor: colorScheme.onSurfaceVariant,
                    backgroundColor: colorScheme.surfaceContainerLow,
                    onTap: _onItemTapped,
                  ),
                ),
        );
      },
    );
  }

  Widget? _buildAlarmFAB(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return FloatingActionButton(
      onPressed: () => _showQuickCreateAlarmDialog(context),
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      child: const Icon(Icons.add),
    );
  }

  Widget _buildClockFAB(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FloatingActionButton(
      onPressed: () {
        // For clock, open a quick add location dialog or mimic same '+' animation
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.read<AppSettings>().getText('addLocation')),
            content: Text(context.read<AppSettings>().getText('addLocation')),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(context.read<AppSettings>().getText('cancel'))),
            ],
          ),
        );
      },
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      child: const Icon(Icons.add),
    );
  }

  Future<void> _launchGitHub() async {
    final Uri url = Uri.parse('https://github.com/DerEinePaul/Alarum');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Fallback wenn URL nicht geöffnet werden kann
    }
  }

  void _showQuickCreateAlarmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UnifiedCreateAlarmDialog(),
    );
  }
}