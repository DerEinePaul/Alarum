import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dynamic_color/dynamic_color.dart';
// Conditional import für Workmanager (Mobile vs Web)
import 'package:workmanager/workmanager.dart' if (dart.library.html) 'web_stubs/workmanager.dart';
import 'core/services/alarm_service.dart';
import 'core/settings/app_settings.dart';
import 'data/repositories/alarm_repository.dart';
import 'data/repositories/alarm_group_repository.dart';
import 'domain/models/alarm.dart';
import 'domain/models/alarm_group.dart';
import 'presentation/providers/alarm_provider.dart';
import 'presentation/providers/alarm_group_provider.dart';
import 'presentation/providers/stopwatch_provider.dart';
import 'presentation/providers/timer_provider.dart';
import 'data/repositories/label_repository.dart';
import 'presentation/providers/label_provider.dart';
import 'presentation/screens/home_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

/// Background task handler für Workmanager (nur Mobile)
@pragma('vm:entry-point')
void callbackDispatcher() {
  // Nur auf Mobile Plattformen ausführen
  if (kIsWeb) return;
  
  Workmanager().executeTask((task, inputData) async {
    debugPrint("🔧 Background Task: $task");
    
    try {
      // Initialisiere minimal AlarmService für Background
      await AlarmService.initialize();
      
      switch (task) {
        case 'alarm_task':
          final alarmId = inputData?['alarmId'] as String?;
          if (alarmId != null) {
            debugPrint("⏰ Background Alarm triggered: $alarmId");
            await AlarmService.showCriticalNotification(
              alarmId,
              'Alarm!',
              'Weckzeit erreicht',
            );
            await AlarmService.playAlarmSound();
          }
          break;
          
        case 'timer_task':
          final timerDuration = inputData?['duration'] as int?;
          if (timerDuration != null) {
            debugPrint("⏲️ Background Timer finished: ${timerDuration}min");
            await AlarmService.showCriticalNotification(
              'timer_${DateTime.now().millisecondsSinceEpoch}',
              'Timer beendet!',
              'Timer ($timerDuration Minuten) ist abgelaufen',
            );
            await AlarmService.playAlarmSound();
          }
          break;
          
        default:
          debugPrint("🔧 Unbekannte Background Task: $task");
      }
    } catch (e) {
      debugPrint("❌ Background Task Error: $e");
    }
    
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(AlarmAdapter());
  Hive.registerAdapter(AlarmGroupAdapter());
  // Ensure boxes exist
  await Hive.openBox<Alarm>('alarms');
  await Hive.openBox<AlarmGroup>('alarm_groups');
  await Hive.openBox('labels');

  // Initialize notifications
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Initialize alarm service
  await AlarmService.initialize();
  
  // Initialize Workmanager für Background-Alarme (nur Mobile)
  if (!kIsWeb) {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      debugPrint("✅ Workmanager initialisiert für Background-Alarme");
    } catch (e) {
      debugPrint("❌ Workmanager Initialisierung fehlgeschlagen: $e");
    }
  } else {
    debugPrint("ℹ️ Web-Plattform: Workmanager übersprungen");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // Use dynamic colors from the system
          lightScheme = lightDynamic;
          darkScheme = darkDynamic;
        } else {
          // Fallback to static colors
          lightScheme = ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          );
          darkScheme = ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          );
        }

        return MultiProvider(
          providers: [
            ChangeNotifierProvider<AppSettings>(create: (_) => AppSettings()),
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
            Provider<LabelRepository>(create: (_) => HiveLabelRepository()),
            ChangeNotifierProvider<LabelProvider>(create: (context) => LabelProvider(context.read<LabelRepository>())),
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
