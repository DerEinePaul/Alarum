import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import 'core/services/alarm_service.dart';
import 'data/repositories/alarm_repository.dart';
import 'data/repositories/alarm_group_repository.dart';
import 'domain/models/alarm.dart';
import 'domain/models/alarm_group.dart';
import 'presentation/providers/alarm_provider.dart';
import 'presentation/providers/alarm_group_provider.dart';
import 'presentation/providers/stopwatch_provider.dart';
import 'presentation/providers/timer_provider.dart';
import 'presentation/screens/home_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Cross-platform color scheme builder
class CrossPlatformColorBuilder extends StatefulWidget {
  final Widget Function(ColorScheme lightScheme, ColorScheme darkScheme) builder;

  const CrossPlatformColorBuilder({super.key, required this.builder});

  @override
  State<CrossPlatformColorBuilder> createState() => _CrossPlatformColorBuilderState();
}

class _CrossPlatformColorBuilderState extends State<CrossPlatformColorBuilder> {
  ColorScheme? _lightScheme;
  ColorScheme? _darkScheme;

  @override
  void initState() {
    super.initState();
    _initializeColors();
  }

  Future<void> _initializeColors() async {
    if (Platform.isAndroid) {
      try {
        // Try to use dynamic colors on Android
        // Note: This is a simplified version. In a real app, you'd use the dynamic_color package
        // For now, we'll just use the fallback colors
        _setFallbackColors();
      } catch (e) {
        _setFallbackColors();
      }
    } else {
      _setFallbackColors();
    }
  }

  void _setFallbackColors() {
    setState(() {
      _lightScheme = ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.light,
      );
      _darkScheme = ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_lightScheme == null || _darkScheme == null) {
      // Loading state
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return widget.builder(_lightScheme!, _darkScheme!);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(AlarmAdapter());
  Hive.registerAdapter(AlarmGroupAdapter());

  // Initialize notifications
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Initialize alarm service
  await AlarmService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CrossPlatformColorBuilder(
      builder: (ColorScheme lightScheme, ColorScheme darkScheme) {

        return MultiProvider(
          providers: [
            Provider<AlarmRepository>(create: (_) => HiveAlarmRepository()),
            Provider<AlarmGroupRepository>(create: (_) => HiveAlarmGroupRepository()),
            ChangeNotifierProxyProvider<AlarmRepository, AlarmProvider>(
              create: (context) => AlarmProvider(context.read<AlarmRepository>()),
              update: (context, repository, previous) => previous ?? AlarmProvider(repository),
            ),
            ChangeNotifierProxyProvider<AlarmGroupRepository, AlarmGroupProvider>(
              create: (context) => AlarmGroupProvider(context.read<AlarmGroupRepository>()),
              update: (context, repository, previous) => previous ?? AlarmGroupProvider(repository),
            ),
            ChangeNotifierProvider<StopwatchProvider>(create: (_) => StopwatchProvider()),
            ChangeNotifierProvider<TimerProvider>(create: (_) => TimerProvider(const Duration(minutes: 5))),
          ],
          child: MaterialApp(
            title: 'Alarum',
            theme: ThemeData(
              colorScheme: lightScheme,
              useMaterial3: true,
              fontFamily: 'Roboto',
              textTheme: const TextTheme(
                displayLarge: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -1.5,
                ),
                displayMedium: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.5,
                ),
                displaySmall: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w400,
                ),
                headlineLarge: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.25,
                ),
                headlineMedium: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                ),
                headlineSmall: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: darkScheme,
              useMaterial3: true,
              fontFamily: 'Roboto',
              textTheme: const TextTheme(
                displayLarge: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -1.5,
                ),
                displayMedium: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.5,
                ),
                displaySmall: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w400,
                ),
                headlineLarge: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.25,
                ),
                headlineMedium: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                ),
                headlineSmall: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            home: const HomeScreen(),
          ),
        );
      },
    );
  }
}
