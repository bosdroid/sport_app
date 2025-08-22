import 'package:bjj_dairy/providers/ai_analyzer_provider.dart';
import 'package:bjj_dairy/providers/app_provider.dart';
import 'package:bjj_dairy/providers/auth_provider.dart';
import 'package:bjj_dairy/providers/goal_provider.dart';
import 'package:bjj_dairy/providers/log_provider.dart';
import 'package:bjj_dairy/providers/note_provider.dart';
import 'package:bjj_dairy/providers/plan_provider.dart';
import 'package:bjj_dairy/providers/profile_provider.dart';
import 'package:bjj_dairy/providers/validation_provider.dart';
import 'package:bjj_dairy/route_observer.dart';
import 'package:bjj_dairy/services/notification_service.dart';
import 'package:bjj_dairy/utils/routes/routes.dart';
import 'package:bjj_dairy/utils/routes/routes_names.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService.init();
  tz.initializeTimeZones();
  var status = await Permission.notification.status;
  if (!status.isGranted) {
    await Permission.notification.request();
  }
  // Initialise the default Firebase app.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => ValidationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => LogProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        // ChangeNotifierProvider(create: (_) => PlanProvider()),
        ChangeNotifierProvider(
          create: (context) {
            final validationProvider = Provider.of<ValidationProvider>(context, listen: false);
            final planProvider = PlanProvider();
            planProvider.updateDependencies(validationProvider);
            return planProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => AiAnalyzerProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider())
      ],
      child: MaterialApp(
        navigatorObservers: [routeObserver],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0xFF2B303A),        // 👈 Primary
            secondary: Color(0xFF0C7C59),        // 👈 Accent color
          ),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: RoutesNames.splashScreen,
        onGenerateRoute: Routes.generateRoutes,
      ),
    );
  }
}