import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'dart:io' show Platform;

// Core
import 'core/services/alarm_service.dart';
import 'core/settings/app_settings.dart';

// Data Layer
import 'data/repositories/alarm_repository.dart';
import 'data/repositories/alarm_group_repository.dart';
import 'data/repositories/label_repository.dart';
import 'data/services/android_alarm_scheduler.dart';
import 'data/services/android_notification_manager.dart';
import 'data/services/android_permission_manager.dart';

// Domain Layer
import 'domain/models/alarm.dart';
import 'domain/models/alarm_group.dart';
import 'domain/services/alarm_scheduler.dart';
import 'domain/services/notification_manager.dart';
import 'domain/services/permission_manager.dart';

// Presentation Layer
import 'presentation/providers/alarm_provider.dart';
import 'presentation/providers/alarm_group_provider.dart';
import 'presentation/providers/stopwatch_provider.dart';
import 'presentation/providers/timer_provider.dart';
import 'presentation/providers/label_provider.dart';
import 'presentation/controllers/alarm_controller.dart';
import 'presentation/controllers/alarm_permission_controller.dart';
import 'presentation/screens/home_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ═══════════════════════════════════════════════════════════
  // HIVE INITIALIZATION
  // ═══════════════════════════════════════════════════════════
  await Hive.initFlutter();
  Hive.registerAdapter(AlarmAdapter());
  Hive.registerAdapter(AlarmGroupAdapter());
  
  // Open Hive Boxes
  await Hive.openBox<Alarm>('alarms');
  await Hive.openBox<AlarmGroup>('alarm_groups');
  await Hive.openBox('labels');
  
  // ═══════════════════════════════════════════════════════════
  // NOTIFICATION INITIALIZATION
  // ═══════════════════════════════════════════════════════════
  const AndroidInitializationSettings initializationSettingsAndroid = 
      AndroidInitializationSettings('app_icon');
  const InitializationSettings initializationSettings = 
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
  // ═══════════════════════════════════════════════════════════
  // ANDROID NOTIFICATION CHANNELS
  // ═══════════════════════════════════════════════════════════
  if (!kIsWeb && Platform.isAndroid) {
    final notificationManager = AndroidNotificationManager();
    await notificationManager.initializeChannels();
    debugPrint('✅ Android notification channels initialized');
  }
  
  // ═══════════════════════════════════════════════════════════
  // ALARM SERVICE
  // ═══════════════════════════════════════════════════════════
  await AlarmService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ═══════════════════════════════════════════════════════════
        // SETTINGS
        // ═══════════════════════════════════════════════════════════
        ChangeNotifierProvider<AppSettings>(create: (_) => AppSettings()),
        
        // ═══════════════════════════════════════════════════════════
        // PLATFORM SERVICES (Conditional Android)
        // ═══════════════════════════════════════════════════════════
        if (!kIsWeb && Platform.isAndroid) ...[
          Provider<AlarmScheduler>(create: (_) => AndroidAlarmScheduler()),
          Provider<NotificationManager>(create: (_) => AndroidNotificationManager()),
          Provider<PermissionManager>(create: (_) => AndroidPermissionManager()),
        ],
        
        // ═══════════════════════════════════════════════════════════
        // REPOSITORIES
        // ═══════════════════════════════════════════════════════════
        Provider<AlarmRepository>(create: (_) => HiveAlarmRepository()),
        Provider<AlarmGroupRepository>(create: (_) => HiveAlarmGroupRepository()),
        Provider<LabelRepository>(create: (_) => HiveLabelRepository()),
        
        // ═══════════════════════════════════════════════════════════
        // CONTROLLERS (New Clean Architecture)
        // ═══════════════════════════════════════════════════════════
        if (!kIsWeb && Platform.isAndroid) ...[
          ChangeNotifierProxyProvider<PermissionManager, AlarmPermissionController>(
            create: (_) => AlarmPermissionController(AndroidPermissionManager()),
            update: (context, permissionManager, previous) {
              if (previous != null) {
                return previous;
              }
              final controller = AlarmPermissionController(permissionManager);
              // Delayed init to avoid blocking startup
              Future.microtask(() => controller.checkAllPermissions());
              return controller;
            },
          ),
          ChangeNotifierProxyProvider2<AlarmRepository, AlarmScheduler, AlarmController>(
            create: (_) => AlarmController(HiveAlarmRepository(), AndroidAlarmScheduler()),
            update: (context, repository, scheduler, previous) {
              if (previous != null) {
                return previous;
              }
              final controller = AlarmController(repository, scheduler);
              // Delayed init to avoid blocking startup
              Future.microtask(() => controller.initialize());
              return controller;
            },
          ),
        ],
        
        // ═══════════════════════════════════════════════════════════
        // LEGACY PROVIDERS (Keep for backwards compatibility)
        // ═══════════════════════════════════════════════════════════
        ChangeNotifierProxyProvider<AlarmRepository, AlarmProvider>(
          create: (context) => AlarmProvider(context.read<AlarmRepository>()),
          update: (context, repository, previous) => previous ?? AlarmProvider(repository),
        ),
        ChangeNotifierProxyProvider<AlarmGroupRepository, AlarmGroupProvider>(
          create: (context) => AlarmGroupProvider(context.read<AlarmGroupRepository>()),
          update: (context, repository, previous) => previous ?? AlarmGroupProvider(repository),
        ),
        ChangeNotifierProvider<LabelProvider>(
          create: (context) => LabelProvider(context.read<LabelRepository>()),
        ),
        
        // ═══════════════════════════════════════════════════════════
        // UTILITY PROVIDERS
        // ═══════════════════════════════════════════════════════════
        ChangeNotifierProvider<StopwatchProvider>(create: (_) => StopwatchProvider()),
        ChangeNotifierProvider<TimerProvider>(create: (_) => TimerProvider(const Duration(minutes: 5))),
      ],
      // Wrap MaterialApp mit Consumer für Theme-Reaktivität
      child: Consumer<AppSettings>(
        builder: (context, settings, _) {
          return DynamicColorBuilder(
            builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
              // Material You Dynamic Colors - IMMER aktiviert!
              final lightScheme = (lightDynamic != null)
                  ? lightDynamic
                  : ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light);
              
              final darkScheme = (darkDynamic != null)
                  ? darkDynamic
                  : ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark);

              return MaterialApp(
                title: 'Alarum',
                themeMode: settings.themeMode, // Dark/Light/System aus Settings!
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
            );
          },
        );
      },
      ),
    );
  }
}
