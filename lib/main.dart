import 'package:bjj_dairy/data/repositories/note_repository_impl.dart';
import 'package:bjj_dairy/data/repositories/plan_repository_impl.dart';
import 'package:bjj_dairy/data/repositories/profile_repository_impl.dart';
import 'package:bjj_dairy/data/repositories/validation_repository_impl.dart';
import 'package:bjj_dairy/presentation/providers/ai_analyzer_provider.dart';
import 'package:bjj_dairy/presentation/providers/app_provider.dart';
import 'package:bjj_dairy/presentation/providers/auth_provider.dart'
    as authProvider;
import 'package:bjj_dairy/presentation/providers/folder_provider.dart';
import 'package:bjj_dairy/presentation/providers/goal_provider.dart';
import 'package:bjj_dairy/presentation/providers/log_provider.dart';
import 'package:bjj_dairy/presentation/providers/note_provider.dart';
import 'package:bjj_dairy/presentation/providers/plan_provider.dart';
import 'package:bjj_dairy/presentation/providers/profile_provider.dart';
import 'package:bjj_dairy/presentation/providers/validation_provider.dart';
import 'package:bjj_dairy/route_observer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'core/routes/routes.dart';
import 'core/routes/routes_names.dart';
import 'data/repositories/ai_repository_impl.dart';
import 'data/repositories/app_repository_impl.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/folder_repository_impl.dart';
import 'data/repositories/goal_repository_impl.dart';
import 'data/repositories/log_repository_impl.dart';
import 'data/services/notification_service.dart';
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
        ChangeNotifierProvider(create: (_) => AppProvider(AppRepositoryImpl())),
        ChangeNotifierProvider(
            create: (_) => ValidationProvider(ValidationRepositoryImpl())),
        ChangeNotifierProvider(
            create: (_) => authProvider.AuthProvider(AuthRepositoryImpl(
                  FirebaseAuth.instance,
                  FirebaseDatabase.instance,
                ))),
        ChangeNotifierProvider(
            create: (_) => GoalProvider(
                  GoalRepositoryImpl(
                    goalsRef:
                        FirebaseDatabase.instance.ref().child('USERS/GOALS/'),
                    historyRef:
                        FirebaseDatabase.instance.ref().child('GOALS_HISTORY/'),
                    auth: FirebaseAuth.instance,
                  ),
                )),
        ChangeNotifierProvider(
            create: (_) => LogProvider(
                  LogRepositoryImpl(
                    logRef:
                        FirebaseDatabase.instance.ref().child('USERS/LOGS/'),
                    historyRef:
                        FirebaseDatabase.instance.ref().child('LOGS_HISTORY/'),
                    auth: FirebaseAuth.instance,
                  ),
                )),
        ChangeNotifierProvider(
            create: (_) => NoteProvider(NoteRepositoryImpl(
                notesRef: FirebaseDatabase.instance.ref().child('NOTES/')))),
        // ChangeNotifierProvider(create: (_) => PlanProvider()),
        ChangeNotifierProvider(
            // create: (_) => PlanProvider(
            //   PlanRepositoryImpl(
            //     plansRef: FirebaseDatabase.instance.ref().child("PLANS"),
            //     favouritesRef: FirebaseDatabase.instance.ref().child("FAVOURITES"),
            //     auth: FirebaseAuth.instance,
            //   ),
            //     )
            create: (context) {
              final validationProvider =
                  Provider.of<ValidationProvider>(context, listen: false);
              final planProvider = PlanProvider();
              planProvider.updateDependencies(validationProvider);
              return planProvider;
            },
            ),
        ChangeNotifierProvider(
          create: (_) => FolderProvider(
            FolderRepositoryImpl(
              foldersRef: FirebaseDatabase.instance.ref().child("FOLDERS"),
              auth: FirebaseAuth.instance,
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AiAnalyzerProvider(
            aiRepository: AiRepositoryImpl(
              promptRef: FirebaseDatabase.instance.ref().child('AI_PROMPT/'),
              notesRef: FirebaseDatabase.instance.ref().child('NOTES/'),
            ),
            goalRepository: GoalRepositoryImpl(
              goalsRef: FirebaseDatabase.instance.ref().child('USERS/GOALS/'),
              historyRef:
                  FirebaseDatabase.instance.ref().child('GOALS_HISTORY/'),
              auth: FirebaseAuth.instance,
            ),
            logRepository: LogRepositoryImpl(
              logRef: FirebaseDatabase.instance.ref().child('USERS/LOGS/'),
              historyRef:
                  FirebaseDatabase.instance.ref().child('LOGS_HISTORY/'),
              auth: FirebaseAuth.instance,
            ),
            noteRepository: NoteRepositoryImpl(
              notesRef: FirebaseDatabase.instance.ref().child('NOTES/'),
            ),
          ),
        ),
        ChangeNotifierProvider(
            create: (_) => ProfileProvider(ProfileRepositoryImpl(
                usersDetailsRef:
                    FirebaseDatabase.instance.ref().child('USERS_DETAILS/'),
                firebaseAuth: FirebaseAuth.instance)))
      ],
      child: MaterialApp(
        navigatorObservers: [routeObserver],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0xFF2B303A), // 👈 Primary
            secondary: Color(0xFF0C7C59), // 👈 Accent color
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
